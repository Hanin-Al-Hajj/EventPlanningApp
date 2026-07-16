import 'package:event_planner/models/task.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:flutter/foundation.dart';

class PlannerTaskCache {
  final List<Task> tasks;
  final int todoCount;
  final int inProgressCount;
  final int doneCount;
  final int eventGuests;
  final double eventBudget;
  final String eventDescription;
  final String? eventLocation;
  final List<Map<String, dynamic>> assistants;
  final List<Map<String, dynamic>> vendors;

  const PlannerTaskCache({
    required this.tasks,
    required this.todoCount,
    required this.inProgressCount,
    required this.doneCount,
    required this.eventGuests,
    required this.eventBudget,
    required this.eventDescription,
    required this.eventLocation,
    required this.assistants,
    required this.vendors,
  });

  const PlannerTaskCache.empty()
    : tasks = const [],
      todoCount = 0,
      inProgressCount = 0,
      doneCount = 0,
      eventGuests = 0,
      eventBudget = 0,
      eventDescription = '',
      eventLocation = null,
      assistants = const [],
      vendors = const [];

  PlannerTaskCache copyWith({
    List<Task>? tasks,
    int? todoCount,
    int? inProgressCount,
    int? doneCount,
    int? eventGuests,
    double? eventBudget,
    String? eventDescription,
    String? eventLocation,
    List<Map<String, dynamic>>? assistants,
    List<Map<String, dynamic>>? vendors,
  }) {
    return PlannerTaskCache(
      tasks: tasks ?? this.tasks,
      todoCount: todoCount ?? this.todoCount,
      inProgressCount: inProgressCount ?? this.inProgressCount,
      doneCount: doneCount ?? this.doneCount,
      eventGuests: eventGuests ?? this.eventGuests,
      eventBudget: eventBudget ?? this.eventBudget,
      eventDescription: eventDescription ?? this.eventDescription,
      eventLocation: eventLocation ?? this.eventLocation,
      assistants: assistants ?? this.assistants,
      vendors: vendors ?? this.vendors,
    );
  }
}

class PlannerTaskRepository {
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static final Map<int, PlannerTaskCache> _cacheByEvent = {};
  static final Map<int, Future<void>> _runningAllLoads = {};
  static final Map<int, Future<void>> _runningTaskLoads = {};
  static final Map<int, Future<void>> _runningFormDataLoads = {};
  static final Set<int> _formDataLoadedFor = {};

  static PlannerTaskCache cachedFor(int eventId) {
    return _cacheByEvent[eventId] ?? const PlannerTaskCache.empty();
  }

  static bool hasCache(int eventId) {
    return _cacheByEvent.containsKey(eventId);
  }

  static bool hasFormDataCache(int eventId) {
    return _formDataLoadedFor.contains(eventId);
  }

  static Future<void> loadAll({
    required int eventId,
    bool forceRefresh = false,
  }) async {
    if (hasCache(eventId) && hasFormDataCache(eventId) && !forceRefresh) {
      return;
    }

    final runningLoad = _runningAllLoads[eventId];
    if (runningLoad != null) return runningLoad;

    final load = _fetchAll(eventId);
    _runningAllLoads[eventId] = load;

    try {
      await load;
    } finally {
      _runningAllLoads.remove(eventId);
    }
  }

  static Future<void> loadTasks({
    required int eventId,
    bool forceRefresh = false,
  }) async {
    if (hasCache(eventId) && !forceRefresh) return;

    final runningLoad = _runningTaskLoads[eventId];
    if (runningLoad != null) return runningLoad;

    final load = _fetchTasksAndEvent(eventId);
    _runningTaskLoads[eventId] = load;

    try {
      await load;
    } finally {
      _runningTaskLoads.remove(eventId);
    }
  }

