import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/common/main_shell_screen.dart';
import 'services/auth_service.dart';
import 'services/currency_time_service.dart';
import 'services/notification_service.dart';

// ==============================================================================
// PANDUAN PEMULA - TITIK MASUK UTAMA APLIKASI (ENTRY POINT)
// ==============================================================================
// File main.dart adalah gerbang utama eksekusi aplikasi Flutter.
// Fungsi `main()` dijalankan pertama kali saat aplikasi dibuka di Android/iOS/Web.

void main() async {
  // PANDUAN PEMULA:
  // `WidgetsFlutterBinding.ensureInitialized()` WAJIB dipanggil jika ada operasi 'async'
  // sebelum `runApp()`. Ini menghubungkan Flutter Engine dengan platform native (Android/iOS)
  // agar plugin (storage, notifications, geolocation) dapat berkomunikasi dengan aman.
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Memuat konfigurasi variabel lingkungan (.env)
  // Digunakan agar URL backend atau kunci API tidak di-hardcode di dalam source code.
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Notice: .env file not found or failed to load: $e');
  }

  // 2. Inisialisasi Service Notifikasi Lokal
  // Menyiapkan permission channel notifikasi di Android untuk pengingat jatuh tempo & bukti bayar.
  await NotificationService.instance.initialize();

  // 3. Inisialisasi Sesi Login & Token JWT Tersimpan
  // Membaca token JWT terenkripsi dari FlutterSecureStorage agar user tidak perlu login ulang.
  await AuthService.instance.initSession();

  // 4. Unduh Kurs Valuta Asing Terbaru di Latar Belakang (Asynchronous)
  // Tidak menggunakan 'await' di sini agar proses membuka aplikasi tidak tertunda (non-blocking).
  CurrencyTimeService.instance.fetchLatestRates();

  // Menjalankan widget root utama aplikasi
  runApp(const SimaNetApp());
}

/// Widget Induk (Root) Aplikasi
/// Menggunakan `StatelessWidget` karena tema dan rute awal ditentukan sekali saat startup.
class SimaNetApp extends StatelessWidget {
  const SimaNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Mengecek apakah ada token aktif & data user tersimpan
    final bool hasSession = AuthService.instance.isLoggedIn;

    return MaterialApp(
      title: 'Sima.net - ISP Reseller Operations',
      debugShowCheckedModeBanner: false, // Menghilangkan banner "DEBUG" di pojok kanan atas
      theme: AppTheme.lightTheme,
      // PANDUAN PEMULA (Routing Kondisional):
      // Jika user sudah login sebelumnya, langsung arahkan ke 'MainShellScreen' (Home Dashboard).
      // Jika belum, arahkan ke 'LoginScreen'.
      home: hasSession ? const MainShellScreen() : const LoginScreen(),
    );
  }
}
