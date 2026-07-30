import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class Booking {
  final String bookingId;
  final DateTime bookingCreatedAt;
  final String customerName;
  final String phoneNumber;
  final String address;
  final int guests;
  final List<String> rooms;
  final DateTime checkIn;
  final DateTime checkOut;
  final double totalAmount;
  final double advanceAmount;
  final double balanceAmount;
  final String notes;

  Booking({
    required this.bookingId,
    required this.bookingCreatedAt,
    required this.customerName,
    required this.phoneNumber,
    required this.address,
    required this.guests,
    required this.rooms,
    required this.checkIn,
    required this.checkOut,
    required this.totalAmount,
    required this.advanceAmount,
    required this.balanceAmount,
    required this.notes,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'bookingCreatedAt': Timestamp.fromDate(bookingCreatedAt),
      'customerName': customerName,
      'phoneNumber': phoneNumber,
      'address': address,
      'guests': guests,
      'rooms': rooms,
      'checkIn': Timestamp.fromDate(checkIn),
      'checkOut': Timestamp.fromDate(checkOut),
      'totalAmount': totalAmount,
      'advanceAmount': advanceAmount,
      'balanceAmount': balanceAmount,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toBackupJson() {
    return {
      'bookingId': bookingId,
      'bookingCreatedAt': bookingCreatedAt.toIso8601String(),
      'customerName': customerName,
      'phoneNumber': phoneNumber,
      'address': address,
      'guests': guests,
      'rooms': rooms,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'totalAmount': totalAmount,
      'advanceAmount': advanceAmount,
      'balanceAmount': balanceAmount,
      'notes': notes,
    };
  }

  factory Booking.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Booking document ${document.id} has no data.');
    }
    return Booking.fromMap(data, fallbackId: document.id);
  }

  factory Booking.fromMap(
    Map<String, dynamic> data, {
    String? fallbackId,
  }) {
    DateTime readDate(dynamic value, String field, {DateTime? fallback}) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (fallback != null) return fallback;
      throw FormatException('Invalid $field value.');
    }

    final checkIn = readDate(data['checkIn'], 'checkIn');

    return Booking(
      bookingId: (data['bookingId'] as String?) ?? fallbackId ?? '',
      bookingCreatedAt: readDate(
        data['bookingCreatedAt'] ?? data['createdAt'],
        'bookingCreatedAt',
        fallback: checkIn,
      ),
      customerName: (data['customerName'] as String?) ?? '',
      phoneNumber: (data['phoneNumber'] as String?) ?? '',
      address: (data['address'] as String?) ?? '',
      guests: (data['guests'] as num?)?.toInt() ?? 0,
      rooms: List<String>.from(data['rooms'] as List? ?? const []),
      checkIn: checkIn,
      checkOut: readDate(data['checkOut'], 'checkOut'),
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      advanceAmount: (data['advanceAmount'] as num?)?.toDouble() ?? 0,
      balanceAmount: (data['balanceAmount'] as num?)?.toDouble() ?? 0,
      notes: (data['notes'] as String?) ?? '',
    );
  }
}

/// Retained only for one-time migration of existing Hive bookings.
class BookingAdapter extends TypeAdapter<Booking> {
  @override
  final int typeId = 0;

  @override
  Booking read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };

    final checkIn = fields[6] as DateTime;
    return Booking(
      bookingId: fields[0] as String,
      bookingCreatedAt: fields[12] as DateTime? ?? checkIn,
      customerName: fields[1] as String,
      phoneNumber: fields[2] as String,
      address: fields[3] as String,
      guests: fields[4] as int,
      rooms: List<String>.from(fields[5] as List),
      checkIn: checkIn,
      checkOut: fields[7] as DateTime,
      totalAmount: (fields[8] as num).toDouble(),
      advanceAmount: (fields[9] as num).toDouble(),
      balanceAmount: (fields[10] as num).toDouble(),
      notes: fields[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Booking booking) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(booking.bookingId)
      ..writeByte(1)
      ..write(booking.customerName)
      ..writeByte(2)
      ..write(booking.phoneNumber)
      ..writeByte(3)
      ..write(booking.address)
      ..writeByte(4)
      ..write(booking.guests)
      ..writeByte(5)
      ..write(booking.rooms)
      ..writeByte(6)
      ..write(booking.checkIn)
      ..writeByte(7)
      ..write(booking.checkOut)
      ..writeByte(8)
      ..write(booking.totalAmount)
      ..writeByte(9)
      ..write(booking.advanceAmount)
      ..writeByte(10)
      ..write(booking.balanceAmount)
      ..writeByte(11)
      ..write(booking.notes)
      ..writeByte(12)
      ..write(booking.bookingCreatedAt);
  }
}
