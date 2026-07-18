import 'dart:async';

import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/models/planner_dashboard.dart';
import 'package:event_planner/repositories/planner_dashboard_repository.dart';
import 'package:event_planner/screens/planner/Messages_screen_planner.dart';
import 'package:event_planner/screens/planner/analytics.dart';
import 'package:event_planner/screens/planner/my_events.dart';
import 'package:event_planner/screens/planner/planner_notification_screen.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:event_planner/widgets/floating_action_button.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:event_planner/screens/planner/archive.dart';
import 'package:event_planner/screens/planner/planner_setting.dart';
import 'package:event_planner/screens/planner/planner_profile_screen.dart';

class EventPlannerDashboard extends StatefulWidget {
  const EventPlannerDashboard({super.key});

  @override
  State<EventPlannerDashboard> createState() => _EventPlannerDashboardState();
}

class _EventPlannerDashboardState extends State<EventPlannerDashboard> {
  static const int _initialWeekPage = 500;

  int _unreadNotifications = 0;
  late final PageController _weekController = PageController(
    initialPage: _initialWeekPage,
  );

  DateTime _selectedDate = DateTime.now();
  bool _isLoadingDashboard = false;
  bool _isLoadingRequests = false;
  String? _activeDashboardKey;

  List<PlannerCalendarDay> _calendarDays = [];
  List<PlannerDashboardEvent> _dayEvents = [];
  List<PlannerClientRequest> _clientRequests = [];

  @override
  void initState() {
    super.initState();
    _activeDashboardKey = _dateKey(_startOfWeek(_selectedDate));

    PlannerDashboardRepository.dashboardChanges.addListener(
      _onDashboardChanged,
    );
    PlannerDashboardRepository.requests.addListener(_onRequestsChanged);

    final activeDashboard = PlannerDashboardRepository.cachedDashboard(
      _activeDashboardKey!,
    );
    if (activeDashboard != null) {
      _calendarDays = activeDashboard.calendarDays;
      _dayEvents = activeDashboard.dayEvents;
      unawaited(
        PlannerDashboardRepository.refreshDashboardInBackground(
          _activeDashboardKey!,
        ),
      );
    } else {
      unawaited(_loadDashboard(date: _activeDashboardKey));
    }

    _clientRequests = PlannerDashboardRepository.cachedRequests;
    if (PlannerDashboardRepository.hasRequestsCache) {
      unawaited(PlannerDashboardRepository.refreshRequestsInBackground());
    } else {
      unawaited(_loadRequests());
    }

    _loadUnreadCount();
  }

  void _onDashboardChanged() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final cacheKey = _activeDashboardKey;
      if (cacheKey == null) return;

      final dashboard = PlannerDashboardRepository.cachedDashboard(cacheKey);
      if (dashboard == null) return;

