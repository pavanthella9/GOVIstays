import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/expense_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  String _monthName(DateTime date) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _dateText(DateTime date) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExpenseForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: ExpenseService.watchMonth(_selectedMonth),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Unable to load expenses: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = snapshot.data!;
          final total = expenses.fold<double>(0, (sum, item) => sum + item.amount);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Previous month',
                            onPressed: () => _changeMonth(-1),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Expanded(
                            child: Text(
                              _monthName(_selectedMonth),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Next month',
                            onPressed: () => _changeMonth(1),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                      const Divider(),
                      const Text('Total Expenses'),
                      const SizedBox(height: 6),
                      Text(
                        '₹${total.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (expenses.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No expenses recorded for this month.')),
                  ),
                )
              else
                ...expenses.map(
                  (expense) => Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
                      title: Text(
                        expense.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        expense.notes.isEmpty
                            ? _dateText(expense.expenseDate)
                            : '${_dateText(expense.expenseDate)}\n${expense.notes}',
                      ),
                      isThreeLine: expense.notes.isNotEmpty,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${expense.amount.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showExpenseForm(context, expense: expense);
                              } else if (value == 'delete') {
                                _confirmDelete(context, expense);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showExpenseForm(BuildContext context, {Expense? expense}) async {
    final nameController = TextEditingController(text: expense?.name ?? '');
    final amountController = TextEditingController(
      text: expense == null ? '' : expense.amount.toStringAsFixed(0),
    );
    final notesController = TextEditingController(text: expense?.notes ?? '');
    var selectedDate = expense?.expenseDate ?? DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(expense == null ? 'Add Expense' : 'Edit Expense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Expense Name *',
                    hintText: 'Laundry',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount *',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Expense Date *'),
                  subtitle: Text(_dateText(selectedDate)),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text.trim());
                if (nameController.text.trim().isEmpty || amount == null || amount <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Enter an expense name and valid amount.')),
                  );
                  return;
                }
                try {
                  if (expense == null) {
                    await ExpenseService.addExpense(
                      name: nameController.text,
                      amount: amount,
                      expenseDate: selectedDate,
                      notes: notesController.text,
                    );
                  } else {
                    await ExpenseService.updateExpense(
                      id: expense.id,
                      name: nameController.text,
                      amount: amount,
                      expenseDate: selectedDate,
                      notes: notesController.text,
                    );
                  }
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (error) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Unable to save expense: $error')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    amountController.dispose();
    notesController.dispose();

    if (saved == true && mounted) {
      setState(() {
        _selectedMonth = DateTime(selectedDate.year, selectedDate.month);
      });
    }
  }

  Future<void> _confirmDelete(BuildContext context, Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: Text('Delete "${expense.name}" for ₹${expense.amount.toStringAsFixed(0)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ExpenseService.deleteExpense(expense.id);
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unable to delete expense: $error')),
          );
        }
      }
    }
  }
}
