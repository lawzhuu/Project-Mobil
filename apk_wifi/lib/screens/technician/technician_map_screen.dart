import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:sensors_plus/sensors_plus.dart';
import '../../config/app_theme.dart';
import '../../models/task_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/status_badge.dart';
import 'technician_compass_screen.dart';

class TechnicianMapScreen extends StatefulWidget {
  final TaskModel? selectedTask;

  const TechnicianMapScreen({super.key, this.selectedTask});

  @override
  State<TechnicianMapScreen> createState() => _TechnicianMapScreenState();
}

class _TechnicianMapScreenState extends State<TechnicianMapScreen> {
  final MapController _mapController = MapController();
  List<TaskModel> _tasks = [];
  TaskModel? _activeTask;

  LatLng _technicianLocation = const LatLng(-7.7550, 110.3750); // Sleman basecamp default
  bool _isLoading = true;

  StreamSubscription<MagnetometerEvent>? _magnetometerSub;
  double _headingDegrees = 0.0;
  bool _sensorAvailable = true;

  @override
  void initState() {
    super.initState();
    _activeTask = widget.selectedTask;
    _loadTasksAndGPS();
    _startCompass();
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
          double heading = atan2(event.y, event.x) * (180 / pi);
          if (heading < 0) heading += 360;
          if (mounted) {
            setState(() {
              _headingDegrees = heading;
              _sensorAvailable = true;
            });
          }
        },
        onError: (_) {
          if (mounted) setState(() => _sensorAvailable = false);
        },
      );
    } catch (_) {
      if (mounted) setState(() => _sensorAvailable = false);
    }
  }

  Future<void> _loadTasksAndGPS() async {
    final tasks = await ApiService.instance.getTasks();
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 4));
      _technicianLocation = LatLng(pos.latitude, pos.longitude);
    } catch (_) {}

    if (mounted) {
      setState(() {
        _tasks = tasks;
        _isLoading = false;
        if (_activeTask == null && tasks.isNotEmpty) {
          _activeTask = tasks.first;
        } else if (_activeTask != null) {
          _activeTask = tasks.firstWhere(
            (t) => t.id == _activeTask!.id,
            orElse: () => _activeTask!,
          );
        }
      });

      if (_activeTask != null) {
        _mapController.move(LatLng(_activeTask!.pelangganLat, _activeTask!.pelangganLng), 14);
      }
    }
  }

  void _centerToTechnician() {
    _mapController.move(_technicianLocation, 15);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Titik Pelanggan (LBS)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: AppTheme.primary),
            tooltip: 'Lokasi Saya',
            onPressed: _centerToTechnician,
          ),
        ],
      ),
      body: Stack(
        children: [
          // FlutterMap OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _activeTask != null
                  ? LatLng(_activeTask!.pelangganLat, _activeTask!.pelangganLng)
                  : _technicianLocation,
              initialZoom: 13.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.apk_wifi',
              ),

              // Markers Layer
              MarkerLayer(
                markers: [
                  // Technician GPS location marker
                  Marker(
                    point: _technicianLocation,
                    width: 60,
                    height: 60,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.handyman, color: Colors.black, size: 18),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Posisi Anda', style: TextStyle(color: Colors.white, fontSize: 9)),
                        ),
                      ],
                    ),
                  ),

                  // Customer task locations markers
                  ..._tasks.map((task) {
                    final isSelected = _activeTask?.id == task.id;
                    final isDone = task.isDone;

                    return Marker(
                      point: LatLng(task.pelangganLat, task.pelangganLng),
                      width: 70,
                      height: 70,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeTask = task;
                          });
                          _mapController.move(LatLng(task.pelangganLat, task.pelangganLng), 14.5);
                        },
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isDone
                                    ? AppTheme.success
                                    : (task.jenis == 'perbaikan' ? AppTheme.error : AppTheme.warning),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: isSelected ? 2.5 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Icon(
                                task.jenis == 'perbaikan' ? Icons.build : Icons.cable,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                task.pelangganNama.split(' ').first,
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Loading overlay
          if (_isLoading)
            const Positioned(
              top: 16,
              left: 16,
              child: Card(
                color: AppTheme.surfaceCard,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Memuat data titik lapangan...', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),

          // Top-Right Live Compass Overlay
          Positioned(
            top: 16,
            right: 16,
            child: Tooltip(
              message: 'Buka Kompas Digital (${_headingDegrees.toInt()}°)',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TechnicianCompassScreen(targetTask: _activeTask),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Compass Dial Needle
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0F172A),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Positioned(
                                top: 2,
                                child: Text(
                                  'U',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              CustomPaint(
                                size: const Size(44, 44),
                                painter: CompassNeedlePainter(heading: _headingDegrees),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${_headingDegrees.toInt()}°',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _sensorAvailable ? Icons.explore : Icons.explore_off,
                              size: 10,
                              color: AppTheme.secondary,
                            ),
                            const SizedBox(width: 2),
                            const Text(
                              'Kompas',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Selected Customer Floating Bottom Detail Card
          if (_activeTask != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _activeTask!.jenis == 'perbaikan'
                                    ? AppTheme.error.withOpacity(0.18)
                                    : AppTheme.warning.withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _activeTask!.jenis == 'perbaikan' ? Icons.build : Icons.cable,
                                color: _activeTask!.jenis == 'perbaikan' ? AppTheme.error : AppTheme.warning,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _activeTask!.pelangganNama,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                                ),
                                Text(
                                  _activeTask!.jenis == 'perbaikan' ? 'Tugas Perbaikan' : 'Tugas Pasang Baru',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _activeTask!.jenis == 'perbaikan' ? AppTheme.error : AppTheme.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        StatusBadge(status: _activeTask!.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _activeTask!.pelangganAlamat,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    if (_activeTask!.catatan.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Catatan: ${_activeTask!.catatan}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Actions Row
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.explore, size: 16),
                            label: const Text('Buka Kompas', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TechnicianCompassScreen(targetTask: _activeTask),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (_activeTask!.isDone)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock, size: 14, color: AppTheme.success),
                                  SizedBox(width: 4),
                                  Text(
                                    'Selesai (Terkunci)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (_activeTask!.isNew)
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.engineering, size: 16),
                              label: const Text('Dikerjakan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final user = AuthService.instance.currentUser;
                                await ApiService.instance.updateTaskStatus(
                                  _activeTask!.id,
                                  'dikerjakan',
                                  teknisiId: _activeTask!.teknisiId ?? user?.id,
                                );
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Status tugas #${_activeTask!.id} berhasil diubah menjadi "Dikerjakan"!'),
                                    backgroundColor: AppTheme.success,
                                  ),
                                );
                                _loadTasksAndGPS();
                              },
                            ),
                          )
                        else
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.check_circle, size: 16),
                              label: const Text('Selesai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Selesaikan Tugas'),
                                    content: Text('Selesaikan tugas #${_activeTask!.id}? Tugas yang sudah selesai akan dikunci permanen.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Ya, Selesaikan', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final user = AuthService.instance.currentUser;
                                  await ApiService.instance.updateTaskStatus(
                                    _activeTask!.id,
                                    'selesai',
                                    teknisiId: _activeTask!.teknisiId ?? user?.id,
                                  );
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Tugas #${_activeTask!.id} telah selesai dan terkunci permanen!'),
                                      backgroundColor: AppTheme.success,
                                    ),
                                  );
                                  _loadTasksAndGPS();
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CompassNeedlePainter extends CustomPainter {
  final double heading;

  CompassNeedlePainter({required this.heading});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    // Rotate needle relative to compass heading
    canvas.rotate((360 - heading) * pi / 180);

    // North Needle (Red)
    final redPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;
    final northPath = Path()
      ..moveTo(0, -radius + 5)
      ..lineTo(4, -1)
      ..lineTo(-4, -1)
      ..close();
    canvas.drawPath(northPath, redPaint);

    // South Needle (Silver/White)
    final whitePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;
    final southPath = Path()
      ..moveTo(0, radius - 5)
      ..lineTo(4, 1)
      ..lineTo(-4, 1)
      ..close();
    canvas.drawPath(southPath, whitePaint);

    // Center pivot point
    final pivotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset.zero, 2.5, pivotPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CompassNeedlePainter oldDelegate) =>
      oldDelegate.heading != heading;
}
