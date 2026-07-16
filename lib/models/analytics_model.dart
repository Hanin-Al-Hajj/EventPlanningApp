class AnalyticsData {
  final AnalyticsStats stats;
  final List<MonthlyAnalyticsPoint> monthlyData;
  final List<EventTypeAnalyticsStat> eventTypeStats;

  const AnalyticsData({
    required this.stats,
    required this.monthlyData,
    required this.eventTypeStats,
  });

  const AnalyticsData.empty()
    : stats = const AnalyticsStats.empty(),
      monthlyData = const [],
      eventTypeStats = const [];

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      stats: AnalyticsStats.fromJson(_asMap(json['stats'])),
      monthlyData:
          _asList(
                json['monthlyData'] ?? json['monthly_data'] ?? json['monthly'],
              )
              .map(_asMap)
              .whereType<Map<String, dynamic>>()
              .map(MonthlyAnalyticsPoint.fromJson)
              .toList(),
      eventTypeStats:
          _asList(
                json['eventTypeStats'] ??
                    json['event_type_stats'] ??
                    json['eventTypes'] ??
                    json['event_types'],
              )
              .map(_asMap)
              .whereType<Map<String, dynamic>>()
              .map(EventTypeAnalyticsStat.fromJson)
              .toList(),
    );
  }

  factory AnalyticsData.fromApiResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map) {
      return AnalyticsData.fromJson(Map<String, dynamic>.from(data));
    }
    return AnalyticsData.fromJson(response);
  }

  factory AnalyticsData.mock() {
    return AnalyticsData.fromJson({
      'stats': {
        'total_events': 44,
        'total_revenue': 72500.0,
        'task_completion_rate': 87.0,
        'avg_satisfaction': 8.5,
      },
      'monthlyData': [
        {'month': 'Jul', 'count': 2},
        {'month': 'Aug', 'count': 3},
        {'month': 'Sep', 'count': 2},
        {'month': 'Oct', 'count': 4},
        {'month': 'Nov', 'count': 3},
        {'month': 'Dec', 'count': 2},
        {'month': 'Jan', 'count': 2},
        {'month': 'Feb', 'count': 5},
        {'month': 'Mar', 'count': 4},
        {'month': 'Apr', 'count': 6},
        {'month': 'May', 'count': 5},
        {'month': 'Jun', 'count': 8},
      ],
      'eventTypeStats': [
        {'name': 'Weddings', 'count': 18},
        {'name': 'Corporate', 'count': 12},
        {'name': 'Celebrations', 'count': 9},
        {'name': 'Other', 'count': 5},
      ],
    });
  }

  int get eventTypeTotal {
    return eventTypeStats.fold<int>(0, (sum, item) => sum + item.count);
  }
}

class AnalyticsStats {
  final int totalEvents;
  final double totalRevenue;
  final double taskCompletionRate;
  final double avgSatisfaction;

  const AnalyticsStats({
    required this.totalEvents,
    required this.totalRevenue,
    required this.taskCompletionRate,
    required this.avgSatisfaction,
  });

  const AnalyticsStats.empty()
    : totalEvents = 0,
      totalRevenue = 0,
      taskCompletionRate = 0,
      avgSatisfaction = 0;

  factory AnalyticsStats.fromJson(Map<String, dynamic>? json) {
    return AnalyticsStats(
      totalEvents: _asInt(json?['total_events'] ?? json?['totalEvents']),
      totalRevenue: _asDouble(json?['total_revenue'] ?? json?['totalRevenue']),
      taskCompletionRate: _asDouble(
        json?['task_completion_rate'] ?? json?['taskCompletionRate'],
      ),
      avgSatisfaction: _asDouble(
        json?['avg_satisfaction'] ?? json?['avgSatisfaction'],
      ),
    );
  }
}

class MonthlyAnalyticsPoint {
  final String month;
  final int count;

  const MonthlyAnalyticsPoint({required this.month, required this.count});

  factory MonthlyAnalyticsPoint.fromJson(Map<String, dynamic> json) {
    return MonthlyAnalyticsPoint(
      month: _asString(json['month'] ?? json['label']),
      count: _asInt(json['count'] ?? json['events']),
    );
  }
}

class EventTypeAnalyticsStat {
  final String name;
  final int count;

  const EventTypeAnalyticsStat({required this.name, required this.count});

  factory EventTypeAnalyticsStat.fromJson(Map<String, dynamic> json) {
    return EventTypeAnalyticsStat(
      name: _asString(json['name'] ?? json['type'], fallback: 'Other'),
      count: _asInt(json['count'] ?? json['events']),
    );
  }
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

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}
