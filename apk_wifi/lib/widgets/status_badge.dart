import 'package:flutter/material.dart';
import '../config/app_theme.dart';

// ==============================================================================
// PANDUAN PEMULA & TIPS UJIAN: STATUS BADGE (CHIP STATUS WARNA-WARNI)
// ==============================================================================
// Widget ini bertugas menampilkan pill/badge status dengan warna dinamis:
// - Status Hijau (Success) : 'active', 'lunas', 'diverifikasi', 'selesai'
// - Status Kuning (Warning): 'pending', 'belum', 'menunggu', 'dikerjakan'
// - Status Biru (Info)     : 'baru'
// - Status Merah (Error)   : 'ditolak', 'rusak', 'batal', dll.
//
// CARA KERJA PEWARNAAN DI FLUTTER:
// 1. 'bg' (Background) memakai opacity rendah (0.18 / 18%) agar tampak transparan modern.
// 2. 'fg' (Foreground) memakai warna solid pekat untuk titik lingkaran & teks.
// 3. JIKA UJIAN MINTA GANTI WARNA STATUS TERTENTU:
//    - Ubah referensi `AppTheme.success` ke warna langsung, misal: `const Color(0xFF10B981)`
//    - Atau ganti langsung di file `lib/config/app_theme.dart` agar seragam di semua layar!
// ==============================================================================

class StatusBadge extends StatelessWidget {
  final String status;
  final String? customLabel;

  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label = customLabel ?? status.toUpperCase();

    final s = status.toLowerCase();

    // 1. KONDISI STATUS POSITIF / SUKSES (HIJAU -> AppTheme.success)
    if (s == 'active' || s == 'lunas' || s == 'diverifikasi' || s == 'selesai') {
      bg = AppTheme.success.withOpacity(0.18);
      fg = AppTheme.success;
      if (customLabel == null) {
        if (s == 'active') label = 'AKTIF';
        if (s == 'lunas') label = 'LUNAS';
        if (s == 'diverifikasi') label = 'TERVERIFIKASI';
        if (s == 'selesai') label = 'SELESAI';
      }
    // 2. KONDISI STATUS MENUNGGU / PROSES (KUNING/ORANYE -> AppTheme.warning)
    } else if (s == 'pending' || s == 'belum' || s == 'menunggu' || s == 'dikerjakan') {
      bg = AppTheme.warning.withOpacity(0.18);
      fg = AppTheme.warning;
      if (customLabel == null) {
        if (s == 'pending') label = 'PENDING';
        if (s == 'belum') label = 'BELUM DIBAYAR';
        if (s == 'menunggu') label = 'VERIFIKASI';
        if (s == 'dikerjakan') label = 'DIKERJAKAN';
      }
    // 3. KONDISI STATUS INFORMASI / BARU (CYAN/BIRU -> AppTheme.info)
    } else if (s == 'baru') {
      bg = AppTheme.info.withOpacity(0.18);
      fg = AppTheme.info;
      label = 'TUGAS BARU';
    // 4. KONDISI STATUS GAGAL / DITOLAK (MERAH -> AppTheme.error)
    } else {
      bg = AppTheme.error.withOpacity(0.18);
      fg = AppTheme.error;
      if (customLabel == null) {
        if (s == 'ditolak') label = 'DITOLAK';
      }
    }

    // Tampilan Container Badge berbentuk kapsul (BorderRadius 20)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Titik bulat kecil indikator status
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          // Teks Label Status
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
