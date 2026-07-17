import 'dart:async';

import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/models/event.dart';
import 'package:event_planner/models/plannerEvent.dart';
import 'package:event_planner/repositories/planner_events_repository.dart';
import 'package:event_planner/repositories/planner_task_repository.dart';
import 'package:event_planner/screens/planner_tabs_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:event_planner/screens/planner/monthly_calender.dart';

class MyEvents extends StatefulWidget {
  const MyEvents({super.key});

  @override
  State<MyEvents> createState() => _MyEventsState();
}

class _MyEventsState extends State<MyEvents> {
  final TextEditingController _searchController = TextEditingController();

  List<Event> _events = [];
  List<Event> _filteredEvents = [];

  MyEventFilter _selectedFilter = MyEventFilter.all;
  MyEventStats _stats = const MyEventStats.empty();

  bool _isLoading = true;
  String? _errorMessage;
  bool _statusChanged = false;

  @override
  void initState() {
    super.initState();
    PlannerEventsRepository.cache.addListener(_onEventsChanged);
    _searchController.addListener(_filterEvents);

    if (PlannerEventsRepository.hasCache) {
      _events = PlannerEventsRepository.cachedEvents;
      _stats = PlannerEventsRepository.cachedStats;
      _filteredEvents = _applyFilters(_events);
      _isLoading = false;
      _prefetchTaskCaches();
      unawaited(PlannerEventsRepository.refreshInBackground());
    } else {
      unawaited(_loadEvents());
    }
  }

  @override
  void dispose() {
    PlannerEventsRepository.cache.removeListener(_onEventsChanged);
    _searchController.removeListener(_filterEvents);
    _searchController.dispose();
    super.dispose();
  }

