class Order {
  final int id;
  final int taskId;
  final int vendorId;
  final double price;
  final String? notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.taskId,
    required this.vendorId,
    required this.price,
    this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      taskId: json['task_id'] is int
          ? json['task_id']
          : int.tryParse('${json['task_id']}') ?? 0,
      vendorId: json['vendor_id'] is int
          ? json['vendor_id']
          : int.tryParse('${json['vendor_id']}') ?? 0,
      price: (json['price'] is double
          ? json['price']
          : double.tryParse('${json['price']}') ?? 0.0),
      notes: json['notes']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse((json['updated_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'vendor_id': vendorId,
      'price': price,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Order copyWith({
    int? id,
    int? taskId,
    int? vendorId,
    double? price,
    String? notes,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      vendorId: vendorId ?? this.vendorId,
      price: price ?? this.price,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
