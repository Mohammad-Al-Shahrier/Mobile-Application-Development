import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// ============================================================
/// HELPERS — QEasy
///
/// Small shared utility functions used across screens/controllers.
/// ============================================================
class Helpers {
  Helpers._();

  /// Human friendly relative time, e.g. "Just now", "10 min ago".
  /// Mirrors NotificationModel.timeAgo so any screen can format a
  /// raw Timestamp the same way without duplicating the logic.
  static String timeAgo(Timestamp ts) {
    final d = ts.toDate();
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays} day(s) ago';
    return formatDate(d);
  }

  static String formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                     'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  static String formatTime(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Estimated wait, formatted for display (e.g. "~15 mins", "Now serving").
  static String formatWaitEstimate(int positionAhead, {int avgServiceMinutes = 5}) {
    if (positionAhead <= 0) return "You're next!";
    final mins = positionAhead * avgServiceMinutes;
    return '~$mins min${mins == 1 ? '' : 's'}';
  }

  /// Standard floating snackbar used consistently across the app.
  static void showSnack(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  /// Initials from a full name, e.g. "Shahrier Rahman" → "SR".
  static String initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }
}
