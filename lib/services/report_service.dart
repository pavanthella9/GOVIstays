import '../models/booking.dart';
import 'booking_service.dart';

class ReportSummary {
  final DateTime start;
  final DateTime end;
  final int bookings;
  final int guests;
  final int roomNights;
  final double bookingValue;
  final double advanceCollected;
  final double pendingBalance;
  final double occupancyPercentage;
  final String mostBookedRoom;

  const ReportSummary({
    required this.start,
    required this.end,
    required this.bookings,
    required this.guests,
    required this.roomNights,
    required this.bookingValue,
    required this.advanceCollected,
    required this.pendingBalance,
    required this.occupancyPercentage,
    required this.mostBookedRoom,
  });
}

class ReportService {
  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime endOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day, 23, 59, 59, 999);

  static ReportSummary buildSummary(DateTime start, DateTime end) {
    final rangeStart = dateOnly(start);
    final rangeEnd = endOfDay(end);
    final selected = BookingService.bookings.where((booking) {
      return !booking.checkIn.isBefore(rangeStart) &&
          !booking.checkIn.isAfter(rangeEnd);
    }).toList();

    var guests = 0;
    var roomNights = 0;
    var bookingValue = 0.0;
    var advanceCollected = 0.0;
    var pendingBalance = 0.0;
    final roomCounts = <String, int>{};

    for (final booking in selected) {
      guests += booking.guests;
      bookingValue += booking.totalAmount;
      advanceCollected += booking.advanceAmount;
      pendingBalance += booking.balanceAmount;

      final nights = _stayDays(booking);
      roomNights += nights * booking.rooms.length;
      for (final room in booking.rooms) {
        roomCounts.update(room, (value) => value + nights, ifAbsent: () => nights);
      }
    }

    final days = rangeEnd.difference(rangeStart).inDays + 1;
    final possibleRoomNights = BookingService.totalRoomsCount * days;
    final occupancy = possibleRoomNights == 0
        ? 0.0
        : (roomNights / possibleRoomNights * 100).clamp(0.0, 100.0);

    var mostBookedRoom = 'No bookings';
    var highestCount = 0;
    for (final entry in roomCounts.entries) {
      if (entry.value > highestCount) {
        highestCount = entry.value;
        mostBookedRoom = entry.key;
      }
    }

    return ReportSummary(
      start: rangeStart,
      end: rangeEnd,
      bookings: selected.length,
      guests: guests,
      roomNights: roomNights,
      bookingValue: bookingValue,
      advanceCollected: advanceCollected,
      pendingBalance: pendingBalance,
      occupancyPercentage: occupancy,
      mostBookedRoom: mostBookedRoom,
    );
  }

  static int _stayDays(Booking booking) {
    final checkIn = dateOnly(booking.checkIn);
    final checkOut = dateOnly(booking.checkOut);
    final difference = checkOut.difference(checkIn).inDays;
    return difference < 1 ? 1 : difference;
  }

  static ReportSummary get today {
    final now = DateTime.now();
    return buildSummary(now, now);
  }

  static ReportSummary get thisMonth {
    final now = DateTime.now();
    return buildSummary(DateTime(now.year, now.month, 1), now);
  }
}
