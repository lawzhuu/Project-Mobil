import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/invoice_model.dart';
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

          if (invoices.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('Belum ada tagihan.', style: TextStyle(color: AppTheme.textMuted)),
            ))
          else
            ...invoices.map((inv) {
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
                                onPressed: () => onVerifyPayment(inv, false),
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
                                onPressed: () => onVerifyPayment(inv, true),
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
}
