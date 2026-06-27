import 'package:event_planner/models/event.dart';

class CreateEventData {
  final List<EventTypeOption> eventTypes;
  final List<PlannerOption> planners;

  CreateEventData({required this.eventTypes, required this.planners});

  factory CreateEventData.fromJson(Map<String, dynamic> json) {
    final eventTypes = <EventTypeOption>[];
    final planners = <PlannerOption>[];

    for (final item in _asList(json['event_types'])) {
      final itemJson = _asMap(item);
      if (itemJson == null) continue;

      final option = EventTypeOption.fromJson(itemJson);
      if (option.id != 0) eventTypes.add(option);
    }

    for (final item in _asList(json['planners'])) {
      final itemJson = _asMap(item);
      if (itemJson == null) continue;

      final planner = PlannerOption.fromJson(itemJson);
      if (planner.id != 0) planners.add(planner);
    }

    return CreateEventData(eventTypes: eventTypes, planners: planners);
  }

  EventTypeOption? eventTypeByName(String? name) {
    if (name == null || name.isEmpty) return null;

    for (final type in eventTypes) {
      if (type.name == name) return type;
    }
    return null;
  }

  PlannerOption? plannerById(int? id) {
    if (id == null) return null;

    for (final planner in planners) {
      if (planner.id == id) return planner;
    }
    return null;
  }
}

class EventTypeOption {
  final int id;
  final String name;

  EventTypeOption({required this.id, required this.name});

  factory EventTypeOption.fromJson(Map<String, dynamic> json) {
    return EventTypeOption(
      id: _asInt(json['id']),
      name: _asString(json['name']),
    );
  }
}

class PlannerOption {
  final int id;
  final String name;

  PlannerOption({required this.id, required this.name});

  factory PlannerOption.fromJson(Map<String, dynamic> json) {
    return PlannerOption(
      id: _asInt(json['id']),
      name: _asString(json['name'], fallback: 'Unknown'),
    );
  }
}

class CreateEventRequest {
  final int eventTypeId;
  final String name;
  final DateTime startDate;
  final String locationText;
  final int guestEstimate;
  final double budgetOverall;
  final String description;
  final int? plannerId;

  CreateEventRequest({
    required this.eventTypeId,
    required this.name,
    required this.startDate,
    required this.locationText,
    required this.guestEstimate,
    required this.budgetOverall,
    required this.description,
    this.plannerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'event_type_id': eventTypeId,
      'name': name,
      'start_date': _dateOnly(startDate),
      'location_text': locationText.isEmpty ? 'TBD' : locationText,
      'guest_estimate': guestEstimate,
      'budget_overall': budgetOverall,
      'description': description,
      if (plannerId != null) 'planner_id': plannerId,
    };
  }
}

Event eventFromCreateResponse(
  Map<String, dynamic> json, {
  String? eventTypeName,
  int? plannerId,
  String? plannerName,
}) {
  final eventJson = Map<String, dynamic>.from(json);

  if (eventJson['event'] is Map) {
    eventJson
      ..clear()
      ..addAll(Map<String, dynamic>.from(json['event'] as Map));
  }

  if (eventJson['event_type'] == null && eventTypeName != null) {
    eventJson['event_type'] = eventTypeName;
  }
  if (eventJson['planner_id'] == null && plannerId != null) {
    eventJson['planner_id'] = plannerId;
  }
  if (eventJson['planner_name'] == null && plannerName != null) {
    eventJson['planner_name'] = plannerName;
  }

  return Event.fromJson(eventJson);
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

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _dateOnly(DateTime date) {
  return '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
