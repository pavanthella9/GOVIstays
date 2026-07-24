import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/user_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      initialData: AuthService.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashView();
        }

        final user = snapshot.data;
        if (user == null) return const LoginScreen();

        return FutureBuilder<void>(
          future: _initializeSignedInUser(),
          builder: (context, startupSnapshot) {
            if (startupSnapshot.connectionState != ConnectionState.done) {
              return const _SplashView();
            }

            if (startupSnapshot.hasError) {
              return _StartupError(
                message: startupSnapshot.error.toString(),
              );
            }

            return const DashboardScreen();
          },
        );
      },
    );
  }

  Future<void> _initializeSignedInUser() async {
    final profile = await UserService.loadCurrentUser();
    if (!profile.active) {
      await AuthService.signOut();
      throw const UserServiceException(
        'This account has been disabled by the administrator.',
      );
    }
    await BookingService.initialize();
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home_work_rounded, size: 90, color: Colors.blue),
            SizedBox(height: 18),
            Text(
              'GOVIstays',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  final String message;

  const _StartupError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Unable to load GOVIstays',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: AuthService.signOut,
                child: const Text('Return to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
