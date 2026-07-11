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

      // Block booking if the provider has paused this center's queue.
      final queueMeta = await _db.collection('queues').doc(serviceCenterId).get();
      if ((queueMeta.data()?['isPaused'] as bool?) == true) {
        return 'This service center is not accepting new tokens right now. Please try again later.';
      }

      final userData = await AuthController.getCurrentUserData();
      final userName = (userData?['fullName'] ?? 'Guest').toString();
      final userEmail = (userData?['email'] ?? '').toString();

      final queueRef = _db.collection('queues').doc(serviceCenterId);
      final tokenRef = _db.collection('tokens').doc();
      String tokenNumber = 'T-001';

      await _db.runTransaction((tx) async {
        final queueSnap = await tx.get(queueRef);
        if ((queueSnap.data()?['isPaused'] as bool?) == true) {
          throw 'This service center is not accepting new tokens right now.';
        }
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
      return e is String ? e : 'Could not join the queue. Please try again.';
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
      if ((data['userId'] ?? '').toString() != uid) {
        return 'You can only cancel your own ticket.';
      }
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
  //  PROVIDER ACTIONS
  //  These drive the *real* live queue: only one ticket
  //  is ever "Serving" per service center at a time.
  // ══════════════════════════════════════════════

  /// Calls the next "Waiting" ticket in for [serviceCenterId], marking it
  /// "Serving". Refuses if another ticket is already being served.
  /// Also notifies the ticket right after it ("You're next in line").
  static Future<String?> callNextToken(String serviceCenterId) async {
    final queueRef = _db.collection('queues').doc(serviceCenterId);
    try {
      final waitingSnap = await _db
          .collection('tokens')
          .where('queueId', isEqualTo: serviceCenterId)
          .where('status', isEqualTo: 'Waiting')
          .orderBy('createdAt')
          .limit(2)
          .get();

      if (waitingSnap.docs.isEmpty) return 'No customers are waiting.';

      final nextDoc = waitingSnap.docs.first;
      final nextData = nextDoc.data();
      final nextTokenRef = _db.collection('tokens').doc(nextDoc.id);

      await _db.runTransaction((tx) async {
        final queueSnap = await tx.get(queueRef);
        final tokenSnap = await tx.get(nextTokenRef);

        final alreadyServing =
            queueSnap.data()?['currentServingTokenId'] as String?;
        if (alreadyServing != null) {
          throw 'A ticket is already being served. Complete or skip it first.';
        }
        if (!tokenSnap.exists || tokenSnap.data()?['status'] != 'Waiting') {
          throw 'That ticket is no longer waiting — try again.';
        }

        tx.update(nextTokenRef, {
          'status': 'Serving',
          'calledAt': FieldValue.serverTimestamp(),
        });
        tx.set(
          queueRef,
          {
            'currentServingTokenId': nextDoc.id,
            'currentServingTokenNumber': nextData['tokenNumber'],
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      await _addNotification(
        userId: (nextData['userId'] ?? '').toString(),
        title: "It's Your Turn!",
        subtitle:
            'Token ${nextData['tokenNumber']} — please proceed to the counter now.',
        type: 'serving',
      );

      // Give the person right after a heads-up.
      if (waitingSnap.docs.length > 1) {
        final upcoming = waitingSnap.docs[1].data();
        await _addNotification(
          userId: (upcoming['userId'] ?? '').toString(),
          title: "You're Next in Line",
          subtitle:
              'Token ${upcoming['tokenNumber']} — please be ready, you will be called shortly.',
          type: 'next',
        );
      }

      return null;
    } catch (e) {
      debugPrint('❌ callNextToken failed: $e');
      return e is String ? e : 'Could not call the next token. Please try again.';
    }
  }

  /// Marks the ticket currently "Serving" at [serviceCenterId] as "Served".
  static Future<String?> completeCurrentToken(String serviceCenterId) =>
      _resolveCurrentToken(serviceCenterId, newStatus: 'Served');

  /// Marks the ticket currently "Serving" at [serviceCenterId] as "Skipped"
  /// (customer no-show).
  static Future<String?> skipCurrentToken(String serviceCenterId) =>
      _resolveCurrentToken(serviceCenterId, newStatus: 'Skipped');

  static Future<String?> _resolveCurrentToken(
    String serviceCenterId, {
    required String newStatus,
  }) async {
    final queueRef = _db.collection('queues').doc(serviceCenterId);
    try {
      String? resolvedUserId;
      String? resolvedTokenNumber;

      await _db.runTransaction((tx) async {
        final queueSnap = await tx.get(queueRef);
        final currentId = queueSnap.data()?['currentServingTokenId'] as String?;
        if (currentId == null) {
          throw 'No one is currently being served.';
        }

        final tokenRef = _db.collection('tokens').doc(currentId);
        final tokenSnap = await tx.get(tokenRef);
        if (!tokenSnap.exists) throw 'Ticket not found.';

        final data = tokenSnap.data()!;
        resolvedUserId = (data['userId'] ?? '').toString();
        resolvedTokenNumber = (data['tokenNumber'] ?? '').toString();

        tx.update(tokenRef, {
          'status': newStatus,
          if (newStatus == 'Served') 'servedAt': FieldValue.serverTimestamp(),
        });

        tx.set(
          queueRef,
          {
            'currentServingTokenId': null,
            'currentServingTokenNumber': null,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        if (resolvedUserId != null && resolvedUserId!.isNotEmpty) {
          tx.update(_db.collection('users').doc(resolvedUserId), {
            'activeQueueId': null,
            'activeTokenNumber': null,
          });
        }
      });

      if (resolvedUserId != null && resolvedUserId!.isNotEmpty) {
        await _addNotification(
          userId: resolvedUserId!,
          title: newStatus == 'Served' ? 'Service Completed' : 'Ticket Skipped',
          subtitle: newStatus == 'Served'
              ? 'Token $resolvedTokenNumber has been served. Thank you for using QEasy!'
              : 'Token $resolvedTokenNumber was skipped. Please rebook if you still need service.',
          type: newStatus == 'Served' ? 'served' : 'skipped',
        );
      }

      return null;
    } catch (e) {
      debugPrint('❌ _resolveCurrentToken failed: $e');
      return e is String ? e : 'Could not update the ticket. Please try again.';
    }
  }

  /// Pauses/resumes a service center's live queue. While paused, customers
  /// cannot book new tokens (joinQueue is blocked).
  static Future<String?> setQueuePaused(
    String serviceCenterId,
    bool paused,
  ) async {
    try {
      await _db.collection('queues').doc(serviceCenterId).set(
        {'isPaused': paused, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      await _db.collection('service_centers').doc(serviceCenterId).set(
        {'isPaused': paused},
        SetOptions(merge: true),
      );
      return null;
    } catch (e) {
      debugPrint('❌ setQueuePaused failed: $e');
      return 'Could not update the queue status.';
    }
  }

  /// Rough ETA in minutes for someone [positionAhead] people back in line.
  static int estimateWaitMinutes({
    required int positionAhead,
    int avgServiceMinutes = 5,
  }) =>
      positionAhead * avgServiceMinutes;

  // ══════════════════════════════════════════════
  //  REAL-LIFE QUEUE MANAGEMENT (provider-driven)
  // ══════════════════════════════════════════════

  /// Adds a ticket for someone who walked in without using the app
  /// (no `userId` — every real queue has these). Skips the pause check
  /// since the provider is the one adding it, in person.
  static Future<String?> addWalkInToken({
    required String serviceCenterId,
    required String serviceCenterName,
    required String walkInName,
    String phone = '',
  }) async {
    if (walkInName.trim().isEmpty) return "Enter the customer's name.";
    final queueRef = _db.collection('queues').doc(serviceCenterId);
    final tokenRef = _db.collection('tokens').doc();
    try {
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
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        tx.set(tokenRef, {
          'userId': '',
          'userName': walkInName.trim(),
          'userEmail': phone.trim(),
          'isWalkIn': true,
          'queueId': serviceCenterId,
          'serviceCenterId': serviceCenterId,
          'serviceCenterName': serviceCenterName,
          'tokenNumber': tokenNumber,
          'status': 'Waiting',
          'createdAt': FieldValue.serverTimestamp(),
          'servedAt': null,
        });
      });
      return null;
    } catch (e) {
      debugPrint('❌ addWalkInToken failed: $e');
      return 'Could not add the walk-in customer.';
    }
  }

  /// Provider/admin cancelling a ticket on a customer's behalf (e.g. they
  /// called ahead to cancel). Unlike [cancelToken], this doesn't require
  /// the caller to be the ticket's own customer.
  static Future<String?> cancelTokenAsProvider(String tokenId) async {
    try {
      final tokenRef = _db.collection('tokens').doc(tokenId);
      final tokenDoc = await tokenRef.get();
      if (!tokenDoc.exists) return 'Ticket not found.';

      final data = tokenDoc.data()!;
      if (data['status'] != 'Waiting' && data['status'] != 'Serving') {
        return 'This ticket is already finished.';
      }

      final customerId = (data['userId'] ?? '').toString();
      final centerName = (data['serviceCenterName'] ?? '').toString();
      final tokenNumber = (data['tokenNumber'] ?? '').toString();
      final wasServing = data['status'] == 'Serving';

      await tokenRef.update({'status': 'Cancelled'});

      if (wasServing) {
        await _db.collection('queues').doc(data['queueId']).set(
          {'currentServingTokenId': null, 'currentServingTokenNumber': null},
          SetOptions(merge: true),
        );
      }

      if (customerId.isNotEmpty) {
        await _db.collection('users').doc(customerId).update({
          'activeQueueId': null,
          'activeTokenNumber': null,
        });
        await _addNotification(
          userId: customerId,
          title: 'Ticket Cancelled',
          subtitle:
              'Your token $tokenNumber at $centerName was cancelled by the service provider.',
          type: 'cancelled',
        );
      }
      return null;
    } catch (e) {
      debugPrint('❌ cancelTokenAsProvider failed: $e');
      return 'Could not cancel the ticket.';
    }
  }

  /// Recalls a "Skipped" (no-show) ticket back into the waiting line — it
  /// rejoins at the *back* of the current line, same as arriving fresh.
  static Future<String?> recallSkippedToken(String tokenId) async {
    try {
      final tokenRef = _db.collection('tokens').doc(tokenId);
      final tokenDoc = await tokenRef.get();
      if (!tokenDoc.exists) return 'Ticket not found.';
      final data = tokenDoc.data()!;
      if (data['status'] != 'Skipped') {
        return 'Only skipped tickets can be recalled.';
      }

      await tokenRef.update({
        'status': 'Waiting',
        'createdAt': FieldValue.serverTimestamp(),
        'calledAt': null,
      });

      final customerId = (data['userId'] ?? '').toString();
      if (customerId.isNotEmpty) {
        await _db.collection('users').doc(customerId).update({
          'activeQueueId': tokenId,
          'activeTokenNumber': data['tokenNumber'],
        });
        await _addNotification(
          userId: customerId,
          title: "You're Back in the Queue",
          subtitle: 'Token ${data['tokenNumber']} has been added back to the waiting list.',
          type: 'booked',
        );
      }
      return null;
    } catch (e) {
      debugPrint('❌ recallSkippedToken failed: $e');
      return 'Could not recall the ticket.';
    }
  }

  /// Today's "Skipped" tickets at [serviceCenterId] — lets the provider
  /// recall a no-show if the customer turns up late.
  static Stream<List<QueueToken>> skippedTodayStream(String serviceCenterId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _db
        .collection('tokens')
        .where('queueId', isEqualTo: serviceCenterId)
        .where('status', isEqualTo: 'Skipped')
        .snapshots()
        .map((s) {
      final list = s.docs
          .map((d) => QueueToken.fromDoc(d))
          .where((t) => t.createdAtDate.isAfter(startOfDay))
          .toList();
      list.sort((a, b) => b.createdAtDate.compareTo(a.createdAtDate));
      return list;
    });
  }

  /// Today's finished tickets (Served/Skipped/Cancelled) at
  /// [serviceCenterId], newest first — the provider's activity log.
  static Stream<List<QueueToken>> centerHistoryTodayStream(String serviceCenterId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _db
        .collection('tokens')
        .where('queueId', isEqualTo: serviceCenterId)
        .snapshots()
        .map((s) {
      final list = s.docs
          .map((d) => QueueToken.fromDoc(d))
          .where((t) => t.isFinished && t.createdAtDate.isAfter(startOfDay))
          .toList();
      list.sort((a, b) => b.createdAtDate.compareTo(a.createdAtDate));
      return list;
    });
  }

  /// Lets a provider edit their own center's public listing details.
  static Future<String?> updateCenterDetails({
    required String centerId,
    required String name,
    required String category,
    required String address,
    required String description,
    required int avgServiceMinutes,
  }) async {
    try {
      await _db.collection('service_centers').doc(centerId).update({
        'name': name.trim(),
        'category': category,
        'address': address.trim(),
        'description': description.trim(),
        'avgServiceMinutes': avgServiceMinutes,
      });
      // Keep the queue doc's display name in sync (used in notifications).
      await _db.collection('queues').doc(centerId).set(
        {'serviceCenterName': name.trim()},
        SetOptions(merge: true),
      );
      return null;
    } catch (e) {
      debugPrint('❌ updateCenterDetails failed: $e');
      return 'Could not update your center details.';
    }
  }

  /// Live stream of a single service center's document — used to prefill
  /// the provider's "Edit Center Details" form.
  static Stream<ServiceCenter?> serviceCenterStream(String centerId) {
    return _db
        .collection('service_centers')
        .doc(centerId)
        .snapshots()
        .map((d) => d.exists ? ServiceCenter.fromDoc(d) : null);
  }

  // ══════════════════════════════════════════════
  //  STREAMS
  // ══════════════════════════════════════════════

  /// Live metadata for a service center's queue doc (isPaused,
  /// currentServingTokenNumber, etc). Used by the provider dashboard.
  static Stream<Map<String, dynamic>?> queueMetaStream(String serviceCenterId) {
    return _db
        .collection('queues')
        .doc(serviceCenterId)
        .snapshots()
        .map((d) => d.data());
  }

  /// The ticket currently being served at [serviceCenterId], if any.
  static Stream<QueueToken?> currentServingStream(String serviceCenterId) {
    return _db
        .collection('tokens')
        .where('queueId', isEqualTo: serviceCenterId)
        .where('status', isEqualTo: 'Serving')
        .snapshots()
        .map((s) => s.docs.isEmpty ? null : QueueToken.fromDoc(s.docs.first));
  }

  /// All "Waiting" tickets at [serviceCenterId], oldest first.
  static Stream<List<QueueToken>> waitingListStream(String serviceCenterId) {
    return _db
        .collection('tokens')
        .where('queueId', isEqualTo: serviceCenterId)
        .where('status', isEqualTo: 'Waiting')
        .snapshots()
        .map((s) {
      final list = s.docs.map((d) => QueueToken.fromDoc(d)).toList();
      list.sort((a, b) => a.createdAtDate.compareTo(b.createdAtDate));
      return list;
    });
  }

  /// Count of tickets served today at [serviceCenterId] — provider stats.
  static Stream<int> servedTodayCountStream(String serviceCenterId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _db
        .collection('tokens')
        .where('queueId', isEqualTo: serviceCenterId)
        .where('status', isEqualTo: 'Served')
        .snapshots()
        .map((s) => s.docs.where((d) {
              final ts = d.data()['servedAt'];
              return ts is Timestamp && ts.toDate().isAfter(startOfDay);
            }).length);
  }

  // ══════════════════════════════════════════════
  //  STREAMS (customer-facing)
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
    if (userId.isEmpty) return; // Walk-in ticket — no account to notify.
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
