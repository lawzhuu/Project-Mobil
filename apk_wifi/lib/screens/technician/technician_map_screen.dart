import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../config/app_theme.dart';
import '../../models/task_model.dart';
import '../../services/api_service.dart';
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

  @override
  void initState() {
    super.initState();
    _activeTask = widget.selectedTask;
    _loadTasksAndGPS();
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
                  }).toList(),
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
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.update, size: 16),
                            label: const Text('Update Status', style: TextStyle(fontSize: 12)),
                            onPressed: () => _showStatusUpdateDialog(_activeTask!),
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

  void _showStatusUpdateDialog(TaskModel task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: Text('Update Status Tugas #${task.id}', style: const TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.fiber_new, color: AppTheme.info),
              title: const Text('Baru Diterima', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () async {
                Navigator.pop(ctx);
                await ApiService.instance.updateTaskStatus(task.id, 'baru');
                _loadTasksAndGPS();
              },
            ),
            ListTile(
              leading: const Icon(Icons.engineering, color: AppTheme.warning),
              title: const Text('Sedang Dikerjakan di Lapangan', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () async {
                Navigator.pop(ctx);
                await ApiService.instance.updateTaskStatus(task.id, 'dikerjakan');
                _loadTasksAndGPS();
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: AppTheme.success),
              title: const Text('Selesai Dipasang / Diperbaiki', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () async {
                Navigator.pop(ctx);
                await ApiService.instance.updateTaskStatus(task.id, 'selesai');
                _loadTasksAndGPS();
              },
            ),
          ],
        ),
      ),
    );
  }
}
