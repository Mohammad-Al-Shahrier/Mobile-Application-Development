import 'package:cloud_firestore/cloud_firestore.dart';

/// ============================================================
/// USER MODEL — QEasy
///
/// Represents a registered user in the QEasy queue management
/// system. Three roles: customer, service_provider, admin.
///
/// Firestore collection: `users/{uid}`
/// ============================================================
class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String dob;
  final String gender;

  /// Role: 'customer' | 'service_provider' | 'admin'
  final String role;

  /// Service center this user belongs to (service providers only)
  final String serviceCenterId;
  final String serviceCenterName;

  /// Current active queue token (null if not in any queue)
  final String? activeQueueId;
  final String? activeTokenNumber;

  /// Queue history count
  final int totalQueuesJoined;

  /// Notification preference
  final bool notificationsEnabled;

  /// Account timestamps
  final Timestamp createdAt;
  final Timestamp? lastLoginAt;

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.dob,
    required this.gender,
    this.role = 'customer',
    this.serviceCenterId = '',
    this.serviceCenterName = '',
    this.activeQueueId,
    this.activeTokenNumber,
    this.totalQueuesJoined = 0,
    this.notificationsEnabled = true,
    required this.createdAt,
    this.lastLoginAt,
  });

  // ── Firestore → Model ──────────────────────────────────────
  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid:                 doc.id,
      fullName:            (d['fullName']           ?? '').toString(),
      email:               (d['email']              ?? '').toString(),
      phone:               (d['phone']              ?? '').toString(),
      address:             (d['address']            ?? '').toString(),
      dob:                 (d['dob']                ?? '').toString(),
      gender:              (d['gender']             ?? 'Male').toString(),
      role:                (d['role']               ?? 'customer').toString(),
      serviceCenterId:     (d['serviceCenterId']    ?? '').toString(),
      serviceCenterName:   (d['serviceCenterName']  ?? '').toString(),
      activeQueueId:       d['activeQueueId']       as String?,
      activeTokenNumber:   d['activeTokenNumber']   as String?,
      totalQueuesJoined:   (d['totalQueuesJoined']  as int?) ?? 0,
      notificationsEnabled:(d['notificationsEnabled'] as bool?) ?? true,
      createdAt:           d['createdAt'] is Timestamp
                             ? d['createdAt'] as Timestamp
                             : Timestamp.now(),
      lastLoginAt:         d['lastLoginAt'] as Timestamp?,
    );
  }

  // ── Model → Firestore ──────────────────────────────────────
  Map<String, dynamic> toMap() => {
    'uid':                  uid,
    'fullName':             fullName,
    'email':                email,
    'phone':                phone,
    'address':              address,
    'dob':                  dob,
    'gender':               gender,
    'role':                 role,
    'serviceCenterId':      serviceCenterId,
    'serviceCenterName':    serviceCenterName,
    'activeQueueId':        activeQueueId,
    'activeTokenNumber':    activeTokenNumber,
    'totalQueuesJoined':    totalQueuesJoined,
    'notificationsEnabled': notificationsEnabled,
    'createdAt':            createdAt,
    'lastLoginAt':          lastLoginAt,
  };

  // ── Convenience helpers ────────────────────────────────────
  bool get isCustomer        => role == 'customer';
  bool get isServiceProvider => role == 'service_provider';
  bool get isAdmin           => role == 'admin';
  bool get isInQueue         => activeQueueId != null;

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
  }

  // ── CopyWith ──────────────────────────────────────────────
  UserModel copyWith({
    String? fullName,
    String? phone,
    String? address,
    String? dob,
    String? gender,
    String? role,
    String? serviceCenterId,
    String? serviceCenterName,
    String? activeQueueId,
    String? activeTokenNumber,
    int?    totalQueuesJoined,
    bool?   notificationsEnabled,
    Timestamp? lastLoginAt,
  }) {
    return UserModel(
      uid:                  uid,
      fullName:             fullName             ?? this.fullName,
      email:                email,
      phone:                phone                ?? this.phone,
      address:              address              ?? this.address,
      dob:                  dob                  ?? this.dob,
      gender:               gender               ?? this.gender,
      role:                 role                 ?? this.role,
      serviceCenterId:      serviceCenterId      ?? this.serviceCenterId,
      serviceCenterName:    serviceCenterName    ?? this.serviceCenterName,
      activeQueueId:        activeQueueId        ?? this.activeQueueId,
      activeTokenNumber:    activeTokenNumber    ?? this.activeTokenNumber,
      totalQueuesJoined:    totalQueuesJoined    ?? this.totalQueuesJoined,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt:            createdAt,
      lastLoginAt:          lastLoginAt          ?? this.lastLoginAt,
    );
  }

  @override
  String toString() => 'UserModel(uid: $uid, name: $fullName, role: $role)';
}