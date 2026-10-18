import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../widgets/custom_card.dart';

class CourseFeedbackScreen extends StatelessWidget {
  const CourseFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Kesan & Saran Kuliah'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. HERO BANNER
            _buildHeroBanner(),

            const SizedBox(height: 20),

            // 2. KURSUS & DOSEN INFO CARD
            _buildCourseInfoCard(),

            const SizedBox(height: 24),

            // 3. SECTION KESAN
            _buildSectionTitle(
              icon: Icons.thumb_up_alt_rounded,
              title: 'Kesan Perkuliahan',
              subtitle: 'Pengalaman & wawasan berharga selama satu semester',
            ),
            const SizedBox(height: 12),
            _buildImpressionCards(),

            const SizedBox(height: 24),

            // 4. SECTION SARAN
            _buildSectionTitle(
              icon: Icons.lightbulb_rounded,
              title: 'Saran & Rekomendasi',
              subtitle: 'Masukan konstruktif untuk pengembangan kurikulum kedepan',
            ),
            const SizedBox(height: 12),
            _buildSuggestionCards(),

            const SizedBox(height: 24),

            // 5. TESTIMONI & APRESIASI MAHASISWA
            _buildAppreciationCard(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // --- 1. HERO BANNER ---
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0940AA), Color(0xFF1E6BEB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330940AA),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Text(
                  'Semester 5 • 2024/2025',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Saran & Kesan\nMata Kuliah Pemrograman Mobile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Refleksi pembelajaran Flutter, Dart, arsitektur REST API, dan pengembangan aplikasi mobile modern multi-role.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. COURSE INFO CARD ---
  Widget _buildCourseInfoCard() {
    return CustomCard(
      child: Column(
        children: [
          Row(
            children: [
              _buildInfoPill(
                icon: Icons.code_rounded,
                title: 'Framework',
                value: 'Flutter & Dart',
                color: const Color(0xFF0284C7),
              ),
              const SizedBox(width: 12),
              _buildInfoPill(
                icon: Icons.dns_rounded,
                title: 'Backend API',
                value: 'Node.js & Express',
                color: const Color(0xFF10B981),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoPill(
                icon: Icons.devices_other_rounded,
                title: 'Studi Kasus',
                value: 'SIMA.NET ISP App',
                color: const Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 12),
              _buildInfoPill(
                icon: Icons.star_rounded,
                title: 'Bobot',
                value: '3 SKS Praktikum',
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SECTION TITLE ---
  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  // --- 3. KESAN CARDS ---
  Widget _buildImpressionCards() {
    final impressions = [
      {
        'icon': Icons.rocket_launch_rounded,
        'color': const Color(0xFF0B57CF),
        'title': 'Sangat Praktikal & Berorientasi Industri',
        'desc':
            'Praktikum tidak hanya sekadar membuat antarmuka statis, melainkan langsung membedah pembuatan full-stack mobile: dari slicing UI kompleks, state management, hingga interaksi live REST API.',
      },
      {
        'icon': Icons.psychology_rounded,
        'color': const Color(0xFF7C3AED),
        'title': 'Melatih Kemampuan Problem Solving & Debugging',
        'desc':
            'Tantangan menghubungkan emulator/device fisik ke server lokal, penyesuaian IP jaringan, dan penanganan asynchronous data melatih mental pemecahan masalah seperti software engineer profesional.',
      },
      {
        'icon': Icons.diversity_3_rounded,
        'color': const Color(0xFF059669),
        'title': 'Studi Kasus Multi-Role yang Realistis',
        'desc':
            'Pemisahan hak akses Pelanggan, Teknisi Lapangan, dan Admin operasional memberikan gambaran komprehensif bagaimana aplikasi enterprise dirancang dalam dunia nyata.',
      },
      {
        'icon': Icons.sentiment_very_satisfied_rounded,
        'color': const Color(0xFFD97706),
        'title': 'Dosen Pengampu & Pengajaran Suportif',
        'desc':
            'Penyampaian materi terstruktur, sabar dalam membimbing kendala instalasi SDK, serta memberikan kebebasan eksplorasi kreativitas desain UI/UX yang modern.',
      },
    ];

    return Column(
      children: impressions.map((item) {
        final color = item['color'] as Color;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item['icon'] as IconData, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['desc'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- 4. SARAN CARDS ---
  Widget _buildSuggestionCards() {
    final suggestions = [
      {
        'icon': Icons.architecture_rounded,
        'color': const Color(0xFF2563EB),
        'title': 'Eksplorasi State Management Skala Besar',
        'desc':
            'Diharapkan pada angkatan berikutnya dapat ditambahkan sesi khusus pengenalan BLoC Pattern atau Riverpod agar mahasiswa semakin siap masuk ke level enterprise coding standard.',
      },
      {
        'icon': Icons.bolt_rounded,
        'color': const Color(0xFFEA580C),
        'title': 'Mini Hackathon / Sesi Live Code Kolaboratif',
        'desc':
            'Bisa diadakan sesi coding kilat berdurasi 2-3 jam secara berkelompok untuk membangun fitur inovatif tertentu guna melatih kecepatan dan kerjasama tim.',
      },
      {
        'icon': Icons.cloud_upload_rounded,
        'color': const Color(0xFF0D9488),
        'title': 'Materi Deployment & CI/CD ke Play Store',
        'desc':
            'Pemberian panduan praktis proses build release (AAB), sign keystore, hingga trik lolos review di Google Play Console dan Firebase App Distribution.',
      },
    ];

    return Column(
      children: suggestions.map((item) {
        final color = item['color'] as Color;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item['icon'] as IconData, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['desc'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- 5. APRESIASI / TESTIMONI ---
  Widget _buildAppreciationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => const Icon(
                Icons.star_rounded,
                color: Color(0xFFFBBF24),
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '"Mata kuliah Pemrograman Mobile ini telah membuka wawasan nyata dan ketertarikan tinggi saya dalam berkarier sebagai Mobile Developer. Terima kasih banyak kepada Bapak/Ibu Dosen atas ilmu, dedikasi, serta bimbingannya sepanjang perkuliahan ini!"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFF1F5F9), thickness: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                ),
                child: const Center(
                  child: Icon(Icons.person, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Mahasiswa Pemrograman Mobile',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Semester 5 • Sima.net Project Team',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
