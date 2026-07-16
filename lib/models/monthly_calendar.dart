class MonthlyCalendarResponse {
  final List<MonthlyCalendarDay> days;

  MonthlyCalendarResponse({required this.days});

  factory MonthlyCalendarResponse.fromApiResponse(
    Map<String, dynamic> response, {
    required DateTime month,
  }) {
    return MonthlyCalendarResponse.fromApiData(
      response['data'] ?? response,
      month: month,
    );
  }

  factory MonthlyCalendarResponse.fromApiData(
    dynamic data, {
    required DateTime month,
  }) {
    final json = _asMap(data);
    final rawDays = data is List
        ? data
        : json == null
        ? const []
        : _asList(json['calendar_days'] ?? json['days'] ?? json['data']);

    final days = <MonthlyCalendarDay>[];
    for (final item in rawDays) {
      final itemJson = _asMap(item);
      if (itemJson == null) continue;
      days.add(MonthlyCalendarDay.fromJson(itemJson, visibleMonth: month));
    }

    return MonthlyCalendarResponse(days: days);
  }
}

class MonthlyCalendarDay {
  final String dateKey;
  final DateTime date;
  final bool isToday;
  final bool isCurrentMonth;
  final int eventsCount;
  final int moreCount;
  final List<MonthlyCalendarDot> dots;
  final List<MonthlyCalendarDot> visibleDots;

  MonthlyCalendarDay({
    required this.dateKey,
    required this.date,
    required this.isToday,
    required this.isCurrentMonth,
    required this.eventsCount,
    required this.moreCount,
    required this.dots,
    required this.visibleDots,
  });

  factory MonthlyCalendarDay.fromJson(
    Map<String, dynamic> json, {
    DateTime? visibleMonth,
  }) {
    final dateKey = _asString(json['date']);
    final date = DateTime.tryParse(dateKey) ?? DateTime.now();

    final dots = _asList(json['dots']).map(MonthlyCalendarDot.fromAny).toList();
    final visibleDotsRaw = _asList(json['visible_dots']);
    final visibleDots = visibleDotsRaw.isEmpty
        ? dots.take(3).toList()
        : visibleDotsRaw.map(MonthlyCalendarDot.fromAny).toList();

    return MonthlyCalendarDay(
      dateKey: dateKey.isEmpty ? _dateKey(date) : dateKey,
      date: date,
      isToday: _asBool(
        json['is_today'],
        fallback: _isSameDay(date, DateTime.now()),
      ),
      isCurrentMonth: _asBool(
        json['is_current_month'],
        fallback: visibleMonth == null || date.month == visibleMonth.month,
      ),
      eventsCount: _asInt(json['events_count'], fallback: dots.length),
      moreCount: _asInt(
        json['more_count'],
        fallback: dots.length > visibleDots.length
            ? dots.length - visibleDots.length
            : 0,
      ),
      dots: dots,
      visibleDots: visibleDots,
    );
  }

  factory MonthlyCalendarDay.empty(DateTime day, DateTime visibleMonth) {
    return MonthlyCalendarDay(
      dateKey: _dateKey(day),
      date: day,
      isToday: _isSameDay(day, DateTime.now()),
      isCurrentMonth: day.month == visibleMonth.month,
      eventsCount: 0,
      moreCount: 0,
      dots: const [],
      visibleDots: const [],
    );
  }

  bool get hasEvents =>
      eventsCount > 0 || dots.isNotEmpty || visibleDots.isNotEmpty;

  List<MonthlyCalendarDot> get displayDots =>
      visibleDots.isNotEmpty ? visibleDots : dots;
}

class MonthlyCalendarDot {
  final int? eventId;
  final String status;
  final String color;

  MonthlyCalendarDot({this.eventId, required this.status, required this.color});

  factory MonthlyCalendarDot.fromAny(dynamic value) {
    final json = _asMap(value);
    if (json == null) {
      return MonthlyCalendarDot(status: _asString(value), color: '');
    }

    return MonthlyCalendarDot(
      eventId: _asNullableInt(json['event_id'] ?? json['id']),
      status: _asString(json['status']),
      color: _asString(json['color']),
    );
  }
}

class MonthlyCalendarEvent {
  final int id;
  final String title;
  final String clientName;
  final String status;

  MonthlyCalendarEvent({
    required this.id,
    required this.title,
    required this.clientName,
    required this.status,
  });

  factory MonthlyCalendarEvent.fromJson(Map<String, dynamic> json) {
    final client = _asMap(json['client']);

    return MonthlyCalendarEvent(
      id: _asInt(json['id']),
      title: _asString(
        json['title'] ?? json['name'] ?? json['event_name'],
        fallback: 'Event',
      ),
      clientName: _asString(
        json['client_name'] ?? client?['name'],
        fallback: 'No Client',
      ),
      status: _asString(json['status']),
    );
  }
}

List<MonthlyCalendarDay> emptyMonthlyCalendarDays(DateTime month) {
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 0);

  final calendarStart = start.subtract(Duration(days: start.weekday - 1));
  final calendarEnd = end.add(Duration(days: 7 - end.weekday));

  final days = <MonthlyCalendarDay>[];
  var day = calendarStart;

  while (!day.isAfter(calendarEnd)) {
    days.add(MonthlyCalendarDay.empty(day, month));
    day = day.add(const Duration(days: 1));
  }

  return days;
}

String monthlyCalendarMonthKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}';
}

String monthlyCalendarDateKey(DateTime date) => _dateKey(date);

bool monthlyCalendarIsSameDay(DateTime a, DateTime b) => _isSameDay(a, b);

String _dateKey(DateTime date) {
  return '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const [];
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;

  final text = value.toString().toLowerCase().trim();
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return fallback;
}
