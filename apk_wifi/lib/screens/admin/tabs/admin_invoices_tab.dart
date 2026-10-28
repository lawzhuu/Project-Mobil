import 'package:flutter/material.dart';
import '../../../config/app_config.dart';
import '../../../config/app_theme.dart';
import '../../../models/invoice_model.dart';
import '../../../models/payment_model.dart';
import '../../../widgets/custom_card.dart';
import '../../../widgets/glowing_button.dart';
import '../../../widgets/status_badge.dart';

class AdminInvoicesTab extends StatelessWidget {
  final List<InvoiceModel> invoices;
  final Function(InvoiceModel invoice, bool approve) onVerifyPayment;

  const AdminInvoicesTab({
    super.key,
    required this.invoices,
    required this.onVerifyPayment,
  });

  void _showReceiptDialog(BuildContext context, InvoiceModel inv, PaymentModel payment) {
    final imageUrl = AppConfig.resolveImageUrl(payment.buktiPath);
    final isRejected = payment.isRejected;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550, maxHeight: 720),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long, color: AppTheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Bukti Transfer #${inv.id}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${inv.pelangganNama ?? 'Pelanggan'} • ${inv.periode}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
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
              const Divider(color: AppTheme.border, height: 24),

              // Image Viewer with Zoom
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    color: Colors.black26,
                    child: payment.buktiPath.isEmpty || payment.buktiPath == 'MANUAL_VERIFIKASI_ADMIN'
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.payments_outlined, size: 56, color: AppTheme.accent),
                                SizedBox(height: 12),
                                Text(
                                  'Pembayaran Tunai / Manual',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Diverifikasi langsung oleh admin tanpa struk digital.',
                                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          )
                        : InteractiveViewer(
                            panEnabled: true,
                            boundaryMargin: const EdgeInsets.all(20),
                            minScale: 0.8,
                            maxScale: 4.0,
                            child: Center(
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      color: AppTheme.primary,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.broken_image_outlined, size: 52, color: AppTheme.error),
                                          const SizedBox(height: 10),
                                          const Text(
                                            'Gagal memuat gambar bukti transfer.',
                                            style: TextStyle(fontSize: 13, color: AppTheme.error, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            imageUrl,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Detail Bukti
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isRejected
                        ? AppTheme.error.withOpacity(0.3)
                        : (payment.isVerified ? AppTheme.success.withOpacity(0.3) : AppTheme.border),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nominal Tagihan:', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                        Text(
                          inv.formattedAmount,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Status Bukti:', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                        Text(
                          isRejected
                              ? 'DITOLAK ADMIN'
                              : (payment.isVerified ? 'DISETUJUI / SAH' : 'MENUNGGU VERIFIKASI'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: payment.isVerified
                                ? AppTheme.success
                                : (isRejected ? AppTheme.error : AppTheme.warning),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (isRejected) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, size: 16, color: AppTheme.error),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bukti transfer ini telah ditolak. Menunggu pelanggan mengunggah bukti baru.',
                          style: TextStyle(fontSize: 11, color: AppTheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Quick Actions inside Modal
              if (!inv.isPaid)
                Row(
                  children: [
                    if (!isRejected) ...[
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(color: AppTheme.error),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _confirmReject(context, inv);
                          },
                          child: const Text('Tolak Bukti'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ] else ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppTheme.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Tutup', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: GlowingButton(
                        text: isRejected ? 'Verifikasi Manual (A3)' : 'Verifikasi Pembayaran',
                        icon: Icons.verified,
                        color: AppTheme.success,
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmApprove(context, inv);
                        },
                      ),
                    ),
                  ],
                )
              else
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Tutup', style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmReject(BuildContext context, InvoiceModel inv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppTheme.error),
            SizedBox(width: 8),
            Text('Tolak Pembayaran?', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menolak pembayaran Tagihan #${inv.id} dari ${inv.pelangganNama ?? 'Pelanggan'}?\nStatus tagihan akan tetap "Belum Lunas" dan pelanggan dapat mengunggah bukti baru.',
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              Navigator.pop(ctx);
              onVerifyPayment(inv, false);
            },
            child: const Text('Ya, Tolak', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmApprove(BuildContext context, InvoiceModel inv) {
    final hasProof = inv.payment != null && inv.payment!.buktiPath.isNotEmpty;
    final isRejected = inv.payment != null && inv.payment!.isRejected;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.verified, color: AppTheme.success),
            SizedBox(width: 8),
            Text('Verifikasi Pembayaran', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verifikasi pembayaran sebesar ${inv.formattedAmount} untuk Tagihan #${inv.id} (${inv.periode})?',
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasProof && !isRejected
                          ? 'Transaksi sah akan divalidasi dan block SHA-256 baru akan dibuat di Blockchain Ledger.'
                          : 'Pembayaran akan dicatat sebagai Verifikasi Kasir / Tunai Manual dan ditulis permanen ke Blockchain Ledger.',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () {
              Navigator.pop(ctx);
              onVerifyPayment(inv, true);
            },
            child: const Text('Verifikasi & Tulis Ledger', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Expanded(
                child: Text(
                  'Verifikasi Pembayaran (A3)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Hubungkan ke Blockchain Ledger',
                  style: TextStyle(fontSize: 11, color: AppTheme.primary),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (invoices.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('Belum ada tagihan.', style: TextStyle(color: AppTheme.textMuted)),
              ),
            )
          else
            ...invoices.map((inv) {
              final isPaid = inv.isPaid;
              final payment = inv.payment;
              final hasProof = payment != null && payment.buktiPath.isNotEmpty;
              final isRejected = payment != null && payment.isRejected;
              final isPending = payment != null && payment.isPending;
              final proofUrl = hasProof ? AppConfig.resolveImageUrl(payment.buktiPath) : '';

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                child: CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header card
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Tagihan #${inv.id} - ${inv.periode}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: StatusBadge(
                              status: isPaid
                                  ? 'lunas'
                                  : (isRejected ? 'ditolak' : (isPending ? 'menunggu' : inv.status)),
                              customLabel: isPaid
                                  ? 'LUNAS'
                                  : (isRejected
                                      ? 'BUKTI DITOLAK'
                                      : (isPending ? 'MENUNGGU VERIFIKASI' : 'BELUM DIBAYAR')),
                            ),
                          ),
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
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              inv.formattedAmount,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Dasar: ${inv.formattedAmountIdr}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Payment Proof Section
                      if (payment != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isRejected
                                ? AppTheme.error.withOpacity(0.08)
                                : AppTheme.surfaceElevated.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: payment.isVerified
                                  ? AppTheme.success.withOpacity(0.3)
                                  : isRejected
                                      ? AppTheme.error.withOpacity(0.4)
                                      : AppTheme.warning.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Thumbnail preview
                                  if (hasProof && payment.buktiPath != 'MANUAL_VERIFIKASI_ADMIN')
                                    GestureDetector(
                                      onTap: () => _showReceiptDialog(context, inv, payment),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: SizedBox(
                                              width: 60,
                                              height: 60,
                                              child: Image.network(
                                                proofUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  color: Colors.black26,
                                                  child: const Icon(Icons.receipt, color: AppTheme.textMuted),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 2,
                                            right: 2,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: Colors.black87,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Icon(Icons.zoom_in, size: 12, color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceElevated,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.payments_outlined, color: AppTheme.accent),
                                    ),
                                  const SizedBox(width: 12),

                                  // Info & Button
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (payment.isVerified
                                                        ? AppTheme.success
                                                        : isRejected
                                                            ? AppTheme.error
                                                            : AppTheme.warning)
                                                    .withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                isRejected ? 'DITOLAK ADMIN' : payment.status.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: payment.isVerified
                                                      ? AppTheme.success
                                                      : isRejected
                                                          ? AppTheme.error
                                                          : AppTheme.warning,
                                                ),
                                              ),
                                            ),
                                            if (payment.verifiedAt != null) ...[
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  payment.verifiedAt!.substring(0, 10),
                                                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        InkWell(
                                          onTap: () => _showReceiptDialog(context, inv, payment),
                                          borderRadius: BorderRadius.circular(6),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 2),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.visibility_outlined,
                                                  size: 14,
                                                  color: isRejected ? AppTheme.error : AppTheme.primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isRejected ? 'Lihat Bukti yang Ditolak' : 'Lihat Bukti Transfer',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isRejected ? AppTheme.error : AppTheme.primary,
                                                    fontWeight: FontWeight.bold,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (isRejected) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'Bukti transfer telah ditolak. Menunggu pelanggan mengunggah bukti baru.',
                                  style: TextStyle(fontSize: 11, color: AppTheme.error),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ] else ...[
                        // Notice if no payment proof uploaded yet
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.border.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.info_outline, size: 16, color: AppTheme.textMuted),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Pelanggan belum mengunggah bukti transfer digital. Anda dapat melakukan Verifikasi Manual jika pembayaran dilakukan langsung.',
                                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Action Buttons
                      if (!isPaid)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: Icon(
                                  isRejected ? Icons.block : Icons.close,
                                  size: 14,
                                ),
                                label: Text(isRejected ? 'Sudah Ditolak' : 'Tolak'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isPending ? AppTheme.error : AppTheme.textMuted,
                                  side: BorderSide(
                                    color: isPending ? AppTheme.error : AppTheme.border,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: isPending
                                    ? () => _confirmReject(context, inv)
                                    : null, // Disabled jika sudah ditolak atau belum ada bukti!
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: GlowingButton(
                                text: isPending ? 'Verifikasi & Tulis Ledger' : 'Verifikasi Manual (A3)',
                                icon: Icons.verified,
                                color: AppTheme.success,
                                onPressed: () => _confirmApprove(context, inv),
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.success.withOpacity(0.3)),
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
            }),
        ],
      ),
    );
  }
}
