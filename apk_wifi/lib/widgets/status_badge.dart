import 'package:flutter/material.dart';
import '../config/app_theme.dart';

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
    if (s == 'active' || s == 'lunas' || s == 'diverifikasi' || s == 'selesai') {
      bg = AppTheme.success.withOpacity(0.18);
      fg = AppTheme.success;
      if (customLabel == null) {
        if (s == 'active') label = 'AKTIF';
        if (s == 'lunas') label = 'LUNAS';
        if (s == 'diverifikasi') label = 'TERVERIFIKASI';
        if (s == 'selesai') label = 'SELESAI';
      }
    } else if (s == 'pending' || s == 'belum' || s == 'menunggu' || s == 'dikerjakan') {
      bg = AppTheme.warning.withOpacity(0.18);
      fg = AppTheme.warning;
      if (customLabel == null) {
        if (s == 'pending') label = 'PENDING';
        if (s == 'belum') label = 'BELUM DIBAYAR';
        if (s == 'menunggu') label = 'VERIFIKASI';
        if (s == 'dikerjakan') label = 'DIKERJAKAN';
      }
    } else if (s == 'baru') {
      bg = AppTheme.info.withOpacity(0.18);
      fg = AppTheme.info;
      label = 'TUGAS BARU';
    } else {
      bg = AppTheme.error.withOpacity(0.18);
      fg = AppTheme.error;
      if (customLabel == null) {
        if (s == 'ditolak') label = 'DITOLAK';
      }
    }

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
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
