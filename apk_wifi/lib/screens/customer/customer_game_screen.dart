import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/glowing_button.dart';
import 'customer_invoices_screen.dart';

class CustomerGameScreen extends StatefulWidget {
  const CustomerGameScreen({super.key});

  @override
  State<CustomerGameScreen> createState() => _CustomerGameScreenState();
}

class _CustomerGameScreenState extends State<CustomerGameScreen> {
  StreamSubscription<AccelerometerEvent>? _accelerometerSub;

  // Ball / Fiber Core Position (-1.0 to 1.0 normalized)
  double _ballX = 0.0;
  double _ballY = 0.3;
  double _velX = 0.0;
  double _velY = 0.0;

  // Target ODP Port position
  final double _targetX = 0.0;
  final double _targetY = -0.6;
  final double _targetRadius = 0.18;

  // Obstacles (noise packets)
  final List<Offset> _obstacles = [
    const Offset(-0.4, -0.1),
    const Offset(0.4, 0.0),
    const Offset(0.0, 0.1),
  ];

  bool _isPlaying = false;
  bool _isSuccess = false;
  bool _isClaiming = false;
  bool _isClaimed = false;
  int _score = 0;
  Timer? _gameLoop;
  String _statusMsg = 'Miringkan HP Anda untuk mengarahkan pulsa optik ke Port ODP!';

