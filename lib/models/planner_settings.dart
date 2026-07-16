class PlannerSettings {
  final PlannerNotificationSettings notifications;

  const PlannerSettings({required this.notifications});

  const PlannerSettings.defaults()
    : notifications = const PlannerNotificationSettings.defaults();

  bool get inAppAlerts => notifications.inAppAlerts;

  PlannerSettings copyWith({
    PlannerNotificationSettings? notifications,
    bool? inAppAlerts,
  }) {
    return PlannerSettings(
      notifications:
          notifications ??
          this.notifications.copyWith(inAppAlerts: inAppAlerts),
    );
  }

  factory PlannerSettings.fromApiResponse(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is Map) {
      return PlannerSettings.fromJson(Map<String, dynamic>.from(data));
    }

    return PlannerSettings.fromJson(response);
  }

  factory PlannerSettings.fromJson(Map<String, dynamic> json) {
    return PlannerSettings(
      notifications: PlannerNotificationSettings.fromJson(
        _asMap(json['notifications']) ?? json,
      ),
    );
  }
}

class PlannerNotificationSettings {
  final bool inAppAlerts;

  const PlannerNotificationSettings({required this.inAppAlerts});

  const PlannerNotificationSettings.defaults() : inAppAlerts = true;

  PlannerNotificationSettings copyWith({bool? inAppAlerts}) {
    return PlannerNotificationSettings(
      inAppAlerts: inAppAlerts ?? this.inAppAlerts,
    );
  }

  factory PlannerNotificationSettings.fromJson(Map<String, dynamic>? json) {
    return PlannerNotificationSettings(
      inAppAlerts: _asBool(
        json?['in_app_alerts'] ?? json?['inAppAlerts'],
        fallback: true,
      ),
    );
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;

  final text = value?.toString().toLowerCase().trim();
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;

  return fallback;
}
