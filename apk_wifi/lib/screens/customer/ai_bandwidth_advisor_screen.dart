import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/package_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/currency_time_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/glowing_button.dart';
import 'customer_packages_screen.dart';

class AiBandwidthAdvisorScreen extends StatefulWidget {
  const AiBandwidthAdvisorScreen({super.key});

  @override
  State<AiBandwidthAdvisorScreen> createState() => _AiBandwidthAdvisorScreenState();
}

class _AiBandwidthAdvisorScreenState extends State<AiBandwidthAdvisorScreen> {
  // Device count states
  int _smartphones = 3;
  int _laptops = 1;
  int _smartTvs = 1;
  int _iotCctvs = 0;

  int get _totalDevices => _smartphones + _laptops + _smartTvs + _iotCctvs;

  // Selected activities
  final Set<String> _selectedActivities = {
    'streaming_4k',
    'wfh_conference',
  };

  final List<Map<String, dynamic>> _activityOptions = [
    {
      'id': 'streaming_4k',
      'label': 'Streaming 4K / Ultra HD',
      'subtitle': 'Netflix, Disney+, YouTube 4K',
      'icon': Icons.tv_rounded,
    },
    {
      'id': 'competitive_gaming',
      'label': 'Game Kompetitif Online',
      'subtitle': 'MLBB, Valorant, FF (Ping Rendah)',
      'icon': Icons.sports_esports_rounded,
    },
    {
      'id': 'wfh_conference',
      'label': 'WFH & Video Meeting',
      'subtitle': 'Zoom, GMeet, Upload File Besar',
      'icon': Icons.video_camera_front_rounded,
    },
    {
      'id': 'casual_browsing',
      'label': 'Medsos & Browsing Santai',
      'subtitle': 'TikTok, IG, Marketplace',
      'icon': Icons.public_rounded,
    },
  ];

  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  PackageModel? _recommendedPackage;
  PackageModel? _alternativePackage;

  String get _currency => AuthService.instance.currentUser?.mataUang ?? 'IDR';

