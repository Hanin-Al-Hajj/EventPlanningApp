class VendorOrder {
  final int id;
  final int taskId;
  final int vendorId;
  final int assistantId;
  final double price;
  final String? notes;
  final DateTime createdAt;

  final Map<String, dynamic>? task;
  final Map<String, dynamic>? vendor;

  VendorOrder({
    required this.id,
    required this.taskId,
    required this.vendorId,
    required this.assistantId,
    required this.price,
    this.notes,
    required this.createdAt,
    this.task,
    this.vendor,
  });

  factory VendorOrder.fromJson(Map<String, dynamic> json) {
    return VendorOrder(
      id: json['id'] ?? 0,
      taskId: json['task_id'] ?? 0,
      vendorId: json['vendor_id'] ?? 0,
      assistantId: json['assistant_id'] ?? 0,

      // Laravel decimal columns come back as strings — handle both
      price: _parseDouble(json['price']),

      notes: json['notes'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),

      task: json['task'] != null
          ? Map<String, dynamic>.from(json['task'] as Map)
          : null,
      vendor: json['vendor'] != null
          ? Map<String, dynamic>.from(json['vendor'] as Map)
          : null,
    );
  }

  // Safely parse price whether it arrives as String, int, or double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String get taskTitle => task?['title'] as String? ?? '';
  String get vendorName => vendor?['name'] as String? ?? '';

  String get eventName {
    final event = task?['event'];
    if (event == null) return '';
    return (event as Map<String, dynamic>)['name'] as String? ?? '';
  }
}
