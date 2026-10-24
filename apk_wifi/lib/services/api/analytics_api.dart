import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../config/app_config.dart';
import '../../models/user_model.dart';
import '../local_db_service.dart';
import 'http_client.dart';

class AnalyticsApi {
  final ApiClient _client;
  AnalyticsApi([ApiClient? client]) : _client = client ?? ApiClient.instance;

  // --- REPORT SUMMARY ---
  Future<Map<String, dynamic>?> getReportSummary() async {
    try {
      final res = await _client.get('/reports/summary', timeout: const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['summary'];
      }
    } catch (e) {
      debugPrint('[AnalyticsApi] getReportSummary error: $e');
    }
    return null;
  }

  // --- AI ANALYTICS & FORECAST ---
  Future<Map<String, dynamic>?> getForecast() async {
    try {
      final res = await _client.get('/analytics/forecast', timeout: const Duration(seconds: 6));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('[AnalyticsApi] getForecast error: $e');
    }
    return null;
  }

  // --- COMPOSITE AI: ML REGRESSION + GROQ LLM INSIGHT ---
  Future<Map<String, dynamic>?> runAiInsightAnalysis() async {
    try {
      final res = await _client.post(
        '/analytics/analyze-insight',
        timeout: const Duration(seconds: 20),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('[AnalyticsApi] runAiInsightAnalysis error: $e');
    }
    return null;
  }

  Future<List<dynamic>> getLateRisk() async {
    try {
      final res = await _client.get('/analytics/late-risk', timeout: const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['late_risks'] ?? [];
      }
    } catch (e) {
      debugPrint('[AnalyticsApi] getLateRisk error: $e');
    }
    return [];
  }

  // --- CUSTOMERS & USER MANAGEMENT ---
  Future<List<UserModel>> getCustomers() async {
    try {
      final res = await _client.get('/customers', timeout: const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['customers'] is List) {
          return (data['customers'] as List)
              .map((u) => UserModel.fromJson(u))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[AnalyticsApi] getCustomers error: $e');
    }
    return [];
  }

  Future<bool> activateCustomer(int customerId, {int? paketId}) async {
    try {
      final res = await _client.patch(
        '/customers/$customerId/activate',
        body: {'paket_id': paketId},
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[AnalyticsApi] activateCustomer error: $e');
      return false;
    }
  }

  Future<bool> createStaff({
    required String nama,
    required String email,
    required String noHp,
    required String password,
    required String role,
    required String alamat,
  }) async {
    try {
      final res = await _client.post('/staff', body: {
        'nama': nama,
        'email': email,
        'no_hp': noHp,
        'password': password,
        'role': role,
        'alamat': alamat,
      });
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('[AnalyticsApi] createStaff error: $e');
      return false;
    }
  }

  // --- RATES & CURRENCY ---
  Future<Map<String, double>> getExchangeRates() async {
    const cacheKey = 'rates';
    try {
      final res = await _client.get('/rates', timeout: const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final map = (data['data']['idrPerCurrency'] as Map).map(
          (k, v) => MapEntry(k.toString(), double.tryParse(v.toString()) ?? 1.0),
        );
        await LocalDbService.instance.saveCache(cacheKey, map);
        return map;
      }
    } catch (e) {
      debugPrint('[AnalyticsApi] getExchangeRates error: $e. Using offline rates.');
    }

    final cached = await LocalDbService.instance.getCache(cacheKey);
    if (cached is Map) {
      return cached.map(
        (k, v) => MapEntry(k.toString(), double.tryParse(v.toString()) ?? 1.0),
      );
    }
    return AppConfig.idrPerCurrency;
  }
}