  static Future<void> loadFormData({
    required int eventId,
    bool forceRefresh = false,
  }) async {
    if (hasFormDataCache(eventId) && !forceRefresh) return;

    final runningLoad = _runningFormDataLoads[eventId];
    if (runningLoad != null) return runningLoad;

    final load = _fetchFormData(eventId);
    _runningFormDataLoads[eventId] = load;

    try {
      await load;
    } finally {
      _runningFormDataLoads.remove(eventId);
    }
  }

  static Future<void> refreshInBackground(int eventId) async {
    try {
      await loadTasks(eventId: eventId, forceRefresh: true);
    } catch (e) {
      debugPrint('Planner task background refresh error: $e');
    }
  }

  static Future<dynamic> updateTaskStatus(int taskId, String status) {
    return ApiService.updateTaskStatus(taskId, status);
  }

  static Future<dynamic> deleteTask(int taskId) {
    return ApiService.deleteTask(taskId);
  }

  static Future<dynamic> updateTask({
    required int taskId,
    required String title,
    String? description,
    required String priority,
    String? dueDate,
    required int progress,
    int? assistantId,
    List<int>? vendorIds,
  }) {
    return ApiService.updateTask(
      taskId: taskId,
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
      progress: progress,
      assistantId: assistantId,
      vendorIds: vendorIds,
    );
  }

  static Future<dynamic> createTask({
    required int eventId,
    required String title,
    String? description,
    required String priority,
    String? dueDate,
    required int progress,
    int? assistantId,
    List<int>? vendorIds,
  }) {
    return ApiService.createTask(
      eventId: eventId,
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
      progress: progress,
      assistantId: assistantId,
      vendorIds: vendorIds,
    );
  }

  static void removeTaskLocally({required int eventId, required int taskId}) {
    final cache = cachedFor(eventId);
    final nextTasks = cache.tasks.where((task) => task.id != taskId).toList();
    _cacheByEvent[eventId] = _withTaskStats(cache, nextTasks);
    changes.value++;
  }

  static void setCache({
    required int eventId,
    required PlannerTaskCache cache,
  }) {
    _cacheByEvent[eventId] = cache;
    changes.value++;
  }

  static void clearEvent(int eventId) {
    _cacheByEvent.remove(eventId);
    _runningAllLoads.remove(eventId);
    _runningTaskLoads.remove(eventId);
    _runningFormDataLoads.remove(eventId);
    _formDataLoadedFor.remove(eventId);
    changes.value++;
  }

  static void clear() {
    _cacheByEvent.clear();
    _runningAllLoads.clear();
    _runningTaskLoads.clear();
    _runningFormDataLoads.clear();
    _formDataLoadedFor.clear();
    changes.value++;
  }

  static Future<void> _fetchAll(int eventId) async {
    final results = await Future.wait([
      ApiService.getEventTasks(eventId),
      ApiService.getPlannerEvent(eventId),
      ApiService.getAssistants(),
      ApiService.getVendors(eventId.toString()),
    ], eagerError: false);

    final cache = _parseCacheFromResults(
      results: results,
      fallback: cachedFor(eventId),
      includeFormData: true,
    );

    _cacheByEvent[eventId] = cache;
    _formDataLoadedFor.add(eventId);
    changes.value++;
  }

