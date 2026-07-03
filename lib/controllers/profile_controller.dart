import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import 'auth_controller.dart';

/// ============================================================
/// PROFILE CONTROLLER — QEasy
/// Handles reading/updating the signed-in user's Firestore profile.
/// ============================================================
class ProfileController {
  ProfileController._();

  static final _db = FirebaseFirestore.instance;

  /// Live stream of the logged-in user's Firestore document.
  static Stream<UserModel?> currentUserStream() {
    final uid = AuthController.currentUid;
    if (uid == null) return Stream.value(null);

    return _db.collection('users').doc(uid).snapshots().map(
          (doc) => doc.exists ? UserModel.fromDoc(doc) : null,
        );
  }

  /// Updates editable profile fields. Returns null on success.
  static Future<String?> updateProfile({
    required String fullName,
    String? phone,
    String? address,
  }) async {
    final uid = AuthController.currentUid;
    if (uid == null) return 'You must be logged in.';
    if (fullName.trim().isEmpty) return 'Name cannot be empty.';

    try {
      final update = <String, dynamic>{'fullName': fullName.trim()};
      if (phone != null && phone.trim().isNotEmpty) {
        update['phone'] = phone.trim();
      }
      if (address != null && address.trim().isNotEmpty) {
        update['address'] = address.trim();
      }

      await _db.collection('users').doc(uid).update(update);
      await AuthController.currentUser?.updateDisplayName(fullName.trim());
      return null;
    } catch (e) {
      debugPrint('❌ updateProfile failed: $e');
      return 'Could not update profile. Please try again.';
    }
  }

  /// Toggles the user's notification preference.
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final uid = AuthController.currentUid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).update({
        'notificationsEnabled': enabled,
      });
    } catch (e) {
      debugPrint('❌ setNotificationsEnabled failed: $e');
    }
  }
}
