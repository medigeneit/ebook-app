import 'package:ebook_project/api/device_urls.dart';
import 'package:ebook_project/models/device_verification_model/device_verification_otp_model.dart';
import 'package:ebook_project/services/local_storage_service.dart';
import 'package:ebook_project/services/network_caller.dart';
import 'package:ebook_project/services/network_response.dart';

class DeviceVerificationOtpService {
  final NetworkCaller _caller = NetworkCaller();

  Future<NetworkResponse> submitOtp({
    required String otpCode,
    required String step,
  }) async {
    final token = LocalStorageService.getString(LocalStorageService.token);
    final userAgent =
        LocalStorageService.getString(LocalStorageService.deviceInfo);
    final deviceId = LocalStorageService.getString(LocalStorageService.deviceId);
    final platform = LocalStorageService.getString(LocalStorageService.platform);

    if (token == null || userAgent == null || deviceId == null || platform == null) {
      return const NetworkResponse(
        statusCode: -1,
        isSuccess: false,
        errorMessage: 'Missing authentication or device information',
      );
    }

    final url = DeviceUrls.deviceVerificationOtp(step);

    final headers = {
      'Accept': 'application/json',
      'User-Agent': userAgent,
      'X-Gns-Ddt': deviceId,
      'X-DEVICE-TYPE': platform,
    };

    final body = {
      'code': otpCode,
    };

    final response = await _caller.postRequest(
      url,
      token: token,
      headers: headers,
      body: body,
    );

    if (response.isSuccess) {
      try {
        final raw = response.responseData;
        final payload = (raw is Map && raw['data'] is Map)
            ? Map<String, dynamic>.from(raw['data'])
            : Map<String, dynamic>.from(raw as Map);
        final model = SubmitVerificationOtpModel.fromJson(payload);
        return NetworkResponse(
          statusCode: response.statusCode,
          isSuccess: true,
          responseData: model,
        );
      } catch (e) {
        return NetworkResponse(
          statusCode: response.statusCode,
          isSuccess: false,
          errorMessage: 'Failed to parse OTP response: $e',
        );
      }
    }

    return response;
  }
}
