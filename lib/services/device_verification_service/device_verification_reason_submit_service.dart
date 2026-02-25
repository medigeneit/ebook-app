import 'package:ebook_project/api/device_urls.dart';
import 'package:ebook_project/models/device_verification_model/device_verification_reason_submit_model.dart';
import 'package:ebook_project/services/local_storage_service.dart';
import 'package:ebook_project/services/network_caller.dart';
import 'package:ebook_project/services/network_response.dart';

class DeviceVerificationReasonSubmitService {
  final NetworkCaller _caller = NetworkCaller();

  Future<NetworkResponse> submitReason({required String reason}) async {
    final token = LocalStorageService.getString(LocalStorageService.token);
    final userAgent =
        LocalStorageService.getString(LocalStorageService.deviceInfo);
    final deviceId = LocalStorageService.getString(LocalStorageService.deviceId);
    final platform = LocalStorageService.getString(LocalStorageService.platform);

    if (token == null || userAgent == null || deviceId == null || platform == null) {
      return const NetworkResponse(
        statusCode: -1,
        isSuccess: false,
        errorMessage: 'Missing device information or authentication',
      );
    }

    final url = DeviceUrls.deviceVerificationReasonSubmitUrl;

    final headers = {
      'Accept': 'application/json',
      'User-Agent': userAgent,
      'X-Gns-Ddt': deviceId,
      'X-DEVICE-TYPE': platform,
      'Cache-Control': 'no-cache, no-store, must-revalidate',
    };

    final body = {
      'reason': reason,
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
        final model = DeviceVerificationReasonSubmitModel.fromJson(payload);
        return NetworkResponse(
          statusCode: response.statusCode,
          isSuccess: true,
          responseData: model,
        );
      } catch (e) {
        return NetworkResponse(
          statusCode: response.statusCode,
          isSuccess: false,
          errorMessage: 'Failed to parse device verification reason data: $e',
        );
      }
    }

    return response;
  }
}
