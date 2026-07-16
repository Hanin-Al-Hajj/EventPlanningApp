import 'package:event_planner/models/planner_dashboard.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:flutter/foundation.dart';

class PlannerDashboardRepository {
  static final ValueNotifier<int> dashboardChanges = ValueNotifier<int>(0);
  static final ValueNotifier<List<PlannerClientRequest>> requests =
      ValueNotifier<List<PlannerClientRequest>>([]);

  static final Map<String, PlannerDashboard> _dashboardsByWeek = {};
  static final Map<String, Future<void>> _runningDashboardLoads = {};
  static Future<void>? _runningRequestsLoad;
  static bool _requestsLoadedOnce = false;

  static PlannerDashboard? cachedDashboard(String weekKey) {
    return _dashboardsByWeek[weekKey];
  }

  static List<PlannerClientRequest> get cachedRequests => requests.value;

  static bool hasDashboardCache(String weekKey) {
    return _dashboardsByWeek.containsKey(weekKey);
  }

  static bool get hasRequestsCache => _requestsLoadedOnce;

  static Future<void> loadDashboard({
    required String weekKey,
    bool forceRefresh = false,
  }) async {
    if (hasDashboardCache(weekKey) && !forceRefresh) return;

    final runningLoad = _runningDashboardLoads[weekKey];
    if (runningLoad != null) return runningLoad;

    final load = _fetchDashboard(weekKey);
    _runningDashboardLoads[weekKey] = load;

    try {
      await load;
    } finally {
      _runningDashboardLoads.remove(weekKey);
    }
  }

  static Future<void> loadRequests({bool forceRefresh = false}) async {
    if (_requestsLoadedOnce && !forceRefresh) return;

    final runningLoad = _runningRequestsLoad;
    if (runningLoad != null) return runningLoad;

    _runningRequestsLoad = _fetchRequests();

    try {
      await _runningRequestsLoad;
    } finally {
      _runningRequestsLoad = null;
    }
  }

  static Future<void> refreshDashboardInBackground(String weekKey) async {
    try {
      await loadDashboard(weekKey: weekKey, forceRefresh: true);
    } catch (e) {
      debugPrint('Planner dashboard background refresh error: $e');
    }
  }

  static Future<void> refreshRequestsInBackground() async {
    try {
      await loadRequests(forceRefresh: true);
    } catch (e) {
      debugPrint('Planner requests background refresh error: $e');
    }
  }

  static Future<Map<String, dynamic>> acceptRequest(
    PlannerClientRequest request,
  ) async {
    final result = await ApiService.acceptPlannerRequest(request.id.toString());

    if (result['success'] == true) {
      removeRequest(request.id);
      clearDashboardCacheFor(request.date);
    }

    return result;
  }

  static Future<Map<String, dynamic>> declineRequest(
    PlannerClientRequest request,
  ) async {
    final result = await ApiService.declinePlannerRequest(
      request.id.toString(),
    );

    if (result['success'] == true) {
      removeRequest(request.id);
    }

    return result;
  }

  static void removeRequest(int requestId) {
    requests.value = requests.value
        .where((request) => request.id != requestId)
        .toList();
  }

  static void restoreRequest(PlannerClientRequest request) {
    final nextRequests = List<PlannerClientRequest>.from(requests.value);

    if (nextRequests.any((item) => item.id == request.id)) return;

    nextRequests.insert(0, request);
    requests.value = nextRequests;
    _requestsLoadedOnce = true;
  }

  static void upsertEvent({
    required String weekKey,
    required PlannerDashboardEvent event,
  }) {
    final dashboard = _dashboardsByWeek[weekKey];
    if (dashboard == null) return;

    final nextEvents = List<PlannerDashboardEvent>.from(dashboard.dayEvents);
    final eventIndex = nextEvents.indexWhere((item) => item.id == event.id);

    if (eventIndex == -1) {
      nextEvents.add(event);
    } else {
      nextEvents[eventIndex] = event;
    }

    _dashboardsByWeek[weekKey] = dashboard.copyWith(dayEvents: nextEvents);
    dashboardChanges.value++;
  }

  static void removeEvent({required String weekKey, required int eventId}) {
    final dashboard = _dashboardsByWeek[weekKey];
    if (dashboard == null) return;

    _dashboardsByWeek[weekKey] = dashboard.copyWith(
      dayEvents: dashboard.dayEvents
          .where((event) => event.id != eventId)
          .toList(),
    );
    dashboardChanges.value++;
  }

  static void clearDashboardCacheFor(DateTime date) {
    _dashboardsByWeek.remove(_dateKey(_startOfWeek(date)));
    dashboardChanges.value++;
  }

  static void clearDashboardCache() {
    _dashboardsByWeek.clear();
    _runningDashboardLoads.clear();
    dashboardChanges.value++;
  }

  static void clear() {
    clearDashboardCache();
    requests.value = [];
    _requestsLoadedOnce = false;
    _runningRequestsLoad = null;
  }

  static Future<void> _fetchDashboard(String weekKey) async {
    final result = await ApiService.getPlannerDashboard(date: weekKey);
    if (result['success'] == false) {
      throw Exception(result['message'] ?? 'Failed to load dashboard');
    }

    final data = result['data'];
    if (data is! Map) {
      throw Exception('Invalid dashboard data');
    }

    _dashboardsByWeek[weekKey] = PlannerDashboard.fromJson(
      Map<String, dynamic>.from(data),
    );
    dashboardChanges.value++;
  }

  static Future<void> _fetchRequests() async {
    final result = await ApiService.getPlannerRequests();
    if (result['success'] == false) {
      throw Exception(result['message'] ?? 'Failed to load requests');
    }

    final data = result['data'];
    if (data is! Map) {
      throw Exception('Invalid requests data');
    }

    final response = PlannerRequestsResponse.fromJson(
      Map<String, dynamic>.from(data),
    );

    requests.value = response.requests;
    _requestsLoadedOnce = true;
  }

  static DateTime _startOfWeek(DateTime d) {
    final current = DateTime(d.year, d.month, d.day);
    return current.subtract(Duration(days: current.weekday - 1));
  }

  static String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
