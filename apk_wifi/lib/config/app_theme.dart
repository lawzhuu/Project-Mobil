import 'package:flutter/material.dart';

// ==============================================================================
// 🎯 PANDUAN UJIAN PRAKTIKUM: CARA MENGGANTI WARNA APLIKASI
// ==============================================================================
// Jika dosen/penguji meminta: "Coba ubah warna tema aplikasi!",
// File ini (lib/config/app_theme.dart) adalah SATU-SATUNYA file yang perlu Anda ubah!
//
// 📌 CARA MEMBACA FORMAT WARNA FLUTTER:
//    Color(0xFFRRGGBB)
//    - 0x   : Notasi Hexadecimal di bahasa Dart.
//    - FF   : Nilai Opacity/Transparansi (FF = 100% solid / pekat, 80 = 50% transparan).
//    - RR   : Red (Merah)    -> 00 sampai FF
//    - GG   : Green (Hijau)  -> 00 sampai FF
//    - BB   : Blue (Biru)    -> 00 sampai FF
//
// 🎨 CONTEKAN KODE WARNA POPULER (SIAP COPY-PASTE SAAT UJIAN):
//    🟢 HIJAU (Gojek / Tokopedia / Emerald) : Color(0xFF10B981) atau Color(0xFF16A34A)
//    🔴 MERAH (Telkomsel / Netflix / Crimson) : Color(0xFFDC2626) atau Color(0xFFEF4444)
//    🟣 UNGU (OVO / Discord / Modern Tech)   : Color(0xFF7C3AED) atau Color(0xFF8B5CF6)
//    🟠 ORANYE (Shopee / Indosat / Tangerine) : Color(0xFFEA580C) atau Color(0xFFF97316)
//    🔵 BIRU CYAN (BCA / Traveloka / Sky)    : Color(0xFF0284C7) atau Color(0xFF06B6D4)
//    ⚫ DARK / HITAM ELEGAN                   : Color(0xFF0F172A) atau Color(0xFF1E293B)
//
// ⚡ CONTOH PENGGANTIAN CEPAT:
//    Ingin ganti tema biru ke hijau? Cukup ganti:
//    static const Color primary = Color(0xFF10B981); // <-- Ganti baris 42 di bawah
// ==============================================================================

class AppTheme {
  // --- 1. WARNA LATAR & PERMUKAAN (BACKGROUND & CARD) ---
  // Ganti `background` jika penguji meminta warna latar belakang aplikasi diubah.
  static const Color background = Color(0xFFF6F8FC); // Latar belakang utama layar (Putih keabuan lembut)
  static const Color surface = Color(0xFFFFFFFF);    // Permukaan AppBar, Dialog, TextField (Putih bersih)
  static const Color surfaceCard = Color(0xFFFFFFFF);// Warna dasar kartu widget
  static const Color surfaceElevated = Color(0xFFEEF3FB);
  static const Color border = Color(0xFFE2E8F0);     // Warna garis tepi (border) kartu & input

  // --- 2. WARNA BRAND UTAMA (PRIMARY & SECONDARY) ---
  // ⭐ INI YANG PALING SERING DIUJI DOSEN ⭐
  static const Color primary = Color(0xFF0B57CF);      // Warna utama (Tombol login, AppBar aktif, Tab aktif)
  static const Color primaryGlow = Color(0x220B57CF);  // Efek bayangan bersinar (glow) pada tombol
  static const Color primaryLight = Color(0xFFEBF2FD); // Background chip/badge biru muda
  static const Color secondary = Color(0xFF1E40AF);    // Warna pendukung (Biru dongker/indigo)
  static const Color accent = Color(0xFF0284C7);       // Warna aksen pemanis (Biru langit cerah)
  static const Color accentLight = Color(0xFFE0F2FE);

  // --- 3. WARNA STATUS & INDIKATOR SISTEM ---
  // Digunakan di StatusBadge (Lunas, Pending, Ditolak, Berhasil)
  static const Color success = Color(0xFF10B981); // Hijau Emerald (Status: Aktif, Lunas, Berhasil)
  static const Color warning = Color(0xFFF59E0B); // Kuning Amber (Status: Pending, Menunggu verifikasi)
  static const Color error = Color(0xFFEF4444);   // Merah Crimson (Status: Gagal, Ditolak, Hapus)
  static const Color info = Color(0xFF0284C7);    // Biru Langit (Status: Info, Tugas baru)

  // --- 4. WARNA TIPOGRAFI / TEKS ---
  static const Color textPrimary = Color(0xFF0F172A);   // Teks judul/utama (Hitam slate pekat)
  static const Color textSecondary = Color(0xFF475569); // Teks subjudul/deskripsi (Abu-abu gelap)
  static const Color textMuted = Color(0xFF94A3B8);     // Teks petunjuk placeholder/tanggal (Abu-abu pudar)

  // --- 5. GRADASI WARNA (GRADIENTS) ---
  // Digunakan pada Card Header beranda dan Hero banner
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0B57CF), Color(0xFF2563EB)], // Gradasi biru elegan
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF083CA8), Color(0xFF1D68EE)], // Gradasi banner selamat datang
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 2,
        shadowColor: const Color(0x0C000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primary.withOpacity(0.35),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }

  // Alias for backward compatibility
  static ThemeData get darkTheme => lightTheme;
}
