import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'network_response.dart';

class NetworkCaller {
  NetworkCaller({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 25);

  Future<NetworkResponse> getRequest(
    String url, {
    String? token,
    Map<String, String>? headers,
  }) async {
    final reqHeaders = _buildHeaders(token: token, headers: headers);

    try {
      final response = await _client
          .get(Uri.parse(url), headers: reqHeaders)
          .timeout(_timeout);

      return _parseResponse(response);
    } on TimeoutException {
      return const NetworkResponse(
        statusCode: -1,
        isSuccess: false,
        errorMessage: 'Network timeout',
      );
    } catch (e) {
      return NetworkResponse(
        statusCode: -1,
        isSuccess: false,
        errorMessage: 'Network error: $e',
      );
    }
  }

  Future<NetworkResponse> postRequest(
    String url, {
    String? token,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    final reqHeaders = _buildHeaders(token: token, headers: headers)
      ..putIfAbsent('Content-Type', () => 'application/json');

    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: reqHeaders,
            body: jsonEncode(body ?? {}),
          )
          .timeout(_timeout);

      return _parseResponse(response);
    } on TimeoutException {
      return const NetworkResponse(
        statusCode: -1,
        isSuccess: false,
        errorMessage: 'Network timeout',
      );
    } catch (e) {
      return NetworkResponse(
        statusCode: -1,
        isSuccess: false,
        errorMessage: 'Network error: $e',
      );
    }
  }

  Map<String, String> _buildHeaders({
    String? token,
    Map<String, String>? headers,
  }) {
    final out = <String, String>{
      'Accept': 'application/json',
    };
    if (headers != null) out.addAll(headers);
    if (token != null && token.isNotEmpty) {
      out['Authorization'] = 'Bearer $token';
    }
    return out;
  }

  NetworkResponse _parseResponse(http.Response response) {
    final statusCode = response.statusCode;
    final text = utf8.decode(response.bodyBytes);
    final isSuccess = statusCode >= 200 && statusCode < 300;

    if (text.trim().isEmpty) {
      return NetworkResponse(
        statusCode: statusCode,
        isSuccess: isSuccess,
        responseData: null,
        errorMessage: isSuccess ? null : 'Empty response',
      );
    }

    dynamic data;
    try {
      data = jsonDecode(text);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NetworkCaller: JSON decode failed: $e');
      }
      return NetworkResponse(
        statusCode: statusCode,
        isSuccess: false,
        errorMessage: 'Invalid JSON response',
        responseData: text,
      );
    }

    if (isSuccess) {
      return NetworkResponse(
        statusCode: statusCode,
        isSuccess: true,
        responseData: data,
      );
    }

    String? errorMessage;
    if (data is Map<String, dynamic> && data['message'] != null) {
      errorMessage = data['message'].toString();
    }

    return NetworkResponse(
      statusCode: statusCode,
      isSuccess: false,
      errorMessage: errorMessage ?? 'Request failed',
      responseData: data,
    );
  }
}
