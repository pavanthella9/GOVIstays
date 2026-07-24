import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../models/customer.dart';
import 'booking_service.dart';

class CustomerService {
  CustomerService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _customers =>
      _firestore.collection('customers');

  static String normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 10) return digits.substring(digits.length - 10);
    return digits;
  }

  static String customerIdForPhone(String phone) {
    final normalized = normalizePhone(phone);
    if (normalized.isNotEmpty) return normalized;
    return 'customer-${DateTime.now().millisecondsSinceEpoch}';
  }

  static Stream<List<Customer>> watchCustomers() {
    return _customers.snapshots().map((snapshot) {
      final customers = snapshot.docs.map(Customer.fromFirestore).toList();
      customers.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return customers;
    });
  }

  static Future<Customer?> getByPhone(String phone) async {
    final id = customerIdForPhone(phone);
    final document = await _customers.doc(id).get();
    if (!document.exists) return null;
    return Customer.fromFirestore(document);
  }

  static List<Booking> bookingsForPhone(String phone) {
    final normalized = normalizePhone(phone);
    final result = BookingService.bookings.where((booking) {
      return normalizePhone(booking.phoneNumber) == normalized;
    }).toList();
    result.sort((a, b) => b.checkIn.compareTo(a.checkIn));
    return result;
  }

  static Future<void> upsertFromBooking(Booking booking) async {
    final id = customerIdForPhone(booking.phoneNumber);
    final existing = await _customers.doc(id).get();
    final allBookings = bookingsForPhone(booking.phoneNumber);
    if (!allBookings.any((item) => item.bookingId == booking.bookingId)) {
      allBookings.add(booking);
    }

    final totalSpent = allBookings.fold<double>(
      0,
      (sum, item) => sum + item.advanceAmount,
    );
    final lastVisit = allBookings
        .map((item) => item.checkOut)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    await _customers.doc(id).set({
      'customerId': id,
      'name': booking.customerName.trim(),
      'phone': booking.phoneNumber.trim(),
      'address': booking.address.trim(),
      'notes': existing.data()?['notes'] ?? '',
      'totalBookings': allBookings.length,
      'totalSpent': totalSpent,
      'lastVisit': Timestamp.fromDate(lastVisit),
      'createdAt': existing.exists
          ? (existing.data()?['createdAt'] ?? FieldValue.serverTimestamp())
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> addCustomer({
    required String name,
    required String phone,
    required String address,
    String notes = '',
  }) async {
    if (name.trim().isEmpty || normalizePhone(phone).isEmpty) {
      throw const CustomerServiceException('Name and phone number are required.');
    }
    final id = customerIdForPhone(phone);
    final existing = await _customers.doc(id).get();
    if (existing.exists) {
      throw const CustomerServiceException(
        'A customer with this phone number already exists.',
      );
    }
    await _customers.doc(id).set({
      'customerId': id,
      'name': name.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'notes': notes.trim(),
      'totalBookings': 0,
      'totalSpent': 0.0,
      'lastVisit': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateCustomer(Customer customer) async {
    await _customers.doc(customer.customerId).update({
      'name': customer.name.trim(),
      'phone': customer.phone.trim(),
      'address': customer.address.trim(),
      'notes': customer.notes.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> syncExistingBookings() async {
    final grouped = <String, List<Booking>>{};
    for (final booking in BookingService.bookings) {
      final id = customerIdForPhone(booking.phoneNumber);
      grouped.putIfAbsent(id, () => <Booking>[]).add(booking);
    }

    for (final entry in grouped.entries) {
      final bookings = entry.value;
      bookings.sort((a, b) => b.checkIn.compareTo(a.checkIn));
      final latest = bookings.first;
      final totalSpent = bookings.fold<double>(
        0,
        (sum, item) => sum + item.advanceAmount,
      );
      final lastVisit = bookings
          .map((item) => item.checkOut)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final reference = _customers.doc(entry.key);
      final existing = await reference.get();
      await reference.set({
        'customerId': entry.key,
        'name': latest.customerName.trim(),
        'phone': latest.phoneNumber.trim(),
        'address': latest.address.trim(),
        'notes': existing.data()?['notes'] ?? '',
        'totalBookings': bookings.length,
        'totalSpent': totalSpent,
        'lastVisit': Timestamp.fromDate(lastVisit),
        'createdAt': existing.exists
            ? (existing.data()?['createdAt'] ?? FieldValue.serverTimestamp())
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    debugPrint('${grouped.length} customer record(s) synchronized.');
  }
}

class CustomerServiceException implements Exception {
  final String message;
  const CustomerServiceException(this.message);
  @override
  String toString() => message;
}
