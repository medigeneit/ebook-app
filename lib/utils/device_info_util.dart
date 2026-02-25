import 'dart:io';
import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceInfoUtil {
  static const String _keyDeviceInfo = 'device_info';
  static const String _keyDeviceId = 'device_id';
  static const String _keyPlatform = 'platform';

  static Future<void> saveDeviceInfo() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    const androidIdPlugin = AndroidId();
    String deviceId = 'unknown';
    String deviceInfo = 'unknown';
    String platform = 'unknown';

    final packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        final androidId = await androidIdPlugin.getId();
        deviceId = (androidId != null && androidId.trim().isNotEmpty)
            ? androidId.trim()
            : 'unknown';
        deviceInfo =
            '${androidInfo.manufacturer}/${androidInfo.model}/Android_${androidInfo.version.release}/$version';
        platform = 'Android';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
        deviceInfo =
            '${iosInfo.name}/${iosInfo.model}/iOS_${iosInfo.systemVersion}/$version';
        platform = 'iOS';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfoPlugin.macOsInfo;
        deviceId = macInfo.systemGUID ?? 'unknown';
        deviceInfo = '${macInfo.model}/macOS ${macInfo.osRelease}/$version';
        platform = 'macOS';
      } else if (Platform.isWindows) {
        final winInfo = await deviceInfoPlugin.windowsInfo;
        deviceId = winInfo.deviceId ?? 'unknown';
        deviceInfo =
            '${winInfo.computerName}/Windows_${winInfo.productName}/$version';
        platform = 'Windows';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfoPlugin.linuxInfo;
        deviceId = linuxInfo.machineId ?? 'unknown';
        deviceInfo = '${linuxInfo.name}/Linux_${linuxInfo.version}/$version';
        platform = 'Linux';
      }
    } catch (e) {
      debugPrint('Device info error: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDeviceId, deviceId);
    await prefs.setString(_keyDeviceInfo, deviceInfo);
    await prefs.setString(_keyPlatform, platform);

    debugPrint('Platform: $platform');
    debugPrint('Device ID: $deviceId');
    debugPrint('Device Info: $deviceInfo');
  }
}
