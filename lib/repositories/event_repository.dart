import 'package:event_planner/models/event.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:flutter/foundation.dart';

class EventRepository {
  static final ValueNotifier<List<Event>> events = ValueNotifier<List<Event>>(
    [],
  );

  static bool _loadedOnce = false;
  static Future<void>? _runningRefresh;

  static List<Event> get cachedEvents => events.value;
  static bool get hasCache => events.value.isNotEmpty;

  static void seed(List<Event> initialEvents) {
    if (events.value.isNotEmpty || initialEvents.isEmpty) return;
    events.value = List<Event>.from(initialEvents);
    _loadedOnce = true;
  }

  static Future<void> loadEvents({bool forceRefresh = false}) async {
    if (_loadedOnce && !forceRefresh) return;

    final runningRefresh = _runningRefresh;
    if (runningRefresh != null) return runningRefresh;

    _runningRefresh = _fetchEvents();

    try {
      await _runningRefresh;
    } finally {
      _runningRefresh = null;
    }
  }

  static Future<void> refreshInBackground() async {
    try {
      await loadEvents(forceRefresh: true);
    } catch (e) {
      debugPrint('Events background refresh error: $e');
    }
  }

  static Future<void> _fetchEvents() async {
    final result = await ApiService.getEvents();
    if (result['success'] == false) {
      throw Exception(result['message'] ?? 'Failed to load events');
    }

    final rawEvents = _eventListFromResponse(result);
    final parsedEvents = rawEvents
        .map((item) => Event.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    events.value = parsedEvents;
    _loadedOnce = true;
  }

  static List<dynamic> _eventListFromResponse(Map<String, dynamic> result) {
    final data = result['data'];
    if (data is List) return data;
    if (data is Map && data['events'] is List) return data['events'] as List;
    return const [];
  }

  static void upsert(Event event) {
    final nextEvents = List<Event>.from(events.value);
    final index = nextEvents.indexWhere((item) => item.id == event.id);

    if (index == -1) {
      nextEvents.insert(0, event);
    } else {
      nextEvents[index] = event;
    }

    events.value = nextEvents;
  }

  static void remove(String eventId) {
    events.value = events.value.where((event) => event.id != eventId).toList();
  }

  static void clear() {
    events.value = [];
    _loadedOnce = false;
    _runningRefresh = null;
  }
}
