class Event {
  final String id;
  final String title;
  final DateTime date;
  final String location;
  final int guests;
  final double budget;
  final double progress;
  final String status;
  final String? eventType;
  final String? description;
  final int? plannerId;
  final String? plannerName;
  final String? clientName;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.guests,
    required this.budget,
    required this.progress,
    required this.status,
    this.eventType,
    this.description,
    this.plannerId,
    this.plannerName,
    this.clientName,
  });

  Map<String, dynamic> get eventMap {
    return {
      'id': id,
      'title': title,
      'date': date.millisecondsSinceEpoch,
      'location': location,
      'guests': guests,
      'budget': budget,
      'progress': progress,
      'status': status,
      'eventType': eventType,
      'description': description,
      'plannerId': plannerId,
      'plannerName': plannerName,
      'clientName': clientName,
    };
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    final planner = json['planner'];
    final client = json['client'];
    final user = json['user'];
    final plannerIdValue =
        json['planner_id'] ?? (planner is Map ? planner['id'] : null);

    return Event(
      id: json['id']?.toString() ?? '',
      title: json['name'] ?? json['title'] ?? '',
      date:
          DateTime.tryParse(
            json['start_date'] ?? json['date']?.toString() ?? '',
          ) ??
          DateTime.now(),
      location: json['location'] ?? json['location_text'] ?? 'TBD',
      guests:
          int.tryParse(
            (json['guest_estimate'] ?? json['guests'] ?? 0).toString(),
          ) ??
          0,
      budget:
          double.tryParse(
            (json['budget'] ?? json['budget_overall'] ?? 0).toString(),
          ) ??
          0.0,
      progress: double.tryParse((json['progress'] ?? 0).toString()) ?? 0.0,
      status: json['status'] ?? 'confirmed',
      eventType: json['event_type'] is Map
          ? json['event_type']['name']
          : json['event_type']?.toString(),
      description: json['description'],
      plannerId: int.tryParse(plannerIdValue?.toString() ?? ''),
      plannerName:
          json['planner_name']?.toString() ??
          json['plannerName']?.toString() ??
          (planner is Map ? planner['name']?.toString() : null),
      clientName:
          json['client_name']?.toString() ??
          json['clientName']?.toString() ??
          (client is Map ? client['name']?.toString() : null) ??
          (user is Map ? user['name']?.toString() : null),
    );
  }
}
