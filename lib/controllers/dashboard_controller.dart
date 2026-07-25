import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/queue_model.dart';

/// ============================================================
/// DASHBOARD CONTROLLER — QEasy
///
/// Feeds DashboardScreen with real, live `service_centers` data
/// from Firestore (instead of the old hard-coded mock list).
/// ============================================================
class DashboardController {
  DashboardController._();

  static final _db = FirebaseFirestore.instance;

  /// Live stream of every active service center.
  static Stream<List<ServiceCenter>> serviceCentersStream() {
    return _db
        .collection('service_centers')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ServiceCenter.fromDoc(d)).toList());
  }

  /// Client-side filter used by the search bar + category chips.
  static List<ServiceCenter> filterCenters(
    List<ServiceCenter> centers,
    String query, {
    String? category,
  }) {
    Iterable<ServiceCenter> result = centers;
    if (category != null && category.isNotEmpty && category != 'All') {
      result = result.where((c) => c.category == category);
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((c) =>
          c.name.toLowerCase().contains(q) ||
          c.address.toLowerCase().contains(q) ||
          c.category.toLowerCase().contains(q));
    }
    return result.toList();
  }

  /// Populates Firestore with the original demo centers the very first
  /// time the app runs (collection empty). Safe to call on every launch —
  /// it's a no-op once data exists. This is what makes "Nearby Centers"
  /// real Firestore data instead of a local mock list.
  static Future<void> seedServiceCentersIfEmpty() async {
    try {
      final existing = await _db.collection('service_centers').limit(1).get();
      if (existing.docs.isNotEmpty) return;

      final demoCenters = <Map<String, dynamic>>[
        {
          'name': 'United Hospital Limited',
          'category': 'Hospital',
          'address': 'Uttara, Dhaka',
          'rating': 4.8,
          'image': 'assets/images/hospital.jpg',
          'description': 'Modern hospital with emergency support.',
        },
        {
          'name': 'City Bank PLC',
          'category': 'Bank',
          'address': 'Mirpur, Dhaka',
          'rating': 4.9,
          'image': 'assets/images/bank.jpg',
          'description': 'Fast banking service with queue system.',
        },
        {
          'name': 'UrbanBite Cafe',
          'category': 'Cafe',
          'address': 'Banani, Dhaka',
          'rating': 4.7,
          'image': 'assets/images/cafe.jpg',
          'description': 'Popular cafe with online booking.',
        },
        {
          'name': 'Square Hospital',
          'category': 'Hospital',
          'address': 'Panthapath, Dhaka',
          'rating': 4.9,
          'image': 'assets/images/hospital.jpg',
          'description': 'Premium healthcare and appointment system.',
        },
        {
          'name': 'BRAC Bank',
          'category': 'Bank',
          'address': 'Dhanmondi, Dhaka',
          'rating': 4.6,
          'image': 'assets/images/bank.jpg',
          'description': 'Modern banking service and support.',
        },
        {
          'name': 'Cafe Milano',
          'category': 'Cafe',
          'address': 'Gulshan, Dhaka',
          'rating': 4.5,
          'image': 'assets/images/cafe.jpg',
          'description': 'Luxury cafe with reservation system.',
        },
        {
          'name': 'Popular Diagnostic',
          'category': 'Hospital',
          'address': 'Shyamoli, Dhaka',
          'rating': 4.7,
          'image': 'assets/images/hospital.jpg',
          'description': 'Diagnostic and healthcare service.',
        },
      ];

      final batch = _db.batch();
      for (final c in demoCenters) {
        final ref = _db.collection('service_centers').doc();
        batch.set(ref, {
          ...c,
          'isActive': true,
          'avgServiceMinutes': 5,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      debugPrint('✅ Seeded ${demoCenters.length} service centers');
    } catch (e) {
      debugPrint('❌ seedServiceCentersIfEmpty failed: $e');
    }
  }
}
