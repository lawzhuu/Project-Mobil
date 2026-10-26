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
import '../../widgets/status_badge.dart';
import 'tabs/admin_forecast_tab.dart';
import 'tabs/admin_invoices_tab.dart';
import 'tabs/admin_overview_tab.dart';

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

    final customers = _customers;

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
                          '${c.nama} [${c.status == 'inactive' ? 'Nonaktif' : 'Aktif'}]',
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
                decoration: const InputDecoration(labelText: 'Jenis / Alasan Tugas'),
                items: const [
                  DropdownMenuItem(
                    value: 'instalasi',
                    child: Text('Pasang Baru / Tarik FO'),
                  ),
                  DropdownMenuItem(
                    value: 'perbaikan',
                    child: Text('Perbaikan Redaman / Putus Kabel'),
                  ),
                  DropdownMenuItem(
                    value: 'pencopotan',
                    child: Text('Pencopotan Perangkat / Deaktivasi'),
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
        return 'Persetujuan Paket & Berhenti Langganan';
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
        return AdminForecastTab(
          summary: _summary,
          forecastData: _forecastData,
          aiInsightResult: _aiInsightResult,
          isAnalyzingAi: _isAnalyzingAi,
          onTriggerAiAnalysis: _triggerAiInsightAnalysis,
        );
      case 1:
        return _buildCustomerActivationTab();
      case 2:
        return _buildPackageRequestsTab();
      case 3:
        return AdminInvoicesTab(
          invoices: _invoices,
          onVerifyPayment: _verifyPaymentAction,
        );
      case 4:
        return _buildBlockchainLedgerTab();
      case 5:
        return _buildTaskDispatchTab();
      case 6:
        return _buildUpstreamBillsTab();
      default:
        return AdminForecastTab(
          summary: _summary,
          forecastData: _forecastData,
          aiInsightResult: _aiInsightResult,
          isAnalyzingAi: _isAnalyzingAi,
          onTriggerAiAnalysis: _triggerAiInsightAnalysis,
        );
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
                ? AdminOverviewTab(
                    summary: _summary,
                    forecastData: _forecastData,
                    customers: _customers,
                    packageRequests: _packageRequests,
                    invoices: _invoices,
                    onRefresh: _loadAllAdminData,
                    onSelectSection: (idx) => setState(() => _selectedSection = idx),
                  )
                : _buildSectionDetail(_selectedSection!)),
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
              const Expanded(
                child: Text(
                  'Pengajuan Paket & Berhenti Langganan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.2),
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
                  'Tidak ada pengajuan ubah paket atau pemutusan yang pending. Semua request telah diproses! 👍',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...pending.map((req) {
              final isTermination = req.isTermination;
              final isUpgrade = req.paketBaruKecepatan > req.paketLamaKecepatan;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: CustomCard(
                  borderColor: isTermination
                      ? const Color(0xFFDC2626).withValues(alpha: 0.6)
                      : AppTheme.warning.withValues(alpha: 0.6),
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
                              color: isTermination
                                  ? const Color(0xFFDC2626).withValues(alpha: 0.2)
                                  : (isUpgrade
                                      ? const Color(0xFF059669).withValues(alpha: 0.2)
                                      : const Color(0xFF2563EB).withValues(alpha: 0.2)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              req.tipe,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isTermination
                                    ? const Color(0xFFEF4444)
                                    : (isUpgrade ? const Color(0xFF10B981) : const Color(0xFF38BDF8)),
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

                      // Box Detail Perubahan Paket / Pemutusan
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isTermination
                              ? const Color(0xFFFEF2F2).withValues(alpha: 0.5)
                              : AppTheme.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isTermination
                                ? const Color(0xFFFECACA)
                                : AppTheme.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isTermination) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Paket yang Diputus:', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                        Text(
                                          '${req.paketLamaNama} (${req.paketLamaKecepatan}M)',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward, size: 16, color: Color(0xFFDC2626)),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Status Baru:', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                        Text(
                                          'Nonaktif / Berhenti',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: AppTheme.border, height: 12),
                              const Row(
                                children: [
                                  Icon(Icons.assignment_outlined, size: 14, color: AppTheme.warning),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Dampak: Diterbitkan SPK penarikan modem/ONT ke teknisi.',
                                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
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
                            ],
                            if (req.alasan.isNotEmpty) ...[
                              const SizedBox(height: 6),
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
                                backgroundColor: isTermination ? const Color(0xFFDC2626) : AppTheme.success,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              icon: Icon(isTermination ? Icons.power_settings_new_rounded : Icons.check, size: 16),
                              label: Text(
                                isTermination ? 'Setujui Pemutusan' : 'Setujui (Approve)',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
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
    final isTerm = req.isTermination;
    final noteController = TextEditingController(
      text: isTerm
          ? 'Pemutusan layanan disetujui. SPK penarikan perangkat telah diterbitkan ke teknisi.'
          : 'Disetujui. Perangkat & konfigurasi siap disesuaikan.',
    );
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isTerm ? Icons.power_settings_new_rounded : Icons.check_circle,
              color: isTerm ? const Color(0xFFDC2626) : AppTheme.success,
            ),
            const SizedBox(width: 8),
            Text(
              isTerm
                  ? 'Setujui Pemutusan #${req.id}'
                  : 'Setujui Pengajuan #${req.id}',
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
            if (isTerm) ...[
              Text(
                'Paket yang Dihentikan: ${req.paketLamaNama} (${req.paketLamaKecepatan}M)',
                style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Text(
                  'Perhatian: Akun pelanggan akan dinonaktifkan dan tiket penarikan modem/ONT otomatis dibuat untuk teknisi.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF991B1B)),
                ),
              ),
            ] else ...[
              Text(
                '${req.paketLamaNama} (${req.paketLamaKecepatan}M) ➔ ${req.paketBaruNama} (${req.paketBaruKecepatan}M)',
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text('Selisih Harga: Rp ${_formatRupiah(req.selisihHarga)} / bulan', style: const TextStyle(color: AppTheme.accent, fontSize: 12)),
            ],
            if (req.alasan.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Alasan: "${req.alasan}"', style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: AppTheme.textMuted)),
            ],
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
            style: ElevatedButton.styleFrom(
              backgroundColor: isTerm ? const Color(0xFFDC2626) : AppTheme.success,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              isTerm ? 'Ya, Putus Layanan' : 'Ya, Setujui',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
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
              const Expanded(
                child: Text(
                  'Penugasan Teknisi Lapangan (A5)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_task, size: 16),
                label: const Text('Buat Tugas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
