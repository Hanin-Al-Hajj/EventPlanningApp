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

  factory plannerNotification.fromJson(Map<String, dynamic> json) {
    return plannerNotification(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse('${json['user_id']}') ?? 0,
      type: json['type']?.toString() ?? 'general',
      priority: json['priority']?.toString() ?? 'normal',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      icon: json['icon']?.toString(),
      actionUrl: json['action_url']?.toString(),
      isRead: json['is_read'] == true || json['is_read'] == 1,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'].toString())
          : null,
      createdAt:
          DateTime.tryParse(
            (json['timestamp'] ?? json['created_at'] ?? '').toString(),
          ) ??
          DateTime.now(),
    );
  }

  String timeAgo() {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
