class BudgetExpense {
  final String id;
  final String eventId;
  final String category;
  final double allocatedAmount;
  final double amountSpent;

  BudgetExpense({
    required this.id,
    required this.eventId,
    required this.category,
    required this.allocatedAmount,
    required this.amountSpent,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'category': category,
      'allocatedAmount': allocatedAmount,
      'amountSpent': amountSpent,
    };
  }

  factory BudgetExpense.fromMap(Map<String, dynamic> map) {
    return BudgetExpense(
      id: map['id'] as String,
      eventId: map['eventId'] as String,
      category: map['category'] as String,
      allocatedAmount: map['allocatedAmount'] as double,
      amountSpent: map['amountSpent'] as double,
    );
  }
}
