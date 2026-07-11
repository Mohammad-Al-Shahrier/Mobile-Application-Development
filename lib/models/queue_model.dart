import 'package:cloud_firestore/cloud_firestore.dart';

/// ============================================================
/// QUEUE MODELS — QEasy
///
/// QueueToken  → Firestore collection `tokens/{id}`
///               One document per booking/ticket a user holds.
///               Lifecycle: Waiting → Serving → Served / Skipped
///               (or → Cancelled if the user cancels).
///
/// ServiceCenter → Firestore collection `service_centers/{id}`
///               A bookable place (hospital, bank, cafe, etc).
/// ============================================================

class QueueToken {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;

  /// The queue this token belongs to. In this app one queue == one
  /// service center, so queueId == serviceCenterId.
  final String queueId;
  final String serviceCenterId;
  final String serviceCenterName;

  /// Human friendly ticket number, e.g. "T-007"
  final String tokenNumber;

  /// 'Waiting' | 'Serving' | 'Served' | 'Skipped' | 'Cancelled'
  final String status;

  final Timestamp createdAt;

  /// Set the moment a provider calls this ticket in ("Waiting" → "Serving").
  final Timestamp? calledAt;
  final Timestamp? servedAt;

  /// True for tickets a provider added manually for a walk-in customer
  /// who doesn't have (or isn't using) the app — no `userId` behind these.
  final bool isWalkIn;

  const QueueToken({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.queueId,
    required this.serviceCenterId,
    required this.serviceCenterName,
    required this.tokenNumber,
    required this.status,
    required this.createdAt,
    this.calledAt,
    this.servedAt,
    this.isWalkIn = false,
  });

  factory QueueToken.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return QueueToken(
      id: doc.id,
      userId: (d['userId'] ?? '').toString(),
      userName: (d['userName'] ?? '').toString(),
      userEmail: (d['userEmail'] ?? '').toString(),
      queueId: (d['queueId'] ?? '').toString(),
      serviceCenterId: (d['serviceCenterId'] ?? '').toString(),
      serviceCenterName: (d['serviceCenterName'] ?? '').toString(),
      tokenNumber: (d['tokenNumber'] ?? '').toString(),
      status: (d['status'] ?? 'Waiting').toString(),
      createdAt: d['createdAt'] is Timestamp
          ? d['createdAt'] as Timestamp
          : Timestamp.now(),
      calledAt: d['calledAt'] as Timestamp?,
      servedAt: d['servedAt'] as Timestamp?,
      isWalkIn: (d['isWalkIn'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'queueId': queueId,
        'serviceCenterId': serviceCenterId,
        'serviceCenterName': serviceCenterName,
        'tokenNumber': tokenNumber,
        'status': status,
        'createdAt': createdAt,
        'calledAt': calledAt,
        'servedAt': servedAt,
        'isWalkIn': isWalkIn,
      };

  bool get isWaiting => status == 'Waiting';
  bool get isServing => status == 'Serving';
  bool get isActive => isWaiting || isServing;
  bool get isFinished =>
      status == 'Served' || status == 'Skipped' || status == 'Cancelled';

  DateTime get createdAtDate => createdAt.toDate();
}

class ServiceCenter {
  final String id;
  final String name;
  final String category;
  final String address;
  final double rating;

  /// Local asset path (kept from the original mock data) or a network URL.
  final String image;
  final String description;
  final bool isActive;

  /// Rough average minutes spent serving one customer — used to estimate
  /// wait time for people in the queue.
  final int avgServiceMinutes;

  /// True when the assigned service provider has paused the live queue
  /// (e.g. on a break, closed for the day). New bookings are blocked.
  final bool isPaused;

  /// The service provider (role == 'service_provider') currently assigned
  /// to run this center's queue, if any.
  final String? assignedProviderUid;
  final String? assignedProviderName;

  const ServiceCenter({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.rating,
    required this.image,
    required this.description,
    this.isActive = true,
    this.avgServiceMinutes = 5,
    this.isPaused = false,
    this.assignedProviderUid,
    this.assignedProviderName,
  });

  factory ServiceCenter.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return ServiceCenter(
      id: doc.id,
      name: (d['name'] ?? '').toString(),
      category: (d['category'] ?? '').toString(),
      address: (d['address'] ?? '').toString(),
      rating: (d['rating'] is num) ? (d['rating'] as num).toDouble() : 4.5,
      image: (d['image'] ?? 'assets/images/hospital.jpg').toString(),
      description: (d['description'] ?? '').toString(),
      isActive: (d['isActive'] as bool?) ?? true,
      avgServiceMinutes: (d['avgServiceMinutes'] as int?) ?? 5,
      isPaused: (d['isPaused'] as bool?) ?? false,
      assignedProviderUid: d['assignedProviderUid'] as String?,
      assignedProviderName: d['assignedProviderName'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'address': address,
        'rating': rating,
        'image': image,
        'description': description,
        'isActive': isActive,
        'avgServiceMinutes': avgServiceMinutes,
        'isPaused': isPaused,
        'assignedProviderUid': assignedProviderUid,
        'assignedProviderName': assignedProviderName,
      };

  bool get hasProvider => assignedProviderUid != null;
}