      setState(() {
        _calendarDays = dashboard.calendarDays;
        _dayEvents = dashboard.dayEvents;
        _isLoadingDashboard = false;
      });
    });
  }

  void _onRequestsChanged() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _clientRequests = PlannerDashboardRepository.cachedRequests;
        _isLoadingRequests = false;
      });
    });
  }

  Future<void> _loadUnreadCount() async {
    try {
      final result = await ApiService.getUnreadNotificationCount();
      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];
        if (data is! Map) return;
        final unreadCount = data['unread_count'];

        setState(() {
          _unreadNotifications = unreadCount is int
              ? unreadCount
              : int.tryParse('$unreadCount') ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Unread count load error: $e');
    }
  }

  void _onWeekPageChanged(int page) {
    final weekStart = _weekStartForPage(page);
    _loadDashboard(date: _dateKey(weekStart));
  }

  Future<void> _loadDashboard({String? date, bool forceRefresh = false}) async {
    final cacheKey = date ?? _dateKey(_startOfWeek(_selectedDate));
    _activeDashboardKey = cacheKey;

    final cachedDashboard = PlannerDashboardRepository.cachedDashboard(
      cacheKey,
    );
    if (cachedDashboard != null && !forceRefresh) {
      if (mounted) {
        setState(() {
          _calendarDays = cachedDashboard.calendarDays;
          _dayEvents = cachedDashboard.dayEvents;
          _isLoadingDashboard = false;
        });
      }
      unawaited(
        PlannerDashboardRepository.refreshDashboardInBackground(cacheKey),
      );
      return;
    }

    final shouldShowLoader = _calendarDays.isEmpty && _dayEvents.isEmpty;
    if (mounted && shouldShowLoader) {
      setState(() => _isLoadingDashboard = true);
    }

    try {
      await PlannerDashboardRepository.loadDashboard(
        weekKey: cacheKey,
        forceRefresh: forceRefresh,
      );
      if (!mounted || _activeDashboardKey != cacheKey) return;

      final dashboard = PlannerDashboardRepository.cachedDashboard(cacheKey);
      if (dashboard == null) return;

      setState(() {
        _calendarDays = dashboard.calendarDays;
        _dayEvents = dashboard.dayEvents;
      });
    } catch (e) {
      debugPrint('Dashboard load error: $e');
    } finally {
      if (mounted && _activeDashboardKey == cacheKey) {
        setState(() => _isLoadingDashboard = false);
      }
    }
  }

  Future<void> _loadRequests({bool forceRefresh = false}) async {
    if (!forceRefresh && PlannerDashboardRepository.hasRequestsCache) {
      if (mounted) {
        setState(() {
          _clientRequests = PlannerDashboardRepository.cachedRequests;
          _isLoadingRequests = false;
        });
      }
      unawaited(PlannerDashboardRepository.refreshRequestsInBackground());
      return;
    }

    if (mounted && _clientRequests.isEmpty) {
      setState(() => _isLoadingRequests = true);
    }

    try {
      await PlannerDashboardRepository.loadRequests(forceRefresh: forceRefresh);
      if (!mounted) return;

      setState(() {
        _clientRequests = PlannerDashboardRepository.cachedRequests;
      });
    } catch (e) {
      debugPrint('Requests load error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingRequests = false);
      }
    }
  }

  Future<void> _acceptRequest(PlannerClientRequest request) async {
    final cacheKey =
        _activeDashboardKey ?? _dateKey(_startOfWeek(_selectedDate));
    final acceptedEvent = request.toDashboardEvent();

    PlannerDashboardRepository.removeRequest(request.id);
    PlannerDashboardRepository.upsertEvent(
      weekKey: cacheKey,
      event: acceptedEvent,
    );

    setState(() {
      _clientRequests.removeWhere((item) => item.id == request.id);
      _dayEvents = [
        ..._dayEvents.where((event) => event.id != acceptedEvent.id),
        acceptedEvent,
      ];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request accepted!'),
        backgroundColor: AppColors.green,
      ),
    );

    try {
      final result = await PlannerDashboardRepository.acceptRequest(request);
      if (!mounted) return;

      if (result['success'] == true) {
        _clearDashboardCacheFor(request.date);
        unawaited(_loadDashboard(forceRefresh: true));
        unawaited(PlannerDashboardRepository.refreshRequestsInBackground());
      } else {
        _rollbackAcceptedRequest(request, acceptedEvent);
      }
    } catch (e) {
      debugPrint('Accept error: $e');
      if (mounted) {
        _rollbackAcceptedRequest(request, acceptedEvent);
      }
    }
  }

  Future<void> _declineRequest(PlannerClientRequest request) async {
    PlannerDashboardRepository.removeRequest(request.id);
    setState(() {
      _clientRequests.removeWhere((item) => item.id == request.id);
    });

    try {
      final result = await PlannerDashboardRepository.declineRequest(request);
      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request declined'),
            backgroundColor: AppColors.darkpink,
          ),
        );
      } else {
        PlannerDashboardRepository.restoreRequest(request);
        setState(() {
          if (!_clientRequests.any((item) => item.id == request.id)) {
            _clientRequests.insert(0, request);
          }
        });
      }
    } catch (e) {
      debugPrint('Decline error: $e');
      if (!mounted) return;

      PlannerDashboardRepository.restoreRequest(request);
      setState(() {
        if (!_clientRequests.any((item) => item.id == request.id)) {
          _clientRequests.insert(0, request);
        }
      });
    }
  }

  void _rollbackAcceptedRequest(
    PlannerClientRequest request,
    PlannerDashboardEvent acceptedEvent,
  ) {
    final cacheKey =
        _activeDashboardKey ?? _dateKey(_startOfWeek(_selectedDate));

    PlannerDashboardRepository.restoreRequest(request);
    PlannerDashboardRepository.removeEvent(
      weekKey: cacheKey,
      eventId: acceptedEvent.id,
    );

    setState(() {
      if (!_clientRequests.any((item) => item.id == request.id)) {
        _clientRequests.add(request);
      }
      _dayEvents = _dayEvents
          .where((event) => event.id != acceptedEvent.id)
          .toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to accept'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _clearDashboardCacheFor(DateTime date) {
    PlannerDashboardRepository.clearDashboardCacheFor(date);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _startOfWeek(DateTime d) {
    final current = DateTime(d.year, d.month, d.day);
    return current.subtract(Duration(days: current.weekday - 1));
  }

  DateTime _weekStartForPage(int page) {
    return _startOfWeek(
      DateTime.now().add(Duration(days: (page - _initialWeekPage) * 7)),
    );
  }

  String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _weekdayLabel(DateTime d) {
    return ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d.weekday - 1];
  }

  String _formatDayMonth(DateTime d) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  String _formatFullDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  List<PlannerDashboardEvent> get _eventsOnSelectedDay {
    return _dayEvents.where((event) => event.isOnDate(_selectedDate)).toList();
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(color: AppColors.burgundy),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppColors.burgundy),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.burgundy),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkpink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    PlannerDashboardRepository.dashboardChanges.removeListener(
      _onDashboardChanged,
    );
    PlannerDashboardRepository.requests.removeListener(_onRequestsChanged);
    _weekController.dispose();
    super.dispose();
  }

  Future<void> _openMyEvents() async {
    final shouldRefresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const MyEvents()),
    );

    if (!mounted || shouldRefresh != true) return;

    PlannerDashboardRepository.clearDashboardCache();

    await _loadDashboard(
      date: _dateKey(_startOfWeek(_selectedDate)),
      forceRefresh: true,
    );
  }

  Future<void> _onPullToRefresh() async {
    await Future.wait([
      _loadDashboard(date: _activeDashboardKey, forceRefresh: true),
      _loadRequests(forceRefresh: true),
      _loadUnreadCount(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final eventsToday = _eventsOnSelectedDay;

    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: CustomPaint(painter: _BgPainter())),
          SafeArea(
            child: RefreshIndicator(
              color: AppColors.darkpink,
              onRefresh: _onPullToRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 40,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            _formatDayMonth(_selectedDate),
                            style: const TextStyle(
                              color: AppColors.burgundy,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: PopupMenuButton<String>(
                              offset: const Offset(0, 45),
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              itemBuilder: (context) => [
                                _popupItem(
                                  'profile',
                                  Icons.person_outline,
                                  'Profile',
                                ),
                                _popupItem(
                                  'settings',
                                  Icons.settings_outlined,
                                  'Settings',
                                ),
                                _popupItem('logout', Icons.logout, 'Logout'),
                              ],
                              onSelected: (value) {
                                if (value == 'profile') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PlannerProfileScreen(),
                                    ),
                                  );
                                } else if (value == 'settings') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PlannerSetting(),
                                    ),
                                  );
                                } else if (value == 'logout') {
                                  _handleLogout();
                                }
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: AppColors.darkpink,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PlannerNotificationScreen(),
                                  ),
                                );
                                _loadUnreadCount();
                              },
                              icon: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.bell,
                                    size: 20,
                                    color: AppColors.darkpink,
                                  ),
                                  if (_unreadNotifications > 0)
                                    Positioned(
                                      top: -4,
                                      right: -4,
                                      child: Container(
                                        width: _unreadNotifications > 9
                                            ? 18
                                            : 14,
                                        height: 14,
                                        decoration: const BoxDecoration(
                                          color: AppColors.darkpink,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            _unreadNotifications > 9
                                                ? '9+'
                                                : '$_unreadNotifications',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: PageView.builder(
                        controller: _weekController,
                        onPageChanged: _onWeekPageChanged,
                        itemBuilder: (context, page) {
                          final weekStart = _weekStartForPage(page);
                          final days = List.generate(
                            7,
                            (i) => weekStart.add(Duration(days: i)),
                          );

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: days.map(_buildWeekDay).toList(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    _sectionHeader(
                      icon: Icons.event_available,
                      title: 'Events - ${_formatFullDate(_selectedDate)}',
                    ),
                    const SizedBox(height: 12),
                    _isLoadingDashboard
                        ? const Center(child: CircularProgressIndicator())
                        : eventsToday.isEmpty
                        ? _emptyBox(
                            icon: Icons.event_outlined,
                            message: 'No events on this day',
                            sub: 'Tap a day in the calendar to see its events',
                          )
                        : Column(
                            children: eventsToday
                                .map((event) => _buildDayEventCard(event))
                                .toList(),
                          ),
                    const SizedBox(height: 28),
                    _sectionHeader(
                      icon: Icons.inbox_outlined,
                      title: 'Client Requests',
                      badge: _clientRequests.isNotEmpty
                          ? '${_clientRequests.length}'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _isLoadingRequests
                        ? const Center(child: CircularProgressIndicator())
                        : _clientRequests.isEmpty
                        ? _emptyBox(
                            icon: Icons.mark_email_read_outlined,
                            message: 'No pending requests',
                            sub: 'New client requests will appear here',
                          )
                        : Column(
                            children: _clientRequests
                                .map((request) => _buildRequestCard(request))
                                .toList(),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10, right: 10),
        child: SizedBox(
          width: 160,
          height: 320,
          child: EventPlannerFAB(
            onMyEvent: _openMyEvents,
            onArchiveEvent: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Archive()),
              );
            },
            onAnalytics: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
            onMessage: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MessagesScreenPlanner(),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildWeekDay(DateTime day) {
    final isSelected = _isSameDay(day, _selectedDate);
    final isToday = _isSameDay(day, DateTime.now());
    final dayStr = _dateKey(day);
    final hasDayEvent = _calendarDays.any(
      (calendarDay) => calendarDay.dateKey == dayStr && calendarDay.hasEvents,
    );

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = day;
        });
      },
      child: SizedBox(
        width: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isToday ? 'Today' : _weekdayLabel(day),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isToday ? AppColors.darkpink : Colors.black45,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.darkpink : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.darkpink, width: 1.5)
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppColors.burgundy,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: hasDayEvent ? AppColors.green : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    String? badge,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.darkpink, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.burgundy,
            ),
          ),
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.darkpink,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _emptyBox({
    required IconData icon,
    required String message,
    required String sub,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.green.withOpacity(0.4)),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.green.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.green.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayEventCard(PlannerDashboardEvent event) {
    final statusColor = _statusColor(event.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                    fontWeight: FontWeight.w800,
                    color: AppColors.burgundy,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  event.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow(Icons.person_outline, event.clientName),
          const SizedBox(height: 4),
          _infoRow(Icons.location_on_outlined, event.location),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoRow(Icons.people_outline, '${event.guests} guests'),
              const SizedBox(width: 16),
              _infoRow(Icons.attach_money, '\$${event.budget}'),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(PlannerEventStatus status) {
    switch (status) {
      case PlannerEventStatus.confirmed:
        return Colors.blue;
      case PlannerEventStatus.inProgress:
        return Colors.orange;
      case PlannerEventStatus.completed:
        return AppColors.green;
      case PlannerEventStatus.cancelled:
        return Colors.red;
      case PlannerEventStatus.unknown:
        return Colors.grey;
    }
  }

  Widget _buildRequestCard(PlannerClientRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        request.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.burgundy,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _infoRow(Icons.person_outline, request.clientName),
                const SizedBox(height: 4),
                _infoRow(
                  Icons.calendar_today_outlined,
                  _formatFullDate(request.date),
                ),
                const SizedBox(height: 4),
                _infoRow(Icons.location_on_outlined, request.location),
                if (request.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 13,
                        color: AppColors.coral,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          request.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _infoRow(Icons.people_outline, '${request.guests} guests'),
                    const SizedBox(width: 16),
                    _infoRow(Icons.attach_money, '\$${request.budget}'),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _declineRequest(request),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.darkpink,
                      side: const BorderSide(color: AppColors.darkpink),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptRequest(request),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  PopupMenuItem<String> _popupItem(String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: AppColors.darkpink),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppColors.darkpink)),
        ],
      ),
    );
  }
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    p.color = AppColors.coral.withValues(alpha: 0.10);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.08), 130, p);
    p.color = AppColors.darkpink.withValues(alpha: 0.07);
    canvas.drawCircle(Offset(size.width * -0.12, size.height * 0.48), 170, p);
    p.color = const Color.fromARGB(255, 176, 27, 44).withValues(alpha: 0.06);
    canvas.drawCircle(Offset(size.width * 1.08, size.height * 0.72), 190, p);
  }

  @override
  bool shouldRepaint(covariant _BgPainter oldDelegate) => false;
}
