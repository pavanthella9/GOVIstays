import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../models/app_user.dart';

class UserService {
  UserService._();

  static const String bootstrapAdminEmail = 'hillsidehomestay1@gmail.com';

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final ValueNotifier<AppUser?> currentUserNotifier =
      ValueNotifier<AppUser?>(null);

  static CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  static AppUser? get currentUser => currentUserNotifier.value;
  static bool get isAdmin => currentUser?.isAdmin == true;
  static bool get canManageBookings => isAdmin;
  static bool get canCreateBookings => currentUser?.active == true;
  static bool get canViewFinancials => isAdmin;
  static bool get canViewBalance => currentUser?.active == true;

  static Future<AppUser> loadCurrentUser({bool createIfMissing = true}) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      currentUserNotifier.value = null;
      throw const UserServiceException('No signed-in user was found.');
    }

    final reference = _users.doc(firebaseUser.uid);
    final snapshot = await reference.get();

    AppUser profile;
    if (!snapshot.exists) {
      if (!createIfMissing) {
        throw const UserServiceException('User profile does not exist.');
      }

      final email = (firebaseUser.email ?? '').trim().toLowerCase();
      final isBootstrapAdmin = email == bootstrapAdminEmail;
      profile = AppUser(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName?.trim().isNotEmpty == true
            ? firebaseUser.displayName!.trim()
            : (isBootstrapAdmin ? 'Administrator' : 'Staff'),
        email: email,
        phone: '',
        role: isBootstrapAdmin ? 'admin' : 'staff',
        active: true,
        createdBy: isBootstrapAdmin ? firebaseUser.uid : 'system',
      );
      await reference.set(profile.toFirestore());
      final createdSnapshot = await reference.get();
      profile = AppUser.fromFirestore(createdSnapshot);
    } else {
      profile = AppUser.fromFirestore(snapshot);
    }

    currentUserNotifier.value = profile;
    return profile;
  }

  static void clearCurrentUser() {
    currentUserNotifier.value = null;
  }

  static Stream<List<AppUser>> watchStaff() {
    return _users
        .where('role', isEqualTo: 'staff')
        .snapshots()
        .map((snapshot) {
      final users = snapshot.docs.map(AppUser.fromFirestore).toList();
      users.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return users;
    });
  }

  static Future<void> createStaff({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _requireAdmin();

    final normalizedEmail = email.trim().toLowerCase();
    if (name.trim().isEmpty || normalizedEmail.isEmpty || password.isEmpty) {
      throw const UserServiceException('Name, email and password are required.');
    }
    if (password.length < 6) {
      throw const UserServiceException(
        'Password must contain at least 6 characters.',
      );
    }

    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'staff-${DateTime.now().microsecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final createdUser = credential.user;
      if (createdUser == null) {
        throw const UserServiceException('Staff account could not be created.');
      }

      await createdUser.updateDisplayName(name.trim());
      final profile = AppUser(
        uid: createdUser.uid,
        name: name.trim(),
        email: normalizedEmail,
        phone: phone.trim(),
        role: 'staff',
        active: true,
        createdBy: currentUser!.uid,
      );
      await _users.doc(createdUser.uid).set(profile.toFirestore());
      await secondaryAuth.signOut();
    } on FirebaseAuthException catch (error) {
      throw UserServiceException(_authErrorMessage(error.code));
    } on FirebaseException catch (error) {
      throw UserServiceException(error.message ?? 'Unable to save staff profile.');
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }

  static Future<void> updateStaff({
    required String uid,
    required String name,
    required String phone,
  }) async {
    _requireAdmin();
    if (name.trim().isEmpty) {
      throw const UserServiceException('Staff name is required.');
    }
    await _users.doc(uid).update({
      'name': name.trim(),
      'phone': phone.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> setStaffActive({
    required String uid,
    required bool active,
  }) async {
    _requireAdmin();
    await _users.doc(uid).update({
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static void _requireAdmin() {
    if (!isAdmin) {
      throw const UserServiceException('Admin access is required.');
    }
  }

  static String _authErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      default:
        return 'Unable to create the staff account. Please try again.';
    }
  }
}

class UserServiceException implements Exception {
  final String message;
  const UserServiceException(this.message);
  @override
  String toString() => message;
}
