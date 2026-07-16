class MessageChatsResponse {
  final List<MessageChat> chats;

  MessageChatsResponse({required this.chats});

  factory MessageChatsResponse.fromApiData(dynamic data) {
    final rawChats = data is List
        ? data
        : data is Map
        ? data['events'] ?? data['chats'] ?? data['data'] ?? const []
        : const [];

    final chats = <MessageChat>[];
    for (final item in _asList(rawChats)) {
      final json = _asMap(item);
      if (json == null) continue;
      chats.add(MessageChat.fromJson(json));
    }

    return MessageChatsResponse(chats: chats);
  }
}

class MessageChat {
  final int id;
  final String eventName;
  final MessagePlanner planner;
  final MessagePreview? lastMessage;
  final int unreadCount;

  MessageChat({
    required this.id,
    required this.eventName,
    required this.planner,
    this.lastMessage,
    required this.unreadCount,
  });

  factory MessageChat.fromJson(Map<String, dynamic> json) {
    final planner = _asMap(json['planner']);
    final client = _asMap(json['client']);
    final participant = planner ?? client ?? _asMap(json['user']);

    final fallbackName = _asString(
      json['planner_name'],
      fallback: _asString(
        json['client_name'],
        fallback: planner == null && client != null ? 'Client' : 'Planner',
      ),
    );

    return MessageChat(
      id: _asInt(json['id'] ?? json['event_id']),
      eventName: _asString(
        json['event_name'] ?? json['name'],
        fallback: _asString(json['title'], fallback: 'Event'),
      ),
      planner: MessagePlanner.fromJson(participant, fallbackName: fallbackName),
      lastMessage: MessagePreview.fromJsonOrNull(json['last_message']),
      unreadCount: _asInt(json['unread_count'] ?? json['unread']),
    );
  }

  String get plannerName => planner.name;

  String get clientName => planner.name;

  String get participantName => planner.name;

  String get lastMessageText => lastMessage?.message.isNotEmpty == true
      ? lastMessage!.message
      : 'Start conversation...';

  String get lastMessageTime => lastMessage?.createdAt ?? '';

  MessageChat copyWith({
    int? id,
    String? eventName,
    MessagePlanner? planner,
    MessagePreview? lastMessage,
    int? unreadCount,
  }) {
    return MessageChat(
      id: id ?? this.id,
      eventName: eventName ?? this.eventName,
      planner: planner ?? this.planner,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class MessagePlanner {
  final int id;
  final String name;

  MessagePlanner({required this.id, required this.name});

  factory MessagePlanner.fromJson(
    Map<String, dynamic>? json, {
    String fallbackName = 'Planner',
  }) {
    return MessagePlanner(
      id: _asInt(json?['id']),
      name: _asString(json?['name'], fallback: fallbackName),
    );
  }
}

class MessagePreview {
  final String message;
  final String createdAt;

  MessagePreview({required this.message, required this.createdAt});

  factory MessagePreview.fromJson(Map<String, dynamic> json) {
    return MessagePreview(
      message: _asString(json['message'] ?? json['body'] ?? json['text']),
      createdAt: _asString(
        json['created_at'],
        fallback: _asString(json['time_ago'] ?? json['createdAt']),
      ),
    );
  }

  static MessagePreview? fromJsonOrNull(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return MessagePreview(message: value, createdAt: '');
    }

    final json = _asMap(value);
    if (json == null) return null;
    return MessagePreview.fromJson(json);
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
