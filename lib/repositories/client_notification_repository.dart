import 'package:event_planner/models/clientNotification.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:flutter/foundation.dart';

class ClientNotificationRepository {
  static final ValueNotifier<List<ClientNotification>> notifications =
      ValueNotifier<List<ClientNotification>>([]);

  static final ValueNotifier<ClientNotificationStats> stats =
      ValueNotifier<ClientNotificationStats>(
        const ClientNotificationStats.empty(),
      );

  static bool _notificationsLoadedOnce = false;
  static bool _statsLoadedOnce = false;
  static Future<void>? _runningNotificationsRefresh;
  static Future<void>? _runningStatsRefresh;

  static List<ClientNotification> get cachedNotifications =>
      notifications.value;

  static ClientNotificationStats get cachedStats => stats.value;

  static bool get hasNotificationsCache => _notificationsLoadedOnce;

  static bool get hasStatsCache => _statsLoadedOnce;

  static bool get hasCache => hasNotificationsCache || hasStatsCache;

  static Future<void> loadNotifications({bool forceRefresh = false}) async {
    if (_notificationsLoadedOnce && !forceRefresh) return;

    final runningRefresh = _runningNotificationsRefresh;
    if (runningRefresh != null) return runningRefresh;

    _runningNotificationsRefresh = _fetchNotifications();

    try {
      await _runningNotificationsRefresh;
    } finally {
      _runningNotificationsRefresh = null;
    }
  }

  static Future<void> loadStats({bool forceRefresh = false}) async {
    if (_statsLoadedOnce && !forceRefresh) return;

    final runningRefresh = _runningStatsRefresh;
    if (runningRefresh != null) return runningRefresh;

    _runningStatsRefresh = _fetchStats();

    try {
      await _runningStatsRefresh;
    } finally {
      _runningStatsRefresh = null;
    }
  }

  static Future<void> loadAll({bool forceRefresh = false}) async {
    await Future.wait([
      loadNotifications(forceRefresh: forceRefresh),
      loadStats(forceRefresh: forceRefresh),
    ]);
  }

  static Future<void> refreshInBackground() async {
    try {
      await loadAll(forceRefresh: true);
    } catch (e) {
      debugPrint('Notifications background refresh error: $e');
    }
  }

  static Future<void> _fetchNotifications() async {
    final result = await ApiService.getNotifications();
    if (result['success'] == false) {
      throw Exception(result['message'] ?? 'Failed to load notifications');
    }

    final response = ClientNotificationsResponse.fromApiData(
      result['data'] ?? result,
    );

    notifications.value = response.notifications;
    _notificationsLoadedOnce = true;
  }

  static Future<void> _fetchStats() async {
    final result = await ApiService.getNotificationStats();
    if (result['success'] == false) {
      throw Exception(result['message'] ?? 'Failed to load notification stats');
    }

    stats.value = ClientNotificationStats.fromApiData(
      result['data'] ?? result,
      fallbackTotal: notifications.value.length,
    );
    _statsLoadedOnce = true;
  }

  static void markOneRead(ClientNotification notification) {
    if (notification.isRead) return;

    notifications.value = notifications.value.map((item) {
      return item.id == notification.id ? item.copyWith(isRead: true) : item;
    }).toList();

    final currentStats = stats.value;
    stats.value = currentStats.copyWith(
      unread: (currentStats.unread - 1).clamp(0, currentStats.unread),
    );
  }

  static void markAllRead() {
    notifications.value = notifications.value.map((item) {
      return item.copyWith(isRead: true);
    }).toList();

    stats.value = stats.value.copyWith(unread: 0);
  }

  static void remove(ClientNotification notification) {
    notifications.value = notifications.value.where((item) {
      return item.id != notification.id;
    }).toList();

    final currentStats = stats.value;
    stats.value = currentStats.copyWith(
      total: (currentStats.total - 1).clamp(0, currentStats.total),
      unread: notification.isRead
          ? currentStats.unread
          : (currentStats.unread - 1).clamp(0, currentStats.unread),
    );
  }

  static void restore(ClientNotification notification) {
    final nextNotifications = List<ClientNotification>.from(
      notifications.value,
    );

    if (nextNotifications.any((item) => item.id == notification.id)) return;

    nextNotifications.insert(0, notification);
    notifications.value = nextNotifications;

    final currentStats = stats.value;
    stats.value = currentStats.copyWith(
      total: currentStats.total + 1,
      unread: notification.isRead
          ? currentStats.unread
          : currentStats.unread + 1,
    );
  }

  static void clearNotifications() {
    notifications.value = [];
    stats.value = const ClientNotificationStats.empty();
    _notificationsLoadedOnce = true;
    _statsLoadedOnce = true;
  }

  static void clear() {
    notifications.value = [];
    stats.value = const ClientNotificationStats.empty();
    _notificationsLoadedOnce = false;
    _statsLoadedOnce = false;
    _runningNotificationsRefresh = null;
    _runningStatsRefresh = null;
  }
}
