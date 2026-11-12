import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';

// ==============================================================================
// PANDUAN PEMULA - JANTUNG KOMUNIKASI HTTP REST API (ApiClient)
// ==============================================================================
// Kelas ini adalah "mesin pengirim surat" (HTTP Client) terpusat untuk aplikasi.
// Setiap kali aplikasi butuh data dari server (misal login, ambil paket, bayar tagihan),
// permintaan akan diproses melalui method get(), post(), put(), patch(), atau delete() di file ini.

/// Core HTTP Client that encapsulates base URL, JWT bearer token,
/// timeout handling, and consistent JSON serialization/deserialization.
class ApiClient {
  // PANDUAN PEMULA:
  // Pola Singleton memastikan semua panggilan API menggunakan token otorisasi yang sama.
  static final ApiClient instance = ApiClient._internal();
  ApiClient._internal();

  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  // PANDUAN PEMULA (Header HTTP Otomatis):
  // Memberitahu server backend bahwa data yang dikirim dan diminta bertipe format JSON.
  // Jika pengguna sudah login (`_authToken` tidak kosong), header 'Authorization: Bearer <token>'
  // otomatis disisipkan sehingga server mengetahui siapa yang melakukan request.
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

  // PANDUAN PEMULA:
  // Menggabungkan Base URL (misal 'https://backend-sima.vercel.app') dengan endpoint (misal '/auth/login')
  Uri buildUri(String endpoint) {
    final normalized = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('${AppConfig.baseUrl}$normalized');
  }

  // PANDUAN PEMULA (Timeout & Error Handling):
  // Method GET untuk mengambil data. Timeout diset (misal 8 detik) agar jika sinyal lemot,
  // aplikasi tidak 'hang' selamanya melainkan memunculkan pesan gagal dengan cepat.
  Future<http.Response> get(String endpoint, {Duration timeout = const Duration(seconds: 8)}) async {
    final url = buildUri(endpoint);
    return await http.get(url, headers: headers).timeout(timeout);
  }

  // Method POST untuk mengirim data baru (seperti login atau buat tiket perbaikan)
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
