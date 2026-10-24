import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/invoice_model.dart';
import '../../../models/package_request_model.dart';
import '../../../models/user_model.dart';
import '../../../widgets/stat_metric_card.dart';

class AdminOverviewTab extends StatelessWidget {
  final Map<String, dynamic>? summary;
  final Map<String, dynamic>? forecastData;
  final List<UserModel> customers;
  final List<PackageRequestModel> packageRequests;
  final List<InvoiceModel> invoices;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onSelectSection;

  const AdminOverviewTab({
    super.key,
    required this.summary,
    required this.forecastData,
    required this.customers,
    required this.packageRequests,
    required this.invoices,
    required this.onRefresh,
    required this.onSelectSection,
  });

  @override
  Widget build(BuildContext context) {
    final rev = (summary?['total_revenue_idr'] as num?)?.toDouble() ?? 725000.0;
    final growth = forecastData?['growth_rate_pct'] ?? 16.5;

    final forecastList = (forecastData?['forecast'] as List?) ?? [];
    final nextForecast = forecastList.isNotEmpty ? forecastList[0] : null;
    final nextMonthNominalJt = nextForecast != null
        ? ((nextForecast['pemasukan'] as num) / 1000000).toStringAsFixed(1)
        : '10.8';

    final pendingActivations = customers.where((c) => c.status == 'pending').length;
    final pendingPackageReqs = packageRequests.where((r) => r.status == 'pending').length;
    final unpaidInvoices = invoices.where((i) => i.status == 'belum').length;
    final activeTasks = (summary?['active_tasks_count'] as num?)?.toInt() ?? 1;

    return RefreshIndicator(
      onRefresh: onRefresh,
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
              onTap: () => onSelectSection(0),
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
                          onSelectSection(2);
                        } else if (pendingActivations > 0) {
                          onSelectSection(1);
                        } else {
                          onSelectSection(3);
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

            // 4. Modul Operasional: List Beraksen tanpa icon
            _buildAdminAccentListItem(
              title: 'Aktivasi Pelanggan Baru',
              subtitle: 'Verifikasi pendaftaran & persetujuan akun',
              accentColor: AppTheme.primary,
              badgeCount: pendingActivations,
              onTap: () => onSelectSection(1),
            ),
            _buildAdminAccentListItem(
              title: 'Pengajuan Ubah Paket',
              subtitle: 'Permintaan upgrade / downgrade kecepatan',
              accentColor: Colors.amber,
              badgeCount: pendingPackageReqs,
              onTap: () => onSelectSection(2),
            ),
            _buildAdminAccentListItem(
              title: 'Verifikasi Pembayaran',
              subtitle: 'Pengecekan bukti transfer & status invoice',
              accentColor: AppTheme.accent,
              badgeCount: unpaidInvoices,
              onTap: () => onSelectSection(3),
            ),
            _buildAdminAccentListItem(
              title: 'Penugasan Teknisi',
              subtitle: 'Disposisi tiket gangguan & pekerjaan instalasi',
              accentColor: Colors.lightBlueAccent,
              badgeCount: activeTasks,
              onTap: () => onSelectSection(5),
            ),
            _buildAdminAccentListItem(
              title: 'Blockchain Ledger',
              subtitle: 'Audit jejak pembayaran anti-tamper SHA-256',
              accentColor: Colors.tealAccent,
              badgeCount: 0,
              onTap: () => onSelectSection(4),
            ),
            _buildAdminAccentListItem(
              title: 'Tagihan ISP Utama (Upstream)',
              subtitle: 'Rekap biaya internet induk & bandwidth grosir',
              accentColor: Colors.deepPurpleAccent,
              badgeCount: 0,
              onTap: () => onSelectSection(6),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

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
                Container(
                  width: 5,
                  color: accentColor,
                ),
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
}
