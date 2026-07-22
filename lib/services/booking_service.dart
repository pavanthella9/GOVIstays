import '../models/booking.dart';

class BookingService {
  static final List<Booking> bookings = [];

  /// Add Booking
  static void addBooking(Booking booking) {
    bookings.add(booking);
  }

  /// Delete Booking
  static void deleteBooking(Booking booking) {
    bookings.remove(booking);
  }

  /// Update Booking
  static void updateBooking(Booking oldBooking, Booking newBooking) {
    final index = bookings.indexOf(oldBooking);
    if (index != -1) {
      bookings[index] = newBooking;
    }
  }

  /// Check Room Availability
  static bool isRoomAvailable(
    String room,
    DateTime checkIn,
    DateTime checkOut,
  ) {
    for (final booking in bookings) {
      if (!booking.rooms.contains(room)) {
        continue;
      }

      final overlap =
          checkIn.isBefore(booking.checkOut) &&
          checkOut.isAfter(booking.checkIn);

      if (overlap) {
        return false;
      }
    }

    return true;
  }

  /// Get Current Guests
  static List<Booking> getCurrentGuests() {
    final now = DateTime.now();

    return bookings.where((booking) {
      return booking.checkIn.isBefore(now) &&
          booking.checkOut.isAfter(now);
    }).toList();
  }

  /// Get Future Bookings
  static List<Booking> getFutureBookings() {
    final now = DateTime.now();

    return bookings.where((booking) {
      return booking.checkIn.isAfter(now);
    }).toList();
  }
}