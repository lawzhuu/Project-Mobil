import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../config/app_config.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/glowing_button.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/termination_request_modal.dart';
import '../auth/login_screen.dart';
import '../customer/customer_chatbot_screen.dart';
import '../customer/customer_packages_screen.dart';
import 'feedback_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _localImageBytes;
  bool _isBiometricEnabled = false;
  bool _isLoadingBiometric = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadBiometricSettings();
  }

  Future<void> _loadBiometricSettings() async {
    final enabled = await AuthService.instance.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _isBiometricEnabled = enabled;
        _isLoadingBiometric = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final canUse = await AuthService.instance.canUseBiometrics();
      if (!canUse) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Perangkat tidak mendukung sensor biometrik atau belum ada sidik jari/wajah yang terdaftar di pengaturan HP Anda.',
            ),
            backgroundColor: AppTheme.warning,
          ),
        );
        return;
      }

      final authenticated = await AuthService.instance.authenticateForToggle();
      if (!mounted) return;

      if (authenticated) {
        await AuthService.instance.setBiometricEnabled(true);
        setState(() => _isBiometricEnabled = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Login Sidik Jari (Biometrik) berhasil diaktifkan!'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verifikasi biometrik dibatalkan. Pengaturan tidak diubah.'),
            backgroundColor: AppTheme.warning,
          ),
        );
      }
    } else {
      await AuthService.instance.setBiometricEnabled(false);
      if (mounted) {
        setState(() => _isBiometricEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login Sidik Jari (Biometrik) dinonaktifkan.'),
            backgroundColor: AppTheme.textSecondary,
          ),
        );
      }
    }
  }

  Future<void> _loadProfile() async {
    try {
      final me = await ApiService.instance.getMe();
      if (me != null && mounted) {
        AuthService.instance.updateUserProfile(me);
        setState(() {});
      }
    } catch (e) {
      debugPrint('[ProfileScreen] Error loading profile: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _localImageBytes = bytes;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Mengunggah foto profil ke Storage...'),
                ],
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }

        final res = await ApiService.instance.uploadProfilePhoto(
          fileBytes: bytes,
          fileName: picked.name,
          file: !kIsWeb ? File(picked.path) : null,
        );
        if (res['success'] == true) {
          final currentUser = AuthService.instance.currentUser;
          if (currentUser != null && res['foto'] != null) {
            final updated = currentUser.copyWith(foto: res['foto']);
            AuthService.instance.updateUserProfile(updated);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Foto profil berhasil diunggah dan disimpan ke Storage!',
                ),
                backgroundColor: AppTheme.success,
              ),
            );
            setState(() {});
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(res['message'] ?? 'Gagal mengunggah foto profil'),
                backgroundColor: AppTheme.warning,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
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
                title: const Text(
                  'Kamera Langsung',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppTheme.accent,
                ),
                title: const Text(
                  'Galeri Gambar',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
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



  // Preset mapping alamat Indonesia populer untuk autofill cepat koordinat & zona waktu
  final Map<String, Map<String, dynamic>> _indonesiaCityPresets = {
    'Jakarta': {'lat': -6.2088, 'lng': 106.8456, 'tz': 'WIB'},
    'Bandung': {'lat': -6.9175, 'lng': 107.6191, 'tz': 'WIB'},
    'Semarang': {'lat': -6.9667, 'lng': 110.4167, 'tz': 'WIB'},
    'Yogyakarta': {'lat': -7.7956, 'lng': 110.3695, 'tz': 'WIB'},
    'Surabaya': {'lat': -7.2575, 'lng': 112.7521, 'tz': 'WIB'},
    'Medan': {'lat': 3.5952, 'lng': 98.6722, 'tz': 'WIB'},
    'Denpasar (Bali)': {'lat': -8.6705, 'lng': 115.2126, 'tz': 'WITA'},
    'Makassar': {'lat': -5.1477, 'lng': 119.4327, 'tz': 'WITA'},
    'Balikpapan': {'lat': -1.2379, 'lng': 116.8289, 'tz': 'WITA'},
    'Jayapura': {'lat': -2.5916, 'lng': 140.6690, 'tz': 'WIT'},
    'Ambon': {'lat': -3.6547, 'lng': 128.1906, 'tz': 'WIT'},
  };

  void _showEditProfileDialog(UserModel currentUser) {
    final formKey = GlobalKey<FormState>();
    final mapController = MapController();
    final namaController = TextEditingController(text: currentUser.nama);
    final noHpController = TextEditingController(text: currentUser.noHp);
    final alamatController = TextEditingController(text: currentUser.alamat);

    String selectedCountry = currentUser.negara;
    String selectedMataUang = currentUser.mataUang;
    String selectedZonaWaktu = currentUser.zonaWaktu;
    double currentLat = currentUser.lat;
    double currentLng = currentUser.lng;
    if (currentLat == 0 && currentLng == 0) {
      currentLat = -7.7956;
      currentLng = 110.3695;
    }
    bool isSaving = false;
    bool isFetchingGps = false;

    // Pastikan selectedCountry ada di daftar supportedCountries
    if (!AppConfig.supportedCountries.any(
      (c) => c['name'] == selectedCountry,
    )) {
      selectedCountry = AppConfig.supportedCountries.first['name']!;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            void updateCountry(String? countryName) {
              if (countryName == null) return;
              final found = AppConfig.supportedCountries.firstWhere(
                (c) => c['name'] == countryName,
                orElse: () => AppConfig.supportedCountries.first,
              );
              setModalState(() {
                selectedCountry = countryName;
                selectedMataUang = found['currency'] ?? 'IDR';
                selectedZonaWaktu = found['timezone'] ?? 'WIB';

                // Default koordinat per negara bila belum diatur
                if (countryName == 'United States') {
                  currentLat = 37.7749;
                  currentLng = -122.4194;
                } else if (countryName == 'United Kingdom') {
                  currentLat = 51.5074;
                  currentLng = -0.1278;
                } else if (countryName == 'Germany') {
                  currentLat = 52.5200;
                  currentLng = 13.4050;
                } else if (countryName == 'Netherlands') {
                  currentLat = 52.3676;
                  currentLng = 4.9041;
                } else if (countryName == 'Australia') {
                  currentLat = -33.8688;
                  currentLng = 151.2093;
                } else if (countryName == 'Indonesia' &&
                    currentLat == 0 &&
                    currentLng == 0) {
                  currentLat = -7.7956;
                  currentLng = 110.3695;
                }
              });
              try {
                mapController.move(LatLng(currentLat, currentLng), 13.0);
              } catch (_) {}
            }

            // Fungsi otomatis update koordinat & timezone berdasarkan input alamat
            void detectAddressChanges(String text) {
              final lower = text.toLowerCase();
              for (final entry in _indonesiaCityPresets.entries) {
                if (lower.contains(entry.key.toLowerCase())) {
                  setModalState(() {
                    currentLat = entry.value['lat'];
                    currentLng = entry.value['lng'];
                    if (selectedCountry == 'Indonesia') {
                      selectedZonaWaktu = entry.value['tz'];
                    }
                  });
                  try {
                    mapController.move(LatLng(currentLat, currentLng), 13.0);
                  } catch (_) {}
                  break;
                }
              }
            }

            Future<void> fetchGps() async {
              setModalState(() => isFetchingGps = true);
              try {
                LocationPermission permission =
                    await Geolocator.checkPermission();
                if (permission == LocationPermission.denied) {
                  permission = await Geolocator.requestPermission();
                  if (permission == LocationPermission.denied) {
                    throw Exception('Izin lokasi ditolak');
                  }
                }
                final pos = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.high,
                );

                String fetchedAddress = '';
                String detectedCountry = selectedCountry;

                // Reverse Geocoding via OpenStreetMap Nominatim API
                try {
                  final geoUrl = Uri.parse(
                    'https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}&zoom=18&addressdetails=1',
                  );
                  final geoRes = await http
                      .get(
                        geoUrl,
                        headers: {
                          'User-Agent':
                              'SimaNet-App/1.0 (Mobile Fiber Operation)',
                        },
                      )
                      .timeout(const Duration(seconds: 4));

                  if (geoRes.statusCode == 200) {
                    final geoData = jsonDecode(geoRes.body);
                    final addr = geoData['address'] as Map<String, dynamic>?;
                    if (addr != null) {
                      final road =
                          addr['road'] ??
                          addr['suburb'] ??
                          addr['neighbourhood'] ??
                          '';
                      final city =
                          addr['city'] ??
                          addr['town'] ??
                          addr['county'] ??
                          addr['regency'] ??
                          '';
                      final state = addr['state'] ?? '';
                      final country = addr['country'] ?? '';

                      final parts = [
                        road,
                        city,
                        state,
                      ].where((p) => p.toString().isNotEmpty).toList();
                      if (parts.isNotEmpty) {
                        fetchedAddress = parts.join(', ');
                      } else if (geoData['display_name'] != null) {
                        fetchedAddress = geoData['display_name'].toString();
                      }

                      // Cocokkan negara jika ditemukan
                      if (country.toString().isNotEmpty) {
                        for (final c in AppConfig.supportedCountries) {
                          if (country.toString().toLowerCase().contains(
                            c['name']!.toLowerCase(),
                          )) {
                            detectedCountry = c['name']!;
                            break;
                          }
                        }
                      }
                    }
                  }
                } catch (_) {
                  // Fallback jika offline atau timeout: cari preset kota Indonesia terdekat
                  double minDistance = double.infinity;
                  String closestCity = '';
                  for (final entry in _indonesiaCityPresets.entries) {
                    final dLat = pos.latitude - (entry.value['lat'] as double);
                    final dLng = pos.longitude - (entry.value['lng'] as double);
                    final dist = (dLat * dLat) + (dLng * dLng);
                    if (dist < minDistance) {
                      minDistance = dist;
                      closestCity = entry.key;
                    }
                  }
                  if (closestCity.isNotEmpty && minDistance < 1.0) {
                    fetchedAddress = 'Jl. Sekitar Pusat Kota, $closestCity';
                  }
                }

                setModalState(() {
                  currentLat = pos.latitude;
                  currentLng = pos.longitude;
                  selectedCountry = detectedCountry;

                  final countryConfig = AppConfig.supportedCountries.firstWhere(
                    (c) => c['name'] == selectedCountry,
                    orElse: () => AppConfig.supportedCountries.first,
                  );
                  selectedMataUang = countryConfig['currency'] ?? 'IDR';

                  if (fetchedAddress.isNotEmpty) {
                    alamatController.text = fetchedAddress;
                  }

                  // Auto tentukan zona waktu Indonesia berdasarkan bujur (longitude)
                  if (selectedCountry == 'Indonesia') {
                    if (pos.longitude < 110.0) {
                      selectedZonaWaktu = 'WIB';
                    } else if (pos.longitude < 125.0) {
                      selectedZonaWaktu = 'WITA';
                    } else {
                      selectedZonaWaktu = 'WIT';
                    }
                  } else {
                    selectedZonaWaktu = countryConfig['timezone'] ?? 'London';
                  }
                });

                try {
                  mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
                } catch (_) {}

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Alamat & Koordinat berhasil di-autofill dari GPS!',
                    ),
                    backgroundColor: AppTheme.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal membaca GPS: $e'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              } finally {
                setModalState(() => isFetchingGps = false);
              }
            }

            Future<void> saveProfile() async {
              if (!formKey.currentState!.validate()) return;
              setModalState(() => isSaving = true);

              final nama = namaController.text.trim();
              final noHp = noHpController.text.trim();
              final alamat = alamatController.text.trim();

              final res = await ApiService.instance.updateProfile(
                nama: nama,
                noHp: noHp,
                negara: selectedCountry,
                mataUang: selectedMataUang,
                zonaWaktu: selectedZonaWaktu,
                alamat: alamat,
                lat: currentLat,
                lng: currentLng,
              );

              setModalState(() => isSaving = false);

              if (res['success'] == true) {
                final updatedUser = currentUser.copyWith(
                  nama: nama,
                  noHp: noHp,
                  negara: selectedCountry,
                  mataUang: selectedMataUang,
                  zonaWaktu: selectedZonaWaktu,
                  alamat: alamat,
                  lat: currentLat,
                  lng: currentLng,
                );
                AuthService.instance.updateUserProfile(updatedUser);
                if (mounted) {
                  setState(() {});
                }
                Navigator.pop(modalCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profil berhasil diperbarui & disimpan!'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Gagal menyimpan profil'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(modalCtx).size.height * 0.88,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Modal
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.edit_note,
                                color: AppTheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edit Profil & Wilayah',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Perbarui data informasi akun Anda',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: AppTheme.textMuted,
                              ),
                              onPressed: () => Navigator.pop(modalCtx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppTheme.border),
                        const SizedBox(height: 12),

                        // Input Nama
                        TextFormField(
                          controller: namaController,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap',
                            prefixIcon: Icon(
                              Icons.person,
                              color: AppTheme.primary,
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Nama tidak boleh kosong'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // Input No HP
                        TextFormField(
                          controller: noHpController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Nomor Telepon / WhatsApp',
                            prefixIcon: Icon(
                              Icons.phone,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Dropdown Negara
                        DropdownButtonFormField<String>(
                          value: selectedCountry,
                          dropdownColor: AppTheme.surfaceCard,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Negara',
                            prefixIcon: Icon(
                              Icons.public,
                              color: AppTheme.primary,
                            ),
                          ),
                          items: AppConfig.supportedCountries.map((c) {
                            return DropdownMenuItem<String>(
                              value: c['name'],
                              child: Text(
                                '${c['flag']} ${c['name']}',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: updateCountry,
                        ),
                        const SizedBox(height: 14),

                        // Mata Uang & Zona Waktu (terisi otomatis sebagai input biasa)
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                key: ValueKey('mata_uang_$selectedMataUang'),
                                initialValue: selectedMataUang,
                                readOnly: true,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Mata Uang',
                                  prefixIcon: Icon(
                                    Icons.payments,
                                    color: AppTheme.accent,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                key: ValueKey('zona_waktu_$selectedZonaWaktu'),
                                initialValue: selectedZonaWaktu,
                                readOnly: true,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Zona Waktu',
                                  prefixIcon: Icon(
                                    Icons.schedule,
                                    color: AppTheme.secondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Input Alamat (Otomatis deteksi kota jika ada)
                        TextFormField(
                          controller: alamatController,
                          maxLines: 2,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: InputDecoration(
                            labelText: currentUser.role == 'admin'
                                ? 'Alamat Kantor / Operasional'
                                : (currentUser.role == 'teknisi'
                                      ? 'Alamat Basecamp Teknisi'
                                      : 'Alamat Pemasangan Fiber'),
                            hintText: currentUser.role == 'admin'
                                ? 'Contoh: Kantor Pusat Sima.net, Jl. Telekomunikasi No. 1, Yogyakarta'
                                : (currentUser.role == 'teknisi'
                                      ? 'Contoh: Basecamp Teknisi Sima, Jl. Palagan, Sleman'
                                      : 'Contoh: Jl. Malioboro No. 12, Yogyakarta'),
                            prefixIcon: const Icon(
                              Icons.location_on,
                              color: AppTheme.primary,
                            ),
                            suffixIcon: IconButton(
                              tooltip: 'Gunakan GPS saat ini',
                              icon: isFetchingGps
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.my_location,
                                      color: AppTheme.primary,
                                      size: 20,
                                    ),
                              onPressed: isFetchingGps ? null : fetchGps,
                            ),
                          ),
                          onChanged: detectAddressChanges,
                        ),
                        const SizedBox(height: 14),

                        // Titik Koordinat Peta (seperti di RegisterScreen)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currentUser.role == 'admin'
                                  ? 'Titik Lokasi Kantor (LBS)'
                                  : (currentUser.role == 'teknisi'
                                        ? 'Titik Lokasi Basecamp (LBS)'
                                        : 'Titik Lokasi Pemasangan (LBS)'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: isFetchingGps ? null : fetchGps,
                              icon: isFetchingGps
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.my_location,
                                      size: 16,
                                      color: AppTheme.primary,
                                    ),
                              label: const Text(
                                'GPS Saya',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentUser.role == 'admin'
                              ? 'Ketuk peta untuk menentukan koordinat kantor:'
                              : (currentUser.role == 'teknisi'
                                    ? 'Ketuk peta untuk menentukan koordinat basecamp:'
                                    : 'Ketuk peta untuk menentukan titik koordinat rumah Anda:'),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Map Container (FlutterMap OpenStreetMap)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            height: 210,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: FlutterMap(
                              mapController: mapController,
                              options: MapOptions(
                                initialCenter: LatLng(currentLat, currentLng),
                                initialZoom: 14.0,
                                onTap: (tapPosition, point) {
                                  setModalState(() {
                                    currentLat = point.latitude;
                                    currentLng = point.longitude;
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
                                      point: LatLng(currentLat, currentLng),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pin: Lat ${currentLat.toStringAsFixed(5)}, Lng ${currentLng.toStringAsFixed(5)}',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              'Ketuk peta untuk pindah pin',
                              style: TextStyle(
                                color: AppTheme.primary.withOpacity(0.85),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSaving
                                    ? null
                                    : () => Navigator.pop(modalCtx),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('Batal'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: GlowingButton(
                                text: 'Simpan Perubahan',
                                icon: Icons.check,
                                isLoading: isSaving,
                                onPressed: saveProfile,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user =
        AuthService.instance.currentUser ??
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

    final hasImage = _localImageBytes != null || user.foto.trim().isNotEmpty;
    final ImageProvider? imageProvider = _localImageBytes != null
        ? MemoryImage(_localImageBytes!)
        : (user.foto.trim().isNotEmpty
              ? NetworkImage(AppConfig.resolveImageUrl(user.foto))
              : null);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          user.role == 'teknisi'
              ? 'Profil Teknisi'
              : (user.role == 'admin' ? 'Profil Admin' : 'Profil Pengguna'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar & Name Card
              CustomCard(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primary,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: AppTheme.surfaceElevated,
                            backgroundImage: imageProvider,
                            onBackgroundImageError: hasImage
                                ? (exception, stackTrace) {
                                    debugPrint(
                                      '[ProfileScreen] Failed loading avatar: $exception',
                                    );
                                  }
                                : null,
                            child: !hasImage
                                ? Text(
                                    user.nama.trim().isNotEmpty
                                        ? user.nama.trim()[0].toUpperCase()
                                        : (user.role == 'admin'
                                              ? 'A'
                                              : (user.role == 'teknisi'
                                                    ? 'T'
                                                    : 'U')),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.primary,
                                    ),
                                  )
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
                            child: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.black,
                            ),
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
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        StatusBadge(status: user.status),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Informasi Akun & Wilayah',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showEditProfileDialog(user),
                          icon: const Icon(
                            Icons.edit,
                            size: 14,
                            color: AppTheme.primary,
                          ),
                          label: const Text(
                            'Ubah',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildDetailRow(
                      Icons.phone,
                      'Nomor Telepon / WA',
                      user.noHp.isNotEmpty ? user.noHp : '-',
                    ),
                    const Divider(color: AppTheme.border, height: 20),
                    _buildDetailRow(
                      Icons.flag,
                      'Negara Terdaftar',
                      user.negara,
                    ),
                    const Divider(color: AppTheme.border, height: 20),
                    if (user.role == 'pelanggan') ...[
                      _buildDetailRow(
                        Icons.payments,
                        'Mata Uang Tagihan',
                        '${user.mataUang} (Terkunci per invoice)',
                      ),
                      const Divider(color: AppTheme.border, height: 20),
                    ] else if (user.role == 'admin') ...[
                      _buildDetailRow(
                        Icons.admin_panel_settings_outlined,
                        'Tingkat Hak Akses',
                        'Super Admin (Manajemen Operasional & Keuangan)',
                      ),
                      const Divider(color: AppTheme.border, height: 20),
                    ] else ...[
                      _buildDetailRow(
                        Icons.engineering_outlined,
                        'Divisi Tugas',
                        'Teknisi Lapangan (Instalasi & Maintenance)',
                      ),
                      const Divider(color: AppTheme.border, height: 20),
                    ],
                    _buildDetailRow(
                      Icons.schedule,
                      'Zona Waktu Default',
                      user.zonaWaktu,
                    ),
                    const Divider(color: AppTheme.border, height: 20),
                    _buildDetailRow(
                      Icons.location_on,
                      user.role == 'admin'
                          ? 'Alamat Kantor / Operasional'
                          : (user.role == 'teknisi'
                                ? 'Alamat Basecamp Teknisi'
                                : 'Alamat Pemasangan'),
                      user.alamat.isNotEmpty ? user.alamat : '-',
                    ),
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

              // Status Langganan Internet (Pelanggan)
              if (user.role == 'pelanggan') ...[
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Status Langganan Internet',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: user.status == 'active'
                                  ? AppTheme.success.withValues(alpha: 0.15)
                                  : AppTheme.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              user.status == 'active' ? 'Aktif' : 'Nonaktif',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: user.status == 'active' ? AppTheme.success : AppTheme.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.wifi, color: AppTheme.primary, size: 22),
                        ),
                        title: Text(
                          user.status == 'inactive'
                              ? 'Layanan Berhenti (Nonaktif)'
                              : (user.paketId != null && user.paketId! > 0
                                  ? 'Paket ID #${user.paketId}'
                                  : 'Belum Berlangganan Paket'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: user.status == 'inactive' ? const Color(0xFFDC2626) : AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          user.status == 'inactive'
                              ? 'Tidak ada paket internet aktif. Modem siap ditarik teknisi.'
                              : (user.paketId != null && user.paketId! > 0
                                  ? 'Koneksi Fiber Optik Dedicated Sima.net'
                                  : 'Belum ada paket aktif. Pilih paket untuk mulai berlangganan.'),
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ),
                      if (user.status == 'active' && user.paketId != null && user.paketId! > 0) ...[
                        const Divider(color: AppTheme.border, height: 16),
                        InkWell(
                          onTap: () {
                            TerminationRequestModal.show(
                              context,
                              currentPackageName: 'Paket #${user.paketId}',
                              onSubmitted: () {
                                setState(() {});
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: const [
                                Icon(Icons.power_settings_new_rounded, color: Color(0xFFDC2626), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Berhenti / Putus Langganan Internet',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                                Spacer(),
                                Icon(Icons.chevron_right, color: Color(0xFFDC2626), size: 18),
                              ],
                            ),
                          ),
                        ),
                      ] else if (user.paketId == null || user.paketId == 0) ...[
                        const Divider(color: AppTheme.border, height: 16),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CustomerPackagesScreen(),
                              ),
                            ).then((_) => setState(() {}));
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: const [
                                Icon(Icons.add_shopping_cart_rounded, color: AppTheme.primary, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Pilih & Beli Paket Internet',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                Spacer(),
                                Icon(Icons.chevron_right, color: AppTheme.primary, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ] else if (user.status == 'inactive') ...[
                        const Divider(color: AppTheme.border, height: 16),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CustomerPackagesScreen(),
                              ),
                            ).then((_) => setState(() {}));
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: const [
                                Icon(Icons.replay_rounded, color: AppTheme.primary, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Aktifkan Kembali Layanan Internet',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                Spacer(),
                                Icon(Icons.chevron_right, color: AppTheme.primary, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Pusat Bantuan & Pengaduan (Lapor Gangguan & Chatbot CS)
              if (user.role == 'pelanggan') ...[
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pusat Bantuan & Layanan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.report_problem_outlined, color: AppTheme.error, size: 22),
                        ),
                        title: const Text(
                          'Lapor Gangguan Jaringan',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Text(
                          'Buat tiket perbaikan & pantau status kedatangan teknisi',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FeedbackScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(color: AppTheme.border, height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.smart_toy_outlined, color: AppTheme.primary, size: 22),
                        ),
                        title: const Text(
                          'Chatbot Asisten CS (AI Support)',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Text(
                          'Tanya jawab 24 jam kendala koneksi & panduan mandiri',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CustomerChatbotScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Settings Card
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pengaturan Aplikasi & Keamanan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (_isBiometricEnabled ? AppTheme.primary : AppTheme.textMuted).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.fingerprint,
                          color: _isBiometricEnabled ? AppTheme.primary : AppTheme.textMuted,
                          size: 24,
                        ),
                      ),
                      title: const Text(
                        'Login Sidik Jari (Biometrik)',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _isBiometricEnabled
                            ? 'Aktif • Masuk cepat dengan sensor sidik jari perangkat'
                            : 'Nonaktif • Masuk memerlukan input email dan kata sandi',
                        style: TextStyle(
                          color: _isBiometricEnabled ? AppTheme.success : AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      value: _isBiometricEnabled,
                      activeThumbColor: AppTheme.primary,
                      onChanged: _isLoadingBiometric ? null : _toggleBiometric,
                    ),

                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Tombol Logout Akun
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                      label: const Text(
                        'Keluar dari Akun (Logout)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Keluar akan mengakhiri sesi aktif akun pada perangkat ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppTheme.error),
            SizedBox(width: 10),
            Text(
              'Konfirmasi Logout',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari aplikasi SIMA.NET?',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Keluar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
