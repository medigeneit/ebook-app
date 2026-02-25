import 'dart:io';
import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'local_storage_service.dart';

class DeviceInfoUtil {
  static Future<void> saveDeviceInfo() async {
    await LocalStorageService.init();
    final deviceInfoPlugin = DeviceInfoPlugin();
    const androidIdPlugin = AndroidId();
    String deviceId = 'unknown';
    String deviceInfo = 'unknown';
    String platform = 'unknown';

    final packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;

    try {
      if (kIsWeb) {
        final webInfo = await deviceInfoPlugin.webBrowserInfo;
        deviceId = webInfo.userAgent ?? 'unknown';
        deviceInfo =
            '${webInfo.vendor ?? 'UnknownVendor'}/${describeEnum(webInfo.browserName)}/Web/$version';
        platform = 'Web';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceId = await androidIdPlugin.getId() ?? 'unknown';
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
      }
    } catch (e) {
      debugPrint('Device info error: $e');
    }

    await LocalStorageService.setString(LocalStorageService.deviceId, deviceId);
    await LocalStorageService.setString(
        LocalStorageService.deviceInfo, deviceInfo);
    await LocalStorageService.setString(LocalStorageService.platform, platform);

    debugPrint('Device Platform: $platform');
    debugPrint('Device ID: $deviceId');
    debugPrint('Device Info: $deviceInfo');
  }
}
