import 'package:event_planner/models/monthly_calendar.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:flutter/foundation.dart';

class MonthlyCalendarRepository {
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static final Map<String, List<MonthlyCalendarDay>> _months = {};
  static final Map<String, Future<List<MonthlyCalendarDay>>> _monthLoads = {};
  static final Map<String, List<MonthlyCalendarEvent>> _dayEvents = {};
  static final Map<String, Future<List<MonthlyCalendarEvent>>> _dayLoads = {};

  static bool hasMonth(DateTime month) {
    return _months.containsKey(monthlyCalendarMonthKey(month));
  }

  static List<MonthlyCalendarDay> daysForMonth(DateTime month) {
    return _months[monthlyCalendarMonthKey(month)] ??
        emptyMonthlyCalendarDays(month);
  }

  static bool hasDayEvents(DateTime date) {
    return _dayEvents.containsKey(monthlyCalendarDateKey(date));
  }

  static List<MonthlyCalendarEvent> cachedDayEvents(DateTime date) {
    return _dayEvents[monthlyCalendarDateKey(date)] ?? const [];
  }

  static Future<List<MonthlyCalendarDay>> loadMonth(
    DateTime month, {
    bool forceRefresh = false,
  }) {
    final key = monthlyCalendarMonthKey(month);
    final cached = _months[key];
    if (!forceRefresh && cached != null) {
      return Future.value(cached);
    }

    final running = _monthLoads[key];
    if (running != null) return running;

    final request = _fetchMonth(month).whenComplete(() {
      _monthLoads.remove(key);
    });
    _monthLoads[key] = request;
    return request;
  }

  static Future<void> refreshMonthInBackground(DateTime month) async {
    try {
      await loadMonth(month, forceRefresh: true);
    } catch (e) {
      debugPrint('Monthly calendar background refresh error: $e');
    }
  }

  static Future<List<MonthlyCalendarEvent>> loadDayEvents(
    DateTime date, {
    bool forceRefresh = false,
  }) {
    final key = monthlyCalendarDateKey(date);
    final cached = _dayEvents[key];
    if (!forceRefresh && cached != null) {
      return Future.value(cached);
    }

    final running = _dayLoads[key];
    if (running != null) return running;

    final request = _fetchDayEvents(date).whenComplete(() {
      _dayLoads.remove(key);
    });
    _dayLoads[key] = request;
    return request;
  }

  static void clear() {
    _months.clear();
    _monthLoads.clear();
    _dayEvents.clear();
    _dayLoads.clear();
    _notify();
  }

  static Future<List<MonthlyCalendarDay>> _fetchMonth(DateTime month) async {
    final key = monthlyCalendarMonthKey(month);
    final result = await ApiService.getPlannerMonthlyCalendar(month: key);

    if (result['success'] != true) {
      throw Exception(result['message'] ?? 'Failed to load calendar');
    }

    final response = MonthlyCalendarResponse.fromApiResponse(
      result,
      month: month,
    );

    final days = response.days.isEmpty
        ? emptyMonthlyCalendarDays(month)
        : response.days;

    _months[key] = days;
    _notify();
    return days;
  }

  static Future<List<MonthlyCalendarEvent>> _fetchDayEvents(
    DateTime date,
  ) async {
    final key = monthlyCalendarDateKey(date);
    final result = await ApiService.getPlannerDayEvents(key);

    if (result['success'] != true) {
      _dayEvents[key] = const [];
      _notify();
      return const [];
    }

    final data = result['data'];
    final dataJson = _asMap(data);
    final rawEvents = _asList(dataJson?['events'] ?? data);

    final events = <MonthlyCalendarEvent>[];
    for (final item in rawEvents) {
      final itemJson = _asMap(item);
      if (itemJson == null) continue;
      events.add(MonthlyCalendarEvent.fromJson(itemJson));
    }

    _dayEvents[key] = events;
    _notify();
    return events;
  }

  static List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return const [];
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static void _notify() {
    changes.value = changes.value + 1;
  }
}