  static Future<void> _fetchFormData(int eventId) async {
    final results = await Future.wait([
      ApiService.getAssistants(),
      ApiService.getVendors(eventId.toString()),
    ], eagerError: false);

    final current = cachedFor(eventId);
    var assistants = current.assistants;
    var vendors = current.vendors;

    final assistantsResult = results[0];
    if (assistantsResult is Map && assistantsResult['success'] == true) {
      assistants = _asList(assistantsResult['data'])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    final vendorsResult = results[1];
    if (vendorsResult is Map && vendorsResult['success'] == true) {
      vendors = _asList(vendorsResult['vendors'] ?? vendorsResult['data'])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    _cacheByEvent[eventId] = current.copyWith(
      assistants: assistants,
      vendors: vendors,
    );
    _formDataLoadedFor.add(eventId);
    changes.value++;
  }

  static Future<void> _fetchTasksAndEvent(int eventId) async {
    final taskResult = await ApiService.getEventTasks(eventId);
    final taskCache = _parseCacheFromResults(
      results: [taskResult],
      fallback: cachedFor(eventId),
      includeFormData: false,
    );

    _cacheByEvent[eventId] = taskCache;
    changes.value++;

    try {
      final eventResult = await ApiService.getPlannerEvent(eventId);
      final eventCache = _parseCacheFromResults(
        results: [null, eventResult],
        fallback: cachedFor(eventId),
        includeFormData: false,
      );

      _cacheByEvent[eventId] = eventCache;
      changes.value++;
    } catch (e) {
      debugPrint('Planner task event summary load error: $e');
    }
  }

  static PlannerTaskCache _parseCacheFromResults({
    required List<Object?> results,
    required PlannerTaskCache fallback,
    required bool includeFormData,
  }) {
    var tasks = fallback.tasks;
    var todoCount = fallback.todoCount;
    var inProgressCount = fallback.inProgressCount;
    var doneCount = fallback.doneCount;
    var eventGuests = fallback.eventGuests;
    var eventBudget = fallback.eventBudget;
    var eventDescription = fallback.eventDescription;
    var eventLocation = fallback.eventLocation;
    var assistants = fallback.assistants;
    var vendors = fallback.vendors;

    final taskResult = results.isNotEmpty ? results[0] : null;
    if (taskResult is Map && taskResult['success'] == true) {
      final data = _asMap(taskResult['data']) ?? const {};
      final tasksList = _asList(data['tasks']);
      final stats = _asMap(data['stats']) ?? const {};

      tasks = tasksList
          .whereType<Map>()
          .map((task) => Task.fromJson(Map<String, dynamic>.from(task)))
          .toList();

      todoCount = _asInt(stats['todo']);
      inProgressCount = _asInt(stats['in_progress']);
      doneCount = _asInt(stats['done']);
    }

    final eventResult = results.length > 1 ? results[1] : null;
    if (eventResult is Map && eventResult['success'] == true) {
      final event = _asMap(eventResult['data']) ?? const {};

      eventGuests = _asInt(event['guest_estimate']);
      eventBudget = _asDouble(event['budget'] ?? event['budget_overall']);
      eventDescription = event['description']?.toString() ?? '';
      eventLocation =
          event['location']?.toString() ?? event['location_text']?.toString();
    }

    if (includeFormData) {
      final assistantsResult = results.length > 2 ? results[2] : null;
      if (assistantsResult is Map && assistantsResult['success'] == true) {
        assistants = _asList(assistantsResult['data'])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      final vendorsResult = results.length > 3 ? results[3] : null;
      if (vendorsResult is Map && vendorsResult['success'] == true) {
        vendors = _asList(vendorsResult['vendors'] ?? vendorsResult['data'])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    return PlannerTaskCache(
      tasks: tasks,
      todoCount: todoCount,
      inProgressCount: inProgressCount,
      doneCount: doneCount,
      eventGuests: eventGuests,
      eventBudget: eventBudget,
      eventDescription: eventDescription,
      eventLocation: eventLocation,
      assistants: assistants,
      vendors: vendors,
    );
  }

  static PlannerTaskCache _withTaskStats(
    PlannerTaskCache cache,
    List<Task> tasks,
  ) {
    var todoCount = 0;
    var inProgressCount = 0;
    var doneCount = 0;

    for (final task in tasks) {
      switch (task.status) {
        case TaskStatus.done:
          doneCount++;
          break;
        case TaskStatus.inProgress:
          inProgressCount++;
          break;
        case TaskStatus.pending:
          todoCount++;
          break;
      }
    }

    return cache.copyWith(
      tasks: tasks,
      todoCount: todoCount,
      inProgressCount: inProgressCount,
      doneCount: doneCount,
    );
  }

  static List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return const [];
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
