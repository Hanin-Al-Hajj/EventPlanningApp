import 'package:event_planner/db/database.dart';
import 'package:event_planner/models/budget.dart';

class BudgetStorage {
  static Future<void> insertExpense(BudgetExpense expense) async {
    EventDatabase database = EventDatabase();
    final db = await database.getDatabase();
    await db.insert('budget_expenses', expense.toMap());
  }

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

  static Future<void> deleteExpense(String expenseId) async {
    EventDatabase database = EventDatabase();
    final db = await database.getDatabase();
    await db.delete('budget_expenses', where: 'id = ?', whereArgs: [expenseId]);
  }

  static Future<void> deleteExpensesByEvent(String eventId) async {
    EventDatabase database = EventDatabase();
    final db = await database.getDatabase();
    await db.delete(
      'budget_expenses',
      where: 'eventId = ?',
      whereArgs: [eventId],
    );
  }

  static Future<double> getTotalSpentByEvent(String eventId) async {
    final expenses = await getExpensesByEvent(eventId);
    return expenses.fold<double>(
      0.0,
      (sum, expense) => sum + expense.amountSpent,
    );
  }
}
