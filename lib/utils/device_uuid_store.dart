import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// banglamed device tracking cookie key: `_gns-ddt`
/// Backend এ request()->cookie('_gns-ddt') দিয়ে device identify করা হচ্ছে।
class DeviceUuidStore {
  static const _key = 'device_uuid';

  static Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.trim().isNotEmpty) return existing.trim();

    final stableId = await _getStablePlatformId();
    if (stableId != null && stableId.trim().isNotEmpty) {
      await prefs.setString(_key, stableId.trim());
      return stableId.trim();
    }

    final uuid = _generateUuidV4();
    await prefs.setString(_key, uuid);
    return uuid;
  }

  static Future<String?> _getStablePlatformId() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        return android.id;
      }
      if (Platform.isIOS) {
        final ios = await info.iosInfo;
        return ios.identifierForVendor;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// UUID v4 generator (dependency ছাড়াই)
  static String _generateUuidV4() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));

    // version: 4
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // variant: 10xx
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int i) => i.toRadixString(16).padLeft(2, '0');
    final b = bytes.map(hex).join();

    return '${b.substring(0, 8)}-'
        '${b.substring(8, 12)}-'
        '${b.substring(12, 16)}-'
        '${b.substring(16, 20)}-'
        '${b.substring(20)}';
  }
}
