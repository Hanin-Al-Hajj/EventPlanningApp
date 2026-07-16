import 'package:event_planner/models/message_chat.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:flutter/foundation.dart';

class PlannerMessageRepository {
  static final ValueNotifier<List<MessageChat>> chats =
      ValueNotifier<List<MessageChat>>([]);

  static bool _loadedOnce = false;
  static Future<void>? _runningRefresh;

  static List<MessageChat> get cachedChats => chats.value;

  static bool get hasCache => _loadedOnce;

  static Future<void> loadChats({bool forceRefresh = false}) async {
    if (_loadedOnce && !forceRefresh) return;

    final runningRefresh = _runningRefresh;
    if (runningRefresh != null) return runningRefresh;

    _runningRefresh = _fetchChats();

    try {
      await _runningRefresh;
    } finally {
      _runningRefresh = null;
    }
  }

  static Future<void> refreshInBackground() async {
    try {
      await loadChats(forceRefresh: true);
    } catch (e) {
      debugPrint('Planner messages background refresh error: $e');
    }
  }

  static Future<void> markReadOnServer(int eventId) async {
    try {
      await ApiService.markPlannerEventMessagesAsRead(eventId);
    } catch (e) {
      debugPrint('Mark planner messages as read error: $e');
    }
  }

  static Future<void> _fetchChats() async {
    final result = await ApiService.getPlannerMessagesEvents();
    if (result['success'] == false) {
      throw Exception(result['message'] ?? 'Failed to load chats');
    }

    final response = MessageChatsResponse.fromApiData(result['data'] ?? result);

    chats.value = response.chats;
    _loadedOnce = true;
  }

  static void markRead(int eventId) {
    chats.value = chats.value.map((chat) {
      return chat.id == eventId ? chat.copyWith(unreadCount: 0) : chat;
    }).toList();
  }

  static void upsert(MessageChat chat) {
    final nextChats = List<MessageChat>.from(chats.value);
    final index = nextChats.indexWhere((item) => item.id == chat.id);

    if (index == -1) {
      nextChats.insert(0, chat);
    } else {
      nextChats[index] = chat;
    }

    chats.value = nextChats;
    _loadedOnce = true;
  }

  static void clear() {
    chats.value = [];
    _loadedOnce = false;
    _runningRefresh = null;
  }
}
