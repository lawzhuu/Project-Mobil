import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/task_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/status_badge.dart';
import 'technician_map_screen.dart';

class TechnicianMyTasksScreen extends StatefulWidget {
  final VoidCallback? onGoToHub;

  const TechnicianMyTasksScreen({super.key, this.onGoToHub});

  @override
  State<TechnicianMyTasksScreen> createState() => _TechnicianMyTasksScreenState();
}

class _TechnicianMyTasksScreenState extends State<TechnicianMyTasksScreen> {
  List<TaskModel> _tasks = [];
  bool _isLoading = true;
  String _selectedFilter = 'semua'; // 'semua', 'baru', 'dikerjakan', 'selesai'

  @override
  void initState() {
    super.initState();
    _loadMyTasks();
  }

  Future<void> _loadMyTasks() async {
    final user = AuthService.instance.currentUser;
    final currentUserId = user?.id;

    // Load tasks from API with myTasks filter flag
    final list = await ApiService.instance.getTasks(myTasks: true);

    // Ensure we filter strictly for this technician's taken tasks
    final myTasks = list.where((t) {
      if (t.isMyTask) return true;
      if (currentUserId != null && t.teknisiId == currentUserId) return true;
      return false;
    }).toList();

    // Urutkan tugas terbaru di urutan paling atas (ID terbesar lebih dahulu)
    myTasks.sort((a, b) => b.id.compareTo(a.id));

    if (mounted) {
      setState(() {
        _tasks = myTasks;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(TaskModel task, String newStatus) async {
    // Pengaman: Tugas selesai terkunci permanen dan tidak dapat diubah lagi
    if (task.isDone) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tugas yang sudah selesai bersifat permanen dan tidak dapat diubah lagi.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final user = AuthService.instance.currentUser;
    final ok = await ApiService.instance.updateTaskStatus(
      task.id,
      newStatus,
      teknisiId: task.teknisiId ?? user?.id,
    );
    if (ok) {
      if (!mounted) return;
      final msg = newStatus == 'selesai'
          ? 'Tugas #${task.id} telah diselesaikan dan sekarang terkunci permanen!'
          : 'Status tugas #${task.id} berhasil diubah menjadi "Dikerjakan"!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.success,
        ),
      );
      _loadMyTasks();
    }
  }

  Future<void> _confirmCompleteTask(TaskModel task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppTheme.success),
            SizedBox(width: 10),
            Text(
              'Selesaikan Tugas',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin tugas #TGS-${task.id} (${task.jenis.toUpperCase()}) telah selesai dikerjakan?\n\nPerhatian: Tugas yang sudah selesai akan terkunci permanen dan tidak dapat diubah-ubah lagi.',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Ya, Selesaikan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updateStatus(task, 'selesai');
    }
  }



  @override
  Widget build(BuildContext context) {
    final filtered = _tasks.where((t) {
      if (_selectedFilter == 'semua') return true;
      return t.status == _selectedFilter;
    }).toList();

    final countDikerjakan = _tasks.where((t) => t.isInProgress).length;
    final countSelesai = _tasks.where((t) => t.isDone).length;
    final user = AuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.assignment, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Tugas Anda'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined, color: AppTheme.primary),
            tooltip: 'Peta Lapangan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TechnicianMapScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
            tooltip: 'Muat Ulang',
            onPressed: () {
              setState(() => _isLoading = true);
              _loadMyTasks();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyTasks,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Banner for Technician
              CustomCard(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primary.withOpacity(0.2),
                          child: const Icon(Icons.engineering, color: AppTheme.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.nama ?? 'Teknisi SIMA.NET',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_tasks.length} tugas telah Anda ambil',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFCBD5E1),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Color(0x33FFFFFF), height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCol('Dikerjakan', countDikerjakan.toString(), const Color(0xFFFBBF24)),
                        Container(width: 1, height: 28, color: const Color(0x33FFFFFF)),
                        _buildStatCol('Selesai', countSelesai.toString(), const Color(0xFF4ADE80)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Filter Tabs (Hanya Semua, Dikerjakan, Selesai)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('semua', 'Semua (${_tasks.length})'),
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
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_tasks.isEmpty)
                CustomCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.assignment_turned_in_outlined, size: 48, color: AppTheme.primary),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum Ada Tugas yang Diambil',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Anda belum mengambil tugas operasional lapangan.\nSilakan buka Beranda untuk melihat dan mengambil tugas yang tersedia.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                          ),
                          if (widget.onGoToHub != null) ...[
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.arrow_back, size: 16),
                              label: const Text('Ambil Tugas di Beranda', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: widget.onGoToHub,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                const CustomCard(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Tidak ada tugas Anda pada filter kategori ini.',
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
                                      color: (task.isPencopotan
                                              ? const Color(0xFFDC2626)
                                              : (task.jenis == 'perbaikan' ? AppTheme.error : AppTheme.warning))
                                          .withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      task.isPencopotan
                                          ? Icons.power_settings_new_rounded
                                          : (task.jenis == 'perbaikan' ? Icons.build : Icons.cable),
                                      color: task.isPencopotan
                                          ? const Color(0xFFDC2626)
                                          : (task.jenis == 'perbaikan' ? AppTheme.error : AppTheme.warning),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '#TGS-${task.id} • ${task.displayJenis.toUpperCase()}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: task.isPencopotan
                                          ? const Color(0xFFDC2626)
                                          : (task.jenis == 'perbaikan' ? AppTheme.error : AppTheme.warning),
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
                          if (task.pelangganNoHp.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 13, color: AppTheme.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  task.pelangganNoHp,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
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
                          if (task.isNew)
                            // TUGAS BARU: Hanya tombol "Peta Lokasi" & "Dikerjakan"
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primary,
                                      side: const BorderSide(color: AppTheme.primary),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.map_outlined, size: 15),
                                    label: const Text('Peta Lokasi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => TechnicianMapScreen(selectedTask: task)),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF59E0B),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(Icons.engineering, size: 15),
                                    label: const Text('Dikerjakan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () => _updateStatus(task, 'dikerjakan'),
                                  ),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                // Open Map (T2)
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primary,
                                      side: const BorderSide(color: AppTheme.primary),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.map_outlined, size: 15),
                                    label: const Text('Peta Lokasi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => TechnicianMapScreen(selectedTask: task)),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Tombol Aksi Status
                                if (task.isDone)
                                  // TUGAS SELESAI = TERKUNCI PERMANEN & TIDAK DAPAT DIUBAH LAGI
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.success.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppTheme.success.withValues(alpha: 0.35)),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.lock, size: 13, color: AppTheme.success),
                                          SizedBox(width: 5),
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
                                else
                                  // SEDANG DIKERJAKAN -> BARU MUNCUL TOMBOL SELESAI
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.success,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(Icons.check_circle, size: 15),
                                      label: const Text(
                                        'Selesai',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () => _confirmCompleteTask(task),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                }),

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
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFFE2E8F0), fontWeight: FontWeight.w600)),
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
