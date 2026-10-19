import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../config/app_theme.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/glowing_button.dart';

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
  int _score = 0;
  Timer? _gameLoop;
  String _statusMsg = 'Miringkan HP Anda untuk mengarahkan pulsa optik ke Port ODP!';

  @override
  void initState() {
    super.initState();
    _startListeningSensors();
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini Game: Sambungkan Fiber'),
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
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // Success Banner
                          if (_isSuccess)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withOpacity(0.75),
                                child: Center(
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
                                        'Skor Akhir: $_score Poin\nInternet Rumah Anda Kini Aktif & Stabil!',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 24),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFF59E0B)),
                                        ),
                                        child: Column(
                                          children: const [
                                            Text(
                                              '🎁 SELAMAT! DAPAT DISKON 10%',
                                              style: TextStyle(
                                                color: Color(0xFFF59E0B),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Gunakan Kode: FIBERHEMAT10 saat bayar tagihan',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(color: Colors.white, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      GlowingButton(
                                        text: 'MAIN LAGI',
                                        icon: Icons.replay,
                                        color: AppTheme.success,
                                        onPressed: _startGame,
                                      ),
                                    ],
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
