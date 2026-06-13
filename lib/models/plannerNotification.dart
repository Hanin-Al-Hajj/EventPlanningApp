class plannerNotification {
  final int id;
  final int userId;
  final String type;
  final String priority;
  final String title;
  final String message;
  final String? icon;
  final String? actionUrl;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  plannerNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    this.icon,
    this.actionUrl,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory plannerNotification.fromJason(Map<String, dynamic> json) {
    return plannerNotification(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      priority: json['priority'],
      title: json['title'],
      message: json['message'],
      icon: json['icon'],
      actionUrl: json['action_url'],
      isRead: json['is_read'],
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
