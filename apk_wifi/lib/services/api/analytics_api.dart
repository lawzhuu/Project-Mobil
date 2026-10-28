import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
      debugPrint('[AnalyticsApi] getExchangeRates backend error: $e. Trying direct CDN fallback.');
    }

    // Direct CDN fallback to fawazahmed0/exchange-api if backend unreachable
    try {
      final cdnUrl = Uri.parse(
        'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.min.json',
      );
      final cdnRes = await http.get(cdnUrl).timeout(const Duration(seconds: 4));
      if (cdnRes.statusCode == 200) {
        final data = jsonDecode(cdnRes.body);
        final usdMap = data['usd'] as Map<String, dynamic>?;
        if (usdMap != null && usdMap['idr'] != null) {
          final usdToIdr = double.tryParse(usdMap['idr'].toString()) ?? 15500.0;
          final usdToEur = double.tryParse(usdMap['eur'].toString()) ?? 0.90;
          final eurToIdr = usdToEur > 0 ? (usdToIdr / usdToEur) : 16800.0;

          final liveMap = {
            'IDR': 1.0,
            'USD': double.parse(usdToIdr.toStringAsFixed(2)),
            'EUR': double.parse(eurToIdr.toStringAsFixed(2)),
          };
          await LocalDbService.instance.saveCache(cacheKey, liveMap);
          return liveMap;
        }
      }
    } catch (e) {
      debugPrint('[AnalyticsApi] Direct CDN fallback error: $e. Checking local storage cache.');
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
