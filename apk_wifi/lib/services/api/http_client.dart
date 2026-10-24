import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';

/// Core HTTP Client that encapsulates base URL, JWT bearer token,
/// timeout handling, and consistent JSON serialization/deserialization.
class ApiClient {
  static final ApiClient instance = ApiClient._internal();
  ApiClient._internal();

  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  Map<String, String> get headers {
    final map = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      map['Authorization'] = 'Bearer $_authToken';
    }
    return map;
  }

  Uri buildUri(String endpoint) {
    final normalized = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('${AppConfig.baseUrl}$normalized');
  }

  Future<http.Response> get(String endpoint, {Duration timeout = const Duration(seconds: 8)}) async {
    final url = buildUri(endpoint);
    return await http.get(url, headers: headers).timeout(timeout);
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final url = buildUri(endpoint);
    return await http
        .post(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(timeout);
  }

  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final url = buildUri(endpoint);
    return await http
        .put(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(timeout);
  }

  Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final url = buildUri(endpoint);
    return await http
        .patch(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(timeout);
  }

  Future<http.Response> delete(
    String endpoint, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final url = buildUri(endpoint);
    return await http.delete(url, headers: headers).timeout(timeout);
  }

  Future<http.Response> sendMultipart(http.MultipartRequest request, {Duration timeout = const Duration(seconds: 20)}) async {
    if (_authToken != null && _authToken!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $_authToken';
    }
    final streamed = await request.send().timeout(timeout);
    return await http.Response.fromStream(streamed);
  }
}
