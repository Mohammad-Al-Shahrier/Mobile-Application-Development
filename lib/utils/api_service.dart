import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// ============================================================
/// API SERVICE — QEasy
///
/// QEasy's data layer (auth, queues, tokens, notifications) all runs
/// directly through Firebase/Firestore — there's no separate backend
/// today. This wrapper exists for the day one is needed (e.g. SMS
/// gateway for token alerts, a payments provider, analytics export)
/// so every screen doesn't grow its own ad-hoc `http.get` calls.
///
/// Requires the `http` package in pubspec.yaml: http: ^1.2.0
/// ============================================================
class ApiService {
  ApiService._();

  static Future<Map<String, dynamic>?> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      debugPrint('❌ ApiService.get [${res.statusCode}]: ${res.body}');
      return null;
    } catch (e) {
      debugPrint('❌ ApiService.get failed: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> post(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', ...?headers},
        body: jsonEncode(body ?? {}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      debugPrint('❌ ApiService.post [${res.statusCode}]: ${res.body}');
      return null;
    } catch (e) {
      debugPrint('❌ ApiService.post failed: $e');
      return null;
    }
  }
}
