import 'package:flutter/material.dart';

/// ============================================================
/// APP THEME — QEasy
///
/// Centralizes the colors/gradients that were previously copy-pasted
/// as raw `Color(0xFF....)` literals across every screen. Existing
/// screens keep working unmodified — new/edited screens should pull
/// from here instead of hardcoding hex values again.
/// ============================================================
class AppTheme {
  AppTheme._();

  // ── Brand ──────────────────────────────────────
  static const primary   = Color(0xFF0047B3);
  static const secondary = Color(0xFFB65AD8);
  static const accentBlue = Color(0xFF109DFF);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const horizontalGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, secondary],
  );

  // ── Status colors (mirrors NotificationModel + token status) ──
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger  = Color(0xFFEF4444);
  static const info    = Color(0xFF2563EB);
  static const purple  = Color(0xFF9333EA);

  // ── Admin / provider dark dashboard palette ────
  static const darkBg0   = Color(0xFF0D1117);
  static const darkBg1   = Color(0xFF161B22);
  static const darkBorder = Color(0xFF30363D);
  static const darkAccent = Color(0xFF3B82F6);

  static Color statusColor(String status) {
    switch (status) {
      case 'Served':
        return success;
      case 'Cancelled':
      case 'Skipped':
        return danger;
      case 'Serving':
        return warning;
      default:
        return info;
    }
  }

  static ThemeData themeData() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primary,
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(seedColor: primary),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
            color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
