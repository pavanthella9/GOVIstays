import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/booking.dart';

class WhatsAppService {
  WhatsAppService._();

  static String buildBookingMessage(Booking booking) {
    return '''🏡 GOVIstays Booking Confirmation

Hello ${booking.customerName},

Your booking has been confirmed.

Booking ID: ${booking.bookingId}
Room(s): ${booking.rooms.join(', ')}
Check-in: ${_formatDate(booking.checkIn)}
Check-out: ${_formatDate(booking.checkOut)}
Guests: ${booking.guests}

Total: ₹${_money(booking.totalAmount)}
Advance: ₹${_money(booking.advanceAmount)}
Balance: ₹${_money(booking.balanceAmount)}

Thank you for choosing GOVIstays.
Have a pleasant stay!''';
  }

  static Future<void> openWhatsApp(Booking booking) async {
    final phone = _normalizePhone(booking.phoneNumber);
    if (phone.isEmpty) {
      throw const WhatsAppException('Enter a valid customer phone number.');
    }

    final message = buildBookingMessage(booking);
    final uri = Uri.https(
      'wa.me',
      '/$phone',
      <String, String>{'text': message},
    );

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw const WhatsAppException(
        'WhatsApp could not be opened on this device.',
      );
    }
  }

  static Future<void> copyBookingDetails(Booking booking) async {
    await Clipboard.setData(
      ClipboardData(text: buildBookingMessage(booking)),
    );
  }

  static String _normalizePhone(String value) {
    var digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.length == 10) digits = '91$digits';
    if (digits.length == 11 && digits.startsWith('0')) {
      digits = '91${digits.substring(1)}';
    }
    return digits.length >= 10 && digits.length <= 15 ? digits : '';
  }

  static String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  static String _money(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }
}

class WhatsAppException implements Exception {
  final String message;
  const WhatsAppException(this.message);

  @override
  String toString() => message;
}
