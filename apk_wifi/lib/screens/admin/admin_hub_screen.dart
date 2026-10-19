import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/invoice_model.dart';
import '../../models/ledger_model.dart';
import '../../models/package_request_model.dart';
import '../../models/upstream_bill_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/blockchain_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/glowing_button.dart';
import '../../widgets/stat_metric_card.dart';
import '../../widgets/status_badge.dart';

class AdminHubScreen extends StatefulWidget {
  const AdminHubScreen({super.key});

  @override
  State<AdminHubScreen> createState() => _AdminHubScreenState();
}

class _AdminHubScreenState extends State<AdminHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data states
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _forecastData;
  List<UserModel> _customers = [];
  List<InvoiceModel> _invoices = [];
  List<LedgerBlockModel> _ledgerBlocks = [];
  List<UpstreamBillModel> _upstreamBills = [];
  List<PackageRequestModel> _packageRequests = [];

  bool _isLoading = true;
  int? _selectedSection; // null = Executive Dashboard Hub, 0..5 = Modul detail
  VerificationResult? _blockchainVerification;
  bool _isVerifyingLedger = false;
  bool _isAnalyzingAi = false;
  Map<String, dynamic>? _aiInsightResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadAllAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllAdminData() async {
    setState(() => _isLoading = true);

    try {
      final summaryFuture = ApiService.instance.getReportSummary();
      final forecastFuture = ApiService.instance.getForecast();
      final customersFuture = ApiService.instance.getCustomers();
      final invoicesFuture = ApiService.instance.getInvoices();
      final ledgerFuture = ApiService.instance.getLedger();
      final upstreamFuture = ApiService.instance.getUpstreamBills();
      final pkgReqsFuture = ApiService.instance.getAdminPackageRequests();

      final results = await Future.wait([
        summaryFuture,
        forecastFuture,
        customersFuture,
        invoicesFuture,
        ledgerFuture,
        upstreamFuture,
        pkgReqsFuture,
      ]);

      if (mounted) {
        setState(() {
          _summary = results[0] as Map<String, dynamic>?;
          _forecastData = results[1] as Map<String, dynamic>?;
          _customers = results[2] as List<UserModel>;
          _invoices = results[3] as List<InvoiceModel>;
          _ledgerBlocks = results[4] as List<LedgerBlockModel>;
          _upstreamBills = results[5] as List<UpstreamBillModel>;
          _packageRequests = results[6] as List<PackageRequestModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[AdminHub] Error loading admin data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- TRIGGER COMPOSITE AI: ML REGRESSION + GROQ LLM INSIGHT ---
  Future<void> _triggerAiInsightAnalysis() async {
    setState(() => _isAnalyzingAi = true);
    try {
      final res = await ApiService.instance.runAiInsightAnalysis();
      if (res != null && res['success'] == true) {
        setState(() {
          _aiInsightResult = res;
          _forecastData = res;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ Analisis AI & Groq LLM Insight berhasil digenerate!'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menjalankan analisis AI.'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[AdminHub] Error triggering AI analysis: $e');
    } finally {
      if (mounted) setState(() => _isAnalyzingAi = false);
    }
  }

  // --- ACTIONS ---
  Future<void> _activateCustomerDialog(UserModel customer) async {
    int selectedPackageId = customer.paketId ?? 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: Text(
            'Aktivasi Pelanggan #${customer.id}',
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nama: ${customer.nama}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Alamat: ${customer.alamat}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              Text(
                'Mata Uang: ${customer.mataUang} (${customer.zonaWaktu})',
                style: const TextStyle(color: AppTheme.accent, fontSize: 12),
              ),
              const SizedBox(height: 14),
              const Text(
                'Tetapkan Paket & Buat Tagihan Perdana:',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: selectedPackageId,
                dropdownColor: AppTheme.surfaceCard,
                decoration: const InputDecoration(labelText: 'Paket Fiber'),
                items: const [
                  DropdownMenuItem(
                    value: 1,
                    child: Text('Hemat 20 Mbps (Rp 175.000)'),
                  ),
                  DropdownMenuItem(
                    value: 2,
                    child: Text('Turbo 50 Mbps (Rp 275.000)'),
                  ),
                  DropdownMenuItem(
                    value: 3,
                    child: Text('Ultimate 100 Mbps (Rp 450.000)'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedPackageId = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await ApiService.instance.activateCustomer(
                  customer.id,
                  paketId: selectedPackageId,
                );
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Akun ${customer.nama} berhasil DIAKTIFKAN dan tagihan perdana telah dibuat dengan kurs terkunci!',
                      ),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                  _loadAllAdminData();
                }
              },
              child: const Text('Aktivasi Sekarang'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyPaymentAction(InvoiceModel invoice, bool approve) async {
    final payment = invoice.payment;
    if (payment == null) return;

    final ok = await ApiService.instance.verifyPayment(
      payment.id,
      approve: approve,
    );
    if (ok) {
      if (approve) {
        NotificationService.instance.notifyPaymentVerified(
          invoicePeriod: invoice.periode,
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? '✅ Pembayaran diverifikasi! Block SHA-256 berhasil ditulis ke ledger blockchain.'
                : '❌ Pembayaran ditolak.',
          ),
          backgroundColor: approve ? AppTheme.success : AppTheme.error,
        ),
      );
      _loadAllAdminData();
    }
  }

  Future<void> _runLedgerVerification() async {
    setState(() => _isVerifyingLedger = true);
    final result = await BlockchainService.instance.verifyServerChain();
    if (mounted) {
      setState(() {
        _blockchainVerification = result;
        _isVerifyingLedger = false;
      });
    }
  }

  void _showAddUpstreamBillDialog() {
    final periodeCtrl = TextEditingController(text: 'November 2026');
    final nominalCtrl = TextEditingController(text: '4500000');
    final providerCtrl = TextEditingController(text: 'Indibizz Dedicated 500M');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text(
          'Catat Tagihan ISP Utama (A4)',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: providerCtrl,
              decoration: const InputDecoration(
                labelText: 'Penyedia ISP Utama (e.g. Indibizz)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: periodeCtrl,
              decoration: const InputDecoration(labelText: 'Periode Tagihan'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nominalCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nominal Beban IDR',
                prefixText: 'Rp ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ApiService.instance.createUpstreamBill(
                periode: periodeCtrl.text.trim(),
                nominalIdr: int.tryParse(nominalCtrl.text.trim()) ?? 4500000,
                providerName: providerCtrl.text.trim(),
                status: 'lunas',
              );
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tagihan ISP utama berhasil dicatat!'),
                    backgroundColor: AppTheme.success,
                  ),
                );
                _loadAllAdminData();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAssignTaskDialog() {
    final catatanCtrl = TextEditingController();
    String jenis = 'instalasi';
    int? selectedCustomerId;

    final customers = _customers.where((c) => c.status == 'active').toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: const Text(
            'Tugaskan Pekerjaan ke Teknisi (A5)',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedCustomerId,
                dropdownColor: AppTheme.surfaceCard,
                decoration: const InputDecoration(labelText: 'Pilih Pelanggan'),
                items: customers
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(
                          '${c.nama} (${c.alamat})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedCustomerId = v),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: jenis,
                dropdownColor: AppTheme.surfaceCard,
                decoration: const InputDecoration(labelText: 'Jenis Tugas'),
                items: const [
                  DropdownMenuItem(
                    value: 'instalasi',
                    child: Text('Pasang Baru / Tarik FO'),
                  ),
                  DropdownMenuItem(
                    value: 'perbaikan',
                    child: Text('Perbaikan Redaman / Putus Kabel'),
                  ),
                ],
                onChanged: (v) =>
                    setDialogState(() => jenis = v ?? 'instalasi'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: catatanCtrl,
                decoration: const InputDecoration(
                  labelText: 'Catatan Lapangan',
                  hintText: 'Misal: ODP-SLM-08 Port 4',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedCustomerId == null) return;
                Navigator.pop(ctx);
                final ok = await ApiService.instance.createTask(
                  teknisiId: 4, // Default technician Rahmat
                  pelangganId: selectedCustomerId!,
                  jenis: jenis,
                  catatan: catatanCtrl.text.trim(),
                );
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tugas berhasil ditugaskan ke teknisi!'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              },
              child: const Text('Kirim Tugas'),
            ),
          ],
        ),
      ),
    );
  }

  String _getSectionTitle(int index) {
    switch (index) {
      case 0:
        return 'AI & Analisis Finansial';
      case 1:
        return 'Aktivasi Pelanggan';
      case 2:
        return 'Pengajuan Ubah Paket';
      case 3:
        return 'Verifikasi Pembayaran';
      case 4:
        return 'Blockchain Ledger';
      case 5:
        return 'Penugasan Teknisi';
      case 6:
        return 'Tagihan ISP Utama (Upstream)';
      default:
        return 'Admin Operations Hub';
    }
  }

  Widget _buildSectionDetail(int index) {
    switch (index) {
      case 0:
        return _buildAiAnalyticsTab();
      case 1:
        return _buildCustomerActivationTab();
      case 2:
        return _buildPackageRequestsTab();
      case 3:
        return _buildPaymentVerificationTab();
      case 4:
        return _buildBlockchainLedgerTab();
      case 5:
        return _buildTaskDispatchTab();
      case 6:
        return _buildUpstreamBillsTab();
      default:
        return _buildAiAnalyticsTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedSection == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_selectedSection != null) {
          setState(() => _selectedSection = null);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _selectedSection != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  tooltip: 'Kembali ke Hub',
                  onPressed: () => setState(() => _selectedSection = null),
                )
              : null,
          title: _selectedSection == null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.admin_panel_settings,
                          color: AppTheme.primary,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Admin Operations Hub'),
                  ],
                )
              : Text(_getSectionTitle(_selectedSection!)),
          actions: [
            if (_selectedSection != null)
              IconButton(
                icon: const Icon(Icons.dashboard_outlined),
                tooltip: 'Kembali ke Dashboard Utama',
                onPressed: () => setState(() => _selectedSection = null),
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Segarkan Data',
              onPressed: _loadAllAdminData,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : (_selectedSection == null
                ? _buildExecutiveHubDashboard()
                : _buildSectionDetail(_selectedSection!)),
      ),
    );
  }

  // --- EXECUTIVE HUB DASHBOARD (GRID MENU & EXECUTIVE SUMMARY) ---
  Widget _buildExecutiveHubDashboard() {
    final rev = (_summary?['total_revenue_idr'] as num?)?.toDouble() ?? 725000.0;
    final growth = _forecastData?['growth_rate_pct'] ?? 16.5;

    final forecastList = (_forecastData?['forecast'] as List?) ?? [];
    final nextForecast = forecastList.isNotEmpty ? forecastList[0] : null;
    final nextMonthNominalJt = nextForecast != null
        ? ((nextForecast['pemasukan'] as num) / 1000000).toStringAsFixed(1)
        : '10.8';

    final pendingActivations = _customers.where((c) => c.status == 'pending').length;
    final pendingPackageReqs = _packageRequests.where((r) => r.status == 'pending').length;
    final unpaidInvoices = _invoices.where((i) => i.status == 'belum').length;
    final activeTasks = (_summary?['active_tasks_count'] as num?)?.toInt() ?? 1;

    return RefreshIndicator(
      onRefresh: _loadAllAdminData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Metrik Kunci Ringkas (Pemasukan Realtime & Estimasi AI)
            Row(
              children: [
                Expanded(
                  child: StatMetricCard(
                    title: 'Pemasukan Realtime',
                    value: 'Rp ${(rev / 1000).toStringAsFixed(0)}K',
                    icon: Icons.payments_rounded,
                    iconColor: AppTheme.success,
                    trend: '+$growth% MoM',
                    subtitle: 'Bulan berjalan',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatMetricCard(
                    title: 'Estimasi Bulan Depan',
                    value: 'Rp $nextMonthNominalJt Juta',
                    icon: Icons.trending_up_rounded,
                    iconColor: AppTheme.accent,
                    subtitle: 'AI Proyeksi ML',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // CTA: Selengkapnya Soal Keuangan (Tampilan Normal Tanpa Gradien)
            InkWell(
              onTap: () => setState(() => _selectedSection = 0),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Selengkapnya Soal Keuangan & Proyeksi AI',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Laporan cashflow, laba rugi, dan forecasting ML',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 2. Strip Minimalis Tindakan Diperlukan (Notifikasi Merah Seragam)
            if (pendingActivations > 0 || pendingPackageReqs > 0 || unpaidInvoices > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        [
                          if (pendingPackageReqs > 0) '$pendingPackageReqs pengajuan paket',
                          if (pendingActivations > 0) '$pendingActivations aktivasi baru',
                          if (unpaidInvoices > 0) '$unpaidInvoices tagihan belum lunas',
                        ].join(' • '),
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        if (pendingPackageReqs > 0) {
                          setState(() => _selectedSection = 2);
                        } else if (pendingActivations > 0) {
                          setState(() => _selectedSection = 1);
                        } else {
                          setState(() => _selectedSection = 3);
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Tinjau',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFFEF4444),
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 3. Header Modul Operasional List Beraksen
            const Padding(
              padding: EdgeInsets.only(left: 2, bottom: 10),
              child: Text(
                'Menu Operasional Admin',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),

            // 4. Modul Operasional: List Beraksen tanpa icon (teks lega & tidak terpotong)
            _buildAdminAccentListItem(
              title: 'Aktivasi Pelanggan Baru',
              subtitle: 'Verifikasi pendaftaran & persetujuan akun',
              accentColor: AppTheme.primary,
              badgeCount: pendingActivations,
              onTap: () => setState(() => _selectedSection = 1),
            ),
            _buildAdminAccentListItem(
              title: 'Pengajuan Ubah Paket',
              subtitle: 'Permintaan upgrade / downgrade kecepatan',
              accentColor: Colors.amber,
              badgeCount: pendingPackageReqs,
              onTap: () => setState(() => _selectedSection = 2),
            ),
            _buildAdminAccentListItem(
              title: 'Verifikasi Pembayaran',
              subtitle: 'Pengecekan bukti transfer & status invoice',
              accentColor: AppTheme.accent,
              badgeCount: unpaidInvoices,
              onTap: () => setState(() => _selectedSection = 3),
            ),
            _buildAdminAccentListItem(
              title: 'Penugasan Teknisi',
              subtitle: 'Disposisi tiket gangguan & pekerjaan instalasi',
              accentColor: Colors.lightBlueAccent,
              badgeCount: activeTasks,
              onTap: () => setState(() => _selectedSection = 5),
            ),
            _buildAdminAccentListItem(
              title: 'Blockchain Ledger',
              subtitle: 'Audit jejak pembayaran anti-tamper SHA-256',
              accentColor: Colors.tealAccent,
              badgeCount: 0,
              onTap: () => setState(() => _selectedSection = 4),
            ),
            _buildAdminAccentListItem(
              title: 'Tagihan ISP Utama (Upstream)',
              subtitle: 'Rekap biaya internet induk & bandwidth grosir',
              accentColor: Colors.deepPurpleAccent,
              badgeCount: 0,
              onTap: () => setState(() => _selectedSection = 6),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Helper widget: List item beraksen tanpa icon (teks luas tanpa kepotong) dengan badge merah seragam
  Widget _buildAdminAccentListItem({
    required String title,
    required String subtitle,
    required Color accentColor,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Garis Aksen Berwarna di sisi kiri
                Container(
                  width: 5,
                  color: accentColor,
                ),
                // Konten Teks (Judul & Subtitle Lega)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Badge Notifikasi (Warna Merah Seragam untuk Semua Status Tindakan)
                if (badgeCount > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- TAB 1: AI & REVENUE FORECAST (PRIORITAS PEMASUKAN & LLM INSIGHT) ---
  Widget _buildAiAnalyticsTab() {
    final rev = _summary?['total_revenue_idr'] ?? 725000;
    final cost = _summary?['total_upstream_cost_idr'] ?? 4500000;
    final growth = _forecastData?['growth_rate_pct'] ?? 16.5;
    final confidenceScore = ((_forecastData?['model_r2'] ?? 0.94) * 100).toStringAsFixed(0);

    // Ambil data historis & proyeksi masa depan dari respons AI
    final historicalList = (_forecastData?['historical'] as List?) ?? [
      {'bulan': 'Mei', 'pemasukan': 3200000},
      {'bulan': 'Jun', 'pemasukan': 4100000},
      {'bulan': 'Jul', 'pemasukan': 5300000},
      {'bulan': 'Agt', 'pemasukan': 6800000},
      {'bulan': 'Sep', 'pemasukan': 7900000},
      {'bulan': 'Okt', 'pemasukan': 9200000},
    ];

    final forecastList = (_forecastData?['forecast'] as List?) ?? [
      {'bulan': 'Nov 2026 (Est)', 'pemasukan': 10800000, 'confidence': 0.94}
    ];

    final nextForecast = forecastList.isNotEmpty ? forecastList[0] : null;
    final nextMonthName = nextForecast?['bulan'] ?? 'Nov 2026';
    final nextMonthNominalJt = nextForecast != null
        ? ((nextForecast['pemasukan'] as num) / 1000000).toStringAsFixed(1)
        : '10.8';

    // Susun bar rods grafik secara dinamis
    final List<BarChartGroupData> barGroups = [];
    final List<String> monthLabels = [];

    int chartIdx = 0;
    for (var h in historicalList) {
      final valJt = ((h['pemasukan'] as num? ?? 0) / 1000000).toDouble();
      final String rawBln = h['bulan']?.toString() ?? '';
      final String shortLabel = rawBln.split(' ').first;
      monthLabels.add(shortLabel);
      barGroups.add(
        BarChartGroupData(
          x: chartIdx,
          barRods: [
            BarChartRodData(
              toY: valJt,
              color: AppTheme.primary,
              width: 14,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
      chartIdx++;
    }

    if (nextForecast != null) {
      final valJt = ((nextForecast['pemasukan'] as num? ?? 0) / 1000000).toDouble();
      monthLabels.add('Nov*');
      barGroups.add(
        BarChartGroupData(
          x: chartIdx,
          barRods: [
            BarChartRodData(
              toY: valJt,
              color: AppTheme.accent,
              width: 14,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stat Metrics Row: Prioritaskan Pemasukan & Pertumbuhan
          Row(
            children: [
              Expanded(
                child: StatMetricCard(
                  title: 'Total Pemasukan',
                  value: 'Rp ${(rev / 1000).toStringAsFixed(0)}K',
                  icon: Icons.payments,
                  iconColor: AppTheme.success,
                  trend: '+$growth% MoM',
                  subtitle: 'Bulan berjalan',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatMetricCard(
                  title: 'Estimasi Bulan Depan',
                  value: 'Rp $nextMonthNominalJt Juta',
                  icon: Icons.trending_up,
                  iconColor: AppTheme.accent,
                  trend: 'AI Predicted',
                  subtitle: nextMonthName.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatMetricCard(
                  title: 'Beban Upstream',
                  value: 'Rp ${(cost / 1000).toStringAsFixed(0)}K',
                  icon: Icons.account_balance_wallet,
                  iconColor: AppTheme.warning,
                  trend: 'Terkontrol',
                  subtitle: 'Pengeluaran ISP',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatMetricCard(
                  title: 'Akurasi Model (R²)',
                  value: '$confidenceScore%',
                  icon: Icons.verified,
                  iconColor: AppTheme.primary,
                  subtitle: 'Linear Regression ML',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // GRAFIK AI REVENUE FORECAST (DINAMIS DARI MACHINE LEARNING)
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: const [
                          Icon(
                            Icons.auto_graph,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tren & Prediksi Pemasukan (AI ML)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'R² $confidenceScore%',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Model Regresi Linier menghitung tren pertumbuhan omset reseller ISP berdasarkan data aktual:',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),

                // Interactive Dynamic Chart
                SizedBox(
                  height: 190,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 16,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final i = val.toInt();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  i < monthLabels.length ? monthLabels[i] : '',
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (val, meta) {
                              return Text(
                                '${val.toInt()}Jt',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 9,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (val) => FlLine(
                          color: AppTheme.border.withOpacity(0.4),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: barGroups,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppTheme.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '*$nextMonthName: Estimasi Rp $nextMonthNominalJt Juta (Pertumbuhan rata-rata +$growth% MoM)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // TOMBOL START ANALISIS AI & GENERATE LLM INSIGHT
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: const [
                    Icon(Icons.psychology, color: AppTheme.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'AI & LLM Financial Intelligence',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Jalankan model Machine Learning untuk menganalisis keuangan dan biarkan Groq LLM mentranslasikan angka menjadi narasi rekomendasi strategi bisnis.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),

                // Action Button
                ElevatedButton.icon(
                  onPressed: _isAnalyzingAi ? null : _triggerAiInsightAnalysis,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  icon: _isAnalyzingAi
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome, size: 20),
                  label: Text(
                    _isAnalyzingAi
                        ? 'Sedang Menganalisis dengan AI & Groq...'
                        : 'Mulai Analisis AI & Generate Insight',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // HASIL INSIGHT LLM CARD
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _aiInsightResult != null
                          ? AppTheme.primary.withOpacity(0.5)
                          : AppTheme.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb,
                                size: 16,
                                color: _aiInsightResult != null
                                    ? AppTheme.accent
                                    : AppTheme.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _aiInsightResult != null
                                    ? 'Insight Hasil Analisis AI'
                                    : 'Belum Ada Analisis yang Dijalankan',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _aiInsightResult != null
                                      ? AppTheme.textPrimary
                                      : AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                          if (_aiInsightResult != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _aiInsightResult?['source']?.toString().contains('Groq') == true
                                    ? 'Groq AI Live'
                                    : (_aiInsightResult?['source']?.toString().contains('Gemini') == true
                                        ? 'Google Gemini Live'
                                        : 'ML Engine'),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _aiInsightResult?['insight_text'] ??
                            'Tekan tombol "Mulai Analisis AI & Generate Insight" di atas. Sistem akan menghitung model regresi linier pemasukan dan meminta Groq LLM merangkum narasi proyeksi serta rekomendasi bisnis untuk Anda.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: _aiInsightResult != null
                              ? AppTheme.textPrimary
                              : AppTheme.textMuted,
                        ),
                      ),
                      if (_aiInsightResult?['timestamp'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Dianalisis pada: ${_aiInsightResult!['timestamp']}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: CUSTOMER ACTIVATION (A1, A2) ---
  Widget _buildCustomerActivationTab() {
    final pending = _customers.where((c) => c.status == 'pending').toList();
    final active = _customers.where((c) => c.status == 'active').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pendaftaran Menunggu Aktivasi (A1)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                '${pending.length} antrean',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (pending.isEmpty)
            const CustomCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Tidak ada pendaftaran baru yang pending. Semua akun aktif! 🚀',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ),
            )
          else
            ...pending.map((c) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: CustomCard(
                  borderColor: AppTheme.warning.withOpacity(0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            c.nama,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          StatusBadge(status: 'pending'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${c.email} • ${c.noHp}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Alamat: ${c.alamat}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        'Negara: ${c.negara} (${c.mataUang} • ${c.zonaWaktu})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.accent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GlowingButton(
                        text: 'Aktifkan Akun & Tetapkan Paket (A1)',
                        icon: Icons.check,
                        color: AppTheme.success,
                        width: double.infinity,
                        onPressed: () => _activateCustomerDialog(c),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

          const SizedBox(height: 24),
          const Text(
            'Pelanggan Aktif Sima.net',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          ...active.map((c) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: CustomCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withOpacity(0.2),
                    child: Text(
                      c.nama[0],
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    c.nama,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${c.email} • ${c.negara} (${c.mataUang})',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  trailing: StatusBadge(status: 'active'),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  String _formatRupiah(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // --- TAB 3: PACKAGE CHANGE REQUESTS (APPROVAL WORKFLOW - OPTION A) ---
  Widget _buildPackageRequestsTab() {
    final pending = _packageRequests.where((r) => r.status == 'pending').toList();
    final processed = _packageRequests.where((r) => r.status != 'pending').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Permintaan Ubah Paket (Pending Requests)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${pending.length} pending',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (pending.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Center(
                child: Text(
                  'Tidak ada permintaan ubah paket yang pending. Semua request telah diproses! 👍',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...pending.map((req) {
              final isUpgrade = req.paketBaruKecepatan > req.paketLamaKecepatan;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: CustomCard(
                  borderColor: AppTheme.warning.withOpacity(0.6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              req.userNama,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isUpgrade ? const Color(0xFF059669).withOpacity(0.2) : const Color(0xFF2563EB).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              req.tipe,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isUpgrade ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${req.userEmail} • ${req.userNoHp}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      if (req.userAlamat.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Alamat: ${req.userAlamat}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                      const SizedBox(height: 10),

                      // Box Detail Perubahan Paket
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Paket Lama:', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                      Text(
                                        '${req.paketLamaNama} (${req.paketLamaKecepatan}M)',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward, size: 16, color: AppTheme.accent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Paket Baru:', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                      Text(
                                        '${req.paketBaruNama} (${req.paketBaruKecepatan}M)',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: AppTheme.border, height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Selisih Harga:', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                Text(
                                  req.selisihHarga >= 0
                                      ? '+Rp ${_formatRupiah(req.selisihHarga)} / bln'
                                      : '-Rp ${_formatRupiah(-req.selisihHarga)} / bln',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: req.selisihHarga >= 0 ? AppTheme.success : AppTheme.accent,
                                  ),
                                ),
                              ],
                            ),
                            if (req.alasan.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Alasan: "${req.alasan}"',
                                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textMuted),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Tombol Approval & Reject
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.error,
                                side: const BorderSide(color: AppTheme.error),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () => _rejectPackageRequestDialog(req),
                              child: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Setujui (Approve)', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () => _approvePackageRequestDialog(req),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

          if (processed.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Riwayat Pengajuan yang Sudah Diproses',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...processed.map((req) {
              final isApproved = req.status == 'approved';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: CustomCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              req.userNama,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              '${req.paketLamaNama} ➔ ${req.paketBaruNama}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                            if (req.adminCatatan.isNotEmpty)
                              Text(
                                'Catatan: ${req.adminCatatan}',
                                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isApproved ? AppTheme.success.withOpacity(0.2) : AppTheme.error.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isApproved ? 'Disetujui' : 'Ditolak',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isApproved ? AppTheme.success : AppTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Future<void> _approvePackageRequestDialog(PackageRequestModel req) async {
    final noteController = TextEditingController(text: 'Disetujui. Perangkat & konfigurasi siap disesuaikan.');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.success),
            const SizedBox(width: 8),
            Text(
              'Setujui Pengajuan #${req.id}',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pelanggan: ${req.userNama}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text(
              '${req.paketLamaNama} (${req.paketLamaKecepatan}M) ➔ ${req.paketBaruNama} (${req.paketBaruKecepatan}M)',
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text('Selisih Harga: Rp ${_formatRupiah(req.selisihHarga)} / bulan', style: const TextStyle(color: AppTheme.accent, fontSize: 12)),
            const SizedBox(height: 12),
            const Text('Catatan Persetujuan Admin:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: noteController,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Tulis catatan persetujuan...',
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Setujui', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService.instance.approvePackageRequest(req.id, adminCatatan: noteController.text.trim());
      if (res['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Pengajuan disetujui!'), backgroundColor: AppTheme.success),
        );
        _loadAllAdminData();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Gagal menyetujui pengajuan'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _rejectPackageRequestDialog(PackageRequestModel req) async {
    final noteController = TextEditingController(text: 'Kapasitas ODP wilayah saat ini belum memadai untuk paket ini.');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.cancel, color: AppTheme.error),
            const SizedBox(width: 8),
            Text(
              'Tolak Pengajuan #${req.id}',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pelanggan: ${req.userNama}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            const Text('Alasan Penolakan:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: noteController,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Tulis alasan penolakan...',
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tolak Pengajuan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService.instance.rejectPackageRequest(req.id, adminCatatan: noteController.text.trim());
      if (res['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Pengajuan ditolak.'), backgroundColor: AppTheme.warning),
        );
        _loadAllAdminData();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Gagal menolak pengajuan'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  // --- TAB 4: VERIFIKASI PEMBAYARAN (A3) ---
  Widget _buildPaymentVerificationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Verifikasi Pembayaran (A3)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                'Hubungkan ke Blockchain Ledger',
                style: TextStyle(fontSize: 11, color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_invoices.isEmpty)
            const Center(child: Text('Belum ada tagihan.'))
          else
            ..._invoices.map((inv) {
              final isPaid = inv.isPaid;
              final payment = inv.payment;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                child: CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tagihan #${inv.id} - ${inv.periode}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          StatusBadge(status: inv.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pelanggan: ${inv.pelangganNama ?? 'User'} (${inv.pelangganEmail ?? ''})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            inv.formattedAmount,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          Text(
                            'Dasar: ${inv.formattedAmountIdr}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),

                      if (payment != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status Bukti: ${payment.status.toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accent,
                                ),
                              ),
                              if (payment.verifiedAt != null)
                                Text(
                                  'Waktu Verifikasi: ${payment.verifiedAt}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      if (!isPaid)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.error,
                                  side: const BorderSide(color: AppTheme.error),
                                ),
                                onPressed: () =>
                                    _verifyPaymentAction(inv, false),
                                child: const Text('Tolak'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: GlowingButton(
                                text: 'Verifikasi & Tulis Ledger (A3)',
                                icon: Icons.verified,
                                color: AppTheme.success,
                                onPressed: () =>
                                    _verifyPaymentAction(inv, true),
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              '✅ Pembayaran Sah & Terverifikasi dalam Hash Chain Blockchain',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  // --- TAB 4: BLOCKCHAIN LEDGER EXPLORER (A7) ---
  Widget _buildBlockchainLedgerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomCard(
            gradient: const LinearGradient(
              colors: [Color(0xFF162544), Color(0xFF1E1F38)],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Cryptographic SHA-256 Ledger (A7)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Hash-Chain Pembayaran Terverifikasi',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.link, color: AppTheme.accent, size: 28),
                  ],
                ),
                const SizedBox(height: 14),
                GlowingButton(
                  text: 'JALANKAN VERIFIKASI INTEGRITAS RANTAI',
                  icon: Icons.check_circle_outline,
                  isLoading: _isVerifyingLedger,
                  width: double.infinity,
                  onPressed: _runLedgerVerification,
                ),
                if (_blockchainVerification != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _blockchainVerification!.isValid
                          ? AppTheme.success.withOpacity(0.15)
                          : AppTheme.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _blockchainVerification!.isValid
                            ? AppTheme.success
                            : AppTheme.error,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _blockchainVerification!.isValid
                              ? Icons.shield
                              : Icons.error,
                          color: _blockchainVerification!.isValid
                              ? AppTheme.success
                              : AppTheme.error,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _blockchainVerification!.message,
                            style: TextStyle(
                              color: _blockchainVerification!.isValid
                                  ? AppTheme.success
                                  : AppTheme.error,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'Daftar Block Pembayaran Terdesentralisasi:',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          ..._ledgerBlocks.map((block) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: CustomCard(
                borderColor: AppTheme.secondary.withOpacity(0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'BLOCK #${block.idx}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          'Payment ID: ${block.paymentId}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nominal: Rp ${block.nominalIdr}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.success,
                      ),
                    ),
                    Text(
                      'Waktu: ${block.waktu}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: AppTheme.border, height: 10),
                    const Text(
                      'Prev Hash:',
                      style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                    Text(
                      block.prevHash,
                      style: const TextStyle(
                        fontSize: 9,
                        fontFamily: 'monospace',
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Block Hash (SHA-256):',
                      style: TextStyle(fontSize: 10, color: AppTheme.primary),
                    ),
                    Text(
                      block.hash,
                      style: const TextStyle(
                        fontSize: 9,
                        fontFamily: 'monospace',
                        color: AppTheme.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // --- TAB 5: UPSTREAM ISP BILLS (A4) ---
  Widget _buildUpstreamBillsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tagihan ISP Utama (A4)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Catat Tagihan Baru'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                ),
                onPressed: _showAddUpstreamBillDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),

          ..._upstreamBills.map((b) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: CustomCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.cloud_circle,
                    size: 36,
                    color: AppTheme.warning,
                  ),
                  title: Text(
                    b.providerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'Periode: ${b.periode}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        b.formattedAmount,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.error,
                        ),
                      ),
                      StatusBadge(status: b.status),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // --- TAB 6: TASK DISPATCH (A5) ---
  Widget _buildTaskDispatchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Penugasan Teknisi Lapangan (A5)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_task, size: 16),
                label: const Text('Buat Tugas Baru'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _showAssignTaskDialog,
              ),
            ],
          ),
          const SizedBox(height: 14),
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Daftar Teknisi Aktif:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Icon(Icons.engineering)),
                  title: Text('Rahmat Hidayat (ID: 4)'),
                  subtitle: Text('Basecamp Sleman • WhatsApp: 081987654321'),
                  trailing: Icon(
                    Icons.check_circle,
                    color: AppTheme.success,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