  @override
  void initState() {
    super.initState();
    _startListeningSensors();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showTutorialModal();
      }
    });
  }

  @override
  void dispose() {
    _accelerometerSub?.cancel();
    _gameLoop?.cancel();
    super.dispose();
  }

  void _startListeningSensors() {
    try {
      _accelerometerSub = accelerometerEventStream().listen((AccelerometerEvent event) {
        if (_isPlaying && !_isSuccess) {
          // Accelerometer X tilts left/right, Y tilts up/down
          // Invert X for natural tilt feel
          _velX += (-event.x) * 0.0015;
          _velY += (event.y) * 0.0015;
        }
      });
    } catch (e) {
      debugPrint('[Game] Accelerometer stream not available: $e');
    }
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isSuccess = false;
      _ballX = 0.0;
      _ballY = 0.6;
      _velX = 0.0;
      _velY = 0.0;
      _score = 100;
      _statusMsg = 'Hubungkan kabel fiber optic ke ODP tanpa menabrak noise!';
    });

    _gameLoop?.cancel();
    _gameLoop = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (!_isPlaying || _isSuccess) return;

      setState(() {
        // Friction
        _velX *= 0.94;
        _velY *= 0.94;

        _ballX += _velX;
        _ballY += _velY;

        // Boundary bounce
        if (_ballX < -0.85) {
          _ballX = -0.85;
          _velX = -_velX * 0.5;
        }
        if (_ballX > 0.85) {
          _ballX = 0.85;
          _velX = -_velX * 0.5;
        }
        if (_ballY < -0.85) {
          _ballY = -0.85;
          _velY = -_velY * 0.5;
        }
        if (_ballY > 0.85) {
          _ballY = 0.85;
          _velY = -_velY * 0.5;
        }

        // Check target distance
        final dx = _ballX - _targetX;
        final dy = _ballY - _targetY;
        final dist = sqrt(dx * dx + dy * dy);

        if (dist < _targetRadius) {
          _isSuccess = true;
          _isPlaying = false;
          _statusMsg = '🎉 KABEL FIBER BERHASIL TERSAMBUNG! Redaman optik sempurna: -18.2 dBm.';
          _gameLoop?.cancel();
        }

        // Collision with noise packets
        for (final obs in _obstacles) {
          final ox = _ballX - obs.dx;
          final oy = _ballY - obs.dy;
          if (sqrt(ox * ox + oy * oy) < 0.12) {
            _score = max(0, _score - 5);
            _velX = -_velX * 1.2;
            _velY = -_velY * 1.2;
          }
        }
      });
    });
  }


  Future<void> _claimVoucherReward() async {
    if (_isClaiming || _isClaimed) return;

    setState(() {
      _isClaiming = true;
    });

    final res = await ApiService.instance.claimGameReward(score: _score);

    if (!mounted) return;

    setState(() {
      _isClaiming = false;
    });

    if (res['success'] == true) {
      setState(() {
        _isClaimed = true;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: AppTheme.success, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Voucher Berhasil Diklaim!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '🎉 Selamat! Diskon Rp 25.000 telah otomatis memotong nominal tagihan internet aktif Anda.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                'Kode Voucher: FIBERHEMAT10\nPotongan: Rp 25.000 (Langsung Mengurangi Total Bayar)',
                style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.receipt_long, size: 16),
              label: const Text('Lihat Tagihan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerInvoicesScreen()),
                );
              },
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal mengklaim voucher'),
          backgroundColor: AppTheme.warning,
        ),
      );
    }
  }

  void _showTutorialModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 25,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Header Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.sports_esports, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Panduan & Aturan Diskon',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Mini Game Tilt Fiber & Voucher Tagihan',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
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
            ),
            const Divider(color: Color(0xFF1E293B), height: 1),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  // CARD 1: CARA BERMAIN TILT FIBER
                  _buildTutorialSectionCard(
                    icon: Icons.screen_rotation,
                    iconColor: AppTheme.primary,
                    title: '1. Cara Bermain (Sensor Accelerometer)',
                    badge: 'KONTROL TILT',
                    badgeColor: AppTheme.primary,
                    items: [
                      'Miringkan HP Anda ke segala arah (depan, belakang, kiri, kanan) untuk mengarahkan pulsa cahaya fiber optic.',
                      'Arahkan pulsa cahaya masuk tepat ke dalam lingkaran target PORT ODP (berwarna hijau).',
                      'Hindari Noise Packet (lingkaran merah berpetir). Tabrakan dengan noise akan memantulkan pulsa & memotong 15 Poin redaman!',
                    ],
                  ),
                  const SizedBox(height: 14),

                  // CARD 2: CARA KLAIM DISKON
                  _buildTutorialSectionCard(
                    icon: Icons.card_giftcard,
                    iconColor: const Color(0xFFF59E0B),
                    title: '2. Cara Klaim Diskon Rp 25.000',
                    badge: 'HADIAH VOUCHER',
                    badgeColor: const Color(0xFFF59E0B),
                    items: [
                      'Selesaikan sambungan kabel fiber ke target ODP dengan sisa skor minimal 60 Poin.',
                      'Saat muncul popup "Koneksi Fiber Berhasil!", klik tombol "KLAIM DISKON KE TAGIHAN".',
                      'Sistem secara otomatis mengaktifkan voucher FIBERHEMAT10 senilai Rp 25.000 ke akun tagihan Anda.',
                    ],
                  ),
                  const SizedBox(height: 14),

                  // CARD 3: ATURAN & SYARAT KLAIM
                  _buildTutorialSectionCard(
                    icon: Icons.rule_folder_outlined,
                    iconColor: AppTheme.success,
                    title: '3. Aturan & Syarat Klaim Diskon',
                    badge: 'SYARAT & KETENTUAN',
                    badgeColor: AppTheme.success,
                    items: [
                      'Hanya Tagihan Aktif: Diskon hanya berlaku untuk invoice bulanan yang berstatus Belum Bayar (unpaid).',
                      'Maksimal 1 Voucher per Tagihan: Anda tidak dapat menumpuk lebih dari 1 voucher pada tagihan yang sama.',
                      'Dukungan Valas Diaspora: Jika Anda membayar menggunakan mata uang asing (USD, EUR, MYR, SAR), diskon Rp 25.000 otomatis terkonversi setara kurs real-time.',
                      'Langsung Mengurangi Total: Potongan langsung tampak pada ringkasan tagihan & nominal pembayaran transfer/QRIS.',
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Bottom CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: GlowingButton(
                text: 'SAYA MENGERTI, AYO MAIN!',
                icon: Icons.play_arrow,
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badge,
    required Color badgeColor,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withOpacity(0.4)),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFCBD5E1),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini Game: Sambungkan Fiber'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Panduan & Aturan Diskon',
            onPressed: _showTutorialModal,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Instructions & Score Header
            CustomCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sensor: Accelerometer (Tilt)',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isSuccess ? 'STATUS: TERSAMBUNG 🚀' : (_isPlaying ? 'MEMBAWA PULSA OPTIK...' : 'SIAP MAIN'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _isSuccess ? AppTheme.success : AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: _showTutorialModal,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.help_outline, size: 14, color: AppTheme.primary),
                              SizedBox(width: 4),
                              Text(
                                'Panduan',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primary),
                        ),
                        child: Text(
                          'Poin: $_score',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Game Arena (Custom Painted Canvas)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF070B14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border, width: 1.5),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;

                      // Convert normalized (-1 to 1) to canvas coordinates
                      final ballPixelX = (w / 2) + (_ballX * (w / 2));
                      final ballPixelY = (h / 2) + (_ballY * (h / 2));

                      final targetPixelX = (w / 2) + (_targetX * (w / 2));
                      final targetPixelY = (h / 2) + (_targetY * (h / 2));

                      return Stack(
                        children: [
                          // Grid lines aesthetic
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _GridBackgroundPainter(),
                            ),
                          ),

                          // Target ODP Optical Port
                          Positioned(
                            left: targetPixelX - 40,
                            top: targetPixelY - 40,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.success.withOpacity(0.15),
                                border: Border.all(color: AppTheme.success, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.success.withOpacity(0.3),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.router, color: AppTheme.success, size: 24),
                                  Text(
                                    'PORT ODP',
                                    style: TextStyle(
                                      color: AppTheme.success,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Noise Obstacles
                          ..._obstacles.map((obs) {
                            final ox = (w / 2) + (obs.dx * (w / 2));
                            final oy = (h / 2) + (obs.dy * (h / 2));
                            return Positioned(
                              left: ox - 18,
                              top: oy - 18,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.error.withOpacity(0.2),
                                  border: Border.all(color: AppTheme.error, width: 1.5),
                                ),
                                child: const Icon(Icons.flash_off, color: AppTheme.error, size: 18),
                              ),
                            );
                          }).toList(),

                          // Light Pulse (The Fiber Ball)
                          Positioned(
                            left: ballPixelX - 16,
                            top: ballPixelY - 16,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [Colors.white, AppTheme.primary, Colors.transparent],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.8),
                                    blurRadius: 16,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.fiber_manual_record, color: Colors.white, size: 14),
                              ),
                            ),
                          ),

                          // Overlay start banner
                          if (!_isPlaying && !_isSuccess)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withOpacity(0.6),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.screen_rotation, size: 52, color: AppTheme.primary),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Sambungkan Kabel Fiber',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 24),
                                        child: Text(
                                          'Miringkan perangkat Anda ke kiri/kanan/depan/belakang untuk mengarahkan pulsa optik ke Port ODP.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      GlowingButton(
                                        text: 'MULAI SAMBUNGKAN',
                                        icon: Icons.play_arrow,
                                        onPressed: _startGame,
                                      ),
                                      const SizedBox(height: 10),
                                      TextButton.icon(
                                        icon: const Icon(Icons.help_outline, color: Colors.white70, size: 16),
                                        label: const Text(
                                          'Panduan Game & Aturan Diskon',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12.5,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                        onPressed: _showTutorialModal,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // Success Banner with Real Claim Voucher Logic
                          if (_isSuccess)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withOpacity(0.8),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Center(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle, size: 64, color: AppTheme.success),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Koneksi Fiber Berhasil!',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Skor Akhir: $_score Poin\nRedaman Optik Prima: -18.2 dBm',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                                        ),
                                        const SizedBox(height: 14),

                                        // Voucher Reward Card
                                        Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 12),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: (_isClaimed ? AppTheme.success : const Color(0xFFF59E0B)).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: _isClaimed ? AppTheme.success : const Color(0xFFF59E0B)),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                _isClaimed ? '✅ VOUCHER DISKON TERPASANG' : '🎁 HADIAH REDAMAN PRIMA: DISKON Rp 25.000',
                                                style: TextStyle(
                                                  color: _isClaimed ? AppTheme.success : const Color(0xFFF59E0B),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _isClaimed
                                                    ? 'Potongan Rp 25.000 telah masuk ke tagihan aktif Anda.'
                                                    : 'Voucher FIBERHEMAT10 siap memotong tagihan internet Anda!',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(color: Colors.white, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 18),

                                        if (!_isClaimed) ...[
                                          GlowingButton(
                                            text: _isClaiming ? 'MENGKLAIM VOUCHER...' : 'KLAIM DISKON KE TAGIHAN',
                                            icon: Icons.card_giftcard,
                                            color: const Color(0xFFF59E0B),
                                            onPressed: _isClaiming ? () {} : _claimVoucherReward,
                                          ),
                                          const SizedBox(height: 10),
                                          TextButton.icon(
                                            icon: const Icon(Icons.replay, color: AppTheme.textMuted, size: 16),
                                            label: const Text('Main Lagi Tanpa Klaim', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                            onPressed: _startGame,
                                          ),
                                        ] else ...[
                                          GlowingButton(
                                            text: 'LIHAT TAGIHAN SAYA',
                                            icon: Icons.receipt_long,
                                            color: AppTheme.primary,
                                            onPressed: () {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(builder: (_) => const CustomerInvoicesScreen()),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 10),
                                          TextButton.icon(
                                            icon: const Icon(Icons.replay, color: AppTheme.textMuted, size: 16),
                                            label: const Text('Main Lagi', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                            onPressed: _startGame,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            Text(
              _statusMsg,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF162138).withOpacity(0.4)
      ..strokeWidth = 1;

    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
