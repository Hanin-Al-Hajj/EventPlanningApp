import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:event_planner/widgets/floating_action_button.dart';
import 'package:event_planner/screens/planner/planner_notification_screen.dart';
import 'package:event_planner/screens/planner/my_events.dart';

class EventPlannerDashboard extends StatefulWidget {
  const EventPlannerDashboard({super.key});

  @override
  State<EventPlannerDashboard> createState() => _EventPlannerDashboardState();
}

class _EventPlannerDashboardState extends State<EventPlannerDashboard> {
  static const int _initialWeekPage = 500;
  late final PageController _weekController = PageController(
    initialPage: _initialWeekPage,
  );
  final Map<String, List<Map<String, dynamic>>> _cachedCalendarDays = {};
  final Map<String, List<Map<String, dynamic>>> _cachedDayEvents = {};
  DateTime _selectedDate = DateTime.now();
  bool _isLoadingDashboard = false;
  bool _isLoadingRequests = false;

  List<Map<String, dynamic>> _calendarDays = [];
  List<Map<String, dynamic>> _dayEvents = [];
  List<Map<String, dynamic>> _clientRequests = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _loadRequests();

    _weekController.addListener(_onWeekPageChanged);
  }

  void _onWeekPageChanged() {
    if (!_weekController.hasClients) return;

    final page = _weekController.page?.round() ?? _initialWeekPage;
    final weekStart = _startOfWeek(
      DateTime.now().add(Duration(days: (page - _initialWeekPage) * 7)),
    );

    // Only reload if we're on a different week
    final dateStr =
        '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
    _loadDashboard(date: dateStr);
  }

  // Load dashboard (calendar + events)
  Future<void> _loadDashboard({String? date}) async {
    final cacheKey = date ?? 'current';

    // Return cached data instantly
    if (_cachedCalendarDays.containsKey(cacheKey)) {
      setState(() {
        _calendarDays = _cachedCalendarDays[cacheKey]!;
        _dayEvents = _cachedDayEvents[cacheKey]!;
      });
      return;
    }

    setState(() => _isLoadingDashboard = true);
    try {
      final result = await ApiService.getPlannerDashboard(date: date);
      if (result['success'] == true) {
        final data = result['data'];
        final calendarDays = List<Map<String, dynamic>>.from(
          data['calendar_days'] ?? [],
        );
        final dayEvents = <Map<String, dynamic>>[];

        for (var day in calendarDays) {
          final events = day['events'] as List? ?? [];
          for (var event in events) {
            if (event is! Map) continue;

            final rawDate = event['start_date'];
            if (rawDate == null) continue;

            DateTime? parsedDate;
            try {
              final dateStr = rawDate.toString();
              final dateOnly = dateStr.split(' ').first;
              parsedDate = DateTime.tryParse(dateOnly);
            } catch (_) {
              continue;
            }

            if (parsedDate == null) continue;

            dayEvents.add({
              'id': event['id'] ?? 0,
              'title': event['title'] ?? '',
              'clientName': event['client_name'] ?? '',
              'date': parsedDate,
              'location': event['location'] ?? '',
              'guests': event['guest_estimate'] ?? event['guests'] ?? 0,
              'budget': (event['budget'] ?? 0).toString(),
              'status': event['status'] ?? 'Accepted',
              'event_type': event['event_type'] ?? '',
            });
          }
        }

        //  Save to cache
        _cachedCalendarDays[cacheKey] = calendarDays;
        _cachedDayEvents[cacheKey] = dayEvents;

        setState(() {
          _calendarDays = calendarDays;
          _dayEvents = dayEvents;
        });
      }
    } catch (e) {
      debugPrint('Dashboard load error: $e');
    }
    setState(() => _isLoadingDashboard = false);
  }

  //  Load client requests
  Future<void> _loadRequests() async {
    setState(() => _isLoadingRequests = true);
    try {
      final result = await ApiService.getPlannerRequests();
      if (result['success'] == true) {
        final data = result['data'];
        final requests = data['requests'] as List? ?? [];
        setState(() {
          _clientRequests = requests
              .map(
                (r) => {
                  'id': r['id'],
                  'title': r['name'],
                  'clientName': r['client']?['name'] ?? 'Unknown',
                  'date':
                      DateTime.tryParse(
                        (r['start_date_iso'] ?? '').toString().split(' ').first,
                      ) ??
                      DateTime.now(),
                  'location': r['location'] ?? '',
                  'guests': r['guest_estimate'] ?? 0,
                  'budget': (r['budget_raw'] ?? 0).toString(),
                  'description':
                      r['description']?.toString() ?? '', //  ADD THIS
                },
              )
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Requests load error: $e');
    }
    setState(() => _isLoadingRequests = false);
  }

  void _acceptRequest(Map<String, dynamic> request) async {
    // ✅ Optimistic update - remove from requests immediately
    final requestCopy = Map<String, dynamic>.from(request);
    setState(() {
      _clientRequests.remove(request);
      // Add to day events immediately
      _dayEvents.add({...requestCopy, 'status': 'Accepted'});
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request accepted!'),
        backgroundColor: AppColors.green,
      ),
    );

    // Then sync with API in background
    final id = (request['id'].toString());
    try {
      final result = await ApiService.acceptPlannerRequest(id);
      if (result['success'] == true) {
        // Reload to get fresh data
        _loadDashboard();
      } else {
        // Rollback if API fails
        if (mounted) {
          setState(() {
            _clientRequests.add(requestCopy);
            _dayEvents.removeWhere((e) => e['id'] == requestCopy['id']);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to accept'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Accept error: $e');
    }
  }

  // ✅ Decline request - calls API
  void _declineRequest(Map<String, dynamic> request) async {
    final id = (request['id'].toString());
    try {
      final result = await ApiService.declinePlannerRequest(id);
      if (result['success'] == true) {
        setState(() => _clientRequests.remove(request));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request declined'),
              backgroundColor: AppColors.darkpink,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Decline error: $e');
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _startOfWeek(DateTime d) {
    final c = DateTime(d.year, d.month, d.day);
    return c.subtract(Duration(days: c.weekday - 1));
  }

  String _weekdayLabel(DateTime d) =>
      ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d.weekday - 1];

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
    const m = [
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
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  List<Map<String, dynamic>> get _eventsOnSelectedDay {
    return _dayEvents.where((e) {
      final date = e['date'];
      if (date == null) return false;
      if (date is! DateTime) return false;
      return _isSameDay(date, _selectedDate);
    }).toList();
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
    _weekController.removeListener(_onWeekPageChanged); // ✅ Remove listener
    _weekController.dispose();
    super.dispose();
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
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Bar ──────────────────────────────────────────────
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
                              if (value == 'logout') _handleLogout();
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PlannerNotificationScreen(),
                                    ),
                                  );
                                },
                                icon: const FaIcon(
                                  FontAwesomeIcons.bell,
                                  size: 20,
                                  color: AppColors.darkpink,
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const FaIcon(
                                  FontAwesomeIcons.calendarDays,
                                  size: 20,
                                  color: AppColors.darkpink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── Weekly Calendar ──────────────────────────────────────
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
                      itemBuilder: (context, page) {
                        final weekStart = _startOfWeek(
                          DateTime.now().add(
                            Duration(days: (page - _initialWeekPage) * 7),
                          ),
                        );
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

                  // ── Events on Selected Day ───────────────────────────────
                  _sectionHeader(
                    icon: Icons.event_available,
                    title: 'Events — ${_formatFullDate(_selectedDate)}',
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
                              .map((e) => _buildDayEventCard(e))
                              .toList(),
                        ),

                  const SizedBox(height: 28),

                  // ── Client Requests ──────────────────────────────────────
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
                              .map((r) => _buildRequestCard(r))
                              .toList(),
                        ),
                ],
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
            onMyEvent: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyEvents()),
              );
            },
            onArchiveEvent: () {},
            onAnalytics: () {},
            onMessage: () {},
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ── Week Day Cell ─────────────────────────────────────────────────────────
  Widget _buildWeekDay(DateTime day) {
    final isSelected = _isSameDay(day, _selectedDate);
    final isToday = _isSameDay(day, DateTime.now());

    // ✅ Safely build date string
    final dayStr =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

    // ✅ Check if this day has events
    bool hasDayEvent = false;
    try {
      hasDayEvent = _calendarDays.any((d) {
        return d['date'] == dayStr &&
            (d['events'] as List?)?.isNotEmpty == true;
      });
    } catch (_) {
      hasDayEvent = false;
    }

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

  // ── Section Header ────────────────────────────────────────────────────────
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

  // ── Empty Box ─────────────────────────────────────────────────────────────
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

  // ── Day Event Card ────────────────────────────────────────────────────────
  Widget _buildDayEventCard(Map<String, dynamic> event) {
    // Safer null handling - use toString() on the raw value
    final title = (event['title'] ?? '').toString();
    final clientName = (event['clientName'] ?? '').toString();
    final location = (event['location'] ?? '').toString();
    final guests = int.tryParse('${event['guests'] ?? 0}') ?? 0;
    final budget = event['budget']?.toString() ?? '0';
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
                  title,
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
                  color: AppColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'Accepted',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow(Icons.person_outline, clientName),
          const SizedBox(height: 4),
          _infoRow(Icons.location_on_outlined, location),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoRow(Icons.people_outline, '$guests guests'),
              const SizedBox(width: 16),
              _infoRow(Icons.attach_money, '\$$budget'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Request Card ──────────────────────────────────────────────────────────
  Widget _buildRequestCard(Map<String, dynamic> request) {
    final title = request['title']?.toString() ?? '';
    final clientName = request['clientName']?.toString() ?? '';
    final location = request['location']?.toString() ?? '';
    final guests = request['guests']?.toString() ?? '0';
    final budget = request['budget']?.toString() ?? '0';
    final description = request['description']?.toString() ?? '';
    final date = request['date'] is DateTime
        ? request['date'] as DateTime
        : DateTime.now();

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
                // Title + Pending badge row
                Row(
                  children: [
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
                _infoRow(Icons.person_outline, clientName),
                const SizedBox(height: 4),
                _infoRow(Icons.calendar_today_outlined, _formatFullDate(date)),
                const SizedBox(height: 4),
                _infoRow(Icons.location_on_outlined, location),

                // Description (only if not empty)
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 13,
                        color: AppColors.coral,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          description,
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
                    _infoRow(Icons.people_outline, '$guests guests'),
                    const SizedBox(width: 16),
                    _infoRow(Icons.attach_money, '\$$budget'),
                  ],
                ),
              ],
            ),
          ),
          // Divider + Accept/Decline buttons
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

// ── Background Painter ────────────────────────────────────────────────────────
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
  bool shouldRepaint(covariant _BgPainter old) => false;
}
