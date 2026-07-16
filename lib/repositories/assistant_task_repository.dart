import 'package:event_planner/models/task.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:flutter/foundation.dart';

class AssistantTaskRepository {
  static final ValueNotifier<List<Task>> tasks = ValueNotifier<List<Task>>([]);

  static bool _loadedOnce = false;
  static Future<void>? _runningLoad;

  static List<Task> get cachedTasks => tasks.value;

  static bool get hasCache => _loadedOnce;

  static Future<void> loadTasks({bool forceRefresh = false}) async {
    if (_loadedOnce && !forceRefresh) return;

    final runningLoad = _runningLoad;
    if (runningLoad != null) return runningLoad;

    _runningLoad = _fetchTasks();

    try {
      await _runningLoad;
    } finally {
      _runningLoad = null;
    }
  }

  static Future<void> refreshInBackground() async {
    try {
      await loadTasks(forceRefresh: true);
    } catch (e) {
      debugPrint('Assistant tasks background refresh error: $e');
    }
  }

  static Future<dynamic> completeTask(int taskId) {
    return ApiService.completeAssistantTask(taskId);
  }

  static void setTasks(List<Task> items) {
    tasks.value = List<Task>.from(items);
    _loadedOnce = true;
  }

  static void remove(Task task) {
    tasks.value = tasks.value.where((item) => item.id != task.id).toList();
    _loadedOnce = true;
  }

  static void restore(Task task) {
    final nextTasks = List<Task>.from(tasks.value);

    if (nextTasks.any((item) => item.id == task.id)) return;

    nextTasks.insert(0, task);
    tasks.value = nextTasks;
    _loadedOnce = true;
  }

  static void markCompleted(Task task) {
    tasks.value = tasks.value.map((item) {
      return item.id == task.id ? _asCompleted(item) : item;
    }).toList();
    _loadedOnce = true;
  }

  static void updateTask(Task updatedTask) {
    tasks.value = tasks.value.map((item) {
      return item.id == updatedTask.id ? updatedTask : item;
    }).toList();
    _loadedOnce = true;
  }

  static void clearTasks() {
    tasks.value = [];
    _loadedOnce = true;
  }

  static void clear() {
    tasks.value = [];
    _loadedOnce = false;
    _runningLoad = null;
  }

  static Future<void> _fetchTasks() async {
    final response = await ApiService.getAssistantTasks();
    if (response['success'] == false) {
      throw Exception(response['message'] ?? 'Failed to load tasks');
    }

    final raw = _taskListFrom(response);
    final parsed = <Task>[];

    for (final item in raw) {
      try {
        parsed.add(Task.fromJson(Map<String, dynamic>.from(item as Map)));
      } catch (_) {}
    }

    tasks.value = parsed;
    _loadedOnce = true;
  }

  static List<dynamic> _taskListFrom(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map && data['tasks'] is List) {
      return data['tasks'] as List;
    }

    final tasks = response['tasks'];
    if (tasks is List) return tasks;

    return const [];
  }

  static Task _asCompleted(Task task) {
    return Task(
      id: task.id,
      title: task.title,
      description: task.description,
      status: TaskStatus.done,
      priority: task.priority,
      progress: 100,
      dueDate: task.dueDate,
      completedAt: DateTime.now(),
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
      event: task.event,
      planner: task.planner,
      vendors: task.vendors,
    );
  }
}
