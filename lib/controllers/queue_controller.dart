import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/queue_model.dart';
import 'auth_controller.dart';

/// ============================================================
/// QUEUE CONTROLLER — QEasy
///
/// Handles all real Firestore queue/token operations:
///   - Book a ticket           → QueueController.joinQueue(...)
///   - Cancel a ticket         → QueueController.cancelToken(...)
///   - Live "my active ticket" → QueueController.myActiveTokenStream()
///   - Live "my history"       → QueueController.myHistoryStream()
///   - Live queue position     → QueueController.positionAheadStream(...)
///
/// Firestore collections used:
///   queues/{serviceCenterId}   → 1 queue per service center, holds the
///                                 running token-number counter.
///   tokens/{tokenId}           → 1 doc per booking (a user's ticket).
///   notifications/{id}         → created on every ticket event.
/// ============================================================
class QueueController {
  QueueController._();

  static final _db = FirebaseFirestore.instance;

  // ══════════════════════════════════════════════
  //  BOOK A QUEUE (Book Now)
  //  Returns null on success, error message on fail.
  // ══════════════════════════════════════════════
  static Future<String?> joinQueue({
    required String serviceCenterId,
    required String serviceCenterName,
  }) async {
    final uid = AuthController.currentUid;
    if (uid == null) return 'You must be logged in.';

    try {
      // Block double-booking — one active ticket at a time.
      final existing = await _db
          .collection('tokens')
          .where('userId', isEqualTo: uid)
          .where('status', whereIn: ['Waiting', 'Serving'])
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        return 'You already have an active queue. Cancel it before booking another.';
      }

      final userData = await AuthController.getCurrentUserData();
      final userName = (userData?['fullName'] ?? 'Guest').toString();
      final userEmail = (userData?['email'] ?? '').toString();

      final queueRef = _db.collection('queues').doc(serviceCenterId);
      final tokenRef = _db.collection('tokens').doc();
      String tokenNumber = 'T-001';

      await _db.runTransaction((tx) async {
        final queueSnap = await tx.get(queueRef);
        final last = queueSnap.exists
            ? ((queueSnap.data()?['lastTokenNumber'] as int?) ?? 0)
            : 0;
        final next = last + 1;
        tokenNumber = 'T-${next.toString().padLeft(3, '0')}';

        tx.set(
          queueRef,
          {
            'serviceCenterId': serviceCenterId,
            'serviceCenterName': serviceCenterName,
            'lastTokenNumber': next,
            'status': 'open',
            'createdAt': queueSnap.exists
                ? (queueSnap.data()?['createdAt'] ??
                    FieldValue.serverTimestamp())
                : FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        tx.set(tokenRef, {
          'userId': uid,
          'userName': userName,
          'userEmail': userEmail,
          'queueId': serviceCenterId,
          'serviceCenterId': serviceCenterId,
          'serviceCenterName': serviceCenterName,
          'tokenNumber': tokenNumber,
          'status': 'Waiting',
          'createdAt': FieldValue.serverTimestamp(),
          'servedAt': null,
        });

        tx.update(_db.collection('users').doc(uid), {
          'activeQueueId': tokenRef.id,
          'activeTokenNumber': tokenNumber,
          'totalQueuesJoined': FieldValue.increment(1),
        });
      });

      await _addNotification(
        userId: uid,
        title: 'Queue Successfully Booked',
        subtitle: 'Your token $tokenNumber at $serviceCenterName is confirmed.',
        type: 'booked',
      );

      return null;
    } catch (e) {
      debugPrint('❌ joinQueue failed: $e');
      return 'Could not join the queue. Please try again.';
    }
  }

  // ══════════════════════════════════════════════
  //  CANCEL A TICKET
  // ══════════════════════════════════════════════
  static Future<String?> cancelToken(String tokenId) async {
    final uid = AuthController.currentUid;
    if (uid == null) return 'You must be logged in.';

    try {
      final tokenDoc = await _db.collection('tokens').doc(tokenId).get();
      if (!tokenDoc.exists) return 'Ticket not found.';

      final data = tokenDoc.data()!;
      final centerName = (data['serviceCenterName'] ?? '').toString();

      await _db.collection('tokens').doc(tokenId).update({
        'status': 'Cancelled',
      });

      await _db.collection('users').doc(uid).update({
        'activeQueueId': null,
        'activeTokenNumber': null,
      });

      await _addNotification(
        userId: uid,
        title: 'Queue Cancelled',
        subtitle: 'You cancelled your ticket at $centerName.',
        type: 'cancelled',
      );

      return null;
    } catch (e) {
      debugPrint('❌ cancelToken failed: $e');
      return 'Could not cancel the ticket. Please try again.';
    }
  }

  // ══════════════════════════════════════════════
  //  STREAMS
  // ══════════════════════════════════════════════

  /// The signed-in user's current active (Waiting/Serving) ticket, if any.
  static Stream<QueueToken?> myActiveTokenStream() {
    final uid = AuthController.currentUid;
    if (uid == null) return Stream.value(null);

    return _db
        .collection('tokens')
        .where('userId', isEqualTo: uid)
        .where('status', whereIn: ['Waiting', 'Serving'])
        .snapshots()
        .map((s) => s.docs.isEmpty ? null : QueueToken.fromDoc(s.docs.first));
  }

  /// The signed-in user's finished tickets (Served / Skipped / Cancelled),
  /// newest first.
  static Stream<List<QueueToken>> myHistoryStream() {
    final uid = AuthController.currentUid;
    if (uid == null) return Stream.value(const []);

    return _db
        .collection('tokens')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((s) {
      final tokens = s.docs
          .map((d) => QueueToken.fromDoc(d))
          .where((t) => t.isFinished)
          .toList();
      tokens.sort((a, b) => b.createdAtDate.compareTo(a.createdAtDate));
      return tokens;
    });
  }

  /// Live count of how many people are still waiting ahead of [token]
  /// in the same queue (used to show live position + ETA).
  static Stream<int> positionAheadStream(QueueToken token) {
    return _db
        .collection('tokens')
        .where('queueId', isEqualTo: token.queueId)
        .where('status', isEqualTo: 'Waiting')
        .snapshots()
        .map((s) {
      final ahead = s.docs
          .map((d) => QueueToken.fromDoc(d))
          .where((t) => t.createdAtDate.isBefore(token.createdAtDate))
          .length;
      return ahead;
    });
  }

  // ══════════════════════════════════════════════
  //  NOTIFICATIONS
  // ══════════════════════════════════════════════
  static Future<void> _addNotification({
    required String userId,
    required String title,
    required String subtitle,
    required String type,
  }) async {
    try {
      await _db.collection('notifications').add({
        'userId': userId,
        'title': title,
        'subtitle': subtitle,
        'type': type,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ _addNotification failed: $e');
    }
  }
}
