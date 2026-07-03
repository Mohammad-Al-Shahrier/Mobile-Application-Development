import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// ============================================================
/// NOTIFICATION MODEL — QEasy
/// Firestore collection: `notifications/{id}`
/// Created automatically by QueueController whenever something
/// happens to a user's ticket (booked, next-in-line, cancelled...).
/// ============================================================
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String subtitle;

  /// 'booked' | 'next' | 'serving' | 'served' | 'skipped' | 'cancelled'
  final String type;
  final bool isRead;
  final Timestamp createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.subtitle,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationModel(
      id: doc.id,
      userId: (d['userId'] ?? '').toString(),
      title: (d['title'] ?? '').toString(),
      subtitle: (d['subtitle'] ?? '').toString(),
      type: (d['type'] ?? 'info').toString(),
      isRead: (d['isRead'] as bool?) ?? false,
      createdAt: d['createdAt'] is Timestamp
          ? d['createdAt'] as Timestamp
          : Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'subtitle': subtitle,
        'type': type,
        'isRead': isRead,
        'createdAt': createdAt,
      };

  IconData get icon {
    switch (type) {
      case 'booked':
        return Icons.check_circle;
      case 'next':
        return Icons.notifications_active;
      case 'serving':
        return Icons.sync;
      case 'served':
        return Icons.done_all;
      case 'skipped':
        return Icons.error_outline;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (type) {
      case 'booked':
        return const Color(0xFF2563EB);
      case 'next':
        return const Color(0xFF16A34A);
      case 'serving':
        return const Color(0xFFF59E0B);
      case 'served':
        return const Color(0xFF16A34A);
      case 'skipped':
        return const Color(0xFFEF4444);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF9333EA);
    }
  }

  /// Human friendly relative time, e.g. "Just now", "10 min ago".
  String get timeAgo {
    final d = createdAt.toDate();
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day(s) ago';
  }
}
