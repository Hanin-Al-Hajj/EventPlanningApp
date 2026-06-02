import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  DateTime _selectedDate = DateTime.now();

  // ── Empty lists — fill from API later ────────────────────────────────────
  // Each map should have: id, title, clientName, date, location, guests, budget, status
  final List<Map<String, dynamic>> _dayEvents = [];

  // Each map should have: id, title, clientName, date, location, guests, budget
  final List<Map<String, dynamic>> _clientRequests = [];

  // ── Helpers ───────────────────────────────────────────────────────────────
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

  // Events on selected day from _dayEvents list
  List<Map<String, dynamic>> get _eventsOnSelectedDay {
    return _dayEvents.where((e) {
      final date = e['date'] as DateTime?;
      return date != null && _isSameDay(date, _selectedDate);
    }).toList();
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  void _acceptRequest(Map<String, dynamic> request) {
    // TODO: call API to accept
    setState(() {
      _clientRequests.remove(request);
      _dayEvents.add({...request, 'status': 'Accepted'});
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request accepted!'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  void _declineRequest(Map<String, dynamic> request) {
    // TODO: call API to decline
    setState(() => _clientRequests.remove(request));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request declined'),
        backgroundColor: AppColors.darkpink,
      ),
    );
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
    _weekController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final eventsToday = _eventsOnSelectedDay;

    return Scaffold(
      body: Stack(
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
                        // Centered date
                        Text(
                          _formatDayMonth(_selectedDate),
                          style: const TextStyle(
                            color: AppColors.burgundy,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        // Left side
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

                        // Right side
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {},
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
                  eventsToday.isEmpty
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
                  _clientRequests.isEmpty
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
    );
  }

  // ── Week Day Cell ─────────────────────────────────────────────────────────
  Widget _buildWeekDay(DateTime day) {
    final isSelected = _isSameDay(day, _selectedDate);
    final isToday = _isSameDay(day, DateTime.now());

    final hasDayEvent = _dayEvents.any((e) {
      final d = e['date'] as DateTime?;
      return d != null && _isSameDay(d, day);
    });

    return GestureDetector(
      onTap: () => setState(() => _selectedDate = day),
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
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ── Day Event Card (accepted events) ──────────────────────────────────────
  Widget _buildDayEventCard(Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  event['title'] ?? '',
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
                  color: AppColors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.green.withOpacity(0.3)),
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
          _infoRow(Icons.person_outline, event['clientName'] ?? ''),
          const SizedBox(height: 4),
          _infoRow(Icons.location_on_outlined, event['location'] ?? ''),
          const SizedBox(height: 4),
          Row(
            children: [
              _infoRow(Icons.people_outline, '${event['guests'] ?? 0} guests'),
              const SizedBox(width: 16),
              _infoRow(Icons.attach_money, '\$${event['budget'] ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Request Card (pending requests with accept/decline) ────────────────────
  Widget _buildRequestCard(Map<String, dynamic> request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                        request['title'] ?? '',
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
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
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
                _infoRow(Icons.person_outline, request['clientName'] ?? ''),
                const SizedBox(height: 4),
                _infoRow(
                  Icons.calendar_today_outlined,
                  _formatFullDate(request['date'] as DateTime),
                ),
                const SizedBox(height: 4),
                _infoRow(Icons.location_on_outlined, request['location'] ?? ''),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _infoRow(
                      Icons.people_outline,
                      '${request['guests'] ?? 0} guests',
                    ),
                    const SizedBox(width: 16),
                    _infoRow(Icons.attach_money, '\$${request['budget'] ?? 0}'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
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
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
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

  Widget _infoRow(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 13, color: AppColors.coral),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );

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
