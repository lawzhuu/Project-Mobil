import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/feedback_model.dart';
import '../../models/invoice_model.dart';
import '../../models/ledger_model.dart';
import '../../models/package_request_model.dart';
import '../../models/task_model.dart';
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
  List<TaskModel> _tasks = [];
  List<UserModel> _technicians = [];
  List<FeedbackModel> _feedbacks = [];

  bool _isLoading = true;
  int? _selectedSection; // null = Executive Dashboard Hub, 0..7 = Modul detail
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
      final tasksFuture = ApiService.instance.getTasks();
      final techsFuture = ApiService.instance.getTechnicians();
      final feedbackFuture = ApiService.instance.getFeedback();

      final results = await Future.wait([
        summaryFuture,
        forecastFuture,
        customersFuture,
        invoicesFuture,
        ledgerFuture,
        upstreamFuture,
        pkgReqsFuture,
        tasksFuture,
        techsFuture,
        feedbackFuture,
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
          _tasks = results[7] as List<TaskModel>;
          _technicians = results[8] as List<UserModel>;
          _feedbacks = results[9] as List<FeedbackModel>;
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
              content: Text(
                '✨ Analisis AI & Groq LLM Insight berhasil digenerate!',
              ),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: Text(
          'Aktivasi Akun Pelanggan #${customer.id}',
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
            const SizedBox(height: 4),
            Text(
              'Email / HP: ${customer.email} • ${customer.noHp}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Alamat: ${customer.alamat}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Negara: ${customer.negara} (${customer.mataUang} • ${customer.zonaWaktu})',
              style: const TextStyle(color: AppTheme.accent, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
              ),
              child: const Text(
                'Akun pelanggan akan diaktifkan sehingga dapat login dan menjelajahi katalog sebelum membeli paket internet.',
                style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
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
              final ok = await ApiService.instance.activateCustomer(
                customer.id,
              );
              if (ok) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Akun ${customer.nama} berhasil DIAKTIFKAN. Pelanggan dapat login dan memilih paket langganan!',
                    ),
                    backgroundColor: AppTheme.success,
                  ),
                );
                _loadAllAdminData();
              }
            },
            child: const Text('Aktifkan Akun'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPaymentAction(InvoiceModel invoice, bool approve) async {
    final payment = invoice.payment;

    bool ok = false;
    if (payment != null) {
      ok = await ApiService.instance.verifyPayment(
        payment.id,
        approve: approve,
      );
    } else {
      if (!approve) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Tagihan ini belum memiliki bukti transfer digital untuk ditolak.'),
              backgroundColor: AppTheme.warning,
            ),
          );
        }
        return;
      }
      ok = await ApiService.instance.verifyInvoiceManual(
        invoice.id,
        approve: true,
      );
    }

    if (!mounted) return;

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
                : '❌ Pembayaran ditolak. Status tagihan tetap Belum Lunas.',
          ),
          backgroundColor: approve ? AppTheme.success : AppTheme.error,
        ),
      );
      _loadAllAdminData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui status pembayaran. Periksa koneksi ke server.'),
          backgroundColor: AppTheme.error,
        ),
      );
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
    int? selectedTechId; // null = antrean penugasan

    final customers = _customers;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: const Text(
            'Buat Tugas Teknisi Lapangan (A5)',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxWidth: 450),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedCustomerId,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceCard,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Pelanggan',
                    ),
                    items: customers
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              '${c.nama} [${c.status == 'inactive' ? 'Nonaktif' : 'Aktif'}]',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedCustomerId = v),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: jenis,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceCard,
                    decoration: const InputDecoration(
                      labelText: 'Jenis / Alasan Tugas',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'instalasi',
                        child: Text(
                          'Pasang Baru / Tarik FO',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'perbaikan',
                        child: Text(
                          'Perbaikan Redaman / Putus Kabel',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'pencopotan',
                        child: Text(
                          'Pencopotan Perangkat / Deaktivasi',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'pemeliharaan',
                        child: Text(
                          'Pemeliharaan / Cek Berkala',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => jenis = v ?? 'instalasi'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int?>(
                    value: selectedTechId,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceCard,
                    decoration: const InputDecoration(
                      labelText: 'Teknisi Pelaksana',
                      helperText: 'Bisa dikosongkan agar masuk antrean',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text(
                          'Antrean (Pilih Teknisi Nanti)',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      ...(_technicians.isNotEmpty
                          ? _technicians.map(
                              (t) => DropdownMenuItem<int?>(
                                value: t.id,
                                child: Text(
                                  '${t.nama}${t.noHp.isNotEmpty ? " (${t.noHp})" : ""}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            )
                          : [
                              const DropdownMenuItem<int?>(
                                value: 4,
                                child: Text(
                                  'Rahmat Hidayat (Teknisi)',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ]),
                    ],
                    onChanged: (v) => setDialogState(() => selectedTechId = v),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: catatanCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Catatan Lapangan',
                      hintText: 'Misal: ODP-SLM-08 Port 4 atau keluhan',
                    ),
                  ),
                ],
              ),
            ),
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
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                final ok = await ApiService.instance.createTask(
                  teknisiId: selectedTechId,
                  pelangganId: selectedCustomerId!,
                  jenis: jenis,
                  catatan: catatanCtrl.text.trim(),
                );
                if (ok) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        selectedTechId != null
                            ? 'Tugas berhasil ditugaskan ke teknisi!'
                            : 'Tugas masuk ke Antrean Penugasan Teknisi!',
                      ),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                  if (mounted) _loadAllAdminData();
                }
              },
              child: const Text('Simpan Tugas'),
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
      case 7:
        return 'Saran & Kesan Pengguna';
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
      case 7:
        return _buildFeedbackPanelTab();
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
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
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
                      tasks: _tasks,
                      feedbacks: _feedbacks,
                      onRefresh: _loadAllAdminData,
                      onSelectSection: (idx) =>
                          setState(() => _selectedSection = idx),
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
                        text: 'Aktifkan Akun Pelanggan',
                        icon: Icons.check_circle_outline,
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
    final pending = _packageRequests
        .where((r) => r.status == 'pending')
        .toList();
    final processed = _packageRequests
        .where((r) => r.status != 'pending')
        .toList();

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
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isTermination
                                    ? const Color(0xFFDC2626)
                                          .withValues(alpha: 0.2)
                                    : (isUpgrade
                                          ? const Color(0xFF059669)
                                                .withValues(alpha: 0.2)
                                          : const Color(0xFF2563EB)
                                                .withValues(alpha: 0.2)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                req.tipe,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isTermination
                                      ? const Color(0xFFEF4444)
                                      : (isUpgrade
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFF38BDF8)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${req.userEmail} • ${req.userNoHp}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (req.userAlamat.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Alamat: ${req.userAlamat}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Paket yang Diputus:',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                        Text(
                                          '${req.paketLamaNama} (${req.paketLamaKecepatan}M)',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                    color: Color(0xFFDC2626),
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Status Baru:',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                        Text(
                                          'Nonaktif / Berhenti',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFDC2626),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Divider(
                                  color: Color(0xFFF1F5F9),
                                  height: 1,
                                  thickness: 1,
                                ),
                              ),
                              const Row(
                                children: [
                                  Icon(
                                    Icons.assignment_outlined,
                                    size: 14,
                                    color: AppTheme.warning,
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Dampak: Diterbitkan SPK penarikan modem/ONT ke teknisi.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Paket Lama:',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                        Text(
                                          '${req.paketLamaNama} (${req.paketLamaKecepatan}M)',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                    color: AppTheme.accent,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Paket Baru:',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                        Text(
                                          '${req.paketBaruNama} (${req.paketBaruKecepatan}M)',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Divider(
                                  color: Color(0xFFF1F5F9),
                                  height: 1,
                                  thickness: 1,
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Selisih Harga:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    req.selisihHarga >= 0
                                        ? '+Rp ${_formatRupiah(req.selisihHarga)} / bln'
                                        : '-Rp ${_formatRupiah(-req.selisihHarga)} / bln',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: req.selisihHarga >= 0
                                          ? AppTheme.success
                                          : AppTheme.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (req.alasan.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Alasan: "${req.alasan}"',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.textMuted,
                                ),
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              onPressed: () => _rejectPackageRequestDialog(req),
                              child: const Text(
                                'Tolak',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isTermination
                                    ? const Color(0xFFDC2626)
                                    : AppTheme.success,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              icon: Icon(
                                isTermination
                                    ? Icons.power_settings_new_rounded
                                    : Icons.check,
                                size: 16,
                              ),
                              label: Text(
                                isTermination
                                    ? 'Setujui Pemutusan'
                                    : 'Setujui (Approve)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () =>
                                  _approvePackageRequestDialog(req),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${req.paketLamaNama} ➔ ${req.paketBaruNama}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            if (req.adminCatatan.isNotEmpty)
                              Text(
                                'Catatan: ${req.adminCatatan}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isApproved
                              ? AppTheme.success.withOpacity(0.2)
                              : AppTheme.error.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isApproved ? 'Disetujui' : 'Ditolak',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isApproved
                                ? AppTheme.success
                                : AppTheme.error,
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
            Text(
              'Pelanggan: ${req.userNama}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            if (isTerm) ...[
              Text(
                'Paket yang Dihentikan: ${req.paketLamaNama} (${req.paketLamaKecepatan}M)',
                style: const TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
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
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Selisih Harga: Rp ${_formatRupiah(req.selisihHarga)} / bulan',
                style: const TextStyle(color: AppTheme.accent, fontSize: 12),
              ),
            ],
            if (req.alasan.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Alasan: "${req.alasan}"',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Catatan Persetujuan Admin:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
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
            child: const Text(
              'Batal',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isTerm
                  ? const Color(0xFFDC2626)
                  : AppTheme.success,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              isTerm ? 'Ya, Putus Layanan' : 'Ya, Setujui',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService.instance.approvePackageRequest(
        req.id,
        adminCatatan: noteController.text.trim(),
      );
      if (res['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Pengajuan disetujui!'),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadAllAdminData();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal menyetujui pengajuan'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectPackageRequestDialog(PackageRequestModel req) async {
    final noteController = TextEditingController(
      text: 'Kapasitas ODP wilayah saat ini belum memadai untuk paket ini.',
    );
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
            Text(
              'Pelanggan: ${req.userNama}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Alasan Penolakan:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
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
            child: const Text(
              'Batal',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Tolak Pengajuan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService.instance.rejectPackageRequest(
        req.id,
        adminCatatan: noteController.text.trim(),
      );
      if (res['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Pengajuan ditolak.'),
            backgroundColor: AppTheme.warning,
          ),
        );
        _loadAllAdminData();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal menolak pengajuan'),
            backgroundColor: AppTheme.error,
          ),
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
          // Sleek High-Tech Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF38BDF8),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cryptographic SHA-256 Ledger (A7)',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Hash-Chain Pembayaran Terverifikasi & Anti-Tamper',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        'IMMUTABLE',
                        style: TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                          ? const Color(0xFF065F46).withValues(alpha: 0.4)
                          : const Color(0xFF991B1B).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _blockchainVerification!.isValid
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _blockchainVerification!.isValid
                              ? Icons.verified_user_rounded
                              : Icons.error_outline_rounded,
                          color: _blockchainVerification!.isValid
                              ? const Color(0xFF34D399)
                              : const Color(0xFFF87171),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _blockchainVerification!.message,
                            style: TextStyle(
                              color: _blockchainVerification!.isValid
                                  ? const Color(0xFF6EE7B7)
                                  : const Color(0xFFFCA5A5),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
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
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          ..._ledgerBlocks.map((block) {
            final formattedNominal = block.nominalIdr.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]}.',
            );
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.border.withValues(alpha: 0.7),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          'BLOCK #${block.idx}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Payment ID: ${block.paymentId}',
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Rp $formattedNominal',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        block.waktu,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: AppTheme.border, height: 1),
                  const SizedBox(height: 10),

                  const Text(
                    'Previous Hash:',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.border.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Text(
                      block.prevHash,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontFamily: 'monospace',
                        color: AppTheme.textSecondary,
                      ),
                      softWrap: true,
                    ),
                  ),
                  const SizedBox(height: 8),

                  const Text(
                    'Block Hash (SHA-256):',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      block.hash,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0369A1),
                      ),
                      softWrap: true,
                    ),
                  ),
                ],
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

  // --- MODAL: PILIH & TUGASKAN TEKNISI ---
  void _showAssignTechnicianModal(TaskModel task) {
    int? selectedTechId = _technicians.isNotEmpty ? _technicians.first.id : 4;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              (task.isPencopotan
                                      ? const Color(0xFFEF4444)
                                      : (task.jenis == 'perbaikan'
                                            ? const Color(0xFFF59E0B)
                                            : AppTheme.primary))
                                  .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          task.isPencopotan
                              ? Icons.power_settings_new_rounded
                              : (task.jenis == 'perbaikan'
                                    ? Icons.build_circle_rounded
                                    : Icons.engineering_rounded),
                          color: task.isPencopotan
                              ? const Color(0xFFEF4444)
                              : (task.jenis == 'perbaikan'
                                    ? const Color(0xFFF59E0B)
                                    : AppTheme.primary),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pilih Teknisi Pelaksana',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Tiket #${task.id}: ${task.displayJenis}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.person_pin_circle_rounded,
                              size: 16,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Pelanggan: ${task.pelangganNama}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (task.pelangganNoHp.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                task.pelangganNoHp,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (task.pelangganAlamat.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  task.pelangganAlamat,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.border.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            task.catatan.isNotEmpty
                                ? task.catatan
                                : 'Tidak ada catatan tambahan',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pilih Teknisi untuk Ditugaskan:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: selectedTechId,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceCard,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(
                        Icons.engineering,
                        color: AppTheme.primary,
                      ),
                    ),
                    items: _technicians.isNotEmpty
                        ? _technicians
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t.id,
                                  child: Text(
                                    '${t.nama} (${t.noHp.isNotEmpty ? t.noHp : "ID: ${t.id}"})',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              )
                              .toList()
                        : [
                            const DropdownMenuItem(
                              value: 4,
                              child: Text(
                                'Rahmat Hidayat (Teknisi - 081987654321)',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                    onChanged: (val) {
                      if (val != null) setSheetState(() => selectedTechId = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Tugaskan ke Teknisi Sekarang'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(ctx);
                      final techId = selectedTechId ?? 4;
                      final success = await ApiService.instance
                          .assignTaskTechnician(task.id, techId);
                      if (success) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Tugas #${task.id} berhasil ditugaskan ke teknisi!',
                            ),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                        if (mounted) _loadAllAdminData();
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Gagal menugaskan teknisi. Silakan coba lagi.',
                            ),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- TAB 5: TASK DISPATCH (A5) ---
  Widget _buildTaskDispatchTab() {
    final unassignedTasks = _tasks
        .where(
          (t) =>
              t.isAvailable ||
              (t.status == 'baru' &&
                  (t.teknisiNama == null || t.teknisiNama == 'Belum Diambil')),
        )
        .toList();
    final inProgressTasks = _tasks
        .where((t) => !unassignedTasks.contains(t) && t.status == 'dikerjakan')
        .toList();
    final finishedTasks = _tasks
        .where((t) => !unassignedTasks.contains(t) && t.status == 'selesai')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Tab
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Penugasan Teknisi Lapangan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_task, size: 16),
                label: const Text('Buat Tugas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onPressed: _showAssignTaskDialog,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Ringkasan Kartu Metrik Antrean & Pengerjaan
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: unassignedTasks.isNotEmpty
                        ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                        : AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: unassignedTasks.isNotEmpty
                          ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                          : AppTheme.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.pending_actions_rounded,
                            size: 16,
                            color: unassignedTasks.isNotEmpty
                                ? const Color(0xFFEF4444)
                                : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Antrean',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${unassignedTasks.length}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: unassignedTasks.isNotEmpty
                              ? const Color(0xFFEF4444)
                              : AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        unassignedTasks.isNotEmpty
                            ? 'Perlu Teknisi'
                            : 'Semua Beres',
                        style: TextStyle(
                          fontSize: 10,
                          color: unassignedTasks.isNotEmpty
                              ? const Color(0xFFEF4444)
                              : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.engineering_rounded,
                            size: 16,
                            color: Colors.lightBlueAccent,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Dikerjakan',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${inProgressTasks.length}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Text(
                        'Sedang Proses',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: AppTheme.success,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Selesai',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${finishedTasks.length}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Text(
                        'Tuntas',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // SECTION 1: ANTREAN MENUNGGU PENUGASAN TEKNISI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Tugas Menunggu Penugasan Teknisi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (unassignedTasks.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${unassignedTasks.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (unassignedTasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.border.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.success,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Semua Tugas Sudah Terdisposisi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tidak ada tiket laporan gangguan atau pencopotan yang tertunda.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            ...unassignedTasks.map((t) {
              final isPencopotan = t.isPencopotan;
              final isTrouble = t.jenis == 'perbaikan';

              final Color accentColor = isPencopotan
                  ? const Color(0xFFEF4444)
                  : (isTrouble
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF3B82F6));

              final IconData icon = isPencopotan
                  ? Icons.power_settings_new_rounded
                  : (isTrouble
                        ? Icons.build_circle_rounded
                        : Icons.cable_rounded);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Kartu
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: accentColor, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        t.displayJenis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: accentColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '#${t.id}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Pelanggan: ${t.pelangganNama}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Belum Ada Teknisi',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (t.pelangganAlamat.isNotEmpty ||
                          t.pelangganNoHp.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (t.pelangganNoHp.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.phone_rounded,
                                    size: 13,
                                    color: AppTheme.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    t.pelangganNoHp,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            if (t.pelangganAlamat.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 13,
                                    color: AppTheme.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 220),
                                    child: Text(
                                      t.pelangganAlamat,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],

                      // Catatan / Deskripsi Keluhan
                      if (t.catatan.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.border.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Text(
                            t.catatan,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Tombol Penugasan Teknisi
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 16,
                        ),
                        label: const Text('Pilih & Tugaskan Teknisi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _showAssignTechnicianModal(t),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 18),

          // SECTION 2: TUGAS SEDANG DIKERJAKAN
          if (inProgressTasks.isNotEmpty) ...[
            const Text(
              'Tugas Sedang Dikerjakan Teknisi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ...inProgressTasks.map((t) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.lightBlueAccent.withValues(
                        alpha: 0.15,
                      ),
                      child: const Icon(
                        Icons.engineering,
                        color: Colors.lightBlueAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  t.displayJenis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '#${t.id}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pelanggan: ${t.pelangganNama} • Teknisi: ${t.teknisiNama ?? "Rahmat Hidayat"}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showAssignTechnicianModal(t),
                      child: const Text(
                        'Ganti Teknisi',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 14),
          ],

          // SECTION 3: DAFTAR TEKNISI AKTIF
          const Text(
            'Daftar Teknisi Lapangan Terdaftar:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_technicians.isNotEmpty)
                  ..._technicians.map((tech) {
                    final assignedCount = _tasks
                        .where(
                          (t) =>
                              t.teknisiId == tech.id &&
                              t.status == 'dikerjakan',
                        )
                        .length;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary.withValues(
                          alpha: 0.15,
                        ),
                        child: const Icon(
                          Icons.engineering,
                          color: AppTheme.primary,
                        ),
                      ),
                      title: Text('${tech.nama} (ID: ${tech.id})'),
                      subtitle: Text(
                        '${tech.alamat.isNotEmpty ? tech.alamat : "Basecamp Sleman"} • Kontak: ${tech.noHp.isNotEmpty ? tech.noHp : "-"}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: assignedCount > 0
                              ? Colors.blue.withValues(alpha: 0.15)
                              : AppTheme.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          assignedCount > 0
                              ? '$assignedCount Tugas Aktif'
                              : 'Tersedia',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: assignedCount > 0
                                ? Colors.blue
                                : AppTheme.success,
                          ),
                        ),
                      ),
                    );
                  })
                else
                  const ListTile(
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

  // --- TAB 7: PANEL FEEDBACK PENGGUNA (SARAN & KESAN) ---
  Widget _buildFeedbackPanelTab() {
    final hasSaranCount = _feedbacks
        .where((f) => f.saran.trim().isNotEmpty)
        .length;
    final hasKesanCount = _feedbacks
        .where((f) => f.kesan.trim().isNotEmpty)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Panel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Saran & Kesan Pengguna',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Segarkan Feedback',
                onPressed: _loadAllAdminData,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Evaluasi pengalaman pelanggan, kritik saran, dan pesan kepuasan layanan Sima.net.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          // Metrik Ringkasan Feedback
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.mark_chat_unread_rounded,
                            size: 16,
                            color: Colors.amberAccent,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Total Masukan',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_feedbacks.length}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Text(
                        'Komentar masuk',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.lightbulb_rounded,
                            size: 16,
                            color: Colors.orangeAccent,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Saran Ide',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$hasSaranCount',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orangeAccent,
                        ),
                      ),
                      const Text(
                        'Rekomendasi fitur',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.chat_bubble_rounded,
                            size: 16,
                            color: Colors.lightBlueAccent,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Kesan Pengguna',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$hasKesanCount',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.lightBlueAccent,
                        ),
                      ),
                      const Text(
                        'Ulasan pengalaman',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Daftar Kartu Feedback
          if (_feedbacks.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.border.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                children: const [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 48,
                    color: AppTheme.textMuted,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Belum Ada Masukan Pengguna',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pengguna dapat mengirimkan saran & kesan melalui menu Masukan di aplikasi pelanggan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._feedbacks.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.border.withValues(alpha: 0.7),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Pengirim
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primary.withValues(
                            alpha: 0.15,
                          ),
                          child: Text(
                            item.userNama.isNotEmpty
                                ? item.userNama[0].toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.userNama,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (item.formattedDate.isNotEmpty)
                                Text(
                                  item.formattedDate,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Text(
                            '#FB-${item.id}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Kotak Saran
                    if (item.saran.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B)
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFF59E0B)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.lightbulb_rounded,
                                  size: 14,
                                  color: Color(0xFFF59E0B),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Saran Peningkatan:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.saran.trim(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Kotak Kesan
                    if (item.kesan.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.lightBlueAccent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.lightBlueAccent.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.chat_bubble_rounded,
                                  size: 14,
                                  color: Colors.lightBlueAccent,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Kesan & Evaluasi:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.lightBlueAccent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.kesan.trim(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
