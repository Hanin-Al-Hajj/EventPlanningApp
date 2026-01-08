import 'package:flutter/material.dart';
import 'package:event_planner/db/budget_storage.dart';
import 'package:event_planner/models/budget.dart';

class AddExpenseDialog extends StatefulWidget {
  final String eventId;
  final double totalBudget;
  final double currentSpent;
  final VoidCallback onExpenseAdded;

  const AddExpenseDialog({
    super.key,
    required this.eventId,
    required this.totalBudget,
    required this.currentSpent,
    required this.onExpenseAdded,
  });

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _allocatedController = TextEditingController();
  final _spentController = TextEditingController();
  final _customCategoryController = TextEditingController();
  String _selectedCategory = 'Venue';
  bool _isLoading = false;

  double get remainingBudget => widget.totalBudget - widget.currentSpent;

  // Calculate remaining after this expense
  double get remainingAfterExpense {
    final allocated = double.tryParse(_allocatedController.text.trim()) ?? 0.0;
    return remainingBudget - allocated;
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

  Future<void> _addExpense() async {
    final category = _selectedCategory == 'Other'
        ? _customCategoryController.text.trim()
        : _selectedCategory;
    final allocated = double.tryParse(_allocatedController.text.trim()) ?? 0.0;
    final spent = double.tryParse(_spentController.text.trim()) ?? 0.0;

    if (category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a category name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (allocated <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid allocated budget'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (spent < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amount spent cannot be negative'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final expense = BudgetExpense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        eventId: widget.eventId,
        category: category,
        allocatedAmount: allocated,
        amountSpent: spent,
      );

      await BudgetStorage.insertExpense(expense);
      widget.onExpenseAdded();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _allocatedController.dispose();
    _spentController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5DC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            const Text(
              'Add Expense',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF151910),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Category Dropdown
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items:
                      [
                        'Venue',
                        'Catering',
                        'Photography',
                        'Decoration',
                        'Entertainment',
                        'Other',
                      ].map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Row(
                            children: [
                              Icon(
                                _getCategoryIcon(category),
                                size: 20,
                                color: const Color(0xFF545A3B),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                category,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
              ),
            ),

            // Custom category input (if Other is selected)
            if (_selectedCategory == 'Other') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _customCategoryController,
                decoration: InputDecoration(
                  hintText: 'Enter category name',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF545A3B),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Allocated Budget
            const Text(
              'Allocated Budget',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _allocatedController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '\$0',
                prefixText: '\$ ',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF545A3B),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                setState(() {}); // Rebuild to update remaining budget display
              },
            ),

            // Show remaining budget info
            if (_allocatedController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: remainingAfterExpense < 0
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: remainingAfterExpense < 0
                        ? Colors.red.shade200
                        : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      remainingAfterExpense < 0
                          ? Icons.warning_rounded
                          : Icons.check_circle_rounded,
                      size: 20,
                      color: remainingAfterExpense < 0
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        remainingAfterExpense < 0
                            ? 'Over budget by \$${(-remainingAfterExpense).toStringAsFixed(0)}'
                            : 'Remaining: \$${remainingAfterExpense.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: remainingAfterExpense < 0
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Amount Spent
            const Text(
              'Amount Spent',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _spentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '\$0',
                prefixText: '\$ ',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF545A3B),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        color: _isLoading
                            ? Colors.grey
                            : const Color(0xFF545A3B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF545A3B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
