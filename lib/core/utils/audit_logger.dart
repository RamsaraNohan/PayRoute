import 'package:cloud_firestore/cloud_firestore.dart';

/// Writes immutable audit trail entries to `activityLogs/`.
///
/// Used throughout the app to track key user actions.
/// The collection has no client read permission (write-only from client).
///
/// Standard action strings:
///   "LOGIN"
///   "REGISTER_NEW_USER"
///   "REGISTER_PASSENGER"
///   "REGISTER_DRIVER"
///   "REGISTER_CONDUCTOR"
///   "REGISTER_OWNER"
///   "TOP_UP"
///   "BOARD_BUS"
///   "SIGNAL_DROP"
///   "FILE_COMPLAINT"
///   "ACCEPT_STAFF_INVITE"
///   "ROLE_SWITCH"
class AuditLogger {
  AuditLogger._();

  /// Writes a log entry. Silently swallows errors — logging must never crash the app.
  static Future<void> log(
    String userId,
    String action, [
    Map<String, dynamic>? metadata,
  ]) async {
    try {
      await FirebaseFirestore.instance.collection('activityLogs').add({
        'userId': userId,
        'action': action,
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Never let audit logging crash the app flow
    }
  }
}
