import '../models/booking.dart';

class BookingService {
  static final List<Booking> bookings = [];

  static int _bookingCounter = 1;

  static String generateBookingId() {
    return "GST${_bookingCounter.toString().padLeft(6, '0')}";
  }

  static bool addBooking(Booking booking) {
    for (final room in booking.rooms) {
      if (!isRoomAvailable(room, booking.checkIn, booking.checkOut)) {
        return false;
      }
    }

    bookings.add(booking);
    _bookingCounter++;

    return true;
  }

  static void deleteBooking(Booking booking) {
  bookings.removeWhere(
    (b) => b.bookingId == booking.bookingId,
  );
}

  static void updateBooking(Booking oldBooking, Booking newBooking) {

  final index = bookings.indexWhere(
    (b) => b.bookingId == oldBooking.bookingId,
  );

  if (index != -1) {
    bookings[index] = newBooking;
  }
}
  static bool isRoomAvailable(
    String room,
    DateTime checkIn,
    DateTime checkOut,
  ) {
    for (final booking in bookings) {
      if (!booking.rooms.contains(room)) continue;

      final overlap =
          checkIn.isBefore(booking.checkOut) &&
          checkOut.isAfter(booking.checkIn);

      if (overlap) {
        return false;
      }
    }

    return true;
  }

  static List<Booking> getCurrentGuests() {
    final now = DateTime.now();

    return bookings.where((booking) {
      return booking.checkIn.isBefore(now) &&
          booking.checkOut.isAfter(now);
    }).toList();
  }

  static List<Booking> getFutureBookings() {
    final now = DateTime.now();

    return bookings.where((booking) {
      return booking.checkIn.isAfter(now);
    }).toList();
  }
}