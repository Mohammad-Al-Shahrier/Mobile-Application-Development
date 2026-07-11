import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
  //  REGISTER — SERVICE CENTER (self-service business signup)
  //  Creates the Auth account, a brand-new `service_centers` doc,
  //  its matching `queues` doc, and a `users` doc with
  //  role: 'service_provider' already linked to that center — all
  //  in one go, straight from the public registration screen.
  //  Returns null on success, error message on fail.
  // ══════════════════════════════════════════════
  static Future<String?> registerServiceCenter({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String dob,
    required String gender,
    required String centerName,
    required String category,
    required String description,
    int avgServiceMinutes = 5,
  }) async {
    User? createdAuthUser;
    try {
      debugPrint('🏢 AuthController.registerServiceCenter() → $email');

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      createdAuthUser = credential.user;
      final uid = credential.user!.uid;
      debugPrint('✅ Auth account created → uid: $uid');

      await credential.user!.updateDisplayName(fullName.trim());

      // Write the service center, its queue, and the owner's user doc as
      // ONE atomic batch — either all three land, or none do. This is what
      // used to be 3 separate `.set()` calls: if the 2nd one got denied by
      // Firestore rules, the center doc from step 1 was already committed
      // (or not) with nothing to show for it and no clear error — a batch
      // fixes that class of "half registered" bug entirely.
      final batch = _db.batch();

      final centerRef = _db.collection('service_centers').doc();
      batch.set(centerRef, {
        'name': centerName.trim(),
        'category': category,
        'address': address.trim(),
        'rating': 5.0,
        'image': 'assets/images/hospital.jpg',
        'description': description.trim(),
        'isActive': true,
        'avgServiceMinutes': avgServiceMinutes,
        'isPaused': false,
        'assignedProviderUid': uid,
        'assignedProviderName': fullName.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      final queueRef = _db.collection('queues').doc(centerRef.id);
      batch.set(queueRef, {
        'serviceCenterId': centerRef.id,
        'serviceCenterName': centerName.trim(),
        // Mirrors service_centers.assignedProviderUid so security rules
        // can validate this write against request.resource.data directly
        // instead of needing a get() on a doc created in the same batch.
        'assignedProviderUid': uid,
        'lastTokenNumber': 0,
        'isPaused': false,
        'currentServingTokenId': null,
        'currentServingTokenNumber': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final userRef = _db.collection('users').doc(uid);
      batch.set(userRef, {
        'uid': uid,
        'fullName': fullName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'address': address.trim(),
        'dob': dob.trim(),
        'gender': gender,
        'role': 'service_provider',
        'serviceCenterId': centerRef.id,
        'serviceCenterName': centerName.trim(),
        'activeQueueId': null,
        'activeTokenNumber': null,
        'totalQueuesJoined': 0,
        'notificationsEnabled': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': null,
      });

      await batch.commit();

      debugPrint('✅ Service center "${centerName.trim()}" created → ${centerRef.id}');
      return null; // null = success

    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException [${e.code}]: ${e.message}');
      return _authErrorMessage(e.code);
    } on FirebaseException catch (e) {
      // Almost always a Firestore security-rules rejection — surface the
      // real reason instead of a generic message, and clean up the auth
      // account we just created so the person isn't left with a login
      // that has no working center/profile behind it.
      debugPrint('❌ Firestore error during registerServiceCenter [${e.code}]: ${e.message}');
      await createdAuthUser?.delete().catchError((_) {});
      if (e.code == 'permission-denied') {
        return 'Registration was blocked by server rules (permission-denied). '
            'Ask your admin to update Firestore security rules to allow '
            'service center self-registration.';
      }
      return 'Could not save your service center (${e.code}). Please try again.';
    } catch (e) {
      debugPrint('❌ Unexpected error during registerServiceCenter: $e');
      await createdAuthUser?.delete().catchError((_) {});
      return 'Could not register your service center. Please try again.';
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
  //  ADMIN: CREATE / REMOVE SERVICE PROVIDER
  //  Uses a throwaway secondary Firebase App so creating the new
  //  provider account never signs the admin out of their own session.
  //  Returns null on success, error message on fail.
  // ══════════════════════════════════════════════
  static Future<String?> registerServiceProvider({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String serviceCenterId,
    required String serviceCenterName,
  }) async {
    FirebaseApp? tempApp;
    try {
      tempApp = await Firebase.initializeApp(
        name: 'ProviderCreation_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final uid = credential.user!.uid;
      await credential.user!.updateDisplayName(fullName.trim());

      final batch = _db.batch();

      batch.set(_db.collection('users').doc(uid), {
        'uid': uid,
        'fullName': fullName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'address': '',
        'dob': '',
        'gender': 'Other',
        'role': 'service_provider',
        'serviceCenterId': serviceCenterId,
        'serviceCenterName': serviceCenterName,
        'activeQueueId': null,
        'activeTokenNumber': null,
        'totalQueuesJoined': 0,
        'notificationsEnabled': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': null,
      });

      batch.set(
        _db.collection('service_centers').doc(serviceCenterId),
        {'assignedProviderUid': uid, 'assignedProviderName': fullName.trim()},
        SetOptions(merge: true),
      );

      await batch.commit();

      await tempAuth.signOut();
      debugPrint('✅ Service provider account created → uid: $uid');
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ registerServiceProvider [${e.code}]: ${e.message}');
      return _authErrorMessage(e.code);
    } on FirebaseException catch (e) {
      debugPrint('❌ Firestore error in registerServiceProvider [${e.code}]: ${e.message}');
      return e.code == 'permission-denied'
          ? 'Blocked by server rules (permission-denied). Check Firestore rules for admin writes to users/service_centers.'
          : 'Could not save the provider account (${e.code}).';
    } catch (e) {
      debugPrint('❌ registerServiceProvider failed: $e');
      return 'Could not create the service provider account.';
    } finally {
      if (tempApp != null) {
        await tempApp.delete();
      }
    }
  }

  /// Unassigns whichever provider is running [serviceCenterId]'s queue.
  /// Leaves their login account intact but clears the center's assignment
  /// (so the provider dashboard will show "not assigned" for them).
  static Future<String?> unassignServiceProvider(String serviceCenterId) async {
    try {
      await _db.collection('service_centers').doc(serviceCenterId).set({
        'assignedProviderUid': null,
        'assignedProviderName': null,
      }, SetOptions(merge: true));
      return null;
    } catch (e) {
      debugPrint('❌ unassignServiceProvider failed: $e');
      return 'Could not unassign the provider.';
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