  void _onEventsChanged() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _events = PlannerEventsRepository.cachedEvents;
        _stats = PlannerEventsRepository.cachedStats;
        _filteredEvents = _applyFilters(_events);
        _isLoading = false;
        _errorMessage = null;
      });

      _prefetchTaskCaches();
    });
  }

  Future<void> _loadEvents({bool forceRefresh = false}) async {
    if (!forceRefresh && PlannerEventsRepository.hasCache) {
      if (mounted) {
        setState(() {
          _events = PlannerEventsRepository.cachedEvents;
          _stats = PlannerEventsRepository.cachedStats;
          _filteredEvents = _applyFilters(_events);
          _isLoading = false;
          _errorMessage = null;
        });
      }
      _prefetchTaskCaches();
      unawaited(PlannerEventsRepository.refreshInBackground());
      return;
    }

    if (mounted && _events.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      await PlannerEventsRepository.loadEvents(forceRefresh: forceRefresh);
      if (!mounted) return;

      setState(() {
        _events = PlannerEventsRepository.cachedEvents;
        _stats = PlannerEventsRepository.cachedStats;
        _filteredEvents = _applyFilters(_events);
        _errorMessage = null;
        _isLoading = false;
      });
      _prefetchTaskCaches();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _events.isEmpty ? 'Connection error' : null;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshEvents() async {
    await _loadEvents(forceRefresh: true);
  }

  List<Event> _applyFilters(List<Event> source) {
    final query = _searchController.text.toLowerCase();

    return source.where((event) {
      final matchesSearch =
          query.isEmpty ||
          event.title.toLowerCase().contains(query) ||
          (event.clientName?.toLowerCase().contains(query) ?? false);
      final matchesFilter = _selectedFilter.matches(event);
      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _filterEvents() {
    if (!mounted) return;

    setState(() {
      _filteredEvents = _applyFilters(_events);
    });
  }

  void _prefetchTaskCaches({int limit = 5}) {
    final eventIds = _events
        .map((event) => int.tryParse(event.id))
        .whereType<int>()
        .where((eventId) => !PlannerTaskRepository.hasCache(eventId))
        .take(limit);

    for (final eventId in eventIds) {
      unawaited(PlannerTaskRepository.loadTasks(eventId: eventId));
    }
  }

  void _openEvent(Event event) {
    final eventId = int.tryParse(event.id);

    if (eventId != null && !PlannerTaskRepository.hasCache(eventId)) {
      unawaited(PlannerTaskRepository.loadTasks(eventId: eventId));
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Plannertabsscreen(event: event)),
    );
  }

  Future<void> _updateStatus(int eventId, MyEventStatus newStatus) async {
    final index = _events.indexWhere((event) => event.id == eventId.toString());
    if (index == -1) return;

    final oldEvent = _events[index];
    final previousEvents = List<Event>.from(_events);
    final previousStats = _stats;

    // Optimistically update UI
    PlannerEventsRepository.updateStatusLocally(
      eventId: oldEvent.id,
      status: newStatus,
    );

    // If cancelling, remove from list immediately (optimistic)
    if (newStatus == MyEventStatus.cancelled) {
      setState(() {
        _events.removeWhere((e) => e.id == eventId.toString());
        _filteredEvents = _applyFilters(_events);
      });
    } else {
      setState(() {
        _events = List<Event>.from(_events);
        _events[index] = oldEvent.copyWithStatus(newStatus);
        _stats = _stats.applyStatusChange(
          oldStatus: oldEvent.status,
          newStatus: newStatus,
        );
        _filteredEvents = _applyFilters(_events);
      });
    }

    try {
      final result = await PlannerEventsRepository.updateStatus(
        eventId: eventId,
        status: newStatus,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _statusChanged = true;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newStatus == MyEventStatus.cancelled
                    ? 'Event cancelled!'
                    : 'Status updated to ${newStatus.label}!',
              ),
              backgroundColor: newStatus == MyEventStatus.cancelled
                  ? AppColors.darkpink
                  : AppColors.green,
            ),
          );
        }

        // Refresh to get updated stats
        unawaited(PlannerEventsRepository.refreshInBackground());
      } else {
        // Rollback on failure
        _rollbackStatusUpdate(previousEvents, previousStats);
        await _refreshEvents();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to update status'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      _rollbackStatusUpdate(previousEvents, previousStats);
      await _refreshEvents();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _rollbackStatusUpdate(List<Event> oldEvents, MyEventStats oldStats) {
    PlannerEventsRepository.setCache(events: oldEvents, stats: oldStats);

    setState(() {
      _events = List<Event>.from(oldEvents);
      _stats = oldStats;
      _filteredEvents = _applyFilters(_events);
    });
  }

  void _showStatusPicker(Event event) {
    final currentStatus = MyEventStatus.fromString(event.status);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Update Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.burgundy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.green.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 16),
                ...MyEventStatus.pickerValues.map((status) {
                  final isSelected = currentStatus == status;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.darkpink.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.darkpink.withOpacity(0.3)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        _statusIcon(status),
                        color: isSelected
                            ? AppColors.darkpink
                            : AppColors.green.withOpacity(0.8),
                      ),
                      title: Text(
                        status.label,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.darkpink
                              : AppColors.green,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppColors.darkpink)
                          : null,
                      onTap: () {
                        final parsedId = int.tryParse(event.id);
                        Navigator.pop(ctx);

                        if (parsedId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invalid event id'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        _updateStatus(parsedId, status);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _archiveEvent(Event event) async {
    final parsedId = int.tryParse(event.id);
    if (parsedId == null) return;

    final previousEvents = List<Event>.from(_events);
    final previousStats = _stats;

    PlannerEventsRepository.removeEventLocally(event.id);

    setState(() {
      _events.removeWhere((e) => e.id == event.id);
      _filteredEvents.removeWhere((e) => e.id == event.id);
    });

    try {
      final result = await PlannerEventsRepository.archiveEvent(parsedId);
      if (!mounted) return;

      if (result is Map && result['success'] == false) {
        _rollbackStatusUpdate(previousEvents, previousStats);
        return;
      }

      _statusChanged = true;
      unawaited(PlannerEventsRepository.refreshInBackground());
    } catch (e) {
      if (!mounted) return;
      _rollbackStatusUpdate(previousEvents, previousStats);
    }
  }

  Color _statusColor(MyEventStatus status) {
    switch (status) {
      case MyEventStatus.confirmed:
        return Colors.blue;
      case MyEventStatus.inProgress:
        return Colors.orange;
      case MyEventStatus.completed:
        return AppColors.green;
      case MyEventStatus.cancelled:
        return Colors.red;
      case MyEventStatus.unknown:
        return Colors.grey;
    }
  }

  IconData _statusIcon(MyEventStatus status) {
    switch (status) {
      case MyEventStatus.confirmed:
        return Icons.check_circle_outline;
      case MyEventStatus.inProgress:
        return Icons.pending;
      case MyEventStatus.completed:
        return Icons.check_circle;
      case MyEventStatus.cancelled:
        return Icons.cancel_outlined;
      case MyEventStatus.unknown:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BgPainter())),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context, _statusChanged),
                        borderRadius: BorderRadius.circular(22),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(
                            child: FaIcon(
                              FontAwesomeIcons.arrowLeft,
                              size: 20,
                              color: AppColors.darkpink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: AppColors.darkpink),
                            decoration: InputDecoration(
                              hintText: 'Search events...',
                              hintStyle: const TextStyle(
                                color: AppColors.coral,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.coral,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(40),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MonthlyCalendar(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(22),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(
                            child: FaIcon(
                              FontAwesomeIcons.calendarDays,
                              size: 20,
                              color: AppColors.darkpink,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Confirmed',
                          '${_stats.confirmed}',
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildStatCard(
                          'In Prog.',
                          '${_stats.inProgress}',
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildStatCard(
                          'Completed',
                          '${_stats.completed}',
                          AppColors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: MyEventFilter.values.map((filter) {
                        final isSelected = _selectedFilter == filter;

                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedFilter = filter);
                              _filterEvents();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.darkpink
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                filter.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.darkpink,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.darkpink,
                          ),
                        )
                      : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () =>
                                    _loadEvents(forceRefresh: true),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _filteredEvents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 64,
                                color: AppColors.green.withOpacity(0.6),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No events found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.green.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _refreshEvents,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _filteredEvents.length,
                            itemBuilder: (context, index) {
                              final event = _filteredEvents[index];
                              return Dismissible(
                                key: ValueKey(event.id),
                                onDismissed: (_) => _archiveEvent(event),
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  alignment: Alignment.centerRight,
                                  decoration: BoxDecoration(
                                    color: AppColors.burgundy,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.archive_outlined,
                                    color: AppColors.coral,
                                  ),
                                ),

                                child: _buildEventCard(event),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  bool _isOverdue(Event event) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
    );

    final status = MyEventStatus.fromString(event.status);

    return eventDate.isBefore(today) &&
        status != MyEventStatus.completed &&
        status != MyEventStatus.cancelled;
  }

  Widget _overdueChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 12,
            color: AppColors.darkpink,
          ),
          SizedBox(width: 4),
          Text(
            'Overdue',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.darkpink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final status = MyEventStatus.fromString(event.status);
    final statusColor = _statusColor(status);
    final isOverdue = _isOverdue(event);
    final formattedDate =
        '${event.date.day}/${event.date.month}/${event.date.year}';

    return GestureDetector(
      onTap: () => _openEvent(event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.burgundy,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showStatusPicker(event),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          status.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: statusColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _infoRow(Icons.person_outline, event.clientName ?? 'N/A'),
            const SizedBox(height: 4),
            Row(
              children: [
                _infoRow(FontAwesomeIcons.calendarDays, formattedDate),
                const SizedBox(width: 16),
                Expanded(child: _infoRow(Icons.location_on, event.location)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _infoRow(Icons.people_outline, '${event.guests} guests'),
                const SizedBox(width: 16),
                _infoRow(Icons.attach_money, '\$${event.budget}'),
                if (isOverdue) ...[const Spacer(), _overdueChip()],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.coral),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    p.color = AppColors.coral.withOpacity(0.10);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.08), 130, p);
    p.color = AppColors.darkpink.withOpacity(0.07);
    canvas.drawCircle(Offset(size.width * -0.12, size.height * 0.48), 170, p);
    p.color = const Color.fromARGB(255, 176, 27, 44).withOpacity(0.06);
    canvas.drawCircle(Offset(size.width * 1.08, size.height * 0.72), 190, p);
  }

  @override
  bool shouldRepaint(covariant _BgPainter oldDelegate) => false;
}
