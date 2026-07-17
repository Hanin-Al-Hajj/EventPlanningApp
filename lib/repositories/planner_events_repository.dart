import 'package:event_planner/models/event.dart';
import 'package:event_planner/models/plannerEvent.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:flutter/foundation.dart';

class PlannerEventsCache {
  final List<Event> events;
  final MyEventStats stats;
  final bool hasData;

  const PlannerEventsCache({
    required this.events,
    required this.stats,
    required this.hasData,
  });

  const PlannerEventsCache.empty()
    : events = const [],
      stats = const MyEventStats.empty(),
      hasData = false;

  PlannerEventsCache copyWith({
    List<Event>? events,
    MyEventStats? stats,
    bool? hasData,
  }) {
    return PlannerEventsCache(
      events: events ?? this.events,
      stats: stats ?? this.stats,
      hasData: hasData ?? this.hasData,
    );
  }
}

class PlannerEventsRepository {
  static final ValueNotifier<PlannerEventsCache> cache =
      ValueNotifier<PlannerEventsCache>(const PlannerEventsCache.empty());

  static Future<void>? _runningLoad;

  static bool get hasCache => cache.value.hasData;
  static List<Event> get cachedEvents => cache.value.events;
  static MyEventStats get cachedStats => cache.value.stats;

  static Future<void> loadEvents({bool forceRefresh = false}) async {
    if (hasCache && !forceRefresh) return;

    final runningLoad = _runningLoad;
    if (runningLoad != null) return runningLoad;

    _runningLoad = _fetchEvents();

    try {
      await _runningLoad;
    } finally {
      _runningLoad = null;
    }
  }

  static Future<void> refreshInBackground() async {
    try {
      await loadEvents(forceRefresh: true);
    } catch (e) {
      debugPrint('Planner events background refresh error: $e');
    }
  }

  static Future<Map<String, dynamic>> updateStatus({
    required int eventId,
    required MyEventStatus status,
  }) async {
    debugPrint(
      '📤 Calling API to update status for event $eventId to ${status.apiValue}',
    );
    try {
      final result = await ApiService.updateEventStatus(
        eventId,
        status.apiValue,
      );
      debugPrint('📥 API Response: $result');
      return result;
    } catch (e) {
      debugPrint('❌ API Error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> archiveEvent(int eventId) async {
    debugPrint('📤 Calling API to archive event $eventId');
    try {
      final result = await ApiService.archivePlannerEvent(eventId);
      debugPrint('📥 Archive API Response: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Archive API Error: $e');
      rethrow;
    }
  }

  static void setCache({
    required List<Event> events,
    required MyEventStats stats,
  }) {
    cache.value = PlannerEventsCache(
      events: List<Event>.from(events),
      stats: stats,
      hasData: true,
    );
  }

  static void updateStatusLocally({
    required String eventId,
    required MyEventStatus status,
  }) {
    final current = cache.value;
    final index = current.events.indexWhere((event) => event.id == eventId);
    if (index == -1) return;

    final oldEvent = current.events[index];
    final nextEvents = List<Event>.from(current.events);

    nextEvents[index] = oldEvent.copyWithStatus(status);

    cache.value = current.copyWith(
      events: nextEvents,
      stats: current.stats.applyStatusChange(
        oldStatus: oldEvent.status,
        newStatus: status,
      ),
      hasData: true,
    );
  }

  static void removeEventLocally(String eventId) {
    final current = cache.value;

    cache.value = current.copyWith(
      events: current.events.where((event) => event.id != eventId).toList(),
      hasData: true,
    );
  }

  static void clear() {
    _runningLoad = null;
    cache.value = const PlannerEventsCache.empty();
  }

  static Future<void> _fetchEvents() async {
    final result = await ApiService.getPlannerEvents();
    if (result['success'] == false) {
      throw Exception(result['message'] ?? 'Failed to load events');
    }

    final data = result['data'];
    if (data is! Map) {
      throw Exception('Invalid events data');
    }

    final response = MyEventsResponse.fromJson(Map<String, dynamic>.from(data));

    cache.value = PlannerEventsCache(
      events: response.events,
      stats: response.stats,
      hasData: true,
    );
  }
}
