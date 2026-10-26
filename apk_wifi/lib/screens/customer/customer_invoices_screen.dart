import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_theme.dart';
import '../../models/invoice_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/currency_time_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/glowing_button.dart';
import '../../widgets/status_badge.dart';

class CustomerInvoicesScreen extends StatefulWidget {
  const CustomerInvoicesScreen({super.key});

  @override
  State<CustomerInvoicesScreen> createState() => _CustomerInvoicesScreenState();
}

class _CustomerInvoicesScreenState extends State<CustomerInvoicesScreen> {
  List<InvoiceModel> _invoices = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
    // Live ticking timer for real-time dual clocks & countdown
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    final list = await ApiService.instance.getInvoices();
    if (mounted) {
      setState(() {
        _invoices = list;
        _isLoading = false;
      });
    }
  }

  void _showPaymentModal(InvoiceModel invoice) {
    Uint8List? selectedImageBytes;
    String? selectedImageName;
    String? selectedImagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pembayaran ${invoice.periode}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bank transfer destination info & Cross-Border Remittance
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Rekening Tujuan Transfer:', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                            if (invoice.mataUang != 'IDR')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Cross-Border Remittance',
                                  style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'BCA (Bank Central Asia): 8830-1928-332\na.n. Sima.net ISP Reseller',
                          style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        if (invoice.mataUang != 'IDR') ...[
                          const SizedBox(height: 6),
                          Row(
                            children: const [
                              Text('SWIFT Code: ', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                              Text('CENAIDJA', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 11)),
                              SizedBox(width: 12),
                              Text('Wise/PayPal: ', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                              Text('pay@sima.net.id', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        const Divider(color: AppTheme.border, height: 1),
                        const SizedBox(height: 10),
                        if (invoice.hasDiscount) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tarif Normal Paket:', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                              Text(
                                invoice.formattedOriginalAmount,
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.card_giftcard, size: 13, color: AppTheme.success),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Voucher ${invoice.voucherCode ?? 'FIBERHEMAT10'}:',
                                    style: const TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Text(
                                '-${invoice.formattedDiscountIdr}',
                                style: const TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Ditransfer (${invoice.mataUang}):',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              invoice.formattedAmount,
                              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ],
                        ),
                        if (invoice.mataUang != 'IDR') ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Setara Rupiah (Kredit ISP):',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                              Text(
                                invoice.formattedAmountIdr,
                                style: const TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kurs Terkunci: 1 ${invoice.mataUang} = Rp ${invoice.kursTerkunci.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Image upload area (Compatible with Flutter Web & Mobile)
                  GestureDetector(
                    onTap: () async {
                      final picked = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                      );
                      if (picked != null) {
                        final bytes = await picked.readAsBytes();
                        setModalState(() {
                          selectedImageBytes = bytes;
                          selectedImageName = picked.name;
                          selectedImagePath = picked.path;
                        });
                      }
                    },
                    child: Container(
                      height: 130,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.5), style: BorderStyle.solid),
                      ),
                      child: selectedImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(selectedImageBytes!, fit: BoxFit.cover, width: double.infinity),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.cloud_upload_outlined, size: 36, color: AppTheme.primary),
                                SizedBox(height: 8),
                                Text(
                                  'Ketuk untuk Memilih Foto / Struk Bukti Bayar',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                ),
                                SizedBox(height: 4),
                                Text('Format: JPG / PNG (Maks 5 MB)', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  GlowingButton(
                    text: 'KIRIM BUKTI BAYAR',
                    icon: Icons.check,
                    onPressed: () async {
                      Navigator.pop(ctx);
                      _uploadProof(
                        invoice.id,
                        bytes: selectedImageBytes,
                        fileName: selectedImageName,
                        path: selectedImagePath,
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _uploadProof(
    int invoiceId, {
    Uint8List? bytes,
    String? fileName,
    String? path,
  }) async {
    final success = await ApiService.instance.uploadPaymentProof(
      invoiceId: invoiceId,
      fileBytes: bytes,
      fileName: fileName,
      filePath: path,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bukti transfer berhasil dikirim. Menunggu verifikasi admin ke ledger blockchain.'),
          backgroundColor: AppTheme.success,
        ),
      );
      _loadInvoices();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengunggah bukti bayar. Silakan coba kembali.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  String _getCountdownText(String jatuhTempo) {
    if (jatuhTempo.isEmpty) return '-';
    try {
      final dueUtc = DateTime.parse(jatuhTempo).toUtc();
      final nowUtc = DateTime.now().toUtc();
      final difference = dueUtc.difference(nowUtc);

      if (difference.isNegative) {
        final absDiff = difference.abs();
        if (absDiff.inDays > 0) {
          return 'Terlewat ${absDiff.inDays}h ${absDiff.inHours % 24}j ${absDiff.inMinutes % 60}m';
        }
        return 'Terlewat ${absDiff.inHours.toString().padLeft(2, '0')}:${(absDiff.inMinutes % 60).toString().padLeft(2, '0')}:${(absDiff.inSeconds % 60).toString().padLeft(2, '0')}';
      } else {
        final days = difference.inDays;
        final hours = (difference.inHours % 24).toString().padLeft(2, '0');
        final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');
        if (days > 0) {
          return '$days hari $hours:$minutes:$seconds';
        }
        return '$hours:$minutes:$seconds';
      }
    } catch (_) {
      return '-';
    }
  }

  bool _isOverdue(String jatuhTempo) {
    if (jatuhTempo.isEmpty) return false;
    try {
      return DateTime.parse(jatuhTempo).toUtc().isBefore(DateTime.now().toUtc());
    } catch (_) {
      return false;
    }
  }

  Widget _buildDiasporaHeader({
    required String userTimezone,
    required String userCurrency,
    String? userAlamat,
  }) {
    final serverTime = CurrencyTimeService.formatTimeForZone('WIB');
    final localTime = CurrencyTimeService.formatTimeForZone(userTimezone);

    String tzDifference = 'Zona Waktu Standar Server (WIB)';
    if (userTimezone == 'London') {
      tzDifference = '-6 Jam dari Server Yogyakarta';
    } else if (userTimezone == 'WITA') {
      tzDifference = '+1 Jam dari Server';
    } else if (userTimezone == 'WIT') {
      tzDifference = '+2 Jam dari Server';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.18),
            AppTheme.secondary.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.public, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cross-Border Sponsorship Billing',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Sinkronisasi jam server ISP & domisili sponsor diaspora',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dual Clocks Live
          Row(
            children: [
              // Server Clock (WIB)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.dns_outlined, size: 12, color: AppTheme.textMuted),
                          SizedBox(width: 4),
                          Text('SERVER ISP (WIB)', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        serverTime,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Local Customer Clock
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 12, color: AppTheme.accent),
                          const SizedBox(width: 4),
                          Text('WAKTU ANDA ($userTimezone)', style: const TextStyle(fontSize: 10, color: AppTheme.accent, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        localTime,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accent,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.sync_alt, size: 13, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Selisih: $tzDifference',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          if (userAlamat != null && userAlamat.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.home_outlined, size: 13, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Instalasi Keluarga: $userAlamat',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final userTimezone = user?.zonaWaktu ?? 'WIB';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagihan & Pembayaran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined, color: AppTheme.warning),
            tooltip: 'Simulasi Notifikasi Jatuh Tempo',
            onPressed: () {
              NotificationService.instance.notifyDueDate(
                period: 'Oktober 2026',
                amount: user?.mataUang == 'USD' ? '\$17.74 USD' : 'Rp 275.000',
                dueDate: '25 Okt 2026 ($userTimezone)',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifikasi pengingat jatuh tempo dikirimkan ke perangkat!'),
                  backgroundColor: AppTheme.info,
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInvoices,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  // Diaspora Header Banner
                  _buildDiasporaHeader(
                    userTimezone: userTimezone,
                    userCurrency: user?.mataUang ?? 'IDR',
                    userAlamat: user?.alamat,
                  ),

                  if (_invoices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'Belum ada tagihan untuk akun Anda.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    )
                  else
                    ..._invoices.map((inv) {
                      final isPaid = inv.isPaid;
                      final payment = inv.payment;
                      final countdown = _getCountdownText(inv.jatuhTempo);
                      final overdue = _isOverdue(inv.jatuhTempo);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: CustomCard(
                          borderColor: isPaid
                              ? AppTheme.success.withOpacity(0.3)
                              : overdue
                                  ? AppTheme.error.withOpacity(0.4)
                                  : AppTheme.warning.withOpacity(0.3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Bar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isPaid ? Icons.check_circle : Icons.receipt_long,
                                        color: isPaid ? AppTheme.success : AppTheme.warning,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        inv.periode,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  StatusBadge(status: inv.status),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Amount display & Locked Rate
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        inv.formattedAmount,
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: isPaid ? AppTheme.success : AppTheme.primary,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      if (inv.hasDiscount) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          inv.formattedOriginalAmount,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.textMuted,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (inv.mataUang != 'IDR')
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceElevated,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
                                      ),
                                      child: Text(
                                        '1 ${inv.mataUang} = Rp ${inv.kursTerkunci.toStringAsFixed(0)} (Terkunci)',
                                        style: const TextStyle(fontSize: 10, color: AppTheme.accent, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),

                              if (inv.hasDiscount) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.card_giftcard, size: 12, color: AppTheme.success),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Diskon Fiber Game (${inv.voucherCode ?? 'FIBERHEMAT10'}): -${inv.formattedDiscountIdr}',
                                        style: const TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              if (inv.mataUang != 'IDR') ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Setara: ${inv.formattedAmountIdr} (Kredit Tagihan Lokal)',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ],

                              const SizedBox(height: 10),
                              const Divider(color: AppTheme.border, height: 16),

                              // Dual Timezone Due Dates
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule, size: 14, color: AppTheme.accent),
                                      const SizedBox(width: 6),
                                      Text('Jatuh Tempo ($userTimezone): ', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                      Expanded(
                                        child: Text(
                                          inv.formattedDueDate(userTimezone),
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (userTimezone != 'WIB') ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.dns_outlined, size: 13, color: AppTheme.textMuted),
                                        const SizedBox(width: 7),
                                        const Text('Server Pusat (WIB): ', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                        Expanded(
                                          child: Text(
                                            inv.formattedDueDate('WIB'),
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),

                              // Live Countdown Ticker if not paid
                              if (!isPaid) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: (overdue ? AppTheme.error : AppTheme.warning).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: (overdue ? AppTheme.error : AppTheme.warning).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        overdue ? Icons.warning_amber_rounded : Icons.timer_outlined,
                                        size: 15,
                                        color: overdue ? AppTheme.error : AppTheme.warning,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        overdue ? 'Batas Waktu Terlewat: ' : 'Sisa Waktu Bayar: ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: overdue ? AppTheme.error : AppTheme.warning,
                                        ),
                                      ),
                                      Text(
                                        countdown,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                          color: overdue ? AppTheme.error : AppTheme.warning,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.wifi, size: 14, color: AppTheme.textMuted),
                                  const SizedBox(width: 6),
                                  Text(
                                    inv.paketNama ?? 'Layanan Fiber Internet',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),

                              // Payment verification status / Action button
                              const SizedBox(height: 16),
                              if (isPaid) ...[
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.verified, color: AppTheme.success, size: 16),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Pembayaran telah diverifikasi & dicatat permanen pada SHA-256 Ledger Blockchain.',
                                          style: TextStyle(fontSize: 11, color: AppTheme.success),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else if (payment != null && payment.isPending) ...[
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.warning.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.hourglass_top, color: AppTheme.warning, size: 16),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Bukti bayar sedang dalam antrean verifikasi admin.',
                                          style: TextStyle(fontSize: 11, color: AppTheme.warning),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                GlowingButton(
                                  text: 'BAYAR & UPLOAD BUKTI',
                                  icon: Icons.upload_file,
                                  width: double.infinity,
                                  onPressed: () => _showPaymentModal(inv),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }
}
