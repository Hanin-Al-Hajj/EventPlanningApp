import 'package:event_planner/db/database.dart';
import 'package:event_planner/models/event.dart';

// Insert a new event into the database
void insertEvent(Event event) async {
  EventDatabase database = EventDatabase();
  final db = await database.getDatabase();
  db.insert('events', event.eventMap);
}

// Load all events from the database
Future<List<Event>> loadEvents() async {
  EventDatabase database = EventDatabase();
  final db = await database.getDatabase();
  final result = await db.query('events');

  List<Event> resultList = result.map((row) {
    return Event(
      id: row['id'] as String,
      title: row['title'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
      location: row['location'] as String,
      guests: row['guests'] as int,
      budget: row['budget'] as double,
      progress: row['progress'] as double,
      status: row['status'] as String, // Direct string, no enum conversion
    );
  }).toList();

  return resultList;
}

// Delete an event from the database
void deleteEvent(Event event) async {
  EventDatabase database = EventDatabase();
  final db = await database.getDatabase();
  db.delete('events', where: 'id = ?', whereArgs: [event.id]);
}

// Update an existing event in the database
void updateEvent(Event event) async {
  EventDatabase database = EventDatabase();
  final db = await database.getDatabase();
  db.update('events', event.eventMap, where: 'id = ?', whereArgs: [event.id]);
}

// Get upcoming events (sorted by date)
Future<List<Event>> loadUpcomingEvents() async {
  EventDatabase database = EventDatabase();
  final db = await database.getDatabase();
  final result = await db.query('events', orderBy: 'date ASC');

  List<Event> resultList = result.map((row) {
    return Event(
      id: row['id'] as String,
      title: row['title'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
      location: row['location'] as String,
      guests: row['guests'] as int,
      budget: row['budget'] as double,
      progress: row['progress'] as double,
      status: row['status'] as String, // Direct string, no enum conversion
    );
  }).toList();

  return resultList;
}

// Get count of active events (planning or inProgress)
Future<int> getActiveEventsCount() async {
  EventDatabase database = EventDatabase();
  final db = await database.getDatabase();
  final result = await db.query(
    'events',
    where: 'status = ? OR status = ?',
    whereArgs: ['Planning', 'In Progress'], // Match the strings you're using
  );
  return result.length;
}

// Get days until the nearest upcoming event
Future<int> getDaysUntilNextEvent() async {
  EventDatabase database = EventDatabase();
  final db = await database.getDatabase();
  final now = DateTime.now();

  final result = await db.query(
    'events',
    where: 'date >= ?',
    whereArgs: [now.millisecondsSinceEpoch],
    orderBy: 'date ASC',
    limit: 1,
  );

  if (result.isEmpty) return 0;

  final nextEventDate = DateTime.fromMillisecondsSinceEpoch(
    result.first['date'] as int,
  );
  return nextEventDate.difference(now).inDays;
}
