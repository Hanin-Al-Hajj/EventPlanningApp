import 'package:event_planner/models/archived_events_response.dart';
import 'package:event_planner/models/event.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:flutter/foundation.dart';

class ArchiveRepositoryException implements Exception {
  final String message;

  ArchiveRepositoryException(this.message);

  @override
  String toString() => message;
}

class ArchiveRepository {
  static final ValueNotifier<List<Event>> events = ValueNotifier<List<Event>>(
    const [],
  );

  static bool _loadedOnce = false;
  static Future<List<Event>>? _runningLoad;

  static List<Event> get cachedEvents => events.value;

  static bool get hasCache => _loadedOnce;

  static Future<List<Event>> loadArchivedEvents({
    bool forceRefresh = false,
  }) async {
    if (_loadedOnce && !forceRefresh) return events.value;

    final runningLoad = _runningLoad;
    if (runningLoad != null) return runningLoad;

    final request = _fetchArchivedEvents();
    _runningLoad = request;

    try {
      return await request;
    } finally {
      _runningLoad = null;
    }
  }

  static Future<void> refreshInBackground() async {
    try {
      await loadArchivedEvents(forceRefresh: true);
    } catch (e) {
      debugPrint('Archive background refresh error: $e');
    }
  }

  static Future<void> unarchiveEvent(int eventId) async {
    final result = await ApiService.unarchivePlannerEvent(eventId);

    if (result['success'] != true) {
      throw ArchiveRepositoryException(
        result['message']?.toString() ?? 'Failed to unarchive event',
      );
    }
  }

  static void removeEventLocally(String eventId) {
    events.value = events.value
        .where((event) => event.id != eventId)
        .toList(growable: false);
    _loadedOnce = true;
  }

  static void restoreEventLocally(Event event, int index) {
    final nextEvents = List<Event>.from(events.value);
    final safeIndex = index.clamp(0, nextEvents.length).toInt();

    if (nextEvents.any((item) => item.id == event.id)) return;

    nextEvents.insert(safeIndex, event);
    events.value = nextEvents;
    _loadedOnce = true;
  }

  static void clear() {
    events.value = const [];
    _loadedOnce = false;
    _runningLoad = null;
  }

  static Future<List<Event>> _fetchArchivedEvents() async {
    final result = await ApiService.getArchivedPlannerEvents();

    if (result['success'] != true) {
      throw ArchiveRepositoryException(
        result['message']?.toString() ?? 'Failed to load archived events',
      );
    }

    final loadedEvents = ArchivedEventsResponse.fromApiResponse(result).events;

    events.value = loadedEvents;
    _loadedOnce = true;
    return loadedEvents;
  }
}
