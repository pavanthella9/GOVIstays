import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/booking.dart';

class BookingService {
  static const List<String> allRooms = [
    'Master Room 1',
    'Master Room 2',
    'Queen Room 1',
    'Queen Room 2',
    'Penthouse',
  ];

  static const String _boxName = 'govistays_bookings';
  static const String _collectionName = 'bookings';

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final List<Booking> bookings = [];
  static final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  static CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionName);

  static Future<void> initialize() async {
    await _migrateExistingHiveBookingsIfNeeded();

    await _subscription?.cancel();
    _subscription = _collection.snapshots().listen(
      (snapshot) {
        bookings
          ..clear()
          ..addAll(snapshot.docs.map(Booking.fromFirestore));
        _sortBookings();
        _notifyChanges();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Firestore booking listener failed: $error');
      },
    );
  }

  static Future<void> _migrateExistingHiveBookingsIfNeeded() async {
    try {
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(BookingAdapter());
      }

      final localBox = await Hive.openBox<Booking>(_boxName);
      if (localBox.isEmpty) return;

      final cloudSnapshot = await _collection.limit(1).get();
      if (cloudSnapshot.docs.isNotEmpty) return;

      final batch = _firestore.batch();
      for (final booking in localBox.values) {
        batch.set(
          _collection.doc(booking.bookingId),
          booking.toFirestore(),
        );
      }
      await batch.commit();
      debugPrint('${localBox.length} Hive booking(s) migrated to Firestore.');
    } catch (error) {
      // Migration must never prevent the app from opening. Firestore's
      // listener will still load cloud/cached data.
      debugPrint('Hive-to-Firestore migration skipped: $error');
    }
  }

  static void _sortBookings() {
    bookings.sort((a, b) => a.checkIn.compareTo(b.checkIn));
  }

  static void _notifyChanges() {
    changeNotifier.value++;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool _isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  static String _normalizeRoomName(String room) {
    switch (room.trim().toLowerCase()) {
      case 'mr1':
        return 'master room 1';
      case 'mr2':
        return 'master room 2';
      case 'qr1':
        return 'queen room 1';
      case 'qr2':
        return 'queen room 2';
      case 'ph':
        return 'penthouse';
      default:
        return room.trim().toLowerCase();
    }
  }

  static String generateBookingId() =>
      'GST${DateTime.now().millisecondsSinceEpoch}';

  static Future<bool> addBooking(Booking booking) async {
    for (final room in booking.rooms) {
      if (!isRoomAvailable(room, booking.checkIn, booking.checkOut)) {
        return false;
      }
    }

    try {
      await _collection.doc(booking.bookingId).set(booking.toFirestore());
      return true;
    } catch (error) {
      debugPrint('Add booking failed: $error');
      return false;
    }
  }

  static Future<bool> deleteBooking(Booking booking) async {
    try {
      await _collection.doc(booking.bookingId).delete();
      return true;
    } catch (error) {
      debugPrint('Delete booking failed: $error');
      return false;
    }
  }

  static Future<bool> updateBooking(
    Booking oldBooking,
    Booking newBooking,
  ) async {
    for (final room in newBooking.rooms) {
      if (!isRoomAvailable(
        room,
        newBooking.checkIn,
        newBooking.checkOut,
        ignoreBookingId: oldBooking.bookingId,
      )) {
        return false;
      }
    }

    try {
      final batch = _firestore.batch();
      if (oldBooking.bookingId != newBooking.bookingId) {
        batch.delete(_collection.doc(oldBooking.bookingId));
      }
      batch.set(
        _collection.doc(newBooking.bookingId),
        newBooking.toFirestore(),
      );
      await batch.commit();
      return true;
    } catch (error) {
      debugPrint('Update booking failed: $error');
      return false;
    }
  }

  static Future<void> replaceAllBookings(
    List<Booking> restoredBookings,
  ) async {
    final existing = await _collection.get();
    var batch = _firestore.batch();
    var operationCount = 0;

    Future<void> commitIfNeeded() async {
      if (operationCount == 0) return;
      await batch.commit();
      batch = _firestore.batch();
      operationCount = 0;
    }

    for (final document in existing.docs) {
      batch.delete(document.reference);
      operationCount++;
      if (operationCount >= 450) await commitIfNeeded();
    }

    for (final booking in restoredBookings) {
      batch.set(_collection.doc(booking.bookingId), booking.toFirestore());
      operationCount++;
      if (operationCount >= 450) await commitIfNeeded();
    }

    await commitIfNeeded();
  }

  static bool isRoomAvailable(
    String room,
    DateTime checkIn,
    DateTime checkOut, {
    String? ignoreBookingId,
  }) {
    final normalizedRoom = _normalizeRoomName(room);

    for (final booking in bookings) {
      if (booking.bookingId == ignoreBookingId) continue;
      final bookingHasRoom = booking.rooms.any(
        (bookedRoom) => _normalizeRoomName(bookedRoom) == normalizedRoom,
      );
      if (!bookingHasRoom) continue;

      if (checkIn.isBefore(booking.checkOut) &&
          checkOut.isAfter(booking.checkIn)) {
        return false;
      }
    }
    return true;
  }

  static List<Booking> getTodayCheckIns() {
    final today = DateTime.now();
    final result = bookings
        .where((booking) => _isSameDay(booking.checkIn, today))
        .toList();
    result.sort((a, b) => a.customerName.compareTo(b.customerName));
    return result;
  }

  static List<Booking> getTodayCheckOuts() {
    final today = DateTime.now();
    final result = bookings
        .where((booking) => _isSameDay(booking.checkOut, today))
        .toList();
    result.sort((a, b) => a.customerName.compareTo(b.customerName));
    return result;
  }

  static List<Booking> getCurrentGuests() {
    final today = _dateOnly(DateTime.now());
    final result = bookings.where((booking) {
      final checkIn = _dateOnly(booking.checkIn);
      final checkOut = _dateOnly(booking.checkOut);
      return !today.isBefore(checkIn) && today.isBefore(checkOut);
    }).toList();
    result.sort((a, b) => a.checkOut.compareTo(b.checkOut));
    return result;
  }

  static List<Booking> getFutureBookings() {
    final today = _dateOnly(DateTime.now());
    final result = bookings
        .where((booking) => _dateOnly(booking.checkIn).isAfter(today))
        .toList();
    result.sort((a, b) => a.checkIn.compareTo(b.checkIn));
    return result;
  }

  static List<Booking> getBookingHistory() {
    final today = _dateOnly(DateTime.now());
    final result = bookings
        .where((booking) => _dateOnly(booking.checkOut).isBefore(today))
        .toList();
    result.sort((a, b) => b.checkOut.compareTo(a.checkOut));
    return result;
  }

  static List<Booking> searchBookings(List<Booking> source, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return List<Booking>.from(source);

    return source.where((booking) {
      return booking.customerName.toLowerCase().contains(normalizedQuery) ||
          booking.phoneNumber.toLowerCase().contains(normalizedQuery) ||
          booking.bookingId.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  static bool isRoomOccupiedToday(String room) {
    final today = _dateOnly(DateTime.now());
    final normalizedRoom = _normalizeRoomName(room);

    for (final booking in bookings) {
      final bookingHasRoom = booking.rooms.any(
        (bookedRoom) => _normalizeRoomName(bookedRoom) == normalizedRoom,
      );
      if (!bookingHasRoom) continue;

      final checkIn = _dateOnly(booking.checkIn);
      final checkOut = _dateOnly(booking.checkOut);
      if (!today.isBefore(checkIn) && today.isBefore(checkOut)) return true;
    }
    return false;
  }

  static Set<String> get occupiedRoomsToday =>
      allRooms.where(isRoomOccupiedToday).toSet();

  static int get totalRoomsCount => allRooms.length;
  static int get occupiedRoomsCount => occupiedRoomsToday.length;
  static int get availableRoomsCount => totalRoomsCount - occupiedRoomsCount;
  static double get occupancyPercentage => totalRoomsCount == 0
      ? 0
      : (occupiedRoomsCount / totalRoomsCount) * 100;
  static int get todayCheckInsCount => getTodayCheckIns().length;
  static int get todayCheckOutsCount => getTodayCheckOuts().length;
  static int get currentGuestsCount => getCurrentGuests().length;
  static int get futureBookingsCount => getFutureBookings().length;
  static int get bookingHistoryCount => getBookingHistory().length;
}
