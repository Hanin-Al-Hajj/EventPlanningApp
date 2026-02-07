import 'package:event_planner/db/database.dart';
import 'package:event_planner/models/event.dart';
import 'package:event_planner/db/guest_storage.dart';
import 'package:event_planner/db/budget_storage.dart';

Future<void> insertEvent(Event event) async {
  EventDatabase database = EventDatabase();
  final db = await database.getDatabase();
  await db.insert('events', event.eventMap);
}

Future<List<Event>> loadEvents() async {
  EventDatabase database = EventDatabase();
  final db = await database.getDatabase();
  final result = await db.query('events', orderBy: 'date DESC');

  List<Event> resultList = result.map((row) {
    return Event(
      id: row['id'] as String,
      title: row['title'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
      location: row['location'] as String,
      guests: row['guests'] as int,
      budget: row['budget'] as double,
      progress: (row['progress'] as num?)?.toDouble() ?? 0.0,
      status: (row['status'] as String?) ?? 'Planning',
      eventType: row['eventType'] as String?,
    );
  }).toList();

  return resultList;
}

Future<void> deleteEvent(Event event) async {
  EventDatabase database = EventDatabase();
  final db = await database.getDatabase();
  await db.delete('events', where: 'id = ?', whereArgs: [event.id]);
}

Future<void> updateEvent(Event event) async {
  EventDatabase database = EventDatabase();
  final db = await database.getDatabase();
  await db.update(
    'events',
    event.eventMap,
    where: 'id = ?',
    whereArgs: [event.id],
  );
}

Future<Map<String, int>> getBudgetStatsByEvent(String eventId) async {
  try {
    final expenses = await BudgetStorage.getExpensesByEvent(eventId);

    final total = expenses.length;
    final completed = expenses
        .where((expense) => expense.amountSpent >= expense.allocatedAmount)
        .length;

    return {'total': total, 'completed': completed};
  } catch (e) {
    return {'total': 0, 'completed': 0};
  }
}

Future<double> calculateEventProgress(String eventId) async {
  try {
    double totalProgress = 0.0;

    EventDatabase database = EventDatabase();
    final db = await database.getDatabase();
    final eventResult = await db.query(
      'events',
      where: 'id = ?',
      whereArgs: [eventId],
    );

    double currentProgress = 0.0;
    if (eventResult.isNotEmpty) {
      currentProgress =
          (eventResult.first['progress'] as num?)?.toDouble() ?? 0.0;
    }

    final guestStats = await GuestStorage.getGuestStatsByEvent(eventId);
    final totalGuests = guestStats['total'] ?? 0;
    if (totalGuests > 0) {
      totalProgress += 0.25;
    }

    final budgetStats = await getBudgetStatsByEvent(eventId);
    final totalExpenses = budgetStats['total'] ?? 0;
    if (totalExpenses > 0) {
      totalProgress += 0.25;
    }

    return totalProgress.clamp(0.0, 1.0);
  } catch (e) {
    return 0.0;
  }
}

String determineEventStatus(double progress, DateTime eventDate) {
  final now = DateTime.now();
  final daysUntilEvent = eventDate.difference(now).inDays;

  if (daysUntilEvent < 0) {
    return 'Completed';
  }

  if (progress >= 0.80) {
    return 'In Progress';
  }

  if (progress >= 0.10) {
    return 'In Progress';
  }

  return 'Planning';
}

Future<void> updateEventProgress(String eventId) async {
  try {
    EventDatabase database = EventDatabase();
    final db = await database.getDatabase();

    final eventResult = await db.query(
      'events',
      where: 'id = ?',
      whereArgs: [eventId],
    );

    if (eventResult.isEmpty) return;

    final eventDate = DateTime.fromMillisecondsSinceEpoch(
      eventResult.first['date'] as int,
    );

    final newProgress = await calculateEventProgress(eventId);
    final newStatus = determineEventStatus(newProgress, eventDate);

    await db.update(
      'events',
      {'progress': newProgress, 'status': newStatus},
      where: 'id = ?',
      whereArgs: [eventId],
    );
  } catch (e) {
    // Silent error
  }
}

Future<List<Event>> loadUpcomingEvents() async {
  EventDatabase database = EventDatabase();
  final db = await database.getDatabase();
  final now = DateTime.now();

  final result = await db.query(
    'events',
    where: 'date >= ?',
    whereArgs: [now.millisecondsSinceEpoch],
    orderBy: 'date ASC',
  );

  List<Event> resultList = result.map((row) {
    return Event(
      id: row['id'] as String,
      title: row['title'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
      location: row['location'] as String,
      guests: row['guests'] as int,
      budget: row['budget'] as double,
      progress: (row['progress'] as num?)?.toDouble() ?? 0.0,
      status: (row['status'] as String?) ?? 'Planning',
      eventType: row['eventType'] as String?,
    );
  }).toList();

  return resultList;
}

Future<int> getActiveEventsCount() async {
  EventDatabase database = EventDatabase();
  final db = await database.getDatabase();
  final result = await db.query(
    'events',
    where: 'status = ? OR status = ?',
    whereArgs: ['Planning', 'In Progress'],
  );
  return result.length;
}

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
