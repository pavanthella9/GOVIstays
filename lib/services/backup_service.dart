import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../models/booking.dart';
import 'booking_service.dart';

class BackupResult {
  final bool success;
  final bool cancelled;
  final String message;

  const BackupResult({
    required this.success,
    required this.cancelled,
    required this.message,
  });
}

class BackupService {
  static const int backupVersion = 2;

  static Future<BackupResult> createBackup() async {
    try {
      final now = DateTime.now();
      final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      final selectedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save GOVIstays backup',
        fileName: 'GOVIstays_Cloud_Backup_$date.json',
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );

      if (selectedPath == null) {
        return const BackupResult(
          success: false,
          cancelled: true,
          message: 'Backup cancelled.',
        );
      }

      final data = {
        'app': 'GOVIstays',
        'version': backupVersion,
        'createdAt': now.toIso8601String(),
        'bookingCount': BookingService.bookings.length,
        'bookings': BookingService.bookings
            .map((booking) => booking.toBackupJson())
            .toList(),
      };

      await File(selectedPath).writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
        flush: true,
      );

      return BackupResult(
        success: true,
        cancelled: false,
        message: 'Backup saved successfully.\n\n$selectedPath',
      );
    } catch (error) {
      return BackupResult(
        success: false,
        cancelled: false,
        message: 'Backup failed: $error',
      );
    }
  }

  static Future<BackupResult> restoreBackup() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select GOVIstays backup',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        allowMultiple: false,
        withData: true,
      );

      if (picked == null) {
        return const BackupResult(
          success: false,
          cancelled: true,
          message: 'Restore cancelled.',
        );
      }

      final selected = picked.files.single;
      final text = selected.bytes != null
          ? utf8.decode(selected.bytes!)
          : await File(selected.path!).readAsString();
      final decoded = jsonDecode(text);

      if (decoded is! Map || decoded['app'] != 'GOVIstays') {
        throw const FormatException('This is not a valid GOVIstays backup.');
      }

      final rawBookings = decoded['bookings'];
      if (rawBookings is! List) {
        throw const FormatException('The backup contains no booking list.');
      }

      final restored = <Booking>[];
      final ids = <String>{};
      for (final raw in rawBookings) {
        if (raw is! Map) {
          throw const FormatException('Invalid booking entry.');
        }
        final booking = Booking.fromMap(Map<String, dynamic>.from(raw));
        if (booking.bookingId.isEmpty || !ids.add(booking.bookingId)) {
          throw const FormatException('Invalid or duplicate booking ID.');
        }
        restored.add(booking);
      }

      await BookingService.replaceAllBookings(restored);
      return BackupResult(
        success: true,
        cancelled: false,
        message: '${restored.length} booking(s) restored to Firestore.',
      );
    } catch (error) {
      return BackupResult(
        success: false,
        cancelled: false,
        message: 'Restore failed: $error',
      );
    }
  }
}
