import 'package:event_planner/models/analytics_model.dart';
import 'package:flutter/foundation.dart';
import 'package:event_planner/services/api_service.dart';

class AnalyticsRepository {
  static final ValueNotifier<AnalyticsData?> analytics =
      ValueNotifier<AnalyticsData?>(null);

  static bool _loadedOnce = false;
  static Future<AnalyticsData>? _runningRefresh;

  static AnalyticsData? get cachedAnalytics => analytics.value;

  static bool get hasCache => _loadedOnce && analytics.value != null;

  static Future<AnalyticsData> loadAnalytics({
    bool forceRefresh = false,
  }) async {
    final cached = analytics.value;
    if (!forceRefresh && cached != null) return cached;

    final runningRefresh = _runningRefresh;
    if (runningRefresh != null) return runningRefresh;

    final request = _fetchAnalytics();
    _runningRefresh = request;

    try {
      return await request;
    } finally {
      _runningRefresh = null;
    }
  }

  static Future<void> refreshInBackground() async {
    try {
      await loadAnalytics(forceRefresh: true);
    } catch (e) {
      debugPrint('Analytics background refresh error: $e');
    }
  }

  static void setCache(AnalyticsData data) {
    analytics.value = data;
    _loadedOnce = true;
  }

  static void clear() {
    analytics.value = null;
    _loadedOnce = false;
    _runningRefresh = null;
  }

  static Future<AnalyticsData> _fetchAnalytics() async {
    final response = await ApiService.getPlannerAnalytics();

    if (response['success'] == false) {
      throw Exception(response['message'] ?? 'Failed to load analytics');
    }

    final data = AnalyticsData.fromApiResponse(response);

    analytics.value = data;
    _loadedOnce = true;
    return data;
  }
}
