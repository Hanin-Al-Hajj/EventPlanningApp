enum PlannerEventStatus {
  confirmed,
  inProgress,
  completed,
  cancelled,
  unknown;

  static PlannerEventStatus fromString(String? status) {
    final normalized = (status ?? '')
        .toLowerCase()
        .trim()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    switch (normalized) {
      case 'confirmed':
      case 'accepted':
        return PlannerEventStatus.confirmed;
      case 'in_progress':
      case 'inprogress':
        return PlannerEventStatus.inProgress;
      case 'completed':
      case 'done':
        return PlannerEventStatus.completed;
      case 'cancelled':
      case 'canceled':
        return PlannerEventStatus.cancelled;
      default:
        return PlannerEventStatus.unknown;
    }
  }

  String get apiValue {
    switch (this) {
      case PlannerEventStatus.confirmed:
        return 'confirmed';
      case PlannerEventStatus.inProgress:
        return 'in_progress';
      case PlannerEventStatus.completed:
        return 'completed';
      case PlannerEventStatus.cancelled:
        return 'cancelled';
      case PlannerEventStatus.unknown:
        return '';
    }
  }

  String get label {
    switch (this) {
      case PlannerEventStatus.confirmed:
        return 'Confirmed';
      case PlannerEventStatus.inProgress:
        return 'In Progress';
      case PlannerEventStatus.completed:
        return 'Completed';
      case PlannerEventStatus.cancelled:
        return 'Cancelled';
      case PlannerEventStatus.unknown:
        return 'Unknown';
    }
  }
}

class PlannerDashboard {
  final List<PlannerCalendarDay> calendarDays;
  final List<PlannerDashboardEvent> dayEvents;

  PlannerDashboard({required this.calendarDays, required this.dayEvents});

  factory PlannerDashboard.fromJson(Map<String, dynamic> json) {
    final calendarDays = <PlannerCalendarDay>[];

    for (final item in _asList(json['calendar_days'])) {
      final dayJson = _asMap(item);
      if (dayJson == null) continue;
      calendarDays.add(PlannerCalendarDay.fromJson(dayJson));
    }

    return PlannerDashboard(
      calendarDays: calendarDays,
      dayEvents: calendarDays
          .expand((day) => day.events)
          .where((event) => event.date != null)
          .toList(),
    );
  }

  List<PlannerDashboardEvent> eventsOn(DateTime selectedDate) {
    return dayEvents.where((event) => event.isOnDate(selectedDate)).toList();
  }

  PlannerDashboard copyWith({
    List<PlannerCalendarDay>? calendarDays,
    List<PlannerDashboardEvent>? dayEvents,
  }) {
    return PlannerDashboard(
      calendarDays: calendarDays ?? this.calendarDays,
      dayEvents: dayEvents ?? this.dayEvents,
    );
  }
}

class PlannerCalendarDay {
  final String dateKey;
  final DateTime? date;
  final List<PlannerDashboardEvent> events;

  PlannerCalendarDay({required this.dateKey, this.date, required this.events});

  factory PlannerCalendarDay.fromJson(Map<String, dynamic> json) {
    final dateKey = _asString(json['date']);
    final parsedDate = _parseDate(dateKey);
    final events = <PlannerDashboardEvent>[];

    for (final item in _asList(json['events'])) {
      final eventJson = _asMap(item);
      if (eventJson == null) continue;
      events.add(
        PlannerDashboardEvent.fromJson(eventJson, fallbackDate: parsedDate),
      );
    }

    return PlannerCalendarDay(
      dateKey: dateKey,
      date: parsedDate,
      events: events,
    );
  }

  bool get hasEvents => events.isNotEmpty;

  PlannerCalendarDay copyWith({
    String? dateKey,
    DateTime? date,
    List<PlannerDashboardEvent>? events,
  }) {
    return PlannerCalendarDay(
      dateKey: dateKey ?? this.dateKey,
      date: date ?? this.date,
      events: events ?? this.events,
    );
  }
}

class PlannerDashboardEvent {
  final int id;
  final String title;
  final String clientName;
  final DateTime? date;
  final String location;
  final int guests;
  final String budget;
  final PlannerEventStatus status;
  final String eventType;
  final String description;

  PlannerDashboardEvent({
    required this.id,
    required this.title,
    required this.clientName,
    this.date,
    required this.location,
    required this.guests,
    required this.budget,
    required this.status,
    required this.eventType,
    required this.description,
  });

