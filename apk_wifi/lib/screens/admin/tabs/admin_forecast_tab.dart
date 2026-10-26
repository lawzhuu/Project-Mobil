import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../widgets/custom_card.dart';
import '../../../widgets/stat_metric_card.dart';

class AdminForecastTab extends StatelessWidget {
  final Map<String, dynamic>? summary;
  final Map<String, dynamic>? forecastData;
  final Map<String, dynamic>? aiInsightResult;
  final bool isAnalyzingAi;
  final VoidCallback onTriggerAiAnalysis;

  const AdminForecastTab({
    super.key,
    required this.summary,
    required this.forecastData,
    required this.aiInsightResult,
    required this.isAnalyzingAi,
    required this.onTriggerAiAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    final rev = summary?['total_revenue_idr'] ?? 725000;
    final cost = summary?['total_upstream_cost_idr'] ?? 4500000;
    final growth = forecastData?['growth_rate_pct'] ?? 16.5;
    final confidenceScore = ((forecastData?['model_r2'] ?? 0.94) * 100).toStringAsFixed(0);

    final historicalList = (forecastData?['historical'] as List?) ?? [
      {'bulan': 'Mei', 'pemasukan': 3200000},
      {'bulan': 'Jun', 'pemasukan': 4100000},
      {'bulan': 'Jul', 'pemasukan': 5300000},
      {'bulan': 'Agt', 'pemasukan': 6800000},
      {'bulan': 'Sep', 'pemasukan': 7900000},
      {'bulan': 'Okt', 'pemasukan': 9200000},
    ];

    final forecastList = (forecastData?['forecast'] as List?) ?? [
      {'bulan': 'Nov 2026 (Est)', 'pemasukan': 10800000, 'confidence': 0.94}
    ];

    final nextForecast = forecastList.isNotEmpty ? forecastList[0] : null;
    final nextMonthName = nextForecast?['bulan'] ?? 'Nov 2026';
    final nextMonthNominalJt = nextForecast != null
        ? ((nextForecast['pemasukan'] as num) / 1000000).toStringAsFixed(1)
        : '10.8';

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
                  onPressed: isAnalyzingAi ? null : onTriggerAiAnalysis,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  icon: isAnalyzingAi
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
                    isAnalyzingAi
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
                      color: aiInsightResult != null
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
                                color: aiInsightResult != null
                                    ? AppTheme.accent
                                    : AppTheme.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                aiInsightResult != null
                                    ? 'Insight Hasil Analisis AI'
                                    : 'Belum Ada Analisis yang Dijalankan',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: aiInsightResult != null
                                      ? AppTheme.textPrimary
                                      : AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                          if (aiInsightResult != null)
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
                                aiInsightResult?['source']?.toString().contains('Groq') == true
                                    ? 'Groq AI Live'
                                    : (aiInsightResult?['source']?.toString().contains('Gemini') == true
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
                        (aiInsightResult?['insight_text'] ??
                                'Tekan tombol "Mulai Analisis AI & Generate Insight" di atas. Sistem akan menghitung model regresi linier pemasukan dan meminta Groq LLM merangkum narasi proyeksi serta rekomendasi bisnis untuk Anda.')
                            .replaceAll('**', '')
                            .replaceAll('###', '')
                            .replaceAll('`', ''),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: aiInsightResult != null
                              ? AppTheme.textPrimary
                              : AppTheme.textMuted,
                        ),
                      ),
                      if (aiInsightResult?['timestamp'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Dianalisis pada: ${aiInsightResult!['timestamp']}',
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
}
