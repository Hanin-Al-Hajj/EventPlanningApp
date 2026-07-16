class ChatMessagesResponse {
  final List<ChatMessage> messages;

  ChatMessagesResponse({required this.messages});

  factory ChatMessagesResponse.fromApiResponse(Map<String, dynamic> response) {
    return ChatMessagesResponse.fromApiData(response['data'] ?? response);
  }

  factory ChatMessagesResponse.fromApiData(dynamic data) {
    dynamic rawMessages;

    if (data is List) {
      rawMessages = data;
    } else if (data is Map) {
      final nestedData = data['data'];
      rawMessages =
          data['messages'] ??
          (nestedData is Map ? nestedData['messages'] : null) ??
          (nestedData is List ? nestedData : null) ??
          const [];
    } else {
      rawMessages = const [];
    }

    final messages = <ChatMessage>[];
    for (final item in _asList(rawMessages)) {
      final json = _asMap(item);
      if (json == null) continue;
      messages.add(ChatMessage.fromJson(json));
    }

    return ChatMessagesResponse(messages: messages);
  }
}

class ChatMessage {
  final int id;
  final int? senderId;
  final String senderName;
  final String message;
  final String createdAt;
  final bool isMine;

  ChatMessage({
    required this.id,
    this.senderId,
    required this.senderName,
    required this.message,
    required this.createdAt,
    required this.isMine,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = _asMap(json['sender']);

    return ChatMessage(
      id: _asInt(json['id']),
      senderId: _asNullableInt(json['sender_id']),
      senderName: _asString(
        json['sender_name'] ?? sender?['name'] ?? json['user_name'],
        fallback: 'Unknown',
      ),
      message: _asString(json['message'], fallback: _asString(json['body'])),
      createdAt: _asString(
        json['created_at'],
        fallback: _asString(json['time_ago'], fallback: 'Just now'),
      ),
      isMine: _asBool(json['is_mine'] ?? json['isMine']),
    );
  }

  factory ChatMessage.local({required String message, String senderName = ''}) {
    return ChatMessage(
      id: -DateTime.now().microsecondsSinceEpoch,
      senderName: senderName,
      message: message,
      createdAt: 'Just now',
      isMine: true,
    );
  }

  ChatMessage copyWith({
    int? id,
    int? senderId,
    String? senderName,
    String? message,
    String? createdAt,
    bool? isMine,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isMine: isMine ?? this.isMine,
    );
  }
}

ChatMessage? chatMessageFromSendResponse(
  Map<String, dynamic> response, {
  required String fallbackText,
}) {
  final data = response['data'];
  final responseMessage = response['message'];

  final json =
      _asMap(responseMessage) ??
      (data is Map ? _asMap(data['message']) : null) ??
      _asMap(response['sent_message']);

  if (json != null) return ChatMessage.fromJson(json);

  final rawMessages = data is Map ? data['messages'] : null;
  if (rawMessages is List && rawMessages.isNotEmpty) {
    final lastMessage = _asMap(rawMessages.last);
    if (lastMessage != null) return ChatMessage.fromJson(lastMessage);
  }

  return ChatMessage.local(message: fallbackText);
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

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;

  final text = value?.toString().toLowerCase().trim();
  return text == 'true' || text == '1' || text == 'yes';
}
