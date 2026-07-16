import 'package:event_planner/models/create_event.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:flutter/foundation.dart';

class CreateEventRepository {
  static final ValueNotifier<CreateEventData?> createData =
      ValueNotifier<CreateEventData?>(null);

  static Future<void>? _runningRefresh;

  static CreateEventData? get cachedData => createData.value;
  static bool get hasCache => createData.value != null;

  static Future<CreateEventData> loadCreateData({
    bool forceRefresh = false,
  }) async {
    final cached = createData.value;
    if (cached != null && !forceRefresh) return cached;

    final runningRefresh = _runningRefresh;
    if (runningRefresh != null) {
      await runningRefresh;
      final refreshedCache = createData.value;
      if (refreshedCache != null) return refreshedCache;
    }

    _runningRefresh = _fetchCreateData();

    try {
      await _runningRefresh;
    } finally {
      _runningRefresh = null;
    }

    final refreshedCache = createData.value;
    if (refreshedCache == null) {
      throw Exception('Failed to load form data');
    }

    return refreshedCache;
  }

  static Future<void> refreshInBackground() async {
    try {
      await loadCreateData(forceRefresh: true);
    } catch (e) {
      debugPrint('Create event data background refresh error: $e');
    }
  }

  static Future<void> _fetchCreateData() async {
    final result = await ApiService.getCreateData();
    if (result['success'] == false) {
      throw Exception(result['message'] ?? 'Failed to load form data');
    }

    final data = result['data'];
    if (data is! Map) {
      throw Exception('Invalid form data');
    }

    createData.value = CreateEventData.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  static void clear() {
    createData.value = null;
    _runningRefresh = null;
  }
}
