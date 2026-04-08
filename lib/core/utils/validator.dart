/// Form validators for PayRoute registration flows.
///
/// All validators return null on success or an error string on failure.
/// Designed for use with [TextFormField.validator].
class PayRouteValidator {
  PayRouteValidator._();

  // ─── NIC ─────────────────────────────────────────────────────────────────────
  /// Sri Lankan NIC: 9 digits + V/X  OR  12 digits.
  /// Example valid: "123456789V" | "200012345678"
  static String? nic(String? value) {
    if (value == null || value.trim().isEmpty) return 'NIC is required';
    final old = RegExp(r'^\d{9}[VvXx]$');
    final newNic = RegExp(r'^\d{12}$');
    if (!old.hasMatch(value.trim()) && !newNic.hasMatch(value.trim())) {
      return 'Enter a valid NIC (e.g. 123456789V or 200012345678)';
    }
    return null;
  }

  /// Optional NIC — only validates format if value is non-empty.
  static String? nicOptional(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return nic(value);
  }

  // ─── Phone ───────────────────────────────────────────────────────────────────
  /// Sri Lankan phone: 10 digits starting with 07.
  /// Example valid: "0712345678"
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    if (!RegExp(r'^07\d{8}$').hasMatch(value.trim())) {
      return 'Enter a valid phone number (e.g. 0712345678)';
    }
    return null;
  }

  /// Optional phone — only validates format if non-empty.
  static String? phoneOptional(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return phone(value);
  }

  // ─── General ─────────────────────────────────────────────────────────────────
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? minLength(String? value, int min, String fieldName) {
    if (value == null || value.trim().length < min) {
      return '$fieldName must be at least $min characters';
    }
    return null;
  }

  static String? requiredMinLength(String? value, int min, String fieldName) {
    final req = required(value, fieldName);
    if (req != null) return req;
    return minLength(value, min, fieldName);
  }

  // ─── License ─────────────────────────────────────────────────────────────────
  /// Sri Lankan driving license — basic format check.
  static String? licenseNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'License number is required';
    if (value.trim().length < 6) return 'Enter a valid license number';
    return null;
  }

  // ─── Vehicle Number ───────────────────────────────────────────────────────────
  /// Sri Lankan vehicle number — letters, digits and hyphens/spaces.
  static String? vehicleNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vehicle number is required';
    if (!RegExp(r'^[A-Za-z0-9\- ]{4,15}$').hasMatch(value.trim())) {
      return 'Enter a valid vehicle number (e.g. WP NC-1234)';
    }
    return null;
  }
}
