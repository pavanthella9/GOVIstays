import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/booking.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';

class RoomAvailabilitySegment {
  final DateTime start;
  final DateTime end;
  final bool isBooked;
  final Booking? booking;

  const RoomAvailabilitySegment({
    required this.start,
    required this.end,
    required this.isBooked,
    this.booking,
  });
}

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
  static Timer? _clockTimer;

  static CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionName);

  static Future<void> initialize() async {
    // Refresh time-dependent dashboard/current/future/history status automatically.
    _clockTimer ??= Timer.periodic(const Duration(minutes: 1), (_) {
      _notifyChanges();
    });

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

  static String generateBookingId() {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return 'HHH-${now.year}${two(now.month)}${two(now.day)}-'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

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


  /// Records an arrival/departure or an admin-only timestamp correction.
  /// The transaction prevents duplicate actions and preserves booking fields.
  static Future<void> recordGuestEvent({
    required String bookingId,
    required bool checkIn,
    DateTime? correctedTime,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || UserService.currentUser?.active != true) {
      throw StateError('An active user must be signed in.');
    }
    if (correctedTime != null && !UserService.isAdmin) {
      throw StateError('Only admin can correct actual timestamps.');
    }
    final ref = _collection.doc(bookingId);
    // Read potential room occupants before the transaction, then re-read
    // their documents inside it to detect changes before recording arrival.
    final possibleOccupants = <DocumentReference<Map<String, dynamic>>>[];
    if (checkIn && correctedTime == null) {
      final target = await ref.get();
      if (!target.exists) throw StateError('Booking not found.');
      final targetBooking = Booking.fromFirestore(target);
      final now = DateTime.now();
      if (!now.isBefore(targetBooking.checkOut)) {
        throw StateError('This booking is historical; check-in is unavailable.');
      }
      final active = await _collection
          .where('actualCheckIn', isNull: false)
          .get();
      for (final doc in active.docs) {
        if (doc.id == bookingId) continue;
        final other = Booking.fromFirestore(doc);
        if (other.actualCheckOut != null) continue;
        final targetRooms = targetBooking.rooms.map(_normalizeRoomName).toSet();
        if (other.rooms.any((room) => targetRooms.contains(_normalizeRoomName(room)))) {
          possibleOccupants.add(doc.reference);
        }
      }
    }
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw StateError('Booking not found.');
      final data = snapshot.data()!;
      if (checkIn && correctedTime == null) {
        final scheduledOut = (data['checkOut'] as Timestamp).toDate();
        if (!DateTime.now().isBefore(scheduledOut)) {
          throw StateError('Historical bookings cannot be checked in.');
        }
        for (final occupantRef in possibleOccupants) {
          final occupant = await transaction.get(occupantRef);
          if (!occupant.exists) continue;
          final occupantData = occupant.data()!;
          if (occupantData['actualCheckIn'] == null ||
              occupantData['actualCheckOut'] != null) continue;
          final occupiedRooms = List<String>.from(occupantData['rooms'] as List? ?? const []);
          final targetRooms = List<String>.from(data['rooms'] as List? ?? const []);
          final targetNames = targetRooms.map(_normalizeRoomName).toSet();
          final conflict = occupiedRooms.where((room) =>
              targetNames.contains(_normalizeRoomName(room))).toList();
          if (conflict.isNotEmpty) {
            throw StateError('Previous guest checkout not recorded for ${conflict.join(', ')}.');
          }
        }
      }
      final field = checkIn ? 'actualCheckIn' : 'actualCheckOut';
      final actorField = checkIn ? 'checkInMarkedBy' : 'checkOutMarkedBy';
      final oldValue = data[field] as Timestamp?;
      if (correctedTime == null && oldValue != null) {
        throw StateError('This action was already recorded.');
      }
      if (correctedTime != null && oldValue == null) {
        throw StateError('Record the event before correcting it.');
      }
      final newTime = correctedTime ?? DateTime.now();
      final arrival = checkIn ? newTime : (data['actualCheckIn'] as Timestamp?)?.toDate();
      final departure = checkIn ? (data['actualCheckOut'] as Timestamp?)?.toDate() : newTime;
      if (!checkIn && arrival == null) throw StateError('Check in the guest first.');
      if (arrival != null && departure != null && departure.isBefore(arrival)) {
        throw StateError('Check-out cannot precede check-in.');
      }
      final auditRef = ref.collection('guestEventAudit').doc();
      transaction.update(ref, {
        field: correctedTime == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(newTime),
        actorField: uid,
      });
      transaction.set(auditRef, {
        'event': checkIn ? 'checkIn' : 'checkOut',
        'action': correctedTime == null ? 'mark' : 'correct',
        'actorUid': uid,
        'oldTime': oldValue,
        'newTime': correctedTime == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(newTime),
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
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
        SetOptions(merge: true),
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


  /// Returns bookings that touch any part of the supplied calendar day.
  /// Full DateTime values are used, so partial-day and back-to-back stays
  /// are handled correctly.
  static List<Booking> getBookingsForDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final result = bookings.where((booking) {
      return booking.checkIn.isBefore(dayEnd) &&
          booking.checkOut.isAfter(dayStart);
    }).toList();

    result.sort((a, b) => a.checkIn.compareTo(b.checkIn));
    return result;
  }

  static List<Booking> getRoomBookingsForDate(
    String room,
    DateTime date,
  ) {
    final normalizedRoom = _normalizeRoomName(room);
    return getBookingsForDate(date).where((booking) {
      return booking.rooms.any(
        (bookedRoom) =>
            _normalizeRoomName(bookedRoom) == normalizedRoom,
      );
    }).toList()
      ..sort((a, b) => a.checkIn.compareTo(b.checkIn));
  }

  /// Builds a complete midnight-to-midnight timeline for one room.
  /// Available gaps and booked portions are both returned.
  static List<RoomAvailabilitySegment> getRoomAvailabilityForDate(
    String room,
    DateTime date,
  ) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final roomBookings = getRoomBookingsForDate(room, date);

    if (roomBookings.isEmpty) {
      return [
        RoomAvailabilitySegment(
          start: dayStart,
          end: dayEnd,
          isBooked: false,
        ),
      ];
    }

    final segments = <RoomAvailabilitySegment>[];
    var cursor = dayStart;

    for (final booking in roomBookings) {
      final bookedStart =
          booking.checkIn.isAfter(dayStart) ? booking.checkIn : dayStart;
      final bookedEnd =
          booking.checkOut.isBefore(dayEnd) ? booking.checkOut : dayEnd;

      if (!bookedEnd.isAfter(bookedStart)) continue;

      if (cursor.isBefore(bookedStart)) {
        segments.add(
          RoomAvailabilitySegment(
            start: cursor,
            end: bookedStart,
            isBooked: false,
          ),
        );
      }

      segments.add(
        RoomAvailabilitySegment(
          start: bookedStart,
          end: bookedEnd,
          isBooked: true,
          booking: booking,
        ),
      );

      if (bookedEnd.isAfter(cursor)) {
        cursor = bookedEnd;
      }
    }

    if (cursor.isBefore(dayEnd)) {
      segments.add(
        RoomAvailabilitySegment(
          start: cursor,
          end: dayEnd,
          isBooked: false,
        ),
      );
    }

    return segments;
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
    final now = DateTime.now();
    final result = bookings.where((booking) {
      return !now.isBefore(booking.checkIn) &&
          now.isBefore(booking.checkOut);
    }).toList();
    result.sort((a, b) => a.checkOut.compareTo(b.checkOut));
    return result;
  }

  static List<Booking> getFutureBookings() {
    final now = DateTime.now();
    final result = bookings
        .where((booking) => booking.checkIn.isAfter(now))
        .toList();
    result.sort((a, b) => a.checkIn.compareTo(b.checkIn));
    return result;
  }

  static List<Booking> getBookingHistory() {
    final now = DateTime.now();
    final result = bookings
        .where((booking) => !booking.checkOut.isAfter(now))
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
    final now = DateTime.now();
    final normalizedRoom = _normalizeRoomName(room);

    for (final booking in bookings) {
      final bookingHasRoom = booking.rooms.any(
        (bookedRoom) => _normalizeRoomName(bookedRoom) == normalizedRoom,
      );
      if (!bookingHasRoom) continue;

      if (!now.isBefore(booking.checkIn) && now.isBefore(booking.checkOut)) {
        return true;
      }
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
