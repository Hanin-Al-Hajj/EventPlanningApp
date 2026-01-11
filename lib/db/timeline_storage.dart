import 'package:event_planner/db/database.dart';
import 'package:event_planner/models/timeline_task.dart';
import 'package:sqflite/sqflite.dart';

class TimelineStorage {
  //get timeline for specific event
  static Future<List<TimelineTask>> getTasksByEvent(String eventId) async {
    final db = await EventDatabase().getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      'timeline_tasks',
      where: 'eventId = ?',
      whereArgs: [eventId],
      orderBy: 'daysBeforeEvent DESC',
    );

    return List.generate(maps.length, (i) {
      return TimelineTask.fromMap(maps[i]);
    });
  }

  //insert new timeline task
  static Future<void> insertTask(TimelineTask task) async {
    final db = await EventDatabase().getDatabase();
    await db.insert(
      'timeline_tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  //update the timeline task
  static Future<void> updateTask(TimelineTask task) async {
    final db = await EventDatabase().getDatabase();
    await db.update(
      'timeline_tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  //delet the timeline task
  static Future<void> deleteTask(String taskId) async {
    final db = await EventDatabase().getDatabase();
    await db.delete('timeline_tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  static Future<void> toggleTaskCompletion(String taskId) async {
    final db = await EventDatabase().getDatabase();

    final List<Map<String, dynamic>> maps = await db.query(
      'timeline_tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );

    if (maps.isNotEmpty) {
      final task = TimelineTask.fromMap(maps[0]);
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      await updateTask(updatedTask);
    }
  }

  //ensure that everyevent has default tasks
  static Future<void> ensureDefaultTasks(String eventId) async {
    final existingTasks = await getTasksByEvent(eventId);

    if (existingTasks.isEmpty) {
      final defaultTasks = TimelineTask.getDefaultTasks(eventId);
      for (final task in defaultTasks) {
        await insertTask(task);
      }
    }
  }
}
