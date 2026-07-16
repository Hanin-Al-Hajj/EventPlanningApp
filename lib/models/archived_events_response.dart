import 'package:event_planner/models/event.dart';

class ArchivedEventsResponse {
  final List<Event> events;

  const ArchivedEventsResponse({required this.events});

  factory ArchivedEventsResponse.fromApiResponse(
    Map<String, dynamic> response,
  ) {
    final data = response['data'];

    if (data is Map) {
      return ArchivedEventsResponse.fromApiData(data['events']);
    }

    return ArchivedEventsResponse.fromApiData(response['events'] ?? data);
  }

  factory ArchivedEventsResponse.fromApiData(dynamic data) {
    final events = <Event>[];

    for (final item in _asList(data)) {
      final json = _asMap(item);
      if (json == null) continue;
      events.add(Event.fromJson(json));
    }

    return ArchivedEventsResponse(events: events);
  }
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const [];
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}
