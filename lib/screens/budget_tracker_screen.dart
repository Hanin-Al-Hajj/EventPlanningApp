import 'package:flutter/material.dart';
import 'package:event_planner/models/event.dart';
import 'package:event_planner/db/budget_storage.dart';
import 'package:event_planner/db/event_storage.dart';
import 'package:event_planner/widgets/add_expense_dialog.dart';
import 'package:event_planner/models/budget.dart';

class BudgetTrackerScreen extends StatefulWidget {
  final Event event;
  const BudgetTrackerScreen({super.key, required this.event});

  @override
  State<BudgetTrackerScreen> createState() => _BudgetTrackerScreenState();
}

class _BudgetTrackerScreenState extends State<BudgetTrackerScreen> {
  List<BudgetExpense> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final expenses = await BudgetStorage.getExpensesByEvent(widget.event.id);
      setState(() {
        _expenses = expenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading expenses: $e')));
      }
    }
  }

  double get totalSpent {
    return _expenses.fold(0.0, (sum, expense) => sum + expense.amountSpent);
  }

  double get remainingBudget {
    return widget.event.budget - totalSpent;
  }

  double get budgetProgress {
    if (widget.event.budget == 0) return 0.0;
    return (totalSpent / widget.event.budget).clamp(0.0, 1.0);
  }

  // Calculate completed expenses (where amountSpent >= allocatedAmount)
  int get completedExpenses {
    return _expenses
        .where((expense) => expense.amountSpent >= expense.allocatedAmount)
        .length;
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'venue':
        return Icons.business;
      case 'catering':
        return Icons.restaurant;
      case 'photography':
        return Icons.camera_alt;
      case 'decoration':
        return Icons.celebration;
      case 'entertainment':
        return Icons.music_note;
      default:
        return Icons.attach_money;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'venue':
        return const Color(0xFF8B7355);
      case 'catering':
        return const Color(0xFFB4869F);
      case 'photography':
        return const Color(0xFF6B7A8F);
      case 'decoration':
        return const Color(0xFFE8A598);
      case 'entertainment':
        return const Color(0xFF9B8B7E);
      default:
        return const Color(0xFF545A3B);
    }
  }

  // ✅ UPDATED: Now updates event progress after adding expense
  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => AddExpenseDialog(
        eventId: widget.event.id,
        totalBudget: widget.event.budget,
        currentSpent: totalSpent,
        onExpenseAdded: () async {
          await _loadExpenses();
          // ✅ UPDATE EVENT PROGRESS AFTER ADDING EXPENSE
          await updateEventProgress(widget.event.id);
        },
      ),
    );
  }

  // ✅ UPDATED: Now updates event progress after editing expense
  void _showEditExpenseDialog(BudgetExpense expense) {
    final spentController = TextEditingController(
      text: expense.amountSpent.toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${expense.category}'),
        content: TextField(
          controller: spentController,
          decoration: const InputDecoration(
            labelText: 'Amount Spent',
            border: OutlineInputBorder(),
            prefixText: '\$',
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final spent = double.tryParse(spentController.text.trim()) ?? 0.0;
              final updatedExpense = BudgetExpense(
                id: expense.id,
                eventId: expense.eventId,
                category: expense.category,
                allocatedAmount: expense.allocatedAmount,
                amountSpent: spent,
              );
              await BudgetStorage.updateExpense(updatedExpense);
              Navigator.pop(context);
              await _loadExpenses();
              // ✅ UPDATE EVENT PROGRESS AFTER EDITING EXPENSE
              await updateEventProgress(widget.event.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF545A3B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ✅ UPDATED: Now updates event progress after deleting expense
  Future<void> _deleteExpense(BudgetExpense expense) async {
    await BudgetStorage.deleteExpense(expense.id);
    await _loadExpenses();
    // ✅ UPDATE EVENT PROGRESS AFTER DELETING EXPENSE
    await updateEventProgress(widget.event.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${expense.category} expense deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              await BudgetStorage.insertExpense(expense);
              await _loadExpenses();
              // ✅ UPDATE EVENT PROGRESS AFTER UNDOING DELETE
              await updateEventProgress(widget.event.id);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF586041),
        foregroundColor: Colors.white,
        title: const Text('Budget Tracker'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Budget Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Total Budget',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${widget.event.budget.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF151910),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: budgetProgress,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                budgetProgress > 0.9
                                    ? Colors.red
                                    : budgetProgress > 0.7
                                    ? Colors.orange
                                    : const Color(0xFF545A3B),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Spent: \$${totalSpent.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$completedExpenses/${_expenses.length} Categories Completed',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Remaining: \$${remainingBudget.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: remainingBudget < 0
                                      ? Colors.red
                                      : Colors.grey,
                                  fontWeight: remainingBudget < 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Expenses by Category
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Expenses by Category',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF151910),
                          ),
                        ),
                        if (_expenses.isNotEmpty)
                          Text(
                            'Swipe to delete',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Expense List with Dismissible
                    if (_expenses.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.attach_money,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No expenses yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._expenses.map((expense) {
                        final progress = expense.allocatedAmount > 0
                            ? (expense.amountSpent / expense.allocatedAmount)
                                  .clamp(0.0, 1.0)
                            : 0.0;

                        return Dismissible(
                          key: Key(expense.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Expense'),
                                content: Text(
                                  'Are you sure you want to delete ${expense.category}?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (direction) => _deleteExpense(expense),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => _showEditExpenseDialog(expense),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: _getCategoryColor(
                                              expense.category,
                                            ).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            _getCategoryIcon(expense.category),
                                            color: _getCategoryColor(
                                              expense.category,
                                            ),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            expense.category,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '\$${expense.amountSpent.toStringAsFixed(0)} / \$${expense.allocatedAmount.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 6,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              _getCategoryColor(
                                                expense.category,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        backgroundColor: const Color(0xFF545A3B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }
}
