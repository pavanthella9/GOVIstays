import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String name;
  final double amount;
  final DateTime expenseDate;
  final String notes;
  final String createdBy;
  final DateTime? createdAt;

  const Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.expenseDate,
    required this.notes,
    required this.createdBy,
    this.createdAt,
  });

  factory Expense.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Expense(
      id: doc.id,
      name: (data['expenseName'] ?? '').toString(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      expenseDate: (data['expenseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: (data['notes'] ?? '').toString(),
      createdBy: (data['createdBy'] ?? '').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
