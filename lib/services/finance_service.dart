import '../models/booking.dart';
import 'booking_service.dart';
import 'customer_service.dart';

class FinanceSummary {
  final double totalBookingValue;
  final double totalCollected;
  final double pendingBalance;
  final int paidBookings;
  final int partialBookings;
  final int pendingBookings;

  const FinanceSummary({
    required this.totalBookingValue,
    required this.totalCollected,
    required this.pendingBalance,
    required this.paidBookings,
    required this.partialBookings,
    required this.pendingBookings,
  });
}

class FinanceService {
  FinanceService._();

  static FinanceSummary buildSummary(Iterable<Booking> bookings) {
    var totalBookingValue = 0.0;
    var totalCollected = 0.0;
    var pendingBalance = 0.0;
    var paidBookings = 0;
    var partialBookings = 0;
    var pendingBookings = 0;

    for (final booking in bookings) {
      totalBookingValue += booking.totalAmount;
      totalCollected += booking.advanceAmount;
      pendingBalance += booking.balanceAmount;

      if (booking.balanceAmount <= 0.01) {
        paidBookings++;
      } else if (booking.advanceAmount > 0.01) {
        partialBookings++;
      } else {
        pendingBookings++;
      }
    }

    return FinanceSummary(
      totalBookingValue: totalBookingValue,
      totalCollected: totalCollected,
      pendingBalance: pendingBalance,
      paidBookings: paidBookings,
      partialBookings: partialBookings,
      pendingBookings: pendingBookings,
    );
  }

  static FinanceSummary get allTime =>
      buildSummary(BookingService.bookings);

  static List<Booking> get outstandingBookings {
    final result = BookingService.bookings
        .where((booking) => booking.balanceAmount > 0.01)
        .toList();
    result.sort((a, b) => a.checkOut.compareTo(b.checkOut));
    return result;
  }

  static String paymentStatus(Booking booking) {
    if (booking.balanceAmount <= 0.01) return 'Paid';
    if (booking.advanceAmount > 0.01) return 'Partial';
    return 'Pending';
  }

  static Future<bool> collectPayment(
    Booking booking,
    double amount,
  ) async {
    if (amount <= 0 || amount > booking.balanceAmount + 0.01) {
      return false;
    }

    final newAdvance = (booking.advanceAmount + amount)
        .clamp(0.0, booking.totalAmount)
        .toDouble();
    final newBalance = (booking.totalAmount - newAdvance)
        .clamp(0.0, booking.totalAmount)
        .toDouble();

    final updated = Booking(
      bookingId: booking.bookingId,
      customerName: booking.customerName,
      phoneNumber: booking.phoneNumber,
      address: booking.address,
      guests: booking.guests,
      rooms: booking.rooms,
      checkIn: booking.checkIn,
      checkOut: booking.checkOut,
      totalAmount: booking.totalAmount,
      advanceAmount: newAdvance,
      balanceAmount: newBalance,
      notes: booking.notes,
    );

    final success = await BookingService.updateBooking(booking, updated);
    if (success) {
      await CustomerService.upsertFromBooking(updated);
    }
    return success;
  }
}
