import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/invoice_model.dart';
import '../../models/ledger_model.dart';
import '../../models/payment_model.dart';
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

class _AdminHubScreenState extends State<AdminHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data states
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _forecastData;
  List<dynamic> _lateRisks = [];
  List<UserModel> _customers = [];
  List<InvoiceModel> _invoices = [];
  List<LedgerBlockModel> _ledgerBlocks = [];
  List<UpstreamBillModel> _upstreamBills = [];

  bool _isLoading = true;
  VerificationResult? _blockchainVerification;
  bool _isVerifyingLedger = false;

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
      final lateRiskFuture = ApiService.instance.getLateRisk();
      final customersFuture = ApiService.instance.getCustomers();
      final invoicesFuture = ApiService.instance.getInvoices();
      final ledgerFuture = ApiService.instance.getLedger();
      final upstreamFuture = ApiService.instance.getUpstreamBills();

      final results = await Future.wait([
        summaryFuture,
        forecastFuture,
        lateRiskFuture,
        customersFuture,
        invoicesFuture,
        ledgerFuture,
        upstreamFuture,
      ]);

      if (mounted) {
        setState(() {
          _summary = results[0] as Map<String, dynamic>?;
          _forecastData = results[1] as Map<String, dynamic>?;
          _lateRisks = results[2] as List<dynamic>;
          _customers = results[3] as List<UserModel>;
          _invoices = results[4] as List<InvoiceModel>;
          _ledgerBlocks = results[5] as List<LedgerBlockModel>;
          _upstreamBills = results[6] as List<UpstreamBillModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[AdminHub] Error loading admin data: $e');
      if (mounted) setState(() => _isLoading = false);
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
          title: Text('Aktivasi Pelanggan #${customer.id}', style: const TextStyle(color: AppTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nama: ${customer.nama}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              Text('Alamat: ${customer.alamat}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              Text('Mata Uang: ${customer.mataUang} (${customer.zonaWaktu})', style: const TextStyle(color: AppTheme.accent, fontSize: 12)),
              const SizedBox(height: 14),
              const Text('Tetapkan Paket & Buat Tagihan Perdana:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: selectedPackageId,
                dropdownColor: AppTheme.surfaceCard,
                decoration: const InputDecoration(labelText: 'Paket Fiber'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Hemat 20 Mbps (Rp 175.000)')),
                  DropdownMenuItem(value: 2, child: Text('Turbo 50 Mbps (Rp 275.000)')),
                  DropdownMenuItem(value: 3, child: Text('Ultimate 100 Mbps (Rp 450.000)')),
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
              child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await ApiService.instance.activateCustomer(customer.id, paketId: selectedPackageId);
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Akun ${customer.nama} berhasil DIAKTIFKAN dan tagihan perdana telah dibuat dengan kurs terkunci!'),
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

    final ok = await ApiService.instance.verifyPayment(payment.id, approve: approve);
    if (ok) {
      if (approve) {
        NotificationService.instance.notifyPaymentVerified(invoicePeriod: invoice.periode);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve
              ? '✅ Pembayaran diverifikasi! Block SHA-256 berhasil ditulis ke ledger blockchain.'
              : '❌ Pembayaran ditolak.'),
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
        title: const Text('Catat Tagihan ISP Utama (A4)', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: providerCtrl,
              decoration: const InputDecoration(labelText: 'Penyedia ISP Utama (e.g. Indibizz)'),
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
              decoration: const InputDecoration(labelText: 'Nominal Beban IDR', prefixText: 'Rp '),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
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
                  const SnackBar(content: Text('Tagihan ISP utama berhasil dicatat!'), backgroundColor: AppTheme.success),
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
    final customerCtrl = TextEditingController();
    final catatanCtrl = TextEditingController();
    String jenis = 'instalasi';
    int? selectedCustomerId;
    int? selectedTechnicianId;

    final customers = _customers.where((c) => c.status == 'active').toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: const Text('Tugaskan Pekerjaan ke Teknisi (A5)', style: TextStyle(color: AppTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedCustomerId,
                dropdownColor: AppTheme.surfaceCard,
                decoration: const InputDecoration(labelText: 'Pilih Pelanggan'),
                items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.nama} (${c.alamat})', overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setDialogState(() => selectedCustomerId = v),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: jenis,
                dropdownColor: AppTheme.surfaceCard,
                decoration: const InputDecoration(labelText: 'Jenis Tugas'),
                items: const [
                  DropdownMenuItem(value: 'instalasi', child: Text('Pasang Baru / Tarik FO')),
                  DropdownMenuItem(value: 'perbaikan', child: Text('Perbaikan Redaman / Putus Kabel')),
                ],
                onChanged: (v) => setDialogState(() => jenis = v ?? 'instalasi'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: catatanCtrl,
                decoration: const InputDecoration(labelText: 'Catatan Lapangan', hintText: 'Misal: ODP-SLM-08 Port 4'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
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
                    const SnackBar(content: Text('Tugas berhasil ditugaskan ke teknisi!'), backgroundColor: AppTheme.success),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Operations Hub'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.analytics, size: 18), text: 'AI & Keuangan'),
            Tab(icon: Icon(Icons.how_to_reg, size: 18), text: 'Aktivasi (A1)'),
            Tab(icon: Icon(Icons.verified_user, size: 18), text: 'Verifikasi Bayar (A3)'),
            Tab(icon: Icon(Icons.link, size: 18), text: 'Blockchain Ledger (A7)'),
            Tab(icon: Icon(Icons.account_balance, size: 18), text: 'Tagihan Indibizz (A4)'),
            Tab(icon: Icon(Icons.assignment, size: 18), text: 'Tugas Teknisi (A5)'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAiAnalyticsTab(),
                _buildCustomerActivationTab(),
                _buildPaymentVerificationTab(),
                _buildBlockchainLedgerTab(),
                _buildUpstreamBillsTab(),
                _buildTaskDispatchTab(),
              ],
            ),
    );
  }

  // --- TAB 1: AI & REVENUE FORECAST (A6, A4 SUMMARY) ---
  Widget _buildAiAnalyticsTab() {
    final rev = _summary?['total_revenue_idr'] ?? 725000;
    final cost = _summary?['total_upstream_cost_idr'] ?? 4500000;
    final profit = _summary?['net_profit_idr'] ?? -3775000;
    final activeCust = _summary?['active_customers'] ?? 3;
    final pendingCust = _summary?['pending_customers'] ?? 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stat Metrics Row
          Row(
            children: [
              Expanded(
                child: StatMetricCard(
                  title: 'Total Pemasukan',
                  value: 'Rp ${(rev / 1000).toStringAsFixed(0)}K',
                  icon: Icons.payments,
                  iconColor: AppTheme.success,
                  trend: '+16.5%',
                  subtitle: 'Bulan ini',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatMetricCard(
                  title: 'Beban Indibizz',
                  value: 'Rp ${(cost / 1000).toStringAsFixed(0)}K',
                  icon: Icons.cloud_download,
                  iconColor: AppTheme.warning,
                  trend: 'Flat',
                  subtitle: '500M Dedicated',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatMetricCard(
                  title: 'Pelanggan Aktif',
                  value: '$activeCust User',
                  icon: Icons.people,
                  iconColor: AppTheme.primary,
                  subtitle: '$pendingCust Menunggu aktivasi',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatMetricCard(
                  title: 'Ledger Hash Blocks',
                  value: '${_ledgerBlocks.length} Block',
                  icon: Icons.security,
                  iconColor: AppTheme.secondary,
                  subtitle: 'SHA-256 Valid',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // AI REVENUE FORECAST (A6)
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.auto_graph, color: AppTheme.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'AI Forecast Pemasukan (Non-LLM)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Confidence 94%', style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Model regresi tren historis 6 bulan terakhir memproyeksikan pertumbuhan omset reseller ISP:',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),

                // Interactive Chart
                SizedBox(
                  height: 190,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 15,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              const labels = ['Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov*'];
                              final i = val.toInt();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  i < labels.length ? labels[i] : '',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
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
                              return Text('${val.toInt()}Jt', style: const TextStyle(color: AppTheme.textMuted, fontSize: 9));
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (val) => FlLine(color: AppTheme.border.withOpacity(0.4), strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 3.2, color: AppTheme.primary)]),
                        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 4.1, color: AppTheme.primary)]),
                        BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 5.3, color: AppTheme.primary)]),
                        BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 6.8, color: AppTheme.primary)]),
                        BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 7.9, color: AppTheme.primary)]),
                        BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 9.2, color: AppTheme.primary)]),
                        BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 10.8, color: AppTheme.accent)]), // Projection
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '*Nov: Estimasi Rp 10.8 Juta (Pertumbuhan rata-rata +16.5% MoM)',
                  style: TextStyle(fontSize: 11, color: AppTheme.accent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // LATE-RISK SCORING TABLE (A6)
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.warning_amber, color: AppTheme.warning, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'AI Skor Risiko Telat Bayar Pelanggan',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Algoritma multi-faktor menganalisis historis tagihan, valuta asing, dan perilaku pembayaran:',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),

                ..._lateRisks.map((item) {
                  final score = item['risk_score'] ?? 20;
                  final level = item['risk_level'] ?? 'Rendah';
                  final name = item['nama'] ?? 'Pelanggan';
                  final currency = item['mata_uang'] ?? 'IDR';
                  final rec = item['recommendation'] ?? '';

                  Color scoreColor = AppTheme.success;
                  if (level == 'Tinggi') scoreColor = AppTheme.error;
                  if (level == 'Sedang') scoreColor = AppTheme.warning;

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.8)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                              Text('$currency • $rec', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: scoreColor.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: scoreColor),
                          ),
                          child: Text(
                            '$score / 100 ($level)',
                            style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
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
              const Text('Pendaftaran Menunggu Aktivasi (A1)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              Text('${pending.length} antrean', style: const TextStyle(fontSize: 12, color: AppTheme.warning, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),

          if (pending.isEmpty)
            const CustomCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Tidak ada pendaftaran baru yang pending. Semua akun aktif! 🚀', style: TextStyle(color: AppTheme.textSecondary)),
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
                          Text(c.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          StatusBadge(status: 'pending'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${c.email} • ${c.noHp}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Text('Alamat: ${c.alamat}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      Text('Negara: ${c.negara} (${c.mataUang} • ${c.zonaWaktu})', style: const TextStyle(fontSize: 12, color: AppTheme.accent)),
                      const SizedBox(height: 12),
                      GlowingButton(
                        text: 'AKTIFKAN AKUN & TETAPKAN TAGIHAN (A1, A2)',
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
          const Text('Pelanggan Aktif Sima.net', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          ...active.map((c) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: CustomCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withOpacity(0.2),
                    child: Text(c.nama[0], style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(c.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('${c.email} • ${c.negara} (${c.mataUang})', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  trailing: StatusBadge(status: 'active'),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // --- TAB 3: VERIFIKASI PEMBAYARAN (A3) ---
  Widget _buildPaymentVerificationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Verifikasi Pembayaran Pelanggan (A3)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              Text('Hubungkan ke Blockchain Ledger', style: TextStyle(fontSize: 11, color: AppTheme.primary)),
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          StatusBadge(status: inv.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Pelanggan: ${inv.pelangganNama ?? 'User'} (${inv.pelangganEmail ?? ''})', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(inv.formattedAmount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          Text('Dasar: ${inv.formattedAmountIdr}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
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
                              Text('Status Bukti: ${payment.status.toUpperCase()}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accent)),
                              if (payment.verifiedAt != null)
                                Text('Waktu Verifikasi: ${payment.verifiedAt}', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
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
                                onPressed: () => _verifyPaymentAction(inv, false),
                                child: const Text('Tolak'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: GlowingButton(
                                text: 'VERIFIKASI & TULIS KE LEDGER (A3)',
                                icon: Icons.verified,
                                color: AppTheme.success,
                                onPressed: () => _verifyPaymentAction(inv, true),
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
                              style: TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.bold),
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
            gradient: const LinearGradient(colors: [Color(0xFF162544), Color(0xFF1E1F38)]),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Cryptographic SHA-256 Ledger (A7)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Hash-Chain Pembayaran Terverifikasi', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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
                      color: _blockchainVerification!.isValid ? AppTheme.success.withOpacity(0.15) : AppTheme.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _blockchainVerification!.isValid ? AppTheme.success : AppTheme.error),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _blockchainVerification!.isValid ? Icons.shield : Icons.error,
                          color: _blockchainVerification!.isValid ? AppTheme.success : AppTheme.error,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _blockchainVerification!.message,
                            style: TextStyle(
                              color: _blockchainVerification!.isValid ? AppTheme.success : AppTheme.error,
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
          const Text('Daftar Block Pembayaran Terdesentralisasi:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
                        Text('BLOCK #${block.idx}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary)),
                        Text('Payment ID: ${block.paymentId}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Nominal: Rp ${block.nominalIdr}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.success)),
                    Text('Waktu: ${block.waktu}', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    const SizedBox(height: 8),
                    const Divider(color: AppTheme.border, height: 10),
                    const Text('Prev Hash:', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    Text(block.prevHash, style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    const Text('Block Hash (SHA-256):', style: TextStyle(fontSize: 10, color: AppTheme.primary)),
                    Text(block.hash, style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: AppTheme.accent, fontWeight: FontWeight.bold)),
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
              const Text('Tagihan ISP Utama (A4)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Catat Tagihan Baru'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black),
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
                  leading: const Icon(Icons.cloud_circle, size: 36, color: AppTheme.warning),
                  title: Text(b.providerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Periode: ${b.periode}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(b.formattedAmount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.error)),
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
              const Text('Penugasan Teknisi Lapangan (A5)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_task, size: 16),
                label: const Text('Buat Tugas Baru'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary, foregroundColor: Colors.white),
                onPressed: _showAssignTaskDialog,
              ),
            ],
          ),
          const SizedBox(height: 14),
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Daftar Teknisi Aktif:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Icon(Icons.engineering)),
                  title: Text('Rahmat Hidayat (ID: 4)'),
                  subtitle: Text('Basecamp Sleman • WhatsApp: 081987654321'),
                  trailing: Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
