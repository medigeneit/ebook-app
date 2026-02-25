import 'dart:io';
import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceMeta {
  static Future<Map<String, String>> headers({
    required String appDeviceUuid, // _gns-ddt uuid
  }) async {
    final info = DeviceInfoPlugin();
    final pkg = await PackageInfo.fromPlatform();

    String platform = Platform.operatingSystem; // android/ios
    String osVersion = Platform.operatingSystemVersion;
    String brand = '';
    String model = '';
    String deviceId = appDeviceUuid; // default: app uuid (safe)

    if (Platform.isAndroid) {
      final a = await info.androidInfo;
      brand = a.brand ?? '';
      model = a.model ?? '';
      const androidId = AndroidId();
      final id = await androidId.getId();
      deviceId = (id != null && id.trim().isNotEmpty) ? id.trim() : appDeviceUuid;
      osVersion = 'Android ${a.version.release ?? ''}'.trim();
    } else if (Platform.isIOS) {
      final i = await info.iosInfo;
      brand = 'Apple';
      model = i.utsname.machine ?? '';
      deviceId = i.identifierForVendor ?? appDeviceUuid;
      osVersion = 'iOS ${i.systemVersion ?? ''}'.trim();
    }

    return {
      'X-Device-Uuid': appDeviceUuid,
      'X-GNS-DDT': appDeviceUuid,
      'X-Device-Platform': platform,
      'X-Device-Brand': brand,
      'X-Device-Model': model,
      'X-Device-Id': deviceId,
      'X-OS-Version': osVersion,
      'X-App-Version': '${pkg.version}+${pkg.buildNumber}',
    };
  }
}
