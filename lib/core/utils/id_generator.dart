import 'dart:math';

/// Generates prefixed, human-readable IDs for PayRoute entities.
///
/// Usage:
///   IdGenerator.generate('PAS') → "PAS-A3F2K9LM"
///   IdGenerator.generate('DRV') → "DRV-X8P2R4QN"
///   IdGenerator.generate('CON') → "CON-B7M1W5YT"
///   IdGenerator.generate('OWN') → "OWN-C4N6D2EJ"
class IdGenerator {
  IdGenerator._();

  static final Random _random = Random.secure();
  static const String _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  /// Generates a prefixed ID: `{prefix}-{8 random uppercase alphanumeric chars}`.
  static String generate(String prefix) {
    final suffix = List.generate(
      8,
      (_) => _chars[_random.nextInt(_chars.length)],
    ).join();
    return '$prefix-$suffix';
  }

  /// Truncates a raw UID to [maxLength] chars and appends '...' for display.
  /// Returns the full ID unchanged when it is shorter than [maxLength].
  static String truncate(String id, {int maxLength = 8}) {
    if (id.length <= maxLength) return id;
    return '${id.substring(0, maxLength)}...';
  }
}
