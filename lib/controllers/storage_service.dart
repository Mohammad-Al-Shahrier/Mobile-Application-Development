import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// ============================================================
/// STORAGE SERVICE — QEasy
///
/// Thin wrapper around Firebase Storage. Currently used for profile
/// photo uploads (users/{uid}/profile.jpg) — QEasy previously only
/// showed initials, this lets a real photo replace that avatar.
///
/// Requires the `firebase_storage` package in pubspec.yaml:
///   firebase_storage: ^12.0.0
/// ============================================================
class StorageService {
  StorageService._();

  static final _storage = FirebaseStorage.instance;

  /// Uploads [file] as the given user's profile photo and returns its
  /// public download URL, or null on failure.
  static Future<String?> uploadProfilePhoto({
    required String uid,
    required File file,
  }) async {
    try {
      final ref = _storage.ref().child('users/$uid/profile.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('❌ uploadProfilePhoto failed: $e');
      return null;
    }
  }

  /// Deletes a user's profile photo, if one exists. Safe to call even if
  /// no photo was ever uploaded.
  static Future<void> deleteProfilePhoto(String uid) async {
    try {
      await _storage.ref().child('users/$uid/profile.jpg').delete();
    } catch (e) {
      // No-op if the file never existed.
      debugPrint('ℹ️ deleteProfilePhoto: $e');
    }
  }

  /// Generic upload helper for any future file (e.g. provider verification
  /// documents), stored under [path], returning its download URL.
  static Future<String?> uploadFile({
    required String path,
    required File file,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('❌ uploadFile failed: $e');
      return null;
    }
  }
}
