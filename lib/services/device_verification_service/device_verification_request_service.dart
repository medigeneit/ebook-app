import 'package:ebook_project/api/device_urls.dart';
import 'package:ebook_project/models/device_verification_model/device_verification_submit_model.dart';
import 'package:ebook_project/services/local_storage_service.dart';
import 'package:ebook_project/services/network_caller.dart';
import 'package:ebook_project/services/network_response.dart';

class DeviceVerificationRequestService {
  final NetworkCaller _caller = NetworkCaller();

  Future<NetworkResponse> requestAgreementVerification({
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
        errorMessage: 'Missing device info or authentication',
      );
    }

    final url = DeviceUrls.deviceVerificationOtp(step);

    final headers = {
      'Accept': 'application/json',
      'User-Agent': userAgent,
      'X-Gns-Ddt': deviceId,
      'X-DEVICE-TYPE': platform,
    };

    final response = await _caller.getRequest(
      '$url?agreement=yes',
      token: token,
      headers: headers,
    );

    if (response.isSuccess) {
      try {
        final raw = response.responseData;
        final payload = (raw is Map && raw['data'] is Map)
            ? Map<String, dynamic>.from(raw['data'])
            : Map<String, dynamic>.from(raw as Map);
        final model = DeviceVerificationSubmitModel.fromJson(payload);
        return NetworkResponse(
          statusCode: response.statusCode,
          isSuccess: true,
          responseData: model,
        );
      } catch (e) {
        return NetworkResponse(
          statusCode: response.statusCode,
          isSuccess: false,
          errorMessage: 'Failed to parse verification model: $e',
        );
      }
    }

    return response;
  }
}
