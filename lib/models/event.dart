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
    };
  }
}
