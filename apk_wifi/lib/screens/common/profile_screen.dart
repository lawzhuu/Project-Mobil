import 'dart:convert';
import 'dart:io';
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
    if (!AppConfig.supportedCountries.any((c) => c['name'] == selectedCountry)) {
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
                } else if (countryName == 'Indonesia' && currentLat == 0 && currentLng == 0) {
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
                LocationPermission permission = await Geolocator.checkPermission();
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
                  final geoRes = await http.get(
                    geoUrl,
                    headers: {'User-Agent': 'SimaNet-App/1.0 (Mobile Fiber Operation)'},
                  ).timeout(const Duration(seconds: 4));

                  if (geoRes.statusCode == 200) {
                    final geoData = jsonDecode(geoRes.body);
                    final addr = geoData['address'] as Map<String, dynamic>?;
                    if (addr != null) {
                      final road = addr['road'] ?? addr['suburb'] ?? addr['neighbourhood'] ?? '';
                      final city = addr['city'] ?? addr['town'] ?? addr['county'] ?? addr['regency'] ?? '';
                      final state = addr['state'] ?? '';
                      final country = addr['country'] ?? '';

                      final parts = [road, city, state].where((p) => p.toString().isNotEmpty).toList();
                      if (parts.isNotEmpty) {
                        fetchedAddress = parts.join(', ');
                      } else if (geoData['display_name'] != null) {
                        fetchedAddress = geoData['display_name'].toString();
                      }

                      // Cocokkan negara jika ditemukan
                      if (country.toString().isNotEmpty) {
                        for (final c in AppConfig.supportedCountries) {
                          if (country.toString().toLowerCase().contains(c['name']!.toLowerCase())) {
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
                    content: Text('Alamat & Koordinat berhasil di-autofill dari GPS!'),
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
                            child: const Icon(Icons.edit_note, color: AppTheme.primary, size: 24),
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
                                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppTheme.textMuted),
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
                          prefixIcon: Icon(Icons.person, color: AppTheme.primary),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 14),

                      // Input No HP
                      TextFormField(
                        controller: noHpController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Nomor Telepon / WhatsApp',
                          prefixIcon: Icon(Icons.phone, color: AppTheme.primary),
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
                          prefixIcon: Icon(Icons.public, color: AppTheme.primary),
                        ),
                        items: AppConfig.supportedCountries.map((c) {
                          return DropdownMenuItem<String>(
                            value: c['name'],
                            child: Text(
                              '${c['flag']} ${c['name']}',
                              style: const TextStyle(color: AppTheme.textPrimary),
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
                              style: const TextStyle(color: AppTheme.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Mata Uang',
                                prefixIcon: Icon(Icons.payments, color: AppTheme.accent),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey('zona_waktu_$selectedZonaWaktu'),
                              initialValue: selectedZonaWaktu,
                              readOnly: true,
                              style: const TextStyle(color: AppTheme.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Zona Waktu',
                                prefixIcon: Icon(Icons.schedule, color: AppTheme.secondary),
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
                          labelText: 'Alamat Pemasangan Fiber',
                          hintText: 'Contoh: Jl. Malioboro No. 12, Yogyakarta',
                          prefixIcon: const Icon(Icons.location_on, color: AppTheme.primary),
                          suffixIcon: IconButton(
                            tooltip: 'Gunakan GPS saat ini',
                            icon: isFetchingGps
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.my_location, color: AppTheme.primary, size: 20),
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
                          const Text(
                            'Titik Lokasi Pemasangan (LBS)',
                            style: TextStyle(
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
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.my_location, size: 16, color: AppTheme.primary),
                            label: const Text(
                              'GPS Saya',
                              style: TextStyle(color: AppTheme.primary, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Ketuk peta untuk menentukan titik koordinat rumah Anda:',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
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
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
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
                              onPressed: isSaving ? null : () => Navigator.pop(modalCtx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Informasi Akun & Wilayah',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      TextButton.icon(
                        onPressed: () => _showEditProfileDialog(user),
                        icon: const Icon(Icons.edit, size: 14, color: AppTheme.primary),
                        label: const Text(
                          'Ubah',
                          style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
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
