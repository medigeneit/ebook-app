import 'dart:async';
import 'dart:convert';

import 'package:ebook_project/utils/device_uuid_store.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:ebook_project/api/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 25);

  // -------------------------
  // GET JSON (Map)
  // -------------------------
  Future<Map<String, dynamic>> fetchEbookData(String endpoint) async {
    final headers = await _authHeaders();
    final uri = getFullUrl(endpoint);

    Future<http.Response> doGet() =>
        _client.get(uri, headers: headers).timeout(_timeout);

    http.Response response;
    try {
      response = await doGet();
      debugPrint('[API] GET => $uri');
      debugPrint('[API] status => ${response.statusCode}');
      debugPrint('[API] body(head) => ${response.body}');
    } on TimeoutException {
      throw ApiException('Network timeout. আবার চেষ্টা করুন।');
    } catch (e) {
      throw ApiException('Network error: $e');
    }

    String text = utf8.decode(response.bodyBytes);

    if (response.statusCode != 200) {
      throw ApiException(_httpErrorMessage(response.statusCode, text));
    }

    if (text.trim().isEmpty) {
      throw ApiException('Server থেকে empty response এসেছে।');
    }

    try {
      final decoded = _decodeJson(text);
      return _asMap(decoded);
    } on FormatException {
      // মাঝে মাঝে ট্রাঙ্কেটেড/ইনকমপ্লিট রেসপন্স হলে retry দিয়ে ঠিক হয়
      try {
        final retry = await doGet();
        final retryText = utf8.decode(retry.bodyBytes);

        if (retry.statusCode != 200) {
          throw ApiException(_httpErrorMessage(retry.statusCode, retryText));
        }

        final decoded = _decodeJson(retryText);
        return _asMap(decoded);
      } catch (e) {
        throw ApiException(
          'Invalid JSON response (truncated/invalid). '
              'len=${text.length}, tail=${_tail(text)} | $e',
        );
      }
    } catch (e) {
      throw ApiException('Error fetching data: $e');
    }
  }

  // -------------------------
  // POST JSON (Map?)
  // -------------------------
  Future<Map<String, dynamic>?> postData(
      String endpoint,
      Map<String, dynamic> data,
      ) async {
    final headers = await _authHeaders();
    final uri = getFullUrl(endpoint);

    http.Response response;

    try {
      response = await _client
          .post(
        uri,
        headers: headers,
        body: jsonEncode(data),
      )
          .timeout(_timeout);
      debugPrint('[API] GET => $uri');
      debugPrint('[API] headers => $headers');
      debugPrint('[API] headers body => ${jsonEncode(data)}');
      debugPrint('[API] body(head) => ${response.body}');
    } on TimeoutException {
      return {'error': 1, 'message': 'Network timeout. আবার চেষ্টা করুন।'};
    } catch (e) {
      return {'error': 1, 'message': 'Network Error: $e'};
    }

    final text = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final decoded = _decodeJson(text);
        final map = _asMap(decoded);
        return map;
      } catch (e) {
        return {'error': 1, 'message': 'Invalid JSON response: $e'};
      }
    }

    // চেষ্টা করি server message বের করতে
    try {
      final decoded = _decodeJson(text);
      if (decoded is Map && decoded['message'] != null) {
        return {'error': 1, 'message': decoded['message'].toString()};
      }
    } catch (_) {}

    return {'error': 1, 'message': 'Server Error: ${response.statusCode}'};
  }

  // -------------------------
  // GET Raw Text
  // -------------------------
  Future<String> fetchRawTextData(String endpoint) async {
    final headers = await _authHeaders();
    final uri = getFullUrl(endpoint);

    try {
      final response =
      await _client.get(uri, headers: headers).timeout(_timeout);

      final text = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        return text;
      }
      throw ApiException(_httpErrorMessage(response.statusCode, text));
    } on TimeoutException {
      throw ApiException('Network timeout. আবার চেষ্টা করুন।');
    } catch (e) {
      throw ApiException('Error fetching data: $e');
    }
  }

  // -------------------------
  // Logout
  // -------------------------
  Future<void> logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final response = await _client
          .post(
        getFullUrl('/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 204) {
        await prefs.clear();
        if (context.mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
        }
        return;
      }

      final text = utf8.decode(response.bodyBytes);
      throw ApiException(_httpErrorMessage(response.statusCode, text));
    } on TimeoutException {
      throw ApiException('Logout timeout. আবার চেষ্টা করুন।');
    } catch (e) {
      throw ApiException('Logout failed: $e');
    }
  }

  // -------------------------
  // Subscription Plans
  // -------------------------
  Future<Map<String, dynamic>> fetchSubscriptionPlans(int productId) async {
    final headers = await _authHeaders();
    final uri = getFullUrl('/v1/ebooks/$productId/plans');

    http.Response response;

    try {
      response =
      await _client.get(uri, headers: headers).timeout(_timeout);
    } on TimeoutException {
      throw ApiException('Network timeout. আবার চেষ্টা করুন।');
    } catch (e) {
      throw ApiException('Network error: $e');
    }

    final text = utf8.decode(response.bodyBytes);

    dynamic decoded;
    try {
      decoded = _decodeJson(text);
    } catch (e) {
      throw ApiException('Invalid JSON response: $e');
    }

    if (response.statusCode == 200) {
      return _asMap(decoded);
    }

    if (decoded is Map && decoded['message'] != null) {
      throw ApiException(decoded['message'].toString());
    }

    throw ApiException(_httpErrorMessage(response.statusCode, text));
  }

  // -------------------------
  // Create Subscription
  // -------------------------
  Future<Map<String, dynamic>> createSubscription({
    required int productId,
    required int monthlyPlan,
    int paymentMethod = 1,
  }) async {
    final headers = await _authHeaders();
    final uri = getFullUrl('/v1/ebooks/$productId/subscriptions');

    http.Response response;

    try {
      response = await _client
          .post(
        uri,
        headers: headers,
        body: jsonEncode({
          'monthly_plan': monthlyPlan,
          'payment_method': paymentMethod,
        }),
      )
          .timeout(_timeout);
    } on TimeoutException {
      throw ApiException('Network timeout. আবার চেষ্টা করুন।');
    } catch (e) {
      throw ApiException('Network error: $e');
    }

    final text = utf8.decode(response.bodyBytes);

    dynamic decoded;
    try {
      decoded = _decodeJson(text);
    } catch (e) {
      throw ApiException('Invalid JSON response: $e');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _asMap(decoded);
    }

    if (response.statusCode == 422) {
      if (decoded is Map && decoded['message'] != null) {
        throw ApiException(decoded['message'].toString());
      }
      throw ApiException('Validation failed');
    }

    if (decoded is Map && decoded['message'] != null) {
      throw ApiException(decoded['message'].toString());
    }

    throw ApiException(_httpErrorMessage(response.statusCode, text));
  }

  // -------------------------
  // Auth headers
  // -------------------------
  Future<Map<String, String>> _authHeaders() async {
    final token = await _getToken();
    final deviceUuid = await DeviceUuidStore.getOrCreate();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    // Laravel side: request()->cookie('_gns-ddt') ব্যবহার করছে
    headers['Accept'] = 'application/json';
    headers['Cookie'] = '_gns-ddt=$deviceUuid';
    // future-proof: header fallback
    headers['X-Device-Uuid'] = deviceUuid;
    headers['X-GNS-DDT'] = deviceUuid;
    print('headers: $headers');
    return headers;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // -------------------------
  // Helpers
  // -------------------------
  dynamic _decodeJson(String text) => jsonDecode(text);

  Map<String, dynamic> _asMap(dynamic decoded) {
    if (decoded is Map<String, dynamic>) return decoded;

    // যদি টপ-লেভেলে List আসে, Map টাইপ বজায় রাখতে wrap করে দিই
    if (decoded is List) {
      return {'ok': true, 'data': decoded};
    }

    // অন্য টাইপ এলে এটাও wrap
    return {'ok': true, 'data': decoded};
  }

  String _httpErrorMessage(int code, String body) {
    final clean = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    final snippet = clean.length > 200 ? '$clean...' : clean;
    return 'HTTP $code: $snippet';
  }

  String _tail(String s) {
    final t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.length <= 180) return t;
    return t.substring(t.length - 180);
  }
}

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}
