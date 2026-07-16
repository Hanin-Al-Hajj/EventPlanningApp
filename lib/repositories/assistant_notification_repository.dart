import 'package:event_planner/models/planner_notification.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:flutter/foundation.dart';

class AssistantNotificationRepository {
  static final ValueNotifier<List<plannerNotification>> notifications =
      ValueNotifier<List<plannerNotification>>([]);

  static bool _loadedOnce = false;
  static Future<void>? _runningLoad;

  static List<plannerNotification> get cachedNotifications =>
      notifications.value;

  static bool get hasCache => _loadedOnce;

  static Future<void> loadNotifications({bool forceRefresh = false}) async {
    if (_loadedOnce && !forceRefresh) return;

    final runningLoad = _runningLoad;
    if (runningLoad != null) return runningLoad;

    _runningLoad = _fetchNotifications();

    try {
      await _runningLoad;
    } finally {
      _runningLoad = null;
    }
  }

  static Future<void> refreshInBackground() async {
    try {
      await loadNotifications(forceRefresh: true);
    } catch (e) {
      debugPrint('Assistant notifications background refresh error: $e');
    }
  }

  static Future<dynamic> archiveNotification(int notificationId) {
    return ApiService.archiveAssistantNotification(notificationId);
  }

  static Future<dynamic> markNotificationRead(int notificationId) {
    return ApiService.markAssistantNotificationRead(notificationId);
  }

  static Future<dynamic> markAllReadRemote() {
    return ApiService.markAllAssistantNotificationsRead();
  }

  static Future<dynamic> clearAllRemote() {
    return ApiService.archiveAllAssistantNotifications();
  }

  static void setNotifications(List<plannerNotification> items) {
    notifications.value = List<plannerNotification>.from(items);
    _loadedOnce = true;
  }

  static void remove(plannerNotification notification) {
    notifications.value = notifications.value
        .where((item) => item.id != notification.id)
        .toList();
    _loadedOnce = true;
  }

  static void restore(plannerNotification notification) {
    final nextNotifications = List<plannerNotification>.from(
      notifications.value,
    );

    if (nextNotifications.any((item) => item.id == notification.id)) return;

    nextNotifications.insert(0, notification);
    notifications.value = nextNotifications;
    _loadedOnce = true;
  }

  static void markOneRead(plannerNotification notification) {
    if (notification.isRead) return;

    notifications.value = notifications.value.map((item) {
      return item.id == notification.id ? _asRead(item) : item;
    }).toList();
    _loadedOnce = true;
  }

  static void markAllRead() {
    notifications.value = notifications.value.map(_asRead).toList();
    _loadedOnce = true;
  }

  static void clearNotifications() {
    notifications.value = [];
    _loadedOnce = true;
  }

  static void clear() {
    notifications.value = [];
    _loadedOnce = false;
    _runningLoad = null;
  }

  static Future<void> _fetchNotifications() async {
    final response = await ApiService.getAssistantNotifications();
    if (response['success'] == false) {
      throw Exception(response['message'] ?? 'Failed to load notifications');
    }

    final raw = _notificationListFrom(response);
    final parsed = <plannerNotification>[];

    for (final item in raw) {
      try {
        parsed.add(
          plannerNotification.fromJson(Map<String, dynamic>.from(item as Map)),
        );
      } catch (_) {}
    }

    notifications.value = parsed;
    _loadedOnce = true;
  }

  static List<dynamic> _notificationListFrom(Map<String, dynamic> response) {
    final notifications = response['notifications'];
    if (notifications is List) return notifications;

    final data = response['data'];
    if (data is List) return data;
    if (data is Map && data['notifications'] is List) {
      return data['notifications'] as List;
    }

    return const [];
  }

  static plannerNotification _asRead(plannerNotification notification) {
    return plannerNotification(
      id: notification.id,
      userId: notification.userId,
      type: notification.type,
      priority: notification.priority,
      title: notification.title,
      message: notification.message,
      icon: notification.icon,
      actionUrl: notification.actionUrl,
      isRead: true,
      readAt: notification.readAt ?? DateTime.now(),
      createdAt: notification.createdAt,
    );
  }
}
