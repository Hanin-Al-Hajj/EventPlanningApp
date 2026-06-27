import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MonthlyCalendar extends StatefulWidget {
  const MonthlyCalendar({super.key});

  @override
  State<MonthlyCalendar> createState() => _MonthlyCalendarState();
}

class _MonthlyCalendarState extends State<MonthlyCalendar> {
  static const int _initialMonthPage = 500;
  static const double _calendarHorizontalPadding = 8;

  late final PageController _monthController = PageController(
    initialPage: _initialMonthPage,
  );

  final Map<String, List<Map<String, dynamic>>> _cachedMonths = {};

  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDate;

  bool _isLoading = false;
  List<Map<String, dynamic>> _calendarDays = [];

  @override
  void initState() {
    super.initState();
    _calendarDays = _emptyMonthDays(_visibleMonth);
    _loadMonth(_visibleMonth);
  }

  @override
  void dispose() {
    _monthController.dispose();
    super.dispose();
  }

  String _monthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _monthForPage(int page) {
    final diff = page - _initialMonthPage;
    final now = DateTime.now();
    return DateTime(now.year, now.month + diff);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Map<String, dynamic>> _emptyMonthDays(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);

    final calendarStart = start.subtract(Duration(days: start.weekday - 1));
    final calendarEnd = end.add(Duration(days: 7 - end.weekday));

    final days = <Map<String, dynamic>>[];
    var day = calendarStart;

    while (!day.isAfter(calendarEnd)) {
      days.add({
        'date': _dateKey(day),
        'is_today': _isSameDay(day, DateTime.now()),
        'is_current_month': day.month == month.month,
        'dots': <dynamic>[],
        'visible_dots': <dynamic>[],
      });

      day = day.add(const Duration(days: 1));
    }

    return days;
  }

  Future<void> _loadMonth(DateTime month, {bool forceRefresh = false}) async {
    final key = _monthKey(month);

    if (!forceRefresh && _cachedMonths.containsKey(key)) {
      setState(() {
        _visibleMonth = month;
        _calendarDays = _cachedMonths[key]!;
      });
      return;
    }

    setState(() {
      _visibleMonth = month;
      _isLoading = true;
      _calendarDays = _emptyMonthDays(month);
    });

    try {
      final result = await ApiService.getPlannerMonthlyCalendar(month: key);
      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];
        final rawDays = data['calendar_days'] as List<dynamic>? ?? [];

        final days = rawDays
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        _cachedMonths[key] = days;

        setState(() {
          _calendarDays = days;
        });
      }
    } catch (e) {
      debugPrint('Monthly calendar error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _monthName(DateTime date) {
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

    return months[date.month - 1];
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
                _buildHeader(),
                _buildWeekHeader(),
                Expanded(
                  child: PageView.builder(
                    controller: _monthController,
                    scrollDirection: Axis.vertical,
                    onPageChanged: (page) {
                      _loadMonth(_monthForPage(page));
                    },
                    itemBuilder: (context, page) => _buildMonthBody(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: SizedBox(
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${_monthName(_visibleMonth)} ${_visibleMonth.year}',
              style: const TextStyle(
                color: AppColors.burgundy,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(22),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.xmark,
                      size: 20,
                      color: AppColors.darkpink,
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.darkpink,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekHeader() {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _calendarHorizontalPadding,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.coral.withOpacity(0.18)),
        ),
      ),
      child: Row(
        children: labels.map((label) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.green.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_calendarDays.isEmpty) {
          return const SizedBox.shrink();
        }

        final rows = (_calendarDays.length / 7).ceil();
        final rowHeight = constraints.maxHeight / rows;

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _calendarHorizontalPadding,
          ),
          child: Column(
            children: List.generate(rows, (rowIndex) {
              final start = rowIndex * 7;
              final rowDays = _calendarDays.skip(start).take(7).toList();

              return SizedBox(
                height: rowHeight,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.coral.withOpacity(0.14),
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rowDays.map(_buildDayCell).toList(),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildDayCell(Map<String, dynamic> day) {
    final date = DateTime.parse(day['date'].toString());
    final isCurrentMonth = day['is_current_month'] == true;
    final isToday = day['is_today'] == true;
    final isSelected =
        _selectedDate != null && _isSameDay(date, _selectedDate!);

    final dots =
        (day['visible_dots'] as List<dynamic>?) ??
        (day['dots'] as List<dynamic>?) ??
        [];

    return Expanded(
      child: GestureDetector(
        onTap: () => _handleDayTap(day, date),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 4),
          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.darkpink : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday && !isSelected
                      ? Border.all(color: AppColors.darkpink, width: 1.5)
                      : null,
                ),
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? Colors.white
                        : isCurrentMonth
                        ? AppColors.burgundy
                        : AppColors.burgundy.withOpacity(0.25),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _buildDots(dots, day['more_count']),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDayTap(Map<String, dynamic> day, DateTime date) {
    setState(() => _selectedDate = date);

    final eventsCount = day['events_count'] is int
        ? day['events_count']
        : int.tryParse('${day['events_count']}') ?? 0;

    final dots =
        (day['dots'] as List<dynamic>?) ??
        (day['visible_dots'] as List<dynamic>?) ??
        [];

    if (eventsCount <= 0 && dots.isEmpty) return;

    _showDayEventsSheet(date);
  }

  Future<List<Map<String, dynamic>>> _loadDayEvents(DateTime date) async {
    final result = await ApiService.getPlannerDayEvents(_dateKey(date));

    if (result['success'] != true) return [];

    final data = result['data'];
    if (data is! Map) return [];

    final rawEvents = data['events'] as List<dynamic>? ?? [];

    return rawEvents
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  void _showDayEventsSheet(DateTime date) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SizedBox(
          width: double.infinity,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _loadDayEvents(date),
                builder: (context, snapshot) {
                  final isLoading =
                      snapshot.connectionState == ConnectionState.waiting;
                  final events = snapshot.data ?? [];

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _formatSheetDate(date),
                        style: const TextStyle(
                          color: AppColors.burgundy,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: CircularProgressIndicator(
                            color: AppColors.darkpink,
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight:
                                MediaQuery.of(context).size.height * 0.55,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: events.length,
                            itemBuilder: (context, index) {
                              return _buildEventTile(events[index]);
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventTile(Map<String, dynamic> event) {
    final status = event['status']?.toString();
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title']?.toString() ?? 'Event',
                  style: const TextStyle(
                    color: AppColors.burgundy,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  event['client_name']?.toString() ?? 'No Client',
                  style: TextStyle(
                    color: AppColors.green.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _statusLabel(status),
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String? status) {
    final normalized = (status ?? '')
        .toLowerCase()
        .trim()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    switch (normalized) {
      case 'confirmed':
        return Colors.blue;
      case 'in_progress':
      case 'inprogress':
        return Colors.orange;
      case 'completed':
        return AppColors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    final normalized = (status ?? '')
        .toLowerCase()
        .trim()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    switch (normalized) {
      case 'confirmed':
        return 'Confirmed';
      case 'in_progress':
      case 'inprogress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  String _formatSheetDate(DateTime date) {
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

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildDots(List<dynamic> dots, dynamic moreCountValue) {
    final moreCount = moreCountValue is int
        ? moreCountValue
        : int.tryParse('$moreCountValue') ?? 0;

    if (dots.isEmpty && moreCount <= 0) {
      return const SizedBox(height: 12);
    }

    return SizedBox(
      height: 14,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < dots.length; i++)
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: const BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
              ),
            ),
          if (moreCount > 0)
            Text(
              '+$moreCount',
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
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
