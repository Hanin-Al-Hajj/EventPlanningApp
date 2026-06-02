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
  final int? plannerId; // ADD
  final String? plannerName; // ADD

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
    this.plannerId, // ADD
    this.plannerName, // ADD
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
    };
  }
}
