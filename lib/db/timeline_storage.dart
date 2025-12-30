import 'package:event_planner/db/database.dart';
import 'package:event_planner/models/timeline_task.dart';
import 'package:sqflite/sqflite.dart';

class TimelineStorage {
  /// Get all timeline tasks for a specific event
  static Future<List<TimelineTask>> getTasksByEvent(String eventId) async {
    final db = await EventDatabase().getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      'timeline_tasks',
      where: 'eventId = ?',
      whereArgs: [eventId],
      orderBy: 'daysBeforeEvent DESC', // Sort by furthest to nearest
    );

    return List.generate(maps.length, (i) {
      return TimelineTask.fromMap(maps[i]);
    });
  }

  /// Insert a new timeline task
  static Future<void> insertTask(TimelineTask task) async {
    final db = await EventDatabase().getDatabase();
    await db.insert(
      'timeline_tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing timeline task
  static Future<void> updateTask(TimelineTask task) async {
    final db = await EventDatabase().getDatabase();
    await db.update(
      'timeline_tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  /// Delete a timeline task
  static Future<void> deleteTask(String taskId) async {
    final db = await EventDatabase().getDatabase();
    await db.delete('timeline_tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  /// Toggle task completion status
  static Future<void> toggleTaskCompletion(String taskId) async {
    final db = await EventDatabase().getDatabase();

    // Get current task
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

  /// Ensure default tasks exist for an event
  static Future<void> ensureDefaultTasks(String eventId) async {
    final existingTasks = await getTasksByEvent(eventId);

    // If no tasks exist, create default tasks
    if (existingTasks.isEmpty) {
      final defaultTasks = TimelineTask.getDefaultTasks(eventId);
      for (final task in defaultTasks) {
        await insertTask(task);
      }
    }
  }

  /// Get completion percentage for an event's timeline
  static Future<double> getTimelineProgress(String eventId) async {
    final tasks = await getTasksByEvent(eventId);

    if (tasks.isEmpty) return 0.0;

    final completedTasks = tasks.where((task) => task.isCompleted).length;
    return completedTasks / tasks.length;
  }

  /// Delete all tasks for an event (called when event is deleted)
  static Future<void> deleteTasksByEvent(String eventId) async {
    final db = await EventDatabase().getDatabase();
    await db.delete(
      'timeline_tasks',
      where: 'eventId = ?',
      whereArgs: [eventId],
    );
  }

  /// Get count of completed and total tasks
  static Future<Map<String, int>> getTaskCounts(String eventId) async {
    final tasks = await getTasksByEvent(eventId);
    final completedCount = tasks.where((task) => task.isCompleted).length;

    return {
      'total': tasks.length,
      'completed': completedCount,
      'remaining': tasks.length - completedCount,
    };
  }

  /// Check if all tasks are completed
  static Future<bool> areAllTasksCompleted(String eventId) async {
    final tasks = await getTasksByEvent(eventId);
    if (tasks.isEmpty) return false;
    return tasks.every((task) => task.isCompleted);
  }

  /// Get tasks that are due soon (within specified days)
  static Future<List<TimelineTask>> getUpcomingTasks(
    String eventId,
    int withinDays,
  ) async {
    final tasks = await getTasksByEvent(eventId);
    return tasks
        .where(
          (task) => !task.isCompleted && task.daysBeforeEvent <= withinDays,
        )
        .toList();
  }
}