  Future<void> _runAiAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    try {
      final res = await ApiService.instance.consultAiBandwidthAdvisor(
        devices: {
          'smartphone': _smartphones,
          'laptop': _laptops,
          'smart_tv': _smartTvs,
          'iot_cctv': _iotCctvs,
        },
        activities: _selectedActivities.toList(),
      );

      if (mounted) {
        if (res['success'] == true) {
          setState(() {
            _analysisResult = res;
            if (res['recommended_package'] != null) {
              _recommendedPackage = PackageModel.fromJson(res['recommended_package']);
            }
            if (res['alternative_package'] != null) {
              _alternativePackage = PackageModel.fromJson(res['alternative_package']);
            }
            _isAnalyzing = false;
          });
        } else {
          setState(() => _isAnalyzing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Gagal kalkulasi AI'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _proceedToOrderPackage(PackageModel pkg) {
    // Navigate to packages screen to submit official package change request
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CustomerPackagesScreen(),
      ),
    );
  }

  String _formatPrice(int hargaIdr) {
    if (_currency == 'IDR') {
      return 'Rp ${hargaIdr.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
    }
    final converted = CurrencyTimeService.instance.convertCurrency(
      amount: hargaIdr.toDouble(),
      fromCurrency: 'IDR',
      toCurrency: _currency,
    );
    return CurrencyTimeService.instance.formatCurrency(converted, _currency);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('AI Bandwidth Advisor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. HERO AI CARD
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4C1D95), Color(0xFF6D28D9), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x337C3AED),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Smart Bandwidth Advisor',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Didukung ML Concurrency + Generative AI',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bingung memilih kecepatan paket WiFi? Masukkan profil perangkat dan aktivitas rumah Anda. AI akan menghitung throughput puncak dan merekomendasikan paket paling presisi.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 2. DEVICE COUNTER SECTION
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.devices_rounded, size: 20, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Text(
                        '1. Jumlah Perangkat Terhubung',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pilih estimasi gawai yang aktif menggunakan WiFi di rumah:',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),

                  _buildCounterTile(
                    icon: Icons.smartphone_rounded,
                    title: 'Smartphone & Tablet',
                    subtitle: 'Streaming mobile, chatting, medsos (~5 Mbps)',
                    value: _smartphones,
                    onChanged: (val) => setState(() => _smartphones = val),
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),
                  _buildCounterTile(
                    icon: Icons.laptop_mac_rounded,
                    title: 'Laptop & Komputer Kerja',
                    subtitle: 'Browsing, meeting, download (~12 Mbps)',
                    value: _laptops,
                    onChanged: (val) => setState(() => _laptops = val),
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),
                  _buildCounterTile(
                    icon: Icons.tv_rounded,
                    title: 'Smart TV (4K / FHD)',
                    subtitle: 'Streaming layar besar YouTube/Netflix (~22 Mbps)',
                    value: _smartTvs,
                    onChanged: (val) => setState(() => _smartTvs = val),
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),
                  _buildCounterTile(
                    icon: Icons.videocam_rounded,
                    title: 'CCTV & IoT Smart Home',
                    subtitle: 'Stream video konstan (~4 Mbps)',
                    value: _iotCctvs,
                    onChanged: (val) => setState(() => _iotCctvs = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. ACTIVITY MULTI-SELECT CHIPS
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.bolt_rounded, size: 20, color: Color(0xFFEA580C)),
                      SizedBox(width: 8),
                      Text(
                        '2. Aktivitas Paling Sering',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pilih aktivitas prioritas agar AI dapat mengalokasikan buffer latency:',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _activityOptions.map((opt) {
                      final isSelected = _selectedActivities.contains(opt['id']);
                      return FilterChip(
                        selected: isSelected,
                        showCheckmark: true,
                        avatar: Icon(
                          opt['icon'] as IconData,
                          size: 16,
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                        ),
                        label: Text(opt['label'] as String),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                        ),
                        selectedColor: const Color(0xFF7C3AED),
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedActivities.add(opt['id'] as String);
                            } else {
                              if (_selectedActivities.length > 1) {
                                _selectedActivities.remove(opt['id'] as String);
                              }
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. ACTION CTA BUTTON
            GlowingButton(
              text: _isAnalyzing ? 'MENGANALISIS DENGAN AI...' : 'HITUNG KEBUTUHAN BANDWIDTH',
              icon: Icons.psychology_rounded,
              color: const Color(0xFF7C3AED),
              onPressed: _isAnalyzing ? () {} : _runAiAnalysis,
            ),

            // 5. AI RESULT SECTION
            if (_analysisResult != null) ...[
              const SizedBox(height: 24),
              _buildAnalysisResultCard(),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF334155), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: value > 0 ? () => onChanged(value - 1) : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: value > 0 ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Icon(
                  Icons.remove,
                  size: 16,
                  color: value > 0 ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                ),
              ),
            ),
            SizedBox(
              width: 36,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            InkWell(
              onTap: value < 20 ? () => onChanged(value + 1) : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.add,
                  size: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalysisResultCard() {
    final peakMbps = _analysisResult!['calculated_peak_mbps'] ?? 0;
    final rawAiAnalysis = (_analysisResult!['ai_analysis'] ?? '').toString();
    final aiAnalysis = rawAiAnalysis
        .replaceAll('**', '')
        .replaceAll('###', '')
        .replaceAll('`', '');
    final source = _analysisResult!['source'] ?? 'AI Engine';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFC084FC), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x187C3AED),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header result
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.speed_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HASIL PERHITUNGAN AI ADVISOR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Total $_totalDevices Perangkat Terkoneksi',
                        style: const TextStyle(fontSize: 10.5, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$peakMbps Mbps',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI Narrative Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE9D5FF)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF7C3AED), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              aiAnalysis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF4C1D95),
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Sumber: $source',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF9333EA),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // RECOMMENDED PACKAGE CARD
                if (_recommendedPackage != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Paket Paling Optimal Untuk Anda:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '⭐ BEST VALUE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _recommendedPackage!.nama,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Text(
                                '${_recommendedPackage!.kecepatanMbps} Mbps',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _recommendedPackage!.deskripsi,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Harga Berlangganan',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                ),
                                Text(
                                  '${_formatPrice(_recommendedPackage!.hargaIdr)} / bln',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              label: const Text('Pilih Paket Ini'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C3AED),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _proceedToOrderPackage(_recommendedPackage!),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                if (_alternativePackage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Opsi Alternatif:',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_alternativePackage!.nama} (${_alternativePackage!.kecepatanMbps} Mbps) • ${_formatPrice(_alternativePackage!.hargaIdr)}/bln',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _proceedToOrderPackage(_alternativePackage!),
                          child: const Text('Pilih Ini', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
