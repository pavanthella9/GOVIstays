import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String customerId;
  final String name;
  final String phone;
  final String address;
  final String notes;
  final int totalBookings;
  final double totalSpent;
  final DateTime? lastVisit;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Customer({
    required this.customerId,
    required this.name,
    required this.phone,
    required this.address,
    this.notes = '',
    this.totalBookings = 0,
    this.totalSpent = 0,
    this.lastVisit,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'name': name.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'notes': notes.trim(),
      'totalBookings': totalBookings,
      'totalSpent': totalSpent,
      'lastVisit': lastVisit == null ? null : Timestamp.fromDate(lastVisit!),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }

  factory Customer.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    DateTime? readDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return Customer(
      customerId: (data['customerId'] as String?) ?? document.id,
      name: (data['name'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      address: (data['address'] as String?) ?? '',
      notes: (data['notes'] as String?) ?? '',
      totalBookings: (data['totalBookings'] as num?)?.toInt() ?? 0,
      totalSpent: (data['totalSpent'] as num?)?.toDouble() ?? 0,
      lastVisit: readDate(data['lastVisit']),
      createdAt: readDate(data['createdAt']),
      updatedAt: readDate(data['updatedAt']),
    );
  }
}
