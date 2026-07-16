import 'package:event_planner/models/chat_message.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:flutter/foundation.dart';

class ChatRepository {
  static final Map<String, ValueNotifier<List<ChatMessage>>> _messagesByKey =
      {};
  static final Set<String> _loadedKeys = {};
  static final Map<String, Future<void>> _runningRefreshes = {};

  static ValueNotifier<List<ChatMessage>> messagesFor({
    required int eventId,
    required bool isPlanner,
  }) {
    return _notifierFor(_key(eventId: eventId, isPlanner: isPlanner));
  }

  static List<ChatMessage> cachedMessages({
    required int eventId,
    required bool isPlanner,
  }) {
    return _notifierFor(_key(eventId: eventId, isPlanner: isPlanner)).value;
  }

  static bool hasCache({required int eventId, required bool isPlanner}) {
    return _loadedKeys.contains(_key(eventId: eventId, isPlanner: isPlanner));
  }

  static Future<void> loadMessages({
    required int eventId,
    required bool isPlanner,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _key(eventId: eventId, isPlanner: isPlanner);
    if (_loadedKeys.contains(cacheKey) && !forceRefresh) return;

    final runningRefresh = _runningRefreshes[cacheKey];
    if (runningRefresh != null) return runningRefresh;

    final refresh = _fetchMessages(
      eventId: eventId,
      isPlanner: isPlanner,
      cacheKey: cacheKey,
    );

    _runningRefreshes[cacheKey] = refresh;

    try {
      await refresh;
    } finally {
      _runningRefreshes.remove(cacheKey);
    }
  }

  static Future<void> refreshInBackground({
    required int eventId,
    required bool isPlanner,
  }) async {
    try {
      await loadMessages(
        eventId: eventId,
        isPlanner: isPlanner,
        forceRefresh: true,
      );
    } catch (e) {
      debugPrint('Chat background refresh error: $e');
    }
  }

  static Future<void> sendMessage({
    required int eventId,
    required bool isPlanner,
    required String text,
  }) async {
    final result = isPlanner
        ? await ApiService.sendPlannerMessage(eventId: eventId, message: text)
        : await ApiService.sendMessage(eventId: eventId, message: text);

    if (result['success'] == false) {
      throw Exception(result['message'] ?? 'Failed to send');
    }

    final cacheKey = _key(eventId: eventId, isPlanner: isPlanner);
    final returnedMessages = ChatMessagesResponse.fromApiResponse(result);

    if (returnedMessages.messages.isNotEmpty) {
      _notifierFor(cacheKey).value = returnedMessages.messages;
      _loadedKeys.add(cacheKey);
      return;
    }

    final sentMessage = chatMessageFromSendResponse(result, fallbackText: text);

    if (sentMessage != null) {
      _append(cacheKey, sentMessage);
      return;
    }

    await loadMessages(
      eventId: eventId,
      isPlanner: isPlanner,
      forceRefresh: true,
    );
  }

  static Future<void> clearMessages({
    required int eventId,
    required bool isPlanner,
  }) async {
    final result = isPlanner
        ? await ApiService.deleteAllPlannerMessages(eventId)
        : await ApiService.deleteAllMessages(eventId);

    if (result['success'] == false) {
      throw Exception(result['message'] ?? 'Failed to clear chat');
    }

    final cacheKey = _key(eventId: eventId, isPlanner: isPlanner);
    _notifierFor(cacheKey).value = [];
    _loadedKeys.add(cacheKey);
  }

  static void clearEvent({required int eventId, required bool isPlanner}) {
    final cacheKey = _key(eventId: eventId, isPlanner: isPlanner);
    _messagesByKey.remove(cacheKey);
    _loadedKeys.remove(cacheKey);
    _runningRefreshes.remove(cacheKey);
  }

  static void clear() {
    _messagesByKey.clear();
    _loadedKeys.clear();
    _runningRefreshes.clear();
  }

  static Future<void> _fetchMessages({
    required int eventId,
    required bool isPlanner,
    required String cacheKey,
  }) async {
    final result = isPlanner
        ? await ApiService.getPlannerMessages(eventId)
        : await ApiService.getMessages(eventId);

    if (result['success'] == false) {
      throw Exception(result['message'] ?? 'Failed to load messages');
    }

    final response = ChatMessagesResponse.fromApiResponse(result);
    _notifierFor(cacheKey).value = response.messages;
    _loadedKeys.add(cacheKey);
  }

  static void _append(String cacheKey, ChatMessage message) {
    final notifier = _notifierFor(cacheKey);
    final nextMessages = List<ChatMessage>.from(notifier.value);

    final existingIndex = message.id > 0
        ? nextMessages.indexWhere((item) => item.id == message.id)
        : -1;

    if (existingIndex == -1) {
      nextMessages.add(message);
    } else {
      nextMessages[existingIndex] = message;
    }

    notifier.value = nextMessages;
    _loadedKeys.add(cacheKey);
  }

  static ValueNotifier<List<ChatMessage>> _notifierFor(String cacheKey) {
    return _messagesByKey.putIfAbsent(
      cacheKey,
      () => ValueNotifier<List<ChatMessage>>([]),
    );
  }

  static String _key({required int eventId, required bool isPlanner}) {
    return '${isPlanner ? 'planner' : 'client'}:$eventId';
  }
}
