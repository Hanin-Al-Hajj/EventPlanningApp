enum TaskStatus {
  pending,
  inProgress,
  done;

  static TaskStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      case 'pending':
      default:
        return TaskStatus.pending;
    }
  }

  String get apiValue {
    switch (this) {
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.done:
        return 'done';
      case TaskStatus.pending:
        return 'pending';
    }
  }
}

enum TaskPriority {
  low,
  medium,
  high,
  urgent;

  static TaskPriority fromString(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return TaskPriority.urgent;
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      case 'medium':
      default:
        return TaskPriority.medium;
    }
  }
}

class Task {
  final int id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final int progress;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  final Map<String, dynamic>? event;
  final Map<String, dynamic>? planner;
  final List<Map<String, dynamic>>? vendors;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    required this.progress,
    this.dueDate,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.event,
    this.planner,
    this.vendors,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      status: TaskStatus.fromString(json['status'] ?? 'pending'),
      priority: TaskPriority.fromString(json['priority'] ?? 'medium'),
      progress: json['progress'] ?? 0,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'])
          : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      event: json['event'] != null
          ? Map<String, dynamic>.from(json['event'] as Map)
          : null,
      // After parsing vendors:
      planner:
          json['assistants'] != null && (json['assistants'] as List).isNotEmpty
          ? Map<String, dynamic>.from((json['assistants'] as List).first as Map)
          : (json['assignments'] != null &&
                    (json['assignments'] as List).isNotEmpty
                ? Map<String, dynamic>.from(
                    ((json['assignments'] as List).first as Map)['planner']
                            as Map? ??
                        {},
                  )
                : null),
      vendors: json['vendors'] != null
          ? (json['vendors'] as List)
                .map((v) => Map<String, dynamic>.from(v as Map))
                .toList()
          : null,
    );
  }

  // Get planner name
  String get plannerName {
    if (planner != null && planner!['name'] != null) {
      return planner!['name'];
    }
    return '';
  }

  // Get event name
  String get eventName => event?['name'] ?? '';

  // Get vendor names
  String get vendorNames => vendors?.map((v) => v['name']).join(', ') ?? '';

  // Check if overdue
  bool get isOverdue {
    if (dueDate == null || status == TaskStatus.done) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    int? progress,
    DateTime? dueDate,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      progress: progress ?? this.progress,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
