import 'package:event_planner/db/database.dart';

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

class BudgetStorage {
  // Insert a new expense
  static Future<void> insertExpense(BudgetExpense expense) async {
    EventDatabase database = EventDatabase();
    final db = await database.getDatabase();
    await db.insert('budget_expenses', expense.toMap());
  }

  // Get all expenses for a specific event
  static Future<List<BudgetExpense>> getExpensesByEvent(String eventId) async {
    EventDatabase database = EventDatabase();
    final db = await database.getDatabase();
    final result = await db.query(
      'budget_expenses',
      where: 'eventId = ?',
      whereArgs: [eventId],
    );

    return result.map((map) => BudgetExpense.fromMap(map)).toList();
  }

  // Update an expense
  static Future<void> updateExpense(BudgetExpense expense) async {
    EventDatabase database = EventDatabase();
    final db = await database.getDatabase();
    await db.update(
      'budget_expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  // Delete an expense
  static Future<void> deleteExpense(String expenseId) async {
    EventDatabase database = EventDatabase();
    final db = await database.getDatabase();
    await db.delete('budget_expenses', where: 'id = ?', whereArgs: [expenseId]);
  }

  // Delete all expenses for an event
  static Future<void> deleteExpensesByEvent(String eventId) async {
    EventDatabase database = EventDatabase();
    final db = await database.getDatabase();
    await db.delete(
      'budget_expenses',
      where: 'eventId = ?',
      whereArgs: [eventId],
    );
  }

  // Get total spent for an event
  static Future<double> getTotalSpentByEvent(String eventId) async {
    final expenses = await getExpensesByEvent(eventId);
    return expenses.fold<double>(
      0.0,
      (sum, expense) => sum + expense.amountSpent,
    );
  }
}
