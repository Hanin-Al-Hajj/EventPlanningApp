enum ClientNotificationFilter {
  all,
  events,
  messages;

  String get label {
    switch (this) {
      case ClientNotificationFilter.all:
        return 'All';
      case ClientNotificationFilter.events:
        return 'Events';
      case ClientNotificationFilter.messages:
        return 'Messages';
    }
  }

  bool matches(ClientNotification notification) {
    switch (this) {
      case ClientNotificationFilter.all:
        return true;
      case ClientNotificationFilter.events:
        return notification.category == ClientNotificationCategory.event;
      case ClientNotificationFilter.messages:
        return notification.category == ClientNotificationCategory.message;
    }
  }
}

enum ClientNotificationCategory { event, message }

class ClientNotificationsResponse {
  final List<ClientNotification> notifications;

  ClientNotificationsResponse({required this.notifications});

  factory ClientNotificationsResponse.fromApiData(dynamic data) {
    final rawNotifications = data is List
        ? data
        : data is Map
        ? data['notifications'] ?? data['data'] ?? const []
        : const [];

    final notifications = <ClientNotification>[];
    for (final item in _asList(rawNotifications)) {
      final json = _asMap(item);
      if (json == null) continue;
      notifications.add(ClientNotification.fromJson(json));
    }

    return ClientNotificationsResponse(notifications: notifications);
  }
}

class ClientNotificationStats {
  final int total;
  final int unread;
  final int urgent;

  const ClientNotificationStats({
    required this.total,
    required this.unread,
    required this.urgent,
  });

  const ClientNotificationStats.empty() : total = 0, unread = 0, urgent = 0;

  factory ClientNotificationStats.fromApiData(
    dynamic data, {
    int fallbackTotal = 0,
  }) {
    final json = _asMap(data);
    if (json == null) {
      return ClientNotificationStats(
        total: fallbackTotal,
        unread: 0,
        urgent: 0,
      );
    }

    return ClientNotificationStats(
      total: _asInt(json['total'], fallback: fallbackTotal),
      unread: _asInt(json['unread']),
      urgent: _asInt(json['urgent']),
    );
  }

  ClientNotificationStats copyWith({int? total, int? unread, int? urgent}) {
    return ClientNotificationStats(
      total: total ?? this.total,
      unread: unread ?? this.unread,
      urgent: urgent ?? this.urgent,
    );
  }
}

class ClientNotification {
  final int id;
  final String title;
  final String message;
  final String type;
  final String actionUrl;
  final String timeAgo;
  final DateTime? createdAt;
  final bool isRead;

  ClientNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.actionUrl,
    required this.timeAgo,
    this.createdAt,
    required this.isRead,
  });

  factory ClientNotification.fromJson(Map<String, dynamic> json) {
    return ClientNotification(
      id: _asInt(json['id']),
      title: _asString(json['title']),
      message: _asString(json['message'], fallback: _asString(json['body'])),
      type: _asString(json['type']),
      actionUrl: _asString(json['action_url']),
      timeAgo: _asString(
        json['time_ago'],
        fallback: _asString(json['created_at']),
      ),
      createdAt: _parseDate(json['created_at']),
      isRead: json['is_read'] == true,
    );
  }

  ClientNotificationCategory get category {
    return type.toLowerCase().contains('message')
        ? ClientNotificationCategory.message
        : ClientNotificationCategory.event;
  }

  bool get isMessage => category == ClientNotificationCategory.message;

  int? get eventIdFromActionUrl {
    try {
      final uri = Uri.parse(actionUrl);
      if (uri.pathSegments.length < 2) return null;
      return int.tryParse(uri.pathSegments.last);
    } catch (_) {
      return null;
    }
  }

  String get plannerNameFromTitle {
    const prefix = 'New Message from ';
    if (title.startsWith(prefix)) {
      return title.replaceFirst(prefix, '');
    }
    return 'Planner';
  }

  ClientNotification copyWith({
    int? id,
    String? title,
    String? message,
    String? type,
    String? actionUrl,
    String? timeAgo,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return ClientNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      actionUrl: actionUrl ?? this.actionUrl,
      timeAgo: timeAgo ?? this.timeAgo,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

class ClientNotificationEventDetails {
  final String eventName;
  final String? plannerName;

  ClientNotificationEventDetails({required this.eventName, this.plannerName});

  factory ClientNotificationEventDetails.fromJson(Map<String, dynamic> json) {
    final planner = _asMap(json['planner']);

    return ClientNotificationEventDetails(
      eventName: _asString(json['name'], fallback: 'Chat'),
      plannerName: _asString(planner?['name']),
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

DateTime? _parseDate(dynamic value) {
  if (value is DateTime) return value;
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text) ?? DateTime.tryParse(text.split(' ').first);
}
