/// ============================================================
/// CONSTANTS — QEasy
/// ============================================================
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
