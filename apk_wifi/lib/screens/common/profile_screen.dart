import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_config.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/status_badge.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _localImageFile;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _localImageFile = File(picked.path);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Sumber Foto Profil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.primary),
                title: const Text('Kamera Langsung', style: TextStyle(color: AppTheme.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.accent),
                title: const Text('Galeri Gambar', style: TextStyle(color: AppTheme.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('Konfirmasi Logout', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari aplikasi Sima.net?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.instance.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showServerDialog() {
    final controller = TextEditingController(text: AppConfig.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('Atur Alamat Backend', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ganti URL koneksi API Express backend:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'http://localhost:3000',
                prefixIcon: Icon(Icons.dns, color: AppTheme.primary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              AppConfig.setBaseUrl(controller.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Base URL diubah ke: ${AppConfig.baseUrl}'),
                  backgroundColor: AppTheme.success,
                ),
              );
              setState(() {});
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser ??
        UserModel(
          id: 0,
          nama: 'Tamu Sima.net',
          email: 'guest@sima.net',
          noHp: '-',
          role: 'pelanggan',
          negara: 'Indonesia',
          mataUang: 'IDR',
          zonaWaktu: 'WIB',
          alamat: 'Yogyakarta',
          lat: -7.7956,
          lng: 110.3695,
          foto: '',
          status: 'active',
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.error),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar & Name Card
            CustomCard(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primary, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: AppTheme.surfaceElevated,
                          backgroundImage: _localImageFile != null
                              ? FileImage(_localImageFile!) as ImageProvider
                              : (user.foto.isNotEmpty
                                  ? NetworkImage('${AppConfig.baseUrl}${user.foto}') as ImageProvider
                                  : null),
                          child: (_localImageFile == null && user.foto.isEmpty)
                              ? const Icon(Icons.person, size: 54, color: AppTheme.primary)
                              : null,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showImagePickerModal,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 18, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.nama,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StatusBadge(status: user.status),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.secondary),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Account Detail Card
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Akun & Wilayah',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 14),
                  _buildDetailRow(Icons.phone, 'Nomor Telepon / WA', user.noHp.isNotEmpty ? user.noHp : '-'),
                  const Divider(color: AppTheme.border, height: 20),
                  _buildDetailRow(Icons.flag, 'Negara Terdaftar', user.negara),
                  const Divider(color: AppTheme.border, height: 20),
                  _buildDetailRow(Icons.payments, 'Mata Uang Tagihan', '${user.mataUang} (Terkunci per invoice)'),
                  const Divider(color: AppTheme.border, height: 20),
                  _buildDetailRow(Icons.schedule, 'Zona Waktu Default', user.zonaWaktu),
                  const Divider(color: AppTheme.border, height: 20),
                  _buildDetailRow(Icons.location_on, 'Alamat Pemasangan', user.alamat.isNotEmpty ? user.alamat : '-'),
                  const Divider(color: AppTheme.border, height: 20),
                  _buildDetailRow(
                    Icons.pin_drop,
                    'Koordinat GPS',
                    'Lat: ${user.lat.toStringAsFixed(4)}, Lng: ${user.lng.toStringAsFixed(4)}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Settings Card
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pengaturan Aplikasi & Keamanan',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.fingerprint, color: AppTheme.primary),
                    title: const Text('Login Sidik Jari (Biometrik)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                    subtitle: const Text('Pintasan login cepat tanpa memasukkan password', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    trailing: const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                  ),
                  const Divider(color: AppTheme.border),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.dns, color: AppTheme.accent),
                    title: const Text('Server Backend URL', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                    subtitle: Text(AppConfig.baseUrl, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    trailing: const Icon(Icons.edit, color: AppTheme.textSecondary, size: 18),
                    onTap: _showServerDialog,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout Button
            OutlinedButton.icon(
              onPressed: _handleLogout,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'KELUAR DARI APLIKASI (LOGOUT)',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
