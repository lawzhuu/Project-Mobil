import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../config/app_config.dart';
import '../../config/app_theme.dart';
import '../../models/package_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/glowing_button.dart';
import '../common/main_shell_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _hpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();

  String _selectedCountry = 'Indonesia';
  int _selectedPackageId = 1;
  List<PackageModel> _packages = [];

  LatLng _selectedLocation = const LatLng(-7.7956, 110.3695); // Yogyakarta default
  final MapController _mapController = MapController();

  bool _isLoading = false;
  bool _isLoadingPackages = true;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _hpController.dispose();
    _passwordController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  Future<void> _loadPackages() async {
    final pkgs = await ApiService.instance.getPackages();
    if (mounted) {
      setState(() {
        _packages = pkgs;
        if (pkgs.isNotEmpty) _selectedPackageId = pkgs.first.id;
        _isLoadingPackages = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showToast('Izin lokasi ditolak', isError: true);
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newLoc = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _selectedLocation = newLoc;
      });
      _mapController.move(newLoc, 15);
      _showToast('Titik koordinat berhasil disesuaikan dengan GPS');
    } catch (e) {
      _showToast('Gagal membaca GPS: $e', isError: true);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await AuthService.instance.register(
      nama: _namaController.text.trim(),
      email: _emailController.text.trim(),
      noHp: _hpController.text.trim(),
      password: _passwordController.text.trim(),
      negara: _selectedCountry,
      alamat: _alamatController.text.trim(),
      lat: _selectedLocation.latitude,
      lng: _selectedLocation.longitude,
      paketId: _selectedPackageId,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: AppTheme.success),
              SizedBox(width: 8),
              Text('Pendaftaran Berhasil!', style: TextStyle(color: AppTheme.textPrimary)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Akun Anda telah berhasil didaftarkan dengan status PENDING.',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Tim teknisi & admin Sima.net akan segera memverifikasi lokasi pemasangan fiber optic Anda di ${_alamatController.text.trim()}.',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainShellScreen()),
                );
              },
              child: const Text('Buka Dashboard Pelanggan'),
            ),
          ],
        ),
      );
    } else {
      _showToast('Gagal mendaftarkan akun. Silakan periksa kembali data Anda.', isError: true);
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lookup country config
    final countryConfig = AppConfig.supportedCountries.firstWhere(
      (c) => c['name'] == _selectedCountry,
      orElse: () => AppConfig.supportedCountries.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrasi Pasang Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Country & foreign client explanation card
              CustomCard(
                backgroundColor: AppTheme.surfaceElevated.withOpacity(0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.public, color: AppTheme.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Negara & Konversi Otomatis',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pilihan negara otomatis menentukan mata uang tagihan (IDR, USD, EUR) dan zona waktu (WIB, WITA, WIT, London). Cocok untuk pelanggan diaspora.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCountry,
                      dropdownColor: AppTheme.surfaceCard,
                      decoration: const InputDecoration(labelText: 'Pilih Negara'),
                      items: AppConfig.supportedCountries.map((c) {
                        return DropdownMenuItem<String>(
                          value: c['name'],
                          child: Text('${c['flag']}  ${c['name']} (${c['currency']} • ${c['timezone']})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCountry = val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Personal info card
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informasi Pelanggan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _namaController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: Icon(Icons.person, color: AppTheme.primary),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email, color: AppTheme.primary),
                      ),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _hpController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Nomor WhatsApp / HP',
                        prefixIcon: Icon(Icons.phone, color: AppTheme.primary),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Nomor HP wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Password Akun',
                        prefixIcon: Icon(Icons.lock, color: AppTheme.primary),
                      ),
                      validator: (v) => (v == null || v.length < 3) ? 'Password minimal 3 karakter' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Installation address & LBS OpenStreetMap pin picker
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Lokasi Pemasangan (LBS)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        TextButton.icon(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Icons.my_location, size: 16, color: AppTheme.primary),
                          label: const Text('GPS Saya', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _alamatController,
                      maxLines: 2,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Alamat Lengkap Rumah / Kantor',
                        hintText: 'Jl. Contoh No. 123, RT/RW, Kecamatan, Kota',
                        prefixIcon: Icon(Icons.home, color: AppTheme.primary),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Alamat wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Ketuk peta untuk menentukan titik koordinat rumah Anda:',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 8),

                    // Map Container
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 220,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _selectedLocation,
                            initialZoom: 14.0,
                            onTap: (tapPosition, point) {
                              setState(() {
                                _selectedLocation = point;
                              });
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.apk_wifi',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _selectedLocation,
                                  width: 50,
                                  height: 50,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.redAccent,
                                    size: 44,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pin: Lat ${_selectedLocation.latitude.toStringAsFixed(5)}, Lng ${_selectedLocation.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Package selection
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilihan Paket Internet Fiber',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingPackages)
                      const Center(child: CircularProgressIndicator())
                    else
                      Column(
                        children: _packages.map((pkg) {
                          final isSelected = _selectedPackageId == pkg.id;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary.withOpacity(0.12) : AppTheme.surfaceElevated.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppTheme.primary : AppTheme.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: RadioListTile<int>(
                              value: pkg.id,
                              groupValue: _selectedPackageId,
                              activeColor: AppTheme.primary,
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    pkg.nama,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                  Text(
                                    '${pkg.kecepatanMbps} Mbps',
                                    style: const TextStyle(
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                'Rp ${pkg.hargaIdr} / bulan • ${pkg.deskripsi}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedPackageId = val);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              GlowingButton(
                text: 'KIRIM PENDAFTARAN PASANG BARU',
                icon: Icons.send,
                isLoading: _isLoading,
                onPressed: _handleRegister,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
