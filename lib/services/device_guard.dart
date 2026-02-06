import 'package:flutter/foundation.dart';
import '../api/api_service.dart';

class DeviceGuard {
  DeviceGuard._();
  static final DeviceGuard I = DeviceGuard._();

  final _api = ApiService();

  bool? _cached;
  DateTime? _cachedAt;

  /// 15 সেকেন্ড cache রাখলাম যাতে বারবার hit না হয়
  bool _isCacheValid() {
    if (_cached == null || _cachedAt == null) return false;
    return DateTime.now().difference(_cachedAt!).inSeconds < 15;
  }

  Future<bool> isVerified({bool force = false}) async {
    if (!force && _isCacheValid()) return _cached!;

    final res = await _api.fetchEbookData('/v1/check-active-doctor-device');
    final ok = res['is_active'] == true;

    _cached = ok;
    _cachedAt = DateTime.now();

    if (kDebugMode) {
      debugPrint('[DeviceGuard] is_active=$ok');
    }
    return ok;
  }

  void clearCache() {
    _cached = null;
    _cachedAt = null;
  }
}
