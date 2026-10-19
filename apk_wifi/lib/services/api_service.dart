import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/feedback_model.dart';
import '../models/invoice_model.dart';
import '../models/ledger_model.dart';
import '../models/package_model.dart';
import '../models/package_request_model.dart';
import '../models/task_model.dart';
import '../models/upstream_bill_model.dart';
import '../models/user_model.dart';
import 'local_db_service.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // --- AUTH ---
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/auth/login');
      final res = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      return data;
    } catch (e) {
      debugPrint('[ApiService] Login error: $e');
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server backend ($e)',
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String nama,
    required String email,
    required String noHp,
    required String password,
    required String negara,
    required String alamat,
    required double lat,
    required double lng,
    required int paketId,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/auth/register');
      final res = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nama': nama,
              'email': email,
              'no_hp': noHp,
              'password': password,
              'negara': negara,
              'alamat': alamat,
              'lat': lat,
              'lng': lng,
              'paket_id': paketId,
            }),
          )
          .timeout(const Duration(seconds: 8));

      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[ApiService] Register error: $e');
      return {'success': false, 'message': 'Gagal mendaftar: $e'};
    }
  }

  Future<UserModel?> getMe() async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/me');
      final res = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['user'] != null) {
          return UserModel.fromJson(data['user']);
        }
      }
    } catch (e) {
      debugPrint('[ApiService] getMe error: $e');
    }
    return null;
  }

  Future<UserModel?> getProfile() => getMe();

  Future<Map<String, dynamic>> updateProfile({
    required String nama,
    required String noHp,
    required String negara,
    required String mataUang,
    required String zonaWaktu,
    required String alamat,
    required double lat,
    required double lng,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/me');
      final res = await http
          .put(
            url,
            headers: _headers,
            body: jsonEncode({
              'nama': nama,
              'no_hp': noHp,
              'negara': negara,
              'mata_uang': mataUang,
              'zona_waktu': zonaWaktu,
              'alamat': alamat,
              'lat': lat,
              'lng': lng,
            }),
          )
          .timeout(const Duration(seconds: 8));

      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[ApiService] updateProfile error: $e');
      return {'success': false, 'message': 'Gagal memperbarui profil: $e'};
    }
  }

  Future<Map<String, dynamic>> uploadProfilePhoto({
    File? file,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/me/photo');
      final req = http.MultipartRequest('POST', url);
      if (_authToken != null) {
        req.headers['Authorization'] = 'Bearer $_authToken';
      }

      if (fileBytes != null && fileBytes.isNotEmpty) {
        req.files.add(http.MultipartFile.fromBytes(
          'foto',
          fileBytes,
          filename: fileName ?? 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));
      } else if (file != null && !kIsWeb) {
        req.files.add(await http.MultipartFile.fromPath('foto', file.path));
      } else {
        return {'success': false, 'message': 'Tidak ada berkas foto yang dipilih'};
      }

      final streamed = await req.send().timeout(const Duration(seconds: 20));
      final res = await http.Response.fromStream(streamed);
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[ApiService] uploadProfilePhoto error: $e');
      return {'success': false, 'message': 'Gagal mengunggah foto profil: $e'};
    }
  }

  // --- PACKAGES ---
  Future<List<PackageModel>> getPackages() async {
    const cacheKey = 'packages';
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/packages');
      final res = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['packages'] is List) {
          final list = (data['packages'] as List)
              .map((p) => PackageModel.fromJson(p))
              .toList();
          await LocalDbService.instance.saveCache(cacheKey, data['packages']);
          return list;
        }
      }
    } catch (e) {
      debugPrint(
        '[ApiService] getPackages error: $e. Loading from offline cache...',
      );
    }

    // Offline cache fallback
    final cached = await LocalDbService.instance.getCache(cacheKey);
    if (cached is List) {
      return cached.map((p) => PackageModel.fromJson(p)).toList();
    }

    // Default static packages per PRD
    return [
      PackageModel(
        id: 1,
        nama: 'Paket Hemat Fiber 20',
        kecepatanMbps: 20,
        hargaIdr: 175000,
        deskripsi: 'Akses internet stabil unlimited untuk kebutuhan browsing dan media sosial keluarga.',
      ),
      PackageModel(
        id: 2,
        nama: 'Paket Turbo Home 50',
        kecepatanMbps: 50,
        hargaIdr: 275000,
        deskripsi: 'Kecepatan tinggi untuk streaming 4K, video conference, dan gaming online.',
      ),
      PackageModel(
        id: 3,
        nama: 'Paket Ultimate Pro 100',
        kecepatanMbps: 100,
        hargaIdr: 450000,
        deskripsi: 'Koneksi ultra-cepat simetris untuk profesional dan content creator.',
      ),
      PackageModel(
        id: 4,
        nama: 'Paket Fast Fiber 30',
        kecepatanMbps: 30,
        hargaIdr: 215000,
        deskripsi: 'Internet fiber optic handal untuk WFH, download cepat, dan streaming HD bebas lag.',
      ),
      PackageModel(
        id: 5,
        nama: 'Paket Turbo Home 75',
        kecepatanMbps: 75,
        hargaIdr: 340000,
        deskripsi: 'Keluarga besar aktif & smart TV multi-room, download file besar dalam hitungan detik.',
      ),
      PackageModel(
        id: 6,
        nama: 'Paket Gamer Sakti 100',
        kecepatanMbps: 100,
        hargaIdr: 399000,
        deskripsi: 'Jalur khusus gaming prioritas rendah latensi (<5ms), anti spike & zero packet loss.',
      ),
      PackageModel(
        id: 7,
        nama: 'Paket Gamer Pro 150',
        kecepatanMbps: 150,
        hargaIdr: 520000,
        deskripsi: 'Bandwidth simetris 1:1, live streaming YouTube/Twitch kualitas 1080p 60fps tanpa jeda.',
      ),
      PackageModel(
        id: 8,
        nama: 'Paket Promo Flash 60',
        kecepatanMbps: 60,
        hargaIdr: 239000,
        deskripsi: 'Promo spesial kuota unlimited kecepatan ekstra fiber optic hemat bulanan.',
      ),
      PackageModel(
        id: 9,
        nama: 'Paket Promo Pelajar Hemat',
        kecepatanMbps: 25,
        hargaIdr: 150000,
        deskripsi: 'Paket ramah kantong untuk pelajar & mahasiswa, riset kuliah & Google Classroom.',
      ),
    ];
  }

  Future<bool> createPackage({
    required String nama,
    required int kecepatanMbps,
    required int hargaIdr,
    required String deskripsi,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/packages');
      final res = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'nama': nama,
          'kecepatan_mbps': kecepatanMbps,
          'harga_idr': hargaIdr,
          'deskripsi': deskripsi,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('[ApiService] createPackage error: $e');
      return false;
    }
  }

  Future<bool> deletePackage(int id) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/packages/$id');
      final res = await http.delete(url, headers: _headers);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] deletePackage error: $e');
      return false;
    }
  }

  // --- CUSTOMERS & STAFF (ADMIN) ---
  Future<List<UserModel>> getCustomers() async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/customers');
      final res = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['customers'] is List) {
          return (data['customers'] as List)
              .map((u) => UserModel.fromJson(u))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[ApiService] getCustomers error: $e');
    }
    return [];
  }

  Future<bool> activateCustomer(int customerId, {int? paketId}) async {
    try {
      final url = Uri.parse(
        '${AppConfig.baseUrl}/customers/$customerId/activate',
      );
      final res = await http.patch(
        url,
        headers: _headers,
        body: jsonEncode({'paket_id': paketId}),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] activateCustomer error: $e');
      return false;
    }
  }

  // --- PACKAGE CHANGE REQUEST WORKFLOW (OPTION A) ---
  Future<Map<String, dynamic>> submitPackageChangeRequest({
    required int packageId,
    required String tipe,
    required String alasan,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/packages/change-request');
      final res = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'paket_id': packageId,
              'tipe': tipe,
              'alasan': alasan,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      return data is Map<String, dynamic> ? data : {'success': false, 'message': 'Format respons tidak valid'};
    } catch (e) {
      debugPrint('[ApiService] submitPackageChangeRequest error: $e');
      return {'success': false, 'message': 'Gagal mengajukan perubahan paket: $e'};
    }
  }

  Future<PackageRequestModel?> getCustomerPendingPackageRequest() async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/customer/change-request');
      final res = await http.get(url, headers: _headers).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['pending'] != null) {
          return PackageRequestModel.fromJson(data['pending']);
        }
      }
    } catch (e) {
      debugPrint('[ApiService] getCustomerPendingPackageRequest error: $e');
    }
    return null;
  }

  Future<List<PackageRequestModel>> getAdminPackageRequests() async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/admin/package-requests');
      final res = await http.get(url, headers: _headers).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['requests'] is List) {
          return (data['requests'] as List)
              .map((r) => PackageRequestModel.fromJson(r))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[ApiService] getAdminPackageRequests error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> approvePackageRequest(int requestId, {String? adminCatatan}) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/admin/package-requests/$requestId/approve');
      final res = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({'admin_catatan': adminCatatan ?? 'Disetujui oleh admin'}),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[ApiService] approvePackageRequest error: $e');
      return {'success': false, 'message': 'Gagal menyetujui pengajuan: $e'};
    }
  }

  Future<Map<String, dynamic>> rejectPackageRequest(int requestId, {String? adminCatatan}) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/admin/package-requests/$requestId/reject');
      final res = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({'admin_catatan': adminCatatan ?? 'Ditolak oleh admin'}),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[ApiService] rejectPackageRequest error: $e');
      return {'success': false, 'message': 'Gagal menolak pengajuan: $e'};
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
      final url = Uri.parse('${AppConfig.baseUrl}/staff');
      final res = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'nama': nama,
          'email': email,
          'no_hp': noHp,
          'password': password,
          'role': role,
          'alamat': alamat,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('[ApiService] createStaff error: $e');
      return false;
    }
  }

  // --- INVOICES & PAYMENTS ---
  Future<List<InvoiceModel>> getInvoices() async {
    const cacheKey = 'invoices';
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/invoices');
      final res = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['invoices'] is List) {
          final list = (data['invoices'] as List)
              .map((i) => InvoiceModel.fromJson(i))
              .toList();
          await LocalDbService.instance.saveCache(cacheKey, data['invoices']);
          return list;
        }
      }
    } catch (e) {
      debugPrint('[ApiService] getInvoices error: $e. Loading from cache...');
    }

    final cached = await LocalDbService.instance.getCache(cacheKey);
    if (cached is List) {
      return cached.map((i) => InvoiceModel.fromJson(i)).toList();
    }
    return [];
  }

  Future<bool> createInvoice({
    required int userId,
    required String periode,
    required int nominalIdr,
    required String jatuhTempo,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/invoices');
      final res = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'user_id': userId,
          'periode': periode,
          'nominal_idr': nominalIdr,
          'jatuh_tempo': jatuhTempo,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('[ApiService] createInvoice error: $e');
      return false;
    }
  }

  Future<bool> uploadPaymentProof({
    required int invoiceId,
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/payments');
      if (fileBytes != null && fileBytes.isNotEmpty) {
        final req = http.MultipartRequest('POST', url);
        req.headers.addAll({
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        });
        req.fields['invoice_id'] = invoiceId.toString();
        req.files.add(http.MultipartFile.fromBytes(
          'bukti',
          fileBytes,
          filename: fileName ?? 'bukti_transfer_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));
        final streamed = await req.send();
        final res = await http.Response.fromStream(streamed);
        return res.statusCode == 201 || res.statusCode == 200;
      } else if (filePath != null && filePath.isNotEmpty && !kIsWeb) {
        final req = http.MultipartRequest('POST', url);
        req.headers.addAll({
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        });
        req.fields['invoice_id'] = invoiceId.toString();
        req.files.add(await http.MultipartFile.fromPath('bukti', filePath));
        final streamed = await req.send();
        final res = await http.Response.fromStream(streamed);
        return res.statusCode == 201 || res.statusCode == 200;
      } else {
        // Fallback simulation
        final res = await http.post(
          url,
          headers: _headers,
          body: jsonEncode({
            'invoice_id': invoiceId,
            'bukti_path': '/uploads/sample_receipt.png',
          }),
        );
        return res.statusCode == 201 || res.statusCode == 200;
      }
    } catch (e) {
      debugPrint('[ApiService] uploadPaymentProof error: $e');
      return false;
    }
  }

  Future<bool> verifyPayment(int paymentId, {required bool approve}) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/payments/$paymentId/verify');
      final res = await http.patch(
        url,
        headers: _headers,
        body: jsonEncode({'status': approve ? 'diverifikasi' : 'ditolak'}),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] verifyPayment error: $e');
      return false;
    }
  }

  // --- BLOCKCHAIN LEDGER ---
  Future<List<LedgerBlockModel>> getLedger() async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/ledger');
      final res = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['ledger'] is List) {
          return (data['ledger'] as List)
              .map((b) => LedgerBlockModel.fromJson(b))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[ApiService] getLedger error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> verifyLedger() async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/ledger/verify');
      final res = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 6));
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[ApiService] verifyLedger error: $e');
      return {
        'success': false,
        'message': 'Gagal menjalankan verifikasi hash chain: $e',
      };
    }
  }

  // --- TASKS (TEKNISI & ADMIN) ---
  Future<List<TaskModel>> getTasks() async {
    const cacheKey = 'tasks';
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/tasks');
      final res = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['tasks'] is List) {
          final list = (data['tasks'] as List)
              .map((t) => TaskModel.fromJson(t))
              .toList();
          await LocalDbService.instance.saveCache(cacheKey, data['tasks']);
          return list;
        }
      }
    } catch (e) {
      debugPrint('[ApiService] getTasks error: $e. Loading from cache...');
    }

    final cached = await LocalDbService.instance.getCache(cacheKey);
    if (cached is List) {
      return cached.map((t) => TaskModel.fromJson(t)).toList();
    }
    return [];
  }

  Future<bool> createTask({
    required int teknisiId,
    required int pelangganId,
    required String jenis,
    required String catatan,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/tasks');
      final res = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'teknisi_id': teknisiId,
          'pelanggan_id': pelangganId,
          'jenis': jenis,
          'catatan': catatan,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('[ApiService] createTask error: $e');
      return false;
    }
  }

  Future<bool> updateTaskStatus(int taskId, String status) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/tasks/$taskId');
      final res = await http.patch(
        url,
        headers: _headers,
        body: jsonEncode({'status': status}),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] updateTaskStatus error: $e');
      return false;
    }
  }

  // --- UPSTREAM BILLS & REPORT SUMMARY ---
  Future<List<UpstreamBillModel>> getUpstreamBills() async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/upstream-bills');
      final res = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['upstream_bills'] is List) {
          return (data['upstream_bills'] as List)
              .map((b) => UpstreamBillModel.fromJson(b))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[ApiService] getUpstreamBills error: $e');
    }
    return [];
  }

  Future<bool> createUpstreamBill({
    required String periode,
    required int nominalIdr,
    required String providerName,
    required String status,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/upstream-bills');
      final res = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'periode': periode,
          'nominal_idr': nominalIdr,
          'provider_name': providerName,
          'status': status,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('[ApiService] createUpstreamBill error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getReportSummary() async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/reports/summary');
      final res = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['summary'];
      }
    } catch (e) {
      debugPrint('[ApiService] getReportSummary error: $e');
    }
    return null;
  }

  // --- AI ANALYTICS (NON-LLM) ---
  Future<Map<String, dynamic>?> getForecast() async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/analytics/forecast');
      final res = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('[ApiService] getForecast error: $e');
    }
    return null;
  }

  // --- COMPOSITE AI: ML REGRESSION + GROQ LLM INSIGHT ---
  Future<Map<String, dynamic>?> runAiInsightAnalysis() async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/analytics/analyze-insight');
      final res = await http
          .post(url, headers: _headers)
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('[ApiService] runAiInsightAnalysis error: $e');
    }
    return null;
  }

  Future<List<dynamic>> getLateRisk() async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/analytics/late-risk');
      final res = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['late_risks'] ?? [];
      }
    } catch (e) {
      debugPrint('[ApiService] getLateRisk error: $e');
    }
    return [];
  }

  // --- LLM CHATBOT PROXY ---
  Future<String> sendChatMessage(String message) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/chat');
      final res = await http
          .post(url, headers: _headers, body: jsonEncode({'message': message}))
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['reply'] ?? 'Tidak ada respon dari AI assistant.';
      }
    } catch (e) {
      debugPrint('[ApiService] sendChatMessage error: $e');
    }
    return 'Halo! Maaf, koneksi ke server AI CS sedang sibuk. Silakan pastikan modem menyala dan lampu indikator LOS tidak berkedip merah.';
  }

  // --- RATES ---
  Future<Map<String, double>> getExchangeRates() async {
    const cacheKey = 'rates';
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/rates');
      final res = await http.get(url).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final map = (data['data']['idrPerCurrency'] as Map).map(
          (k, v) =>
              MapEntry(k.toString(), double.tryParse(v.toString()) ?? 1.0),
        );
        await LocalDbService.instance.saveCache(cacheKey, map);
        return map;
      }
    } catch (e) {
      debugPrint(
        '[ApiService] getExchangeRates error: $e. Using offline rates.',
      );
    }

    final cached = await LocalDbService.instance.getCache(cacheKey);
    if (cached is Map) {
      return cached.map(
        (k, v) => MapEntry(k.toString(), double.tryParse(v.toString()) ?? 1.0),
      );
    }
    return AppConfig.idrPerCurrency;
  }

  // --- FEEDBACK ---
  Future<List<FeedbackModel>> getFeedback() async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/feedback');
      final res = await http.get(url).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['feedback'] is List) {
          return (data['feedback'] as List)
              .map((f) => FeedbackModel.fromJson(f))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[ApiService] getFeedback error: $e');
    }
    return [];
  }

  Future<bool> submitFeedback({
    required String saran,
    required String kesan,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/feedback');
      final res = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({'saran': saran, 'kesan': kesan}),
      );
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('[ApiService] submitFeedback error: $e');
      return false;
    }
  }
}
