import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/task_model.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/status_badge.dart';
import 'technician_compass_screen.dart';
import 'technician_map_screen.dart';

class TechnicianHubScreen extends StatefulWidget {
  const TechnicianHubScreen({super.key});

  @override
  State<TechnicianHubScreen> createState() => _TechnicianHubScreenState();
}

class _TechnicianHubScreenState extends State<TechnicianHubScreen> {
  List<TaskModel> _tasks = [];
  bool _isLoading = true;
  String _selectedFilter = 'semua'; // 'semua', 'baru', 'dikerjakan', 'selesai'

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final list = await ApiService.instance.getTasks();
    if (mounted) {
      setState(() {
        _tasks = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(TaskModel task, String newStatus) async {
    final ok = await ApiService.instance.updateTaskStatus(task.id, newStatus);
    if (ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status tugas #${task.id} diubah menjadi $newStatus!'),
          backgroundColor: AppTheme.success,
        ),
      );
      _loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _tasks.where((t) {
      if (_selectedFilter == 'semua') return true;
      return t.status == _selectedFilter;
    }).toList();

    final countBaru = _tasks.where((t) => t.isNew).length;
    final countDikerjakan = _tasks.where((t) => t.isInProgress).length;
    final countSelesai = _tasks.where((t) => t.isDone).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/logo.png',
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.engineering, color: AppTheme.primary, size: 22),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Tugas Lapangan Teknisi'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map, color: AppTheme.primary),
            tooltip: 'Peta Lapangan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TechnicianMapScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary & Quick Map Banner
              CustomCard(
                gradient: const LinearGradient(
                  colors: [Color(0xFF132238), Color(0xFF1A2644)],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pusat Operasional Lapangan',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Total: ${_tasks.length} penugasan ISP Sima.net',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TechnicianMapScreen()),
                            );
                          },
                          icon: const Icon(Icons.explore, size: 16),
                          label: const Text('Peta GPS'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: AppTheme.border, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCol('Baru', countBaru.toString(), AppTheme.info),
                        Container(width: 1, height: 24, color: AppTheme.border),
                        _buildStatCol('Dikerjakan', countDikerjakan.toString(), AppTheme.warning),
                        Container(width: 1, height: 24, color: AppTheme.border),
                        _buildStatCol('Selesai', countSelesai.toString(), AppTheme.success),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Filter Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('semua', 'Semua (${_tasks.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('baru', 'Baru ($countBaru)'),
                    const SizedBox(width: 8),
                    _buildFilterChip('dikerjakan', 'Dikerjakan ($countDikerjakan)'),
                    const SizedBox(width: 8),
                    _buildFilterChip('selesai', 'Selesai ($countSelesai)'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tasks List
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              else if (filtered.isEmpty)
                const CustomCard(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Tidak ada tugas pada kategori ini.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                )
              else
                ...filtered.map((task) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: task.jenis == 'perbaikan'
                                          ? AppTheme.error.withOpacity(0.18)
                                          : AppTheme.warning.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      task.jenis == 'perbaikan' ? Icons.build : Icons.cable,
                                      color: task.jenis == 'perbaikan' ? AppTheme.error : AppTheme.warning,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '#TGS-${task.id} • ${task.jenis.toUpperCase()}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: task.jenis == 'perbaikan' ? AppTheme.error : AppTheme.warning,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              StatusBadge(status: task.status),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            task.pelangganNama,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: AppTheme.textMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  task.pelangganAlamat,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (task.catatan.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.notes, size: 14, color: AppTheme.accent),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      task.catatan,
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 14),
                          const Divider(color: AppTheme.border, height: 14),

                          // Action Buttons
                          Row(
                            children: [
                              // Open Compass (T3)
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.secondary,
                                    side: const BorderSide(color: AppTheme.secondary),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.explore, size: 14),
                                  label: const Text('Kompas (T3)', style: TextStyle(fontSize: 11)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => TechnicianCompassScreen(targetTask: task)),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Open Map (T2)
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primary,
                                    side: const BorderSide(color: AppTheme.primary),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.map, size: 14),
                                  label: const Text('Peta (T2)', style: TextStyle(fontSize: 11)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => TechnicianMapScreen(selectedTask: task)),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Quick status switcher (T4)
                              PopupMenuButton<String>(
                                tooltip: 'Ubah Status (T4)',
                                color: AppTheme.surfaceCard,
                                icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                                onSelected: (status) => _updateStatus(task, status),
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'baru',
                                    child: Text('Set: Baru', style: TextStyle(color: AppTheme.info)),
                                  ),
                                  const PopupMenuItem(
                                    value: 'dikerjakan',
                                    child: Text('Set: Dikerjakan', style: TextStyle(color: AppTheme.warning)),
                                  ),
                                  const PopupMenuItem(
                                    value: 'selesai',
                                    child: Text('Set: Selesai', style: TextStyle(color: AppTheme.success)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primary.withOpacity(0.2),
      backgroundColor: AppTheme.surfaceCard,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
      ),
      side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.border),
      onSelected: (_) {
        setState(() => _selectedFilter = key);
      },
    );
  }
}
