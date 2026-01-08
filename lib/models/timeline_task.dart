class TimelineTask {
  final String id;
  final String eventId;
  final String title;
  final String timeframe; 
  final int daysBeforeEvent; 
  final bool isCompleted;

  TimelineTask({
    required this.id,
    required this.eventId,
    required this.title,
    required this.timeframe,
    required this.daysBeforeEvent,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'title': title,
      'timeframe': timeframe,
      'daysBeforeEvent': daysBeforeEvent,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory TimelineTask.fromMap(Map<String, dynamic> map) {
    return TimelineTask(
      id: map['id'] as String,
      eventId: map['eventId'] as String,
      title: map['title'] as String,
      timeframe: map['timeframe'] as String,
      daysBeforeEvent: map['daysBeforeEvent'] as int,
      isCompleted: (map['isCompleted'] as int) == 1,
    );
  }

  TimelineTask copyWith({
    String? id,
    String? eventId,
    String? title,
    String? timeframe,
    int? daysBeforeEvent,
    bool? isCompleted,
  }) {
    return TimelineTask(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      timeframe: timeframe ?? this.timeframe,
      daysBeforeEvent: daysBeforeEvent ?? this.daysBeforeEvent,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  
  static List<TimelineTask> getDefaultTasks(String eventId) {
    return [
      TimelineTask(
        id: '${eventId}_task_1',
        eventId: eventId,
        title: 'Book venue',
        timeframe: '3 months before',
        daysBeforeEvent: 90,
      ),
      TimelineTask(
        id: '${eventId}_task_2',
        eventId: eventId,
        title: 'Send invitations',
        timeframe: '2 months before',
        daysBeforeEvent: 60,
      ),
      TimelineTask(
        id: '${eventId}_task_3',
        eventId: eventId,
        title: 'Finalize menu with caterer',
        timeframe: '1 month before',
        daysBeforeEvent: 30,
      ),
      TimelineTask(
        id: '${eventId}_task_4',
        eventId: eventId,
        title: 'Confirm vendor bookings',
        timeframe: '2 weeks before',
        daysBeforeEvent: 14,
      ),
      TimelineTask(
        id: '${eventId}_task_5',
        eventId: eventId,
        title: 'Final guest count',
        timeframe: '1 week before',
        daysBeforeEvent: 7,
      ),
    ];
  }
}
