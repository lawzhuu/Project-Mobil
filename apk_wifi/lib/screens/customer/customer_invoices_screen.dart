import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_theme.dart';
import '../../models/invoice_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadInvoices();
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
    File? selectedImage;

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
            return Padding(
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

                  // Bank transfer destination info
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
                        const Text('Rekening Tujuan Transfer:', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        const SizedBox(height: 4),
                        const Text(
                          'BCA: 8830-1928-332\na.n. Sima.net ISP Reseller',
                          style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Nominal Tagihan (${invoice.mataUang}):',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                            Text(
                              invoice.formattedAmount,
                              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        if (invoice.mataUang != 'IDR') ...[
                          const SizedBox(height: 4),
                          Text(
                            'Kurs Terkunci: 1 ${invoice.mataUang} = Rp ${invoice.kursTerkunci.toStringAsFixed(0)} (Dasar: ${invoice.formattedAmountIdr})',
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Image upload area
                  GestureDetector(
                    onTap: () async {
                      final picked = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedImage = File(picked.path);
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
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(selectedImage!, fit: BoxFit.cover, width: double.infinity),
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
                      _uploadProof(invoice.id, selectedImage?.path);
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

  Future<void> _uploadProof(int invoiceId, String? path) async {
    final success = await ApiService.instance.uploadPaymentProof(
      invoiceId: invoiceId,
      filePath: path,
    );

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
            : _invoices.isEmpty
                ? const Center(
                    child: Text('Belum ada tagihan untuk akun Anda.', style: TextStyle(color: AppTheme.textSecondary)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(18),
                    itemCount: _invoices.length,
                    itemBuilder: (context, index) {
                      final inv = _invoices[index];
                      final isPaid = inv.isPaid;
                      final payment = inv.payment;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: CustomCard(
                          borderColor: isPaid ? AppTheme.success.withOpacity(0.3) : AppTheme.warning.withOpacity(0.3),
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

                              // Amount display
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  if (inv.mataUang != 'IDR')
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceElevated,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '1 ${inv.mataUang} = Rp ${inv.kursTerkunci.toStringAsFixed(0)} (Terkunci)',
                                        style: const TextStyle(fontSize: 10, color: AppTheme.accent),
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 10),
                              const Divider(color: AppTheme.border, height: 16),

                              // Due Date in User Timezone
                              Row(
                                children: [
                                  const Icon(Icons.schedule, size: 14, color: AppTheme.textMuted),
                                  const SizedBox(width: 6),
                                  const Text('Jatuh Tempo: ', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                  Text(
                                    inv.formattedDueDate(userTimezone),
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),
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
                    },
                  ),
      ),
    );
  }
}
