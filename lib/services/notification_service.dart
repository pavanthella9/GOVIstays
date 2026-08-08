import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static const String bookingTopic = 'govistays_bookings';

  static Future<void> initialize(
    GlobalKey<ScaffoldMessengerState> messengerKey,
  ) async {
    final messaging = FirebaseMessaging.instance;

    // Android 13+ and iOS ask the user for notification permission.
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Every installed GOVIstays instance receives booking notifications.
    await messaging.subscribeToTopic(bookingTopic);

    // Background/terminated notification messages are displayed by Android.
    // When the app is open, show a visible in-app popup as well.
    FirebaseMessaging.onMessage.listen((message) {
      final title =
          message.notification?.title ?? 'GOVIstays Notification';
      final body = message.notification?.body ?? '';

      final messenger = messengerKey.currentState;
      if (messenger == null) return;

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (body.isNotEmpty) Text(body),
              ],
            ),
          ),
        );
    });
  }
}
