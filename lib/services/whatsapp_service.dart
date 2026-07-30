import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/booking.dart';

class WhatsAppService {
  WhatsAppService._();

  static const String homestayName = 'Hillside Heaven Homestay';
  static const String contactNumber = '+91-77949-72727';
  static const String locationUrl =
      'https://maps.app.goo.gl/njWXCUJjq7jwzonq6?g_st=ac';

  static String buildBookingMessage(Booking booking) {
    return '''🏡 $homestayName

Dear ${booking.customerName},

Thank you for choosing $homestayName.
Your booking has been successfully confirmed.

Booking ID: ${booking.bookingId}
Booking Date: ${_formatDateTime(booking.bookingCreatedAt)}
Room(s): ${booking.rooms.join(', ')}
Guests: ${booking.guests}
Check-in: ${_formatDateTime(booking.checkIn)}
Check-out: ${_formatDateTime(booking.checkOut)}

📍 Location:
$locationUrl

📞 Contact:
$contactNumber

We look forward to welcoming you and hope you have a comfortable and pleasant stay.

Thank you,
🏡 $homestayName''';
  }

  static Future<void> openWhatsApp(Booking booking) async {
    final phone = _normalizePhone(booking.phoneNumber);
    if (phone.isEmpty) {
      throw const WhatsAppException('Enter a valid customer phone number.');
    }

    final uri = Uri.https(
      'wa.me',
      '/$phone',
      <String, String>{'text': buildBookingMessage(booking)},
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
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

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$day/$month/${local.year}, $hour:$minute $period';
  }
}

class WhatsAppException implements Exception {
  final String message;
  const WhatsAppException(this.message);

  @override
  String toString() => message;
}
