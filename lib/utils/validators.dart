/// ============================================================
/// VALIDATORS — QEasy
///
/// Shared TextFormField validators. Extracted so login, registration,
/// and profile-edit forms all apply the same rules instead of each
/// screen defining its own slightly-different inline closure.
/// ============================================================
class Validators {
  Validators._();

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your email';
    final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? v, {int minLength = 6}) {
    if (v == null || v.isEmpty) return 'Enter a password';
    if (v.length < minLength) return 'At least $minLength characters';
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'Confirm your password';
    if (v != original) return 'Passwords do not match';
    return null;
  }

  static String? requiredField(String? v, {String label = 'This field'}) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? fullName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your full name';
    if (v.trim().length < 2) return 'Name is too short';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter a phone number';
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10) return 'Enter a valid phone number';
    return null;
  }

  static String? dateOfBirth(String? v) {
    if (v == null || v.isEmpty) return 'Select date of birth';
    return null;
  }
}