  factory PlannerDashboardEvent.fromJson(
    Map<String, dynamic> json, {
    DateTime? fallbackDate,
  }) {
    final client = _asMap(json['client']);

    return PlannerDashboardEvent(
      id: _asInt(json['id']),
      title: _asString(json['title'], fallback: _asString(json['name'])),
      clientName: _asString(
        json['client_name'],
        fallback: _asString(client?['name']),
      ),
      date:
          _parseDate(
            json['start_date'] ?? json['start_date_iso'] ?? json['date'],
          ) ??
          fallbackDate,
      location: _asString(json['location']),
      guests: _asInt(json['guest_estimate'] ?? json['guests']),
      budget: _asString(
        json['budget'],
        fallback: _asString(json['budget_raw'], fallback: '0'),
      ),
      status: PlannerEventStatus.fromString(
        _asString(json['status'], fallback: 'confirmed'),
      ),
      eventType: _asString(json['event_type']),
      description: _asString(json['description']),
    );
  }

  bool isOnDate(DateTime selectedDate) {
    final eventDate = date;
    if (eventDate == null) return false;

    return eventDate.year == selectedDate.year &&
        eventDate.month == selectedDate.month &&
        eventDate.day == selectedDate.day;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'client_name': clientName,
      'start_date': date?.toIso8601String(),
      'location': location,
      'guest_estimate': guests,
      'budget': budget,
      'status': status.apiValue,
      'event_type': eventType,
      'description': description,
    };
  }

  PlannerDashboardEvent copyWith({
    int? id,
    String? title,
    String? clientName,
    DateTime? date,
    String? location,
    int? guests,
    String? budget,
    PlannerEventStatus? status,
    String? eventType,
    String? description,
  }) {
    return PlannerDashboardEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      clientName: clientName ?? this.clientName,
      date: date ?? this.date,
      location: location ?? this.location,
      guests: guests ?? this.guests,
      budget: budget ?? this.budget,
      status: status ?? this.status,
      eventType: eventType ?? this.eventType,
      description: description ?? this.description,
    );
  }
}

class PlannerRequestsResponse {
  final List<PlannerClientRequest> requests;

  PlannerRequestsResponse({required this.requests});

  factory PlannerRequestsResponse.fromJson(Map<String, dynamic> json) {
    final requests = <PlannerClientRequest>[];

    for (final item in _asList(json['requests'])) {
      final requestJson = _asMap(item);
      if (requestJson == null) continue;
      requests.add(PlannerClientRequest.fromJson(requestJson));
    }

    return PlannerRequestsResponse(requests: requests);
  }
}

class PlannerClientRequest {
  final int id;
  final String title;
  final String clientName;
  final DateTime date;
  final String location;
  final int guests;
  final String budget;
  final String description;

  PlannerClientRequest({
    required this.id,
    required this.title,
    required this.clientName,
    required this.date,
    required this.location,
    required this.guests,
    required this.budget,
    required this.description,
  });

  factory PlannerClientRequest.fromJson(Map<String, dynamic> json) {
    final client = _asMap(json['client']);

    return PlannerClientRequest(
      id: _asInt(json['id']),
      title: _asString(json['name'], fallback: _asString(json['title'])),
      clientName: _asString(client?['name'], fallback: 'Unknown'),
      date:
          _parseDate(
            json['start_date_iso'] ?? json['start_date'] ?? json['date'],
          ) ??
          DateTime.now(),
      location: _asString(json['location']),
      guests: _asInt(json['guest_estimate'] ?? json['guests']),
      budget: _asString(
        json['budget_raw'],
        fallback: _asString(json['budget'], fallback: '0'),
      ),
      description: _asString(json['description']),
    );
  }

  PlannerDashboardEvent toDashboardEvent({
    PlannerEventStatus status = PlannerEventStatus.confirmed,
  }) {
    return PlannerDashboardEvent(
      id: id,
      title: title,
      clientName: clientName,
      date: date,
      location: location,
      guests: guests,
      budget: budget,
      status: status,
      eventType: '',
      description: description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': title,
      'client': {'name': clientName},
      'start_date_iso': date.toIso8601String(),
      'location': location,
      'guest_estimate': guests,
      'budget_raw': budget,
      'description': description,
    };
  }

  PlannerClientRequest copyWith({
    int? id,
    String? title,
    String? clientName,
    DateTime? date,
    String? location,
    int? guests,
    String? budget,
    String? description,
  }) {
    return PlannerClientRequest(
      id: id ?? this.id,
      title: title ?? this.title,
      clientName: clientName ?? this.clientName,
      date: date ?? this.date,
      location: location ?? this.location,
      guests: guests ?? this.guests,
      budget: budget ?? this.budget,
      description: description ?? this.description,
    );
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

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime? _parseDate(dynamic value) {
  if (value is DateTime) return value;
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;

  return DateTime.tryParse(text.split(' ').first);
}
