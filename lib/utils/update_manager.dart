// import 'package:flutter/widgets.dart';
// import 'package:in_app_update/in_app_update.dart';
//
// class UpdateManager {
//   static Future<void> checkForUpdate() async {
//     try {
//       final info = await InAppUpdate.checkForUpdate();
//
//       if (info.updateAvailability == UpdateAvailability.updateAvailable &&
//           info.immediateUpdateAllowed) {
//         await _performUpdate();
//       }
//     } catch (e) {
//       debugPrint('In-app update skipped: $e');
//     }
//   }
//
//   static Future<void> _performUpdate() async {
//     try {
//       await InAppUpdate.performImmediateUpdate();
//     } catch (e) {
//       debugPrint('Update failed: $e');
//     }
//   }
// }


import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_update/in_app_update.dart';

class UpdateManager {
  static bool _checkedOnce = false;

  static Future<void> checkForUpdate() async {
    // একবারই চেক
    if (_checkedOnce) return;
    _checkedOnce = true;

    // শুধু Android + Release build এ চালান
    if (!Platform.isAndroid) return;
    if (!kReleaseMode) return;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable &&
          info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (_) {
      // silent
    }
  }
}
