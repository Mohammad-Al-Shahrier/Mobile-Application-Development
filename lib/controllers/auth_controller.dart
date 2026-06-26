import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// ============================================================
/// AUTH CONTROLLER — QEasy
///
/// Handles all Firebase Auth + Firestore user operations.
/// Use this class from LoginScreen, RegistrationScreen,
/// AuthGate, and anywhere else that needs auth.
///
/// Usage:
///   final result = await AuthController.register(...);
///   final result = await AuthController.login(...);
///   await AuthController.logout();
///   final user = AuthController.currentUser;
/// ============================================================
class AuthController {
  AuthController._(); // static-only class

  static final _auth = FirebaseAuth.instance;
  static final _db   = FirebaseFirestore.instance;

  // ── Current logged-in user ────────────────────
  static User? get currentUser => _auth.currentUser;
  static String? get currentUid => _auth.currentUser?.uid;
  static bool get isLoggedIn => _auth.currentUser != null;

  // ── Auth state stream (for AuthGate) ──────────
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ══════════════════════════════════════════════
  //  REGISTER
  //  Returns null on success, error message on fail
  // ══════════════════════════════════════════════
  static Future<String?> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String dob,
    required String gender,
  }) async {
    try {
      debugPrint('🔐 AuthController.register() → $email');

      // 1️⃣ Create Firebase Auth account
      final credential = await _auth.createUserWithEmailAndPassword(
        email:    email.trim(),
        password: password.trim(),
      );

      final uid  = credential.user!.uid;
      debugPrint('✅ Auth account created → uid: $uid');

      // 2️⃣ Update display name
      await credential.user!.updateDisplayName(fullName.trim());

      // 3️⃣ Save to Firestore users collection
      await _saveUserToFirestore(
        uid:      uid,
        fullName: fullName.trim(),
        email:    email.trim(),
        phone:    phone.trim(),
        address:  address.trim(),
        dob:      dob.trim(),
        gender:   gender,
        role:     'customer',
      );

      debugPrint('✅ User document saved to Firestore');
      return null; // null = success

    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException [${e.code}]: ${e.message}');
      return _authErrorMessage(e.code);
    } catch (e) {
      debugPrint('❌ Unexpected error during register: $e');
      return 'Registration failed. Please try again.';
    }
  }

  // ══════════════════════════════════════════════
  //  LOGIN
  //  Returns null on success, error message on fail
  // ══════════════════════════════════════════════
  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 AuthController.login() → $email');

      final credential = await _auth.signInWithEmailAndPassword(
        email:    email.trim(),
        password: password.trim(),
      );

      final uid = credential.user!.uid;
      debugPrint('✅ Login success → uid: $uid');

      // Update last login timestamp
      await _db.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      }).catchError((e) {
        // Ignore if doc doesn't exist yet
        debugPrint('⚠️ Could not update lastLoginAt: $e');
      });

      return null; // null = success

    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException [${e.code}]: ${e.message}');
      return _authErrorMessage(e.code);
    } catch (e) {
      debugPrint('❌ Unexpected error during login: $e');
      return 'Login failed. Please try again.';
    }
  }

  // ══════════════════════════════════════════════
  //  LOGOUT
  // ══════════════════════════════════════════════
  static Future<void> logout() async {
    debugPrint('🚪 AuthController.logout()');
    await _auth.signOut();
  }

  // ══════════════════════════════════════════════
  //  FORGOT PASSWORD
  // ══════════════════════════════════════════════
  static Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('📧 Password reset email sent to $email');
      return null; // null = success
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e.code);
    } catch (e) {
      return 'Failed to send reset email. Try again.';
    }
  }

  // ══════════════════════════════════════════════
  //  CHECK IF ADMIN
  //  Checks Firestore users collection role field
  // ══════════════════════════════════════════════
  static Future<bool> isAdmin(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return false;
      final role = (doc.data()?['role'] ?? 'customer').toString();
      return role == 'admin';
    } catch (e) {
      debugPrint('❌ isAdmin check failed: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════
  //  GET USER ROLE
  // ══════════════════════════════════════════════
  static Future<String> getUserRole(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return 'customer';
      return (doc.data()?['role'] ?? 'customer').toString();
    } catch (e) {
      debugPrint('❌ getUserRole failed: $e');
      return 'customer';
    }
  }

  // ══════════════════════════════════════════════
  //  GET CURRENT USER DOCUMENT
  // ══════════════════════════════════════════════
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    final uid = currentUid;
    if (uid == null) return null;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('❌ getCurrentUserData failed: $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ══════════════════════════════════════════════

  /// Write user document to Firestore
  static Future<void> _saveUserToFirestore({
    required String uid,
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String dob,
    required String gender,
    required String role,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid':                  uid,
      'fullName':             fullName,
      'email':                email,
      'phone':                phone,
      'address':              address,
      'dob':                  dob,
      'gender':               gender,
      'role':                 role,
      'serviceCenterId':      '',
      'serviceCenterName':    '',
      'activeQueueId':        null,
      'activeTokenNumber':    null,
      'totalQueuesJoined':    0,
      'notificationsEnabled': true,
      'createdAt':            FieldValue.serverTimestamp(),
      'lastLoginAt':          null,
    });
  }

  /// Human-readable Firebase error messages
  static String _authErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please login.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'operation-not-allowed':
        return 'Email sign-up is not enabled.';
      default:
        return 'Something went wrong ($code). Please try again.';
    }
  }
}