import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String appName = 'Sima.net';
  static const String appTagline = 'ISP Reseller & Smart Fiber Operations';
  static const String appVersion = '1.0.0';

  // Base server URL configured via .env (BACKEND_BASE_URL) or --dart-define
  static String get defaultBaseUrl {
    final envUrl = dotenv.env['BACKEND_BASE_URL'];
    if (envUrl != null && envUrl.trim().isNotEmpty) {
      final trimmed = envUrl.trim();
      return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
    }
    const defineUrl = String.fromEnvironment(
      'BACKEND_BASE_URL',
      defaultValue: 'https://backend-sima.vercel.app',
    );
    return defineUrl.endsWith('/') ? defineUrl.substring(0, defineUrl.length - 1) : defineUrl;
  }

  static String get baseUrl => defaultBaseUrl;

  // Resolve image URL (routes external Supabase images through backend proxy to prevent Android emulator DNS errors)
  static String resolveImageUrl(String pathOrUrl) {
    if (pathOrUrl.trim().isEmpty) return '';
    final cleaned = pathOrUrl.trim();
    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      return '$baseUrl/storage/proxy?url=${Uri.encodeComponent(cleaned)}';
    }
    if (cleaned.startsWith('/')) {
      return '$baseUrl$cleaned';
    }
    return '$baseUrl/$cleaned';
  }

  // Fallback exchange rates
  static const Map<String, double> idrPerCurrency = {
    'IDR': 1.0,
    'USD': 15500.0,
    'EUR': 16800.0,
  };

  // Supported countries and their mappings
  static const List<Map<String, String>> supportedCountries = [
    {'name': 'Indonesia', 'currency': 'IDR', 'timezone': 'WIB', 'flag': '🇮🇩'},
    {
      'name': 'United States',
      'currency': 'USD',
      'timezone': 'London',
      'flag': '🇺🇸',
    },
    {
      'name': 'United Kingdom',
      'currency': 'EUR',
      'timezone': 'London',
      'flag': '🇬🇧',
    },
    {
      'name': 'Germany',
      'currency': 'EUR',
      'timezone': 'London',
      'flag': '🇩🇪',
    },
    {
      'name': 'Netherlands',
      'currency': 'EUR',
      'timezone': 'London',
      'flag': '🇳🇱',
    },
    {
      'name': 'Australia',
      'currency': 'USD',
      'timezone': 'WITA',
      'flag': '🇦🇺',
    },
  ];
}
