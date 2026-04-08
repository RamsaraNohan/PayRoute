import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

/// Retrieves device identification info for fraud prevention.
/// Stored in [users/] and individual role documents during registration.
class DeviceInfoUtil {
  DeviceInfoUtil._();

  static final DeviceInfoPlugin _plugin = DeviceInfoPlugin();

  /// Returns a map with `deviceId` and `deviceModel`.
  /// Falls back to `"unknown"` if retrieval fails.
  static Future<Map<String, String>> getInfo() async {
    try {
      if (Platform.isAndroid) {
        final info = await _plugin.androidInfo;
        return {
          'deviceId': info.id,
          'deviceModel': '${info.brand} ${info.model}',
        };
      } else if (Platform.isIOS) {
        final info = await _plugin.iosInfo;
        return {
          'deviceId': info.identifierForVendor ?? 'unknown',
          'deviceModel': info.utsname.machine,
        };
      }
    } catch (_) {}
    return {
      'deviceId': 'unknown',
      'deviceModel': 'unknown',
    };
  }
}
