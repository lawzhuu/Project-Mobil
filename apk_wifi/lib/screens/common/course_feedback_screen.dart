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

            // 2. KURSUS & TIM INFO CARD
            _buildCourseInfoCard(),

            const SizedBox(height: 24),

            // 3. SECTION KESAN DARI TIM PENGEMBANG
            _buildSectionTitle(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Kesan Perkuliahan',
              subtitle: 'Kesan & refleksi nyata dari masing-masing anggota tim',
            ),
            const SizedBox(height: 12),
            _buildMemberImpressionCards(),

            const SizedBox(height: 24),

            // 4. SECTION SARAN
            _buildSectionTitle(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Saran Perkuliahan',
              subtitle: 'Masukan konstruktif untuk mata kuliah Pemrograman Mobile',
            ),
            const SizedBox(height: 12),
            _buildSuggestionCard(),

            const SizedBox(height: 24),

            // 5. APRESIASI TIM PENGEMBANG
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
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0940AA).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  color: Colors.white.withValues(alpha: 0.18),
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
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
            'Kesan & Saran\nMata Kuliah Pemrograman Mobile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Refleksi, pesan, dan masukan dari tim pengembang aplikasi SIMA.NET (Dimas Rhito, Guntur, & Zaky).',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. COURSE & TEAM INFO CARD ---
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
                value: 'Node.js & Vercel',
                color: const Color(0xFF10B981),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoPill(
                icon: Icons.group_rounded,
                title: 'Tim Pengembang',
                value: '3 Mahasiswa',
                color: const Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 12),
              _buildInfoPill(
                icon: Icons.devices_other_rounded,
                title: 'Studi Kasus',
                value: 'SIMA.NET ISP App',
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
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
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

  // --- 3. KESAN INDIVIDU DARI ANGGOTA TIM ---
  Widget _buildMemberImpressionCards() {
    final members = [
      {
        'nama': 'Dimas Rhito',
        'role': 'Mobile Developer',
        'avatar': 'DR',
        'color': const Color(0xFF2563EB), // Blue
        'gradient': const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        'icon': Icons.engineering_rounded,
        'kesan': 'Jadi tau kalau pengembangan aplikasi mobile tidak mudah.',
        'highlight': 'Tantangan arsitektur, integrasi API, dan penyesuaian lifecycle mobile',
      },
      {
        'nama': 'Guntur',
        'role': 'Fullstack & Mobile Developer',
        'avatar': 'G',
        'color': const Color(0xFF059669), // Emerald
        'gradient': const [Color(0xFF059669), Color(0xFF047857)],
        'icon': Icons.local_drink_rounded,
        'kesan':
            'Jadi tau kalau pengembangan aplikasi mobile itu terlalu mudah. Betul-betul segar seperti ES TEH.',
        'highlight': 'Eksplorasi lancar dan memuaskan seperti es teh segar di siang hari 🧊🥤',
      },
      {
        'nama': 'Zaky',
        'role': 'Mobile & UI/UX Developer',
        'avatar': 'Z',
        'color': const Color(0xFF7C3AED), // Violet
        'gradient': const [Color(0xFF7C3AED), Color(0xFF6D28D9)],
        'icon': Icons.sentiment_very_satisfied_rounded,
        'kesan':
            'Jadi tau kalau pengembangan aplikasi mobile itu menyenangkan. Betul-betul matkul yang MEMUDAHKAN mahasiswa.',
        'highlight': 'Pembelajaran yang seru, adaptif, dan memberi pengalaman nyata yang aplikatif',
      },
    ];

    return Column(
      children: members.map((m) {
        final color = m['color'] as Color;
        final gradientColors = m['gradient'] as List<Color>;

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Avatar, Nama, Role
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            m['avatar'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  m['nama'] as String,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  m['icon'] as IconData,
                                  size: 16,
                                  color: color,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m['role'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          'Kesan',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Bubble Kesan
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.format_quote_rounded,
                              size: 20,
                              color: color.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '"${m['kesan']}"',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          m['highlight'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- 4. SARAN REKOMENDASI ---
  Widget _buildSuggestionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Saran
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tips_and_updates_rounded,
                  color: Color(0xFFD97706),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saran & Masukan Kuliah',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Rekomendasi untuk kurikulum & penugasan mendatang',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Quote Utama Saran
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  size: 20,
                  color: Color(0xFFD97706),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '"Deadline mungkin bisa diperpanjang. Fitur mungkin agak dibebaskan, tidak terlalu terikat ketentuan."',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Poin Penjabaran Saran
          _buildSuggestionPoint(
            icon: Icons.hourglass_top_rounded,
            color: const Color(0xFFEA580C),
            title: 'Fleksibilitas Deadline',
            desc:
                'Deadline pengerjaan proyek akhir mungkin bisa diperpanjang agar eksplorasi kode, arsitektur, dan pematangan fitur bisa lebih maksimal.',
          ),
          const SizedBox(height: 10),
          _buildSuggestionPoint(
            icon: Icons.auto_awesome_rounded,
            color: const Color(0xFF2563EB),
            title: 'Kebebasan Eksplorasi Fitur',
            desc:
                'Fitur mungkin agak dibebaskan dan tidak terlalu kaku pada ketentuan silabus, sehingga mahasiswa memiliki ruang lebih leluasa untuk berkreasi sesuai ide unik kelompok.',
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionPoint({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. APRESIASI / TESTIMONI TIM ---
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
          const SizedBox(height: 12),
          const Text(
            '"Terima kasih banyak kepada Bapak/Ibu Dosen Pengampu atas bimbingan, arahan, dan kesempatan berharga dalam menyelesaikan proyek aplikasi mobile multi-role SIMA.NET ini!"',
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
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                ),
                child: const Center(
                  child: Icon(Icons.groups_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dimas Rhito • Guntur • Zaky',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Tim Pengembang SIMA.NET • Semester 5',
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
