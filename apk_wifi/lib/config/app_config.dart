import 'dart:io';

import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'Sima.net';
  static const String appTagline = 'ISP Reseller & Smart Fiber Operations';
  static const String appVersion = '1.0.0';

  // Default server URL based on platform
  // Android emulator uses 10.0.2.2, desktop/web uses localhost:3000
  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  static String baseUrl = defaultBaseUrl;

  static void setBaseUrl(String url) {
    if (url.endsWith('/')) {
      baseUrl = url.substring(0, url.length - 1);
    } else {
      baseUrl = url;
    }
  }

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
