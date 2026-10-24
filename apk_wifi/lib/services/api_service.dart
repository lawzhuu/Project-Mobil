import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/feedback_model.dart';
import '../models/invoice_model.dart';
import '../models/ledger_model.dart';
import '../models/package_model.dart';
import '../models/package_request_model.dart';
import '../models/task_model.dart';
import '../models/upstream_bill_model.dart';
import '../models/user_model.dart';
import 'api/analytics_api.dart';
import 'api/auth_api.dart';
import 'api/billing_api.dart';
import 'api/http_client.dart';
import 'api/task_api.dart';

/// Facade ApiService delegating to domain-specific API clients
/// (AuthApi, BillingApi, TaskApi, AnalyticsApi).
class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  final ApiClient client = ApiClient.instance;
  final AuthApi auth = AuthApi();
  final BillingApi billing = BillingApi();
  final TaskApi task = TaskApi();
  final AnalyticsApi analytics = AnalyticsApi();

  void setAuthToken(String? token) {
    client.setAuthToken(token);
  }

  // --- AUTH & PROFILE ---
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) => auth.login(username: username, password: password);

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
  }) => auth.register(
        nama: nama,
        email: email,
        noHp: noHp,
        password: password,
        negara: negara,
        alamat: alamat,
        lat: lat,
        lng: lng,
        paketId: paketId,
      );

  Future<UserModel?> getMe() => auth.getMe();
  Future<UserModel?> getProfile() => auth.getProfile();

  Future<Map<String, dynamic>> updateProfile({
    required String nama,
    required String noHp,
    required String negara,
    required String mataUang,
    required String zonaWaktu,
    required String alamat,
    required double lat,
    required double lng,
  }) => auth.updateProfile(
        nama: nama,
        noHp: noHp,
        negara: negara,
        mataUang: mataUang,
        zonaWaktu: zonaWaktu,
        alamat: alamat,
        lat: lat,
        lng: lng,
      );

  Future<Map<String, dynamic>> uploadProfilePhoto({
    File? file,
    Uint8List? fileBytes,
    String? fileName,
  }) => auth.uploadProfilePhoto(file: file, fileBytes: fileBytes, fileName: fileName);

  // --- PACKAGES & REQUESTS ---
  Future<List<PackageModel>> getPackages() => billing.getPackages();

  Future<bool> createPackage({
    required String nama,
    required int kecepatanMbps,
    required int hargaIdr,
    required String deskripsi,
  }) => billing.createPackage(
        nama: nama,
        kecepatanMbps: kecepatanMbps,
        hargaIdr: hargaIdr,
        deskripsi: deskripsi,
      );

  Future<bool> deletePackage(int id) => billing.deletePackage(id);

  Future<Map<String, dynamic>> submitPackageChangeRequest({
    required int packageId,
    required String tipe,
    required String alasan,
  }) => billing.submitPackageChangeRequest(
        packageId: packageId,
        tipe: tipe,
        alasan: alasan,
      );

  Future<PackageRequestModel?> getCustomerPendingPackageRequest() =>
      billing.getCustomerPendingPackageRequest();

  Future<List<PackageRequestModel>> getAdminPackageRequests() =>
      billing.getAdminPackageRequests();

  Future<Map<String, dynamic>> approvePackageRequest(int requestId, {String? adminCatatan}) =>
      billing.approvePackageRequest(requestId, adminCatatan: adminCatatan);

  Future<Map<String, dynamic>> rejectPackageRequest(int requestId, {String? adminCatatan}) =>
      billing.rejectPackageRequest(requestId, adminCatatan: adminCatatan);

  // --- CUSTOMERS & STAFF ---
  Future<List<UserModel>> getCustomers() => analytics.getCustomers();

  Future<bool> activateCustomer(int customerId, {int? paketId}) =>
      analytics.activateCustomer(customerId, paketId: paketId);

  Future<bool> createStaff({
    required String nama,
    required String email,
    required String noHp,
    required String password,
    required String role,
    required String alamat,
  }) => analytics.createStaff(
        nama: nama,
        email: email,
        noHp: noHp,
        password: password,
        role: role,
        alamat: alamat,
      );

  // --- INVOICES & PAYMENTS ---
  Future<List<InvoiceModel>> getInvoices() => billing.getInvoices();

  Future<bool> createInvoice({
    required int userId,
    required String periode,
    required int nominalIdr,
    required String jatuhTempo,
  }) => billing.createInvoice(
        userId: userId,
        periode: periode,
        nominalIdr: nominalIdr,
        jatuhTempo: jatuhTempo,
      );

  Future<bool> uploadPaymentProof({
    required int invoiceId,
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
  }) => billing.uploadPaymentProof(
        invoiceId: invoiceId,
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
      );

  Future<bool> verifyPayment(int paymentId, {required bool approve}) =>
      billing.verifyPayment(paymentId, approve: approve);

  // --- BLOCKCHAIN LEDGER ---
  Future<List<LedgerBlockModel>> getLedger() => billing.getLedger();
  Future<Map<String, dynamic>> verifyLedger() => billing.verifyLedger();

  // --- TASKS ---
  Future<List<TaskModel>> getTasks({bool myTasks = false}) =>
      task.getTasks(myTasks: myTasks);

  Future<bool> claimTask(int taskId) => task.claimTask(taskId);

  Future<bool> createTask({
    required int teknisiId,
    required int pelangganId,
    required String jenis,
    required String catatan,
  }) => task.createTask(
        teknisiId: teknisiId,
        pelangganId: pelangganId,
        jenis: jenis,
        catatan: catatan,
      );

  Future<bool> updateTaskStatus(int taskId, String status, {int? teknisiId}) =>
      task.updateTaskStatus(taskId, status, teknisiId: teknisiId);

  // --- UPSTREAM BILLS & REPORT SUMMARY ---
  Future<List<UpstreamBillModel>> getUpstreamBills() => billing.getUpstreamBills();

  Future<bool> createUpstreamBill({
    required String periode,
    required int nominalIdr,
    required String providerName,
    String status = 'belum',
  }) => billing.createUpstreamBill(
        periode: periode,
        nominalIdr: nominalIdr,
        providerName: providerName,
      );

  Future<Map<String, dynamic>?> getReportSummary() => analytics.getReportSummary();

  // --- AI ANALYTICS & FORECAST ---
  Future<Map<String, dynamic>?> getForecast() => analytics.getForecast();

  Future<Map<String, dynamic>?> runAiInsightAnalysis() =>
      analytics.runAiInsightAnalysis();

  Future<List<dynamic>> getLateRisk() => analytics.getLateRisk();

  // --- LLM CHATBOT PROXY ---
  Future<String> sendChatMessage(String message) async {
    final res = await auth.sendChatMessage(message);
    return res['reply'] ?? 'Halo! Maaf, koneksi ke server AI CS sedang sibuk.';
  }

  // --- RATES ---
  Future<Map<String, double>> getExchangeRates() => analytics.getExchangeRates();

  // --- FEEDBACK ---
  Future<List<FeedbackModel>> getFeedback() => auth.getFeedbacks();

  Future<bool> submitFeedback({
    required String saran,
    required String kesan,
  }) async {
    final res = await auth.submitFeedback(saran: saran, kesan: kesan);
    return res['success'] == true;
  }
}
