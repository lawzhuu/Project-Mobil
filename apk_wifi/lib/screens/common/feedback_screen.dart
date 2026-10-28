import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/task_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/glowing_button.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final List<String> _kategoriList = [
    'Lampu LOS Merah / Kabel FO Putus',
    'Internet Lambat / High Ping & RTO',
    'Router / WiFi Terhubung Tanpa Internet',
    'Modem / Adaptor Rusak atau Mati Total',
    'Pindah Posisi Modem / Titik Kabel',
    'Kendala Jaringan Lainnya',
  ];

  late String _selectedKategori;
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _noKontakController = TextEditingController();

  List<TaskModel> _tickets = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedKategori = _kategoriList.first;
    final user = AuthService.instance.currentUser;
    if (user != null && user.noHp.isNotEmpty) {
      _noKontakController.text = user.noHp;
    }
    _loadTickets();
  }

  @override
  void dispose() {
    _deskripsiController.dispose();
    _noKontakController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    try {
      final list = await ApiService.instance.getTasks();
      if (mounted) {
        setState(() {
          // Tampilkan tiket milik pelanggan dengan urutan terbaru di atas
          _tickets = list.reversed.toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSubmit() async {
    final deskripsi = _deskripsiController.text.trim();
    final noKontak = _noKontakController.text.trim();

    if (deskripsi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap jelaskan kendala atau gejala gangguan yang Anda alami!'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final res = await ApiService.instance.reportTrouble(
      kategori: _selectedKategori,
      deskripsi: deskripsi,
      noKontak: noKontak.isNotEmpty ? noKontak : null,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      _deskripsiController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Laporan gangguan berhasil dibuat! Tim teknisi akan segera menindaklanjuti.'),
          backgroundColor: AppTheme.success,
        ),
      );
      _loadTickets();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal membuat laporan gangguan. Coba lagi.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return AppTheme.success;
      case 'dikerjakan':
        return AppTheme.primary;
      case 'baru':
      default:
        return AppTheme.warning;
    }
  }

  String _getStatusLabel(String status, String? teknisiNama) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return 'Selesai Ditangani';
      case 'dikerjakan':
        return teknisiNama != null && teknisiNama.isNotEmpty
            ? 'Ditangani oleh $teknisiNama'
            : 'Sedang Ditangani Teknisi';
      case 'baru':
      default:
        return 'Menunggu Teknisi';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lapor Gangguan Jaringan'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTickets,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Banner Card
              CustomCard(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.error.withValues(alpha: 0.18),
                    AppTheme.primary.withValues(alpha: 0.12),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.build_circle_rounded, color: AppTheme.error, size: 30),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pusat Bantuan & Tiket Gangguan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Mengalami kendala koneksi? Kirim laporan di sini agar teknisi Sima.net segera diterjunkan ke lokasi.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Formulir Lapor Gangguan
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.report_problem_outlined, color: AppTheme.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Formulir Pengaduan Kendala',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Dropdown Kategori
                    const Text(
                      'Jenis Kendala / Gejala Gangguan',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedKategori,
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceCard,
                          icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
                          items: _kategoriList.map((kat) {
                            return DropdownMenuItem<String>(
                              value: kat,
                              child: Text(
                                kat,
                                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedKategori = val);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Field Nomor Kontak
                    const Text(
                      'Nomor WhatsApp Aktif / Darurat',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noKontakController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Contoh: 081234567890 (untuk dihubungi teknisi)',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20, color: AppTheme.textSecondary),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Field Deskripsi Kendala
                    const Text(
                      'Deskripsi Gangguan',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _deskripsiController,
                      maxLines: 3,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Jelaskan kondisi lampu router, kapan mulai terjadi, atau detail kendala...',
                      ),
                    ),

                    const SizedBox(height: 20),

                    GlowingButton(
                      text: 'KIRIM LAPORAN GANGGUAN',
                      icon: Icons.send_rounded,
                      color: AppTheme.error,
                      isLoading: _isSubmitting,
                      width: double.infinity,
                      onPressed: _handleSubmit,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Riwayat Tiket Gangguan Pengguna
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Tiket Gangguan Anda',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  Text(
                    '${_tickets.length} tiket',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_tickets.isEmpty)
                CustomCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: const [
                          Icon(Icons.check_circle_outline, color: AppTheme.success, size: 36),
                          SizedBox(height: 8),
                          Text(
                            'Tidak Ada Tiket Gangguan Aktif',
                            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Koneksi Anda saat ini berjalan normal. Jika mengalami kendala teknis, silakan buat laporan melalui formulir di atas.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ..._tickets.map((t) {
                  final statusColor = _getStatusColor(t.status);
                  final statusLabel = _getStatusLabel(t.status, t.teknisiNama);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        t.jenis == 'instalasi' ? Icons.cable : Icons.build,
                                        size: 16,
                                        color: statusColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '#TKT-${t.id} • ${t.jenis.toUpperCase()}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20, color: AppTheme.border),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.notes, size: 16, color: AppTheme.textMuted),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  t.catatan.isNotEmpty ? t.catatan : 'Laporan kendala jaringan',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (t.teknisiNama != null && t.teknisiNama!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.person_pin, size: 16, color: AppTheme.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Teknisi Ditugaskan: ${t.teknisiNama}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
