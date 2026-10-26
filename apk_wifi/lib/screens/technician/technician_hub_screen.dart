import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/task_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/status_badge.dart';
import 'technician_map_screen.dart';

class TechnicianHubScreen extends StatefulWidget {
  final VoidCallback? onGoToMyTasks;

  const TechnicianHubScreen({super.key, this.onGoToMyTasks});

  @override
  State<TechnicianHubScreen> createState() => _TechnicianHubScreenState();
}

class _TechnicianHubScreenState extends State<TechnicianHubScreen> {
  List<TaskModel> _tasks = [];
  bool _isLoading = true;
  String _selectedFilter = 'semua'; // 'semua', 'tersedia', 'baru', 'dikerjakan', 'selesai'

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final list = await ApiService.instance.getTasks();
    // Urutkan tugas terbaru di urutan paling atas
    list.sort((a, b) => b.id.compareTo(a.id));
    if (mounted) {
      setState(() {
        _tasks = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(TaskModel task, String newStatus) async {
    if (task.isDone) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tugas yang sudah selesai sudah final dan tidak dapat diubah lagi.'),
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
          : 'Status tugas #${task.id} berhasil diubah menjadi "Sedang Dikerjakan"!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.success,
        ),
      );
      _loadTasks();
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
      if (_selectedFilter == 'tersedia') return t.isAvailable;
      return t.status == _selectedFilter;
    }).toList();

    final countTersedia = _tasks.where((t) => t.isAvailable).length;
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
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.engineering, color: AppTheme.primary, size: 22),
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
              // Summary Banner (High Contrast)
              CustomCard(
                gradient: const LinearGradient(
                  colors: [Color(0xFF132238), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total: ${_tasks.length} penugasan ISP Sima.net',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFE2E8F0),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.wifi_tethering, color: AppTheme.accent, size: 13),
                              SizedBox(width: 5),
                              Text(
                                'Live Hub',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
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
                        _buildStatCol('Baru', countBaru.toString(), const Color(0xFF38BDF8)),
                        Container(width: 1, height: 26, color: const Color(0x33FFFFFF)),
                        _buildStatCol('Dikerjakan', countDikerjakan.toString(), const Color(0xFFFBBF24)),
                        Container(width: 1, height: 26, color: const Color(0x33FFFFFF)),
                        _buildStatCol('Selesai', countSelesai.toString(), const Color(0xFF4ADE80)),
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
                    _buildFilterChip('tersedia', 'Tersedia ($countTersedia)'),
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
                                      color: (task.jenis == 'pencopotan'
                                              ? const Color(0xFFDC2626)
                                              : (task.jenis == 'perbaikan' ? AppTheme.error : AppTheme.warning))
                                          .withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      task.jenis == 'pencopotan'
                                          ? Icons.power_settings_new_rounded
                                          : (task.jenis == 'perbaikan' ? Icons.build : Icons.cable),
                                      color: task.jenis == 'pencopotan'
                                          ? const Color(0xFFDC2626)
                                          : (task.jenis == 'perbaikan' ? AppTheme.error : AppTheme.warning),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '#TGS-${task.id} • ${task.jenis.toUpperCase()}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: task.jenis == 'pencopotan'
                                          ? const Color(0xFFDC2626)
                                          : (task.jenis == 'perbaikan' ? AppTheme.error : AppTheme.warning),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  if (task.isAvailable)
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0284C7).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF0284C7)),
                                      ),
                                      child: const Text('Tersedia', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                                    )
                                  else if (task.isMyTask)
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.success.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppTheme.success),
                                      ),
                                      child: const Text('Tugas Anda', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.success)),
                                    )
                                  else
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF64748B).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF64748B)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.lock, size: 9, color: Color(0xFF64748B)),
                                          const SizedBox(width: 3),
                                          Text(
                                            task.teknisiNama ?? 'Diambil',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  StatusBadge(status: task.status),
                                ],
                              ),
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
                          if (task.isAvailable)
                            // 1. TUGAS TERSEDIA (Tugas Baru belum diambil): Hanya tombol "Peta Lokasi" & "Dikerjakan"
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
                                    onPressed: () => _claimAndStart(task),
                                  ),
                                ),
                              ],
                            )
                          else if (task.isMyTask)
                            // 2. TUGAS MILIK SAYA
                            if (task.isNew)
                              // TUGAS BARU MILIK SAYA: Hanya tombol "Peta Lokasi" & "Dikerjakan"
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
                            else if (task.isDone)
                              // TUGAS SELESAI: Terkunci Permanen
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
                                  ),
                                ],
                              )
                            else
                              // TUGAS SEDANG DIKERJAKAN: Baru muncul tombol "Selesai"
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
                                        backgroundColor: AppTheme.success,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(Icons.check_circle, size: 15),
                                      label: const Text('Selesai', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      onPressed: () => _confirmCompleteTask(task),
                                    ),
                                  ),
                                ],
                              )
                          else
                            // 3. SUDAH DIAMBIL TEKNISI LAIN -> Terkunci
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
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF94A3B8),
                                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.lock, size: 13, color: Color(0xFF94A3B8)),
                                    label: const Text('Sudah Diambil', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Tugas #${task.id} sudah diambil oleh ${task.teknisiNama ?? "teknisi lain"} dan tidak bisa diambil lagi.'),
                                          backgroundColor: AppTheme.warning,
                                        ),
                                      );
                                    },
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

  Future<void> _claimAndStart(TaskModel task) async {
    final user = AuthService.instance.currentUser;
    final ok = await ApiService.instance.claimTask(task.id);
    if (!mounted) return;
    if (ok) {
      await ApiService.instance.updateTaskStatus(task.id, 'dikerjakan', teknisiId: user?.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tugas #${task.id} berhasil diambil dan status langsung "Dikerjakan"!'),
          backgroundColor: AppTheme.success,
        ),
      );
      _loadTasks();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengambil tugas. Tugas mungkin telah diambil oleh teknisi lain.'),
          backgroundColor: AppTheme.error,
        ),
      );
      _loadTasks();
    }
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
