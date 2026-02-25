import 'routes.dart';

class DeviceUrls {
  static String deviceVerification =
      getFullUrl('/v1/my-device-verification').toString();
  static String deviceVerificationReasonSubmitUrl =
      getFullUrl('/v1/my-device-verification/replace').toString();

  static String deviceVerificationOtp(String steps) {
    return getFullUrl('/v1/my-device-verification$steps').toString();
  }
}
