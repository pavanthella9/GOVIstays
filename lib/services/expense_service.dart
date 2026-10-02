import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense.dart';
import 'user_service.dart';

class ExpenseService {
  ExpenseService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _expenses =>
      _firestore.collection('expenses');

  static Stream<List<Expense>> watchMonth(DateTime month) {
    _requireAdmin();
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);

    return _expenses
        .where('expenseDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('expenseDate', isLessThan: Timestamp.fromDate(end))
        .orderBy('expenseDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Expense.fromFirestore).toList());
  }

  static Future<void> addExpense({
    required String name,
    required double amount,
    required DateTime expenseDate,
    String notes = '',
  }) async {
    _requireAdmin();
    _validate(name, amount);
    await _expenses.add({
      'expenseName': name.trim(),
      'amount': amount,
      'expenseDate': Timestamp.fromDate(expenseDate),
      'notes': notes.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': UserService.currentUser!.uid,
    });
  }

  static Future<void> updateExpense({
    required String id,
    required String name,
    required double amount,
    required DateTime expenseDate,
    String notes = '',
  }) async {
    _requireAdmin();
    _validate(name, amount);
    await _expenses.doc(id).update({
      'expenseName': name.trim(),
      'amount': amount,
      'expenseDate': Timestamp.fromDate(expenseDate),
      'notes': notes.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': UserService.currentUser!.uid,
    });
  }

  static Future<void> deleteExpense(String id) async {
    _requireAdmin();
    await _expenses.doc(id).delete();
  }

  static void _validate(String name, double amount) {
    if (name.trim().isEmpty) {
      throw const ExpenseServiceException('Expense name is required.');
    }
    if (amount <= 0) {
      throw const ExpenseServiceException('Amount must be greater than zero.');
    }
  }

  static void _requireAdmin() {
    if (!UserService.isAdmin) {
      throw const ExpenseServiceException('Admin access is required.');
    }
  }
}

class ExpenseServiceException implements Exception {
  final String message;
  const ExpenseServiceException(this.message);
  @override
  String toString() => message;
}
