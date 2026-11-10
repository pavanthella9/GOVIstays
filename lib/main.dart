import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const emulatorMode = bool.fromEnvironment('GOVISTAYS_EMULATOR');
  if (emulatorMode) {
    if (kReleaseMode) {
      throw StateError('Emulator mode is prohibited in release builds.');
    }
    // Physical Android device: use adb reverse for both ports.
    await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
  }

  if (!emulatorMode) {
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  await NotificationService.initialize(
    rootScaffoldMessengerKey,
  );

  }

  runApp(GOVIStaysApp(emulatorMode: emulatorMode));
}

class GOVIStaysApp extends StatelessWidget {
  const GOVIStaysApp({super.key, this.emulatorMode = false});
  final bool emulatorMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: emulatorMode ? 'GOVIstays LOCAL TEST' : 'GOVIstays',
      builder: (context, child) => emulatorMode
          ? Banner(message: 'LOCAL TEST', location: BannerLocation.topEnd,
              color: Colors.deepOrange, child: child ?? const SizedBox.shrink())
          : child ?? const SizedBox.shrink(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
