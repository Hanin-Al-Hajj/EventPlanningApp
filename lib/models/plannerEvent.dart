import 'package:event_planner/models/event.dart';

enum MyEventStatus {
  confirmed,
  inProgress,
  completed,
  cancelled,
  unknown;

  static const List<MyEventStatus> pickerValues = [
    MyEventStatus.confirmed,
    MyEventStatus.inProgress,
    MyEventStatus.completed,
    MyEventStatus.cancelled,
  ];

  static MyEventStatus fromString(String? status) {
    switch ((status ?? '').toLowerCase().trim().replaceAll('-', '_')) {
      case 'confirmed':
        return MyEventStatus.confirmed;
      case 'in_progress':
      case 'inprogress':
        return MyEventStatus.inProgress;
      case 'completed':
      case 'done':
        return MyEventStatus.completed;
      case 'cancelled':
      case 'canceled':
        return MyEventStatus.cancelled;
      default:
        return MyEventStatus.unknown;
    }
  }

  String get apiValue {
    switch (this) {
      case MyEventStatus.confirmed:
        return 'confirmed';
      case MyEventStatus.inProgress:
        return 'in_progress';
      case MyEventStatus.completed:
        return 'completed';
      case MyEventStatus.cancelled:
        return 'cancelled';
      case MyEventStatus.unknown:
        return '';
    }
  }

  String get label {
    switch (this) {
      case MyEventStatus.confirmed:
        return 'Confirmed';
      case MyEventStatus.inProgress:
        return 'In Progress';
      case MyEventStatus.completed:
        return 'Completed';
      case MyEventStatus.cancelled:
        return 'Cancelled';
      case MyEventStatus.unknown:
        return 'Unknown';
    }
  }
}

enum MyEventFilter {
  all,
  confirmed,
  inProgress,
  completed;

  MyEventStatus? get status {
    switch (this) {
      case MyEventFilter.confirmed:
        return MyEventStatus.confirmed;
      case MyEventFilter.inProgress:
        return MyEventStatus.inProgress;
      case MyEventFilter.completed:
        return MyEventStatus.completed;
      case MyEventFilter.all:
        return null;
    }
  }

  String get label {
    switch (this) {
      case MyEventFilter.all:
        return 'All';
      case MyEventFilter.confirmed:
        return MyEventStatus.confirmed.label;
      case MyEventFilter.inProgress:
        return MyEventStatus.inProgress.label;
      case MyEventFilter.completed:
        return MyEventStatus.completed.label;
    }
  }

  bool matches(Event event) {
    final filterStatus = status;
    if (filterStatus == null) return true;
    return MyEventStatus.fromString(event.status) == filterStatus;
  }
}

class MyEventsResponse {
  final List<Event> events;
  final MyEventStats stats;

  MyEventsResponse({required this.events, required this.stats});

  factory MyEventsResponse.fromJson(Map<String, dynamic> json) {
    final parsedEvents = <Event>[];

    for (final item in _asList(json['events'])) {
      final eventJson = _asMap(item);
      if (eventJson == null) continue;
      parsedEvents.add(Event.fromJson(eventJson));
    }

    return MyEventsResponse(
      events: parsedEvents,
      stats: MyEventStats.fromJson(_asMap(json['stats'])),
    );
  }
}

class MyEventStats {
  final int confirmed;
  final int inProgress;
  final int completed;

  const MyEventStats({
    required this.confirmed,
    required this.inProgress,
    required this.completed,
  });

  const MyEventStats.empty() : confirmed = 0, inProgress = 0, completed = 0;

  factory MyEventStats.fromJson(Map<String, dynamic>? json) {
    return MyEventStats(
      confirmed: _asInt(json?['confirmed']),
      inProgress: _asInt(json?['in_progress']),
      completed: _asInt(json?['completed']),
    );
  }

  MyEventStats applyStatusChange({
    required String oldStatus,
    required MyEventStatus newStatus,
  }) {
    var confirmedCount = confirmed;
    var inProgressCount = inProgress;
    var completedCount = completed;
    final previousStatus = MyEventStatus.fromString(oldStatus);

    if (previousStatus == newStatus) return this;

    void decrease(MyEventStatus status) {
      switch (status) {
        case MyEventStatus.confirmed:
          confirmedCount = _decrement(confirmedCount);
          break;
        case MyEventStatus.inProgress:
          inProgressCount = _decrement(inProgressCount);
          break;
        case MyEventStatus.completed:
          completedCount = _decrement(completedCount);
          break;
        case MyEventStatus.cancelled:
        case MyEventStatus.unknown:
          break;
      }
    }

    void increase(MyEventStatus status) {
      switch (status) {
        case MyEventStatus.confirmed:
          confirmedCount++;
          break;
        case MyEventStatus.inProgress:
          inProgressCount++;
          break;
        case MyEventStatus.completed:
          completedCount++;
          break;
        case MyEventStatus.cancelled:
        case MyEventStatus.unknown:
          break;
      }
    }

    decrease(previousStatus);
    increase(newStatus);

    return MyEventStats(
      confirmed: confirmedCount,
      inProgress: inProgressCount,
      completed: completedCount,
    );
  }

  MyEventStats copyWith({int? confirmed, int? inProgress, int? completed}) {
    return MyEventStats(
      confirmed: confirmed ?? this.confirmed,
      inProgress: inProgress ?? this.inProgress,
      completed: completed ?? this.completed,
    );
  }
}

extension MyEventStatusCopy on Event {
  Event copyWithStatus(MyEventStatus status) {
    return Event(
      id: id,
      title: title,
      date: date,
      location: location,
      guests: guests,
      budget: budget,
      progress: progress,
      status: status.apiValue,
      eventType: eventType,
      description: description,
      plannerId: plannerId,
      plannerName: plannerName,
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

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int _decrement(int value) {
  if (value <= 0) return 0;
  return value - 1;
}
