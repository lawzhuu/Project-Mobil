import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/invoice_model.dart';
import '../../models/ledger_model.dart';
import '../../models/package_model.dart';
import '../../models/package_request_model.dart';
import '../../models/upstream_bill_model.dart';
import '../local_db_service.dart';
import 'http_client.dart';

class BillingApi {
  final ApiClient _client;
  BillingApi([ApiClient? client]) : _client = client ?? ApiClient.instance;

  // --- INVOICES & PAYMENTS ---
  Future<List<InvoiceModel>> getInvoices() async {
    const cacheKey = 'invoices';
    try {
      final res = await _client.get('/invoices', timeout: const Duration(seconds: 6));
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
      debugPrint('[BillingApi] getInvoices error: $e. Loading from cache...');
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
      final res = await _client.post('/invoices', body: {
        'user_id': userId,
        'periode': periode,
        'nominal_idr': nominalIdr,
        'jatuh_tempo': jatuhTempo,
      });
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('[BillingApi] createInvoice error: $e');
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
      final url = _client.buildUri('/payments');
      if (fileBytes != null && fileBytes.isNotEmpty) {
        final req = http.MultipartRequest('POST', url);
        req.fields['invoice_id'] = invoiceId.toString();
        req.files.add(http.MultipartFile.fromBytes(
          'bukti',
          fileBytes,
          filename: fileName ?? 'bukti_transfer_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));
        final res = await _client.sendMultipart(req);
        return res.statusCode == 201 || res.statusCode == 200;
      } else if (filePath != null && filePath.isNotEmpty && !kIsWeb) {
        final req = http.MultipartRequest('POST', url);
        req.fields['invoice_id'] = invoiceId.toString();
        req.files.add(await http.MultipartFile.fromPath('bukti', filePath));
        final res = await _client.sendMultipart(req);
        return res.statusCode == 201 || res.statusCode == 200;
      } else {
        final res = await _client.post('/payments', body: {
          'invoice_id': invoiceId,
          'bukti_path': '/uploads/sample_receipt.png',
        });
        return res.statusCode == 201 || res.statusCode == 200;
      }
    } catch (e) {
      debugPrint('[BillingApi] uploadPaymentProof error: $e');
      return false;
    }
  }

  Future<bool> verifyPayment(int paymentId, {required bool approve}) async {
    try {
      final res = await _client.patch(
        '/payments/$paymentId/verify',
        body: {'status': approve ? 'diverifikasi' : 'ditolak'},
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[BillingApi] verifyPayment error: $e');
      return false;
    }
  }

  // --- PACKAGES & SUBSCRIPTION ---
  Future<List<PackageModel>> getPackages() async {
    const cacheKey = 'packages';
    try {
      final res = await _client.get('/packages', timeout: const Duration(seconds: 5));
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
      debugPrint('[BillingApi] getPackages error: $e. Loading from cache...');
    }

    final cached = await LocalDbService.instance.getCache(cacheKey);
    if (cached is List) {
      return cached.map((p) => PackageModel.fromJson(p)).toList();
    }

    return [
      PackageModel(id: 1, nama: 'Paket Hemat Fiber 20', kecepatanMbps: 20, hargaIdr: 175000, deskripsi: 'Akses internet stabil unlimited untuk keluarga.'),
      PackageModel(id: 2, nama: 'Paket Turbo Home 50', kecepatanMbps: 50, hargaIdr: 275000, deskripsi: 'Kecepatan tinggi untuk streaming 4K & gaming.'),
      PackageModel(id: 3, nama: 'Paket Ultimate Pro 100', kecepatanMbps: 100, hargaIdr: 450000, deskripsi: 'Koneksi ultra-cepat untuk profesional.'),
    ];
  }

  Future<bool> createPackage({
    required String nama,
    required int kecepatanMbps,
    required int hargaIdr,
    required String deskripsi,
  }) async {
    try {
      final res = await _client.post('/packages', body: {
        'nama': nama,
        'kecepatan_mbps': kecepatanMbps,
        'harga_idr': hargaIdr,
        'deskripsi': deskripsi,
      });
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('[BillingApi] createPackage error: $e');
      return false;
    }
  }

  Future<bool> deletePackage(int id) async {
    try {
      final res = await _client.delete('/packages/$id');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[BillingApi] deletePackage error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> submitPackageChangeRequest({
    required int packageId,
    required String tipe,
    required String alasan,
  }) async {
    try {
      final res = await _client.post(
        '/packages/change-request',
        body: {'paket_id': packageId, 'tipe': tipe, 'alasan': alasan},
        timeout: const Duration(seconds: 10),
      );
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[BillingApi] submitPackageChangeRequest error: $e');
      return {'success': false, 'message': 'Gagal mengajukan perubahan paket: $e'};
    }
  }

  Future<PackageRequestModel?> getCustomerPendingPackageRequest() async {
    try {
      final res = await _client.get('/customer/change-request', timeout: const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['pending'] != null) {
          return PackageRequestModel.fromJson(data['pending']);
        }
      }
    } catch (e) {
      debugPrint('[BillingApi] getCustomerPendingPackageRequest error: $e');
    }
    return null;
  }

  Future<List<PackageRequestModel>> getAdminPackageRequests() async {
    try {
      final res = await _client.get('/admin/package-requests', timeout: const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['requests'] is List) {
          return (data['requests'] as List)
              .map((r) => PackageRequestModel.fromJson(r))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[BillingApi] getAdminPackageRequests error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> approvePackageRequest(int requestId, {String? adminCatatan}) async {
    try {
      final res = await _client.post(
        '/admin/package-requests/$requestId/approve',
        body: {'admin_catatan': adminCatatan ?? 'Disetujui oleh admin'},
        timeout: const Duration(seconds: 10),
      );
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[BillingApi] approvePackageRequest error: $e');
      return {'success': false, 'message': 'Gagal menyetujui pengajuan: $e'};
    }
  }

  Future<Map<String, dynamic>> rejectPackageRequest(int requestId, {String? adminCatatan}) async {
    try {
      final res = await _client.post(
        '/admin/package-requests/$requestId/reject',
        body: {'admin_catatan': adminCatatan ?? 'Ditolak oleh admin'},
        timeout: const Duration(seconds: 10),
      );
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[BillingApi] rejectPackageRequest error: $e');
      return {'success': false, 'message': 'Gagal menolak pengajuan: $e'};
    }
  }

  // --- BLOCKCHAIN LEDGER ---
  Future<List<LedgerBlockModel>> getLedger() async {
    try {
      final res = await _client.get('/ledger', timeout: const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['ledger'] is List) {
          return (data['ledger'] as List)
              .map((b) => LedgerBlockModel.fromJson(b))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[BillingApi] getLedger error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> verifyLedger() async {
    try {
      final res = await _client.get('/ledger/verify', timeout: const Duration(seconds: 6));
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[BillingApi] verifyLedger error: $e');
      return {
        'success': false,
        'message': 'Gagal menjalankan verifikasi hash chain: $e',
      };
    }
  }

  // --- UPSTREAM BILLS ---
  Future<List<UpstreamBillModel>> getUpstreamBills() async {
    try {
      final res = await _client.get('/upstream-bills', timeout: const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['upstream_bills'] is List) {
          return (data['upstream_bills'] as List)
              .map((b) => UpstreamBillModel.fromJson(b))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[BillingApi] getUpstreamBills error: $e');
    }
    return [];
  }

  Future<bool> createUpstreamBill({
    required String periode,
    required int nominalIdr,
    required String providerName,
  }) async {
    try {
      final res = await _client.post('/upstream-bills', body: {
        'periode': periode,
        'nominal_idr': nominalIdr,
        'provider_name': providerName,
      });
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('[BillingApi] createUpstreamBill error: $e');
      return false;
    }
  }
}
