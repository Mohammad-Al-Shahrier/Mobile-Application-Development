/// ============================================================
/// CONSTANTS — QEasy
///
/// Single source of truth for Firestore collection names, status
/// strings, and role names so they're never typo'd across the
/// controllers/screens as raw literals.
/// ============================================================
class FirestoreCollections {
  FirestoreCollections._();

  static const users = 'users';
  static const serviceCenters = 'service_centers';
  static const queues = 'queues';
  static const tokens = 'tokens';
  static const notifications = 'notifications';
  static const complaints = 'complaints';
}

class TokenStatus {
  TokenStatus._();

  static const waiting = 'Waiting';
  static const serving = 'Serving';
  static const served = 'Served';
  static const skipped = 'Skipped';
  static const cancelled = 'Cancelled';

  static const active = [waiting, serving];
  static const finished = [served, skipped, cancelled];
}

class UserRole {
  UserRole._();

  static const customer = 'customer';
  static const serviceProvider = 'service_provider';
  static const admin = 'admin';
}

class NotificationType {
  NotificationType._();

  static const booked = 'booked';
  static const next = 'next';
  static const serving = 'serving';
  static const served = 'served';
  static const skipped = 'skipped';
  static const cancelled = 'cancelled';
}

class ServiceCenterCategories {
  ServiceCenterCategories._();

  static const all = [
    'Hospital', 'Bank', 'Cafe', 'Restaurant',
    'Government Office', 'Retail Store', 'Salon', 'Other',
  ];
}

class AppConstants {
  AppConstants._();

  static const appName = 'QEasy';
  static const appVersion = '1.0.0';
  static const supportEmail = 'support@qeasy.app';

  /// Fallback average service time (minutes) used when a service center
  /// hasn't set its own `avgServiceMinutes`.
  static const defaultAvgServiceMinutes = 5;
}
