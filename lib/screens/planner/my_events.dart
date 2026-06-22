import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:event_planner/models/event.dart';
import 'package:event_planner/screens/planner_tabs_screen.dart';

class MyEvents extends StatefulWidget {
  const MyEvents({super.key});

  @override
  State<MyEvents> createState() => _MyEventsState();
}

class _MyEventsState extends State<MyEvents> {
  final TextEditingController _searchController = TextEditingController();
  List<Event> _events = [];
  List<Event> _filteredEvents = [];
  String _selectedFilter = 'All';
  bool _isLoading = true;
  String? _errorMessage;
  List<Event>? _cachedEvents;
  int _cachedConfirmed = 0;
  int _cachedInProgress = 0;
  int _cachedCompleted = 0;

  int _confirmedCount = 0;
  int _inProgressCount = 0;
  int _completedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _searchController.addListener(_filterEvents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    if (_cachedEvents != null) {
      setState(() {
        _events = _cachedEvents!;
        _filteredEvents = List.from(_events);
        _confirmedCount = _cachedConfirmed;
        _inProgressCount = _cachedInProgress;
        _completedCount = _cachedCompleted;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getPlannerEvents();

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];
        final eventsList = data['events'] as List? ?? [];
        final stats = data['stats'] as Map<String, dynamic>? ?? {};

        final parsedEvents = eventsList
            .map((e) => Event.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        final confirmed = stats['confirmed'] ?? 0;
        final inProgress = stats['in_progress'] ?? 0;
        final completed = stats['completed'] ?? 0;

        // Cache the data
        _cachedEvents = parsedEvents;
        _cachedConfirmed = confirmed;
        _cachedInProgress = inProgress;
        _cachedCompleted = completed;

        setState(() {
          _events = parsedEvents;
          _filteredEvents = List.from(_events);
          _confirmedCount = confirmed;
          _inProgressCount = inProgress;
          _completedCount = completed;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load events';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Connection error';
        _isLoading = false;
      });
    }
  }

  // Add refresh method
  Future<void> _refreshEvents() async {
    _cachedEvents = null;
    await _loadEvents();
  }

  void _filterEvents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEvents = _events.where((e) {
        final matchesSearch =
            query.isEmpty ||
            e.title.toLowerCase().contains(query) ||
            (e.plannerName?.toLowerCase().contains(query) ?? false);

        final matchesFilter =
            _selectedFilter == 'All' || e.status == _selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Future<void> _updateStatus(int eventId, String newStatus) async {
    // ✅ Optimistic update
    setState(() {
      final index = _events.indexWhere((e) => e.id == eventId.toString());
      if (index != -1) {
        final oldStatus = _events[index].status;
        _events[index] = Event(
          id: _events[index].id,
          title: _events[index].title,
          date: _events[index].date,
          location: _events[index].location,
          guests: _events[index].guests,
          budget: _events[index].budget,
          progress: _events[index].progress,
          status: newStatus,
          eventType: _events[index].eventType,
          description: _events[index].description,
          plannerId: _events[index].plannerId,
          plannerName: _events[index].plannerName,
        );
        _filteredEvents = List.from(_events);

        // Update counts
        if (oldStatus == 'confirmed') _confirmedCount--;
        if (oldStatus == 'in_progress') _inProgressCount--;
        if (oldStatus == 'completed') _completedCount--;
        if (newStatus == 'confirmed') _confirmedCount++;
        if (newStatus == 'in_progress') _inProgressCount++;
        if (newStatus == 'completed') _completedCount++;

        // Clear cache to force reload next time
        _cachedEvents = null;
      }
    });

    // Then sync with API
    try {
      final result = await ApiService.updateEventStatus(eventId, newStatus);
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Status updated!'),
              backgroundColor: AppColors.green,
            ),
          );
        }
      }
    } catch (e) {
      // Reload on error to revert
      _cachedEvents = null;
      _loadEvents();
    }
  }

  void _showStatusPicker(Event event) {
    final statuses = ['confirmed', 'in_progress', 'completed'];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
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
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.green.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              ...statuses.map((status) {
                final isSelected = event.status == status;
                return ListTile(
                  leading: Icon(
                    status == 'confirmed'
                        ? Icons.check_circle_outline
                        : status == 'in_progress'
                        ? Icons.pending
                        : Icons.check_circle,
                    color: isSelected
                        ? AppColors.darkpink
                        : AppColors.green.withOpacity(0.8),
                  ),
                  title: Text(
                    status == 'in_progress'
                        ? 'In Progress'
                        : status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(
                      color: isSelected ? AppColors.darkpink : AppColors.green,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.darkpink)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _updateStatus(int.parse(event.id), status);
                  },
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return AppColors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return status;
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
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
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
                      const SizedBox(width: 50), // ✅ Space on the right
                    ],
                  ),
                ),
                // Stats Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Confirmed',
                          '$_confirmedCount',
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildStatCard(
                          'In Progress',
                          '$_inProgressCount',
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildStatCard(
                          'Completed',
                          '$_completedCount',
                          AppColors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      children: ['All', 'confirmed', 'in_progress', 'completed']
                          .map((filter) {
                            final isSelected = _selectedFilter == filter;
                            final label = filter == 'in_progress'
                                ? 'In Progress'
                                : filter[0].toUpperCase() + filter.substring(1);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedFilter = filter);
                                  _filterEvents();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.darkpink
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.darkpink,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Events List
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
                                onPressed: _loadEvents,
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
                            itemBuilder: (context, index) =>
                                _buildEventCard(_filteredEvents[index]),
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
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final statusColor = _getStatusColor(event.status);
    final statusLabel = _getStatusLabel(event.status);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => Plannertabsscreen(event: event)),
        );
      },
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
                // Status dropdown
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
                          statusLabel,
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
            _infoRow(Icons.person_outline, event.plannerName ?? 'N/A'),
            const SizedBox(height: 4),
            _infoRow(Icons.location_on, event.location),
            const SizedBox(height: 4),
            Row(
              children: [
                _infoRow(Icons.people_outline, '${event.guests} guests'),
                const SizedBox(width: 16),
                _infoRow(Icons.attach_money, '\$${event.budget}'),
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
  bool shouldRepaint(covariant _BgPainter old) => false;
}
