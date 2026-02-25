import 'package:ebook_project/api/device_urls.dart';
import 'package:ebook_project/models/device_verification_model/device_verification_model.dart';
import 'package:ebook_project/services/local_storage_service.dart';
import 'package:ebook_project/services/network_caller.dart';
import 'package:ebook_project/services/network_response.dart';

class DeviceVerificationService {
  final NetworkCaller _caller = NetworkCaller();

  Future<NetworkResponse> fetchDeviceVerification() async {
    final token = LocalStorageService.getString(LocalStorageService.token);
    final userAgent =
        LocalStorageService.getString(LocalStorageService.deviceInfo);
    final deviceId = LocalStorageService.getString(LocalStorageService.deviceId);
    final platform = LocalStorageService.getString(LocalStorageService.platform);

    final headers = {
      'User-Agent': userAgent ?? '',
      'X-Gns-Ddt': deviceId ?? '',
      'X-DEVICE-TYPE': platform ?? '',
    };

    final response = await _caller.getRequest(
      DeviceUrls.deviceVerification,
      token: token,
      headers: headers,
    );

    if (response.isSuccess) {
      try {
        final raw = response.responseData;
        final payload = (raw is Map && raw['data'] is Map)
            ? Map<String, dynamic>.from(raw['data'])
            : Map<String, dynamic>.from(raw as Map);
        final model = DeviceVerificationModel.fromJson(payload);
        return NetworkResponse(
          statusCode: response.statusCode,
          isSuccess: true,
          responseData: model,
        );
      } catch (e) {
        return NetworkResponse(
          statusCode: response.statusCode,
          isSuccess: false,
          errorMessage: 'Failed to parse device verification data: $e',
        );
      }
    }

    return response;
  }
}
