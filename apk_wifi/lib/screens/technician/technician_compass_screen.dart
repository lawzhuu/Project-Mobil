import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../config/app_theme.dart';
import '../../models/task_model.dart';
import '../../widgets/custom_card.dart';

class TechnicianCompassScreen extends StatefulWidget {
  final TaskModel? targetTask;

  const TechnicianCompassScreen({super.key, this.targetTask});

  @override
  State<TechnicianCompassScreen> createState() => _TechnicianCompassScreenState();
}

class _TechnicianCompassScreenState extends State<TechnicianCompassScreen> {
  StreamSubscription<MagnetometerEvent>? _magnetometerSub;
  double _headingDegrees = 0.0;
  double _targetBearing = 45.0; // Angle from North to customer
  double _distanceMeters = 0.0;
  bool _sensorAvailable = true;
  String _headingDirection = 'N';

  @override
  void initState() {
    super.initState();
    _startCompass();
    _calculateTargetBearing();
  }

  @override
  void dispose() {
    _magnetometerSub?.cancel();
    super.dispose();
  }

  void _startCompass() {
    try {
      _magnetometerSub = magnetometerEventStream().listen(
        (MagnetometerEvent event) {
          // Calculate heading in radians, then convert to degrees
          double heading = atan2(event.y, event.x) * (180 / pi);
          if (heading < 0) heading += 360;

          setState(() {
            _headingDegrees = heading;
            _sensorAvailable = true;
            _headingDirection = _getCompassDirection(heading);
          });
        },
        onError: (err) {
          setState(() {
            _sensorAvailable = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _sensorAvailable = false;
      });
    }
  }

  Future<void> _calculateTargetBearing() async {
    if (widget.targetTask == null) return;

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 4));

      final startLat = pos.latitude;
      final startLng = pos.longitude;
      final endLat = widget.targetTask!.pelangganLat;
      final endLng = widget.targetTask!.pelangganLng;

      // Distance
      final dist = Geolocator.distanceBetween(startLat, startLng, endLat, endLng);

      // Bearing
      final bearing = Geolocator.bearingBetween(startLat, startLng, endLat, endLng);
      double normalizedBearing = bearing;
      if (normalizedBearing < 0) normalizedBearing += 360;

      if (mounted) {
        setState(() {
          _distanceMeters = dist;
          _targetBearing = normalizedBearing;
        });
      }
    } catch (_) {
      // Default sample distance if GPS unavailable
      if (mounted) {
        setState(() {
          _distanceMeters = 1420.0;
          _targetBearing = 38.0;
        });
      }
    }
  }

  String _getCompassDirection(double degrees) {
    if (degrees >= 337.5 || degrees < 22.5) return 'Utara (N)';
    if (degrees >= 22.5 && degrees < 67.5) return 'Timur Laut (NE)';
    if (degrees >= 67.5 && degrees < 112.5) return 'Timur (E)';
    if (degrees >= 112.5 && degrees < 157.5) return 'Tenggara (SE)';
    if (degrees >= 157.5 && degrees < 202.5) return 'Selatan (S)';
    if (degrees >= 202.5 && degrees < 247.5) return 'Barat Daya (SW)';
    if (degrees >= 247.5 && degrees < 292.5) return 'Barat (W)';
    return 'Barat Laut (NW)';
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.targetTask;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kompas Navigasi Lapangan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Target Customer Info Header
            if (task != null) ...[
              CustomCard(
                borderColor: AppTheme.primary.withOpacity(0.4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryGlow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_pin_circle, color: AppTheme.primary, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.pelangganNama,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            task.pelangganAlamat,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Jarak Garis Lurus: ${(_distanceMeters / 1000).toStringAsFixed(2)} KM (Azimuth: ${_targetBearing.toStringAsFixed(0)}°)',
                            style: const TextStyle(fontSize: 11, color: AppTheme.accent, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (!_sensorAvailable)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.sensors_off, color: AppTheme.warning, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sensor Magnetometer tidak terdeteksi pada perangkat ini. Menampilkan simulasi orientasi arah kompas.',
                        style: TextStyle(fontSize: 12, color: AppTheme.warning),
                      ),
                    ),
                  ],
                ),
              ),

            // Heading readout
            Text(
              '${_headingDegrees.toStringAsFixed(0)}°',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
                letterSpacing: -1,
              ),
            ),
            Text(
              _headingDirection,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 24),

            // COMPASS ROSE VISUALIZER
            Center(
              child: SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Compass Dial (Rotates opposite to device heading)
                    Transform.rotate(
                      angle: -_headingDegrees * (pi / 180),
                      child: Container(
                        width: 270,
                        height: 270,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surfaceCard,
                          border: Border.all(color: AppTheme.border, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Cardinal Labels
                            const Positioned(
                              top: 14,
                              child: Text('N', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w900, fontSize: 18)),
                            ),
                            const Positioned(
                              bottom: 14,
                              child: Text('S', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            const Positioned(
                              left: 16,
                              child: Text('W', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            const Positioned(
                              right: 16,
                              child: Text('E', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),

                            // Customer Target Direction Beacon (Golden Arrow on Dial)
                            if (task != null)
                              Transform.rotate(
                                angle: _targetBearing * (pi / 180),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 36),
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.warning,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.arrow_drop_up, color: Colors.black, size: 24),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Central Needle (Fixed pointing forward relative to phone)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 70,
                          decoration: const BoxDecoration(
                            color: AppTheme.error,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 70,
                          decoration: const BoxDecoration(
                            color: AppTheme.textMuted,
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Simulation slider if hardware magnetometer absent
            if (!_sensorAvailable)
              CustomCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Text('Simulasi Putaran Kompas (Derajat)', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    Slider(
                      value: _headingDegrees,
                      min: 0,
                      max: 360,
                      activeColor: AppTheme.primary,
                      onChanged: (val) {
                        setState(() {
                          _headingDegrees = val;
                          _headingDirection = _getCompassDirection(val);
                        });
                      },
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),
            const Text(
              'Gunakan sensor magnetometer untuk mengarahkan pandangan langsung ke rumah pelanggan saat di lapangan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
