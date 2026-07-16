import 'package:event_planner/models/planner_settings.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:flutter/foundation.dart';

class AssistantSettingsRepositoryException implements Exception {
  final String message;

  AssistantSettingsRepositoryException(this.message);

  @override
  String toString() => message;
}

class AssistantSettingsRepository {
  static final ValueNotifier<PlannerSettings> settings =
      ValueNotifier<PlannerSettings>(const PlannerSettings.defaults());

  static bool _loadedOnce = false;
  static Future<PlannerSettings>? _runningLoad;

  static PlannerSettings get cachedSettings => settings.value;

  static bool get hasCache => _loadedOnce;

  static Future<PlannerSettings> loadSettings({
    bool forceRefresh = false,
  }) async {
    if (_loadedOnce && !forceRefresh) return settings.value;

    final runningLoad = _runningLoad;
    if (runningLoad != null) return runningLoad;

    final request = _fetchSettings();
    _runningLoad = request;

    try {
      return await request;
    } finally {
      _runningLoad = null;
    }
  }

  static Future<void> refreshInBackground() async {
    try {
      await loadSettings(forceRefresh: true);
    } catch (e) {
      debugPrint('Assistant settings background refresh error: $e');
    }
  }

  static void setInAppAlertsLocally(bool value) {
    settings.value = settings.value.copyWith(inAppAlerts: value);
    _loadedOnce = true;
  }

  static Future<PlannerSettings> updateNotificationSettings({
    required bool inAppAlerts,
  }) async {
    final result = await ApiService.updateNotificationSettings(
      inAppAlerts: inAppAlerts,
    );

    if (result['success'] != true) {
      throw AssistantSettingsRepositoryException(
        _apiMessage(result, 'Failed to update setting'),
      );
    }

    final data = result['data'];
    final updatedSettings = data is Map
        ? PlannerSettings.fromApiResponse(result)
        : settings.value.copyWith(inAppAlerts: inAppAlerts);

    settings.value = updatedSettings;
    _loadedOnce = true;
    return updatedSettings;
  }

  static Future<void> logout() async {
    await ApiService.logout();
  }

  static Future<void> deleteAccount() async {
    final result = await ApiService.deleteAccount();

    if (result['success'] != true) {
      throw AssistantSettingsRepositoryException(
        _apiMessage(result, 'Failed to delete account'),
      );
    }
  }

  static void clear() {
    settings.value = const PlannerSettings.defaults();
    _loadedOnce = false;
    _runningLoad = null;
  }

  static Future<PlannerSettings> _fetchSettings() async {
    final result = await ApiService.getSettings();

    if (result['success'] != true) {
      throw AssistantSettingsRepositoryException(
        _apiMessage(result, 'Failed to load settings'),
      );
    }

    final loadedSettings = PlannerSettings.fromApiResponse(result);
    settings.value = loadedSettings;
    _loadedOnce = true;
    return loadedSettings;
  }

  static String _apiMessage(Map<String, dynamic> result, String fallback) {
    if (result['message'] != null) {
      return result['message'].toString();
    }

    final errors = result['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final firstError = errors.values.first;

      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }

      return firstError.toString();
    }

    return fallback;
  }
}
