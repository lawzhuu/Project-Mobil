import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../admin/admin_hub_screen.dart';
import '../customer/customer_home_screen.dart';
import '../technician/technician_hub_screen.dart';
import '../technician/technician_my_tasks_screen.dart';
import 'course_feedback_screen.dart';
import 'profile_screen.dart';

// ==============================================================================
// PANDUAN PEMULA - SHELL NAVIGASI UTAMA BERBASIS PERAN (ROLE-BASED NAVIGATION)
// ==============================================================================
// File ini bertindak sebagai "cangkang" (shell) utama aplikasi setelah pengguna berhasil login.
// Shell ini menentukan menu apa saja di navigasi bawah (BottomNavigationBar) dan halaman
// mana yang berhak diakses berdasarkan 'role' akun pengguna (Admin, Teknisi, atau Pelanggan).

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  // PANDUAN PEMULA:
  // `_currentIndex` menyimpan nomor tab yang sedang aktif (dimulai dari index 0).
  // Nilai ini berubah setiap kali user menekan salah satu ikon di BottomNavigationBar.
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // 1. Mengambil data akun yang sedang login dari sesi AuthService
    final user = AuthService.instance.currentUser;
    // Jika role belum terdeteksi, default-kan ke 'pelanggan' demi keamanan
    final role = user?.role ?? 'pelanggan';

    // Daftar widget halaman yang akan ditampilkan
    List<Widget> pages;
    // Daftar item ikon dan label pada menu navigasi bawah
    List<BottomNavigationBarItem> navItems;

    // 2. KONDISIONAL BERDASARKAN ROLE (Role-Based Access Control):
    if (role == 'admin') {
      // Menu khusus Administrator (Monitoring, Keuangan, Pengesahan, Saran, Profil)
      pages = const [
        AdminHubScreen(),
        CourseFeedbackScreen(),
        ProfileScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school_outlined),
          activeIcon: Icon(Icons.school),
          label: 'Kesan & Saran',
          tooltip: 'Saran dan Kesan Matakuliah Mobile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else if (role == 'teknisi') {
      // Menu khusus Teknisi Lapangan (Hub Penugasan, Daftar Tugas Saya, Saran, Profil)
      pages = [
        TechnicianHubScreen(
          // Callback navigasi internal: berpindah ke tab 'Tugas Anda' (index 1)
          onGoToMyTasks: () => setState(() => _currentIndex = 1),
        ),
        TechnicianMyTasksScreen(
          // Callback navigasi internal: kembali ke tab 'Beranda' (index 0)
          onGoToHub: () => setState(() => _currentIndex = 0),
        ),
        const CourseFeedbackScreen(),
        const ProfileScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          activeIcon: Icon(Icons.assignment),
          label: 'Tugas Anda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school_outlined),
          activeIcon: Icon(Icons.school),
          label: 'Kesan & Saran',
          tooltip: 'Saran dan Kesan Matakuliah Mobile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else {
      // Menu Pelanggan / User Biasa (Dashboard Paket, Tagihan, Chatbot AI, Saran, Profil)
      pages = const [
        CustomerHomeScreen(),
        CourseFeedbackScreen(),
        ProfileScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school_outlined),
          activeIcon: Icon(Icons.school),
          label: 'Kesan & Saran',
          tooltip: 'Saran dan Kesan Matakuliah Mobile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }

    // PANDUAN PEMULA (Pencegahan RangeError Index):
    // Memastikan `_currentIndex` tidak melebihi jumlah halaman yang tersedia saat role berganti.
    final safeIndex = _currentIndex.clamp(0, pages.length - 1);

    return Scaffold(
      // PANDUAN PEMULA:
      // `IndexedStack` digunakan untuk menampilkan halaman sesuai index tanpa menghancurkan
      // state halaman lain. Artinya, jika user mengisi form di tab Profile lalu pindah ke Beranda
      // dan kembali lagi, posisi scroll dan isi ketikan form TIDAK AKAN HILANG.
      body: IndexedStack(
        index: safeIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0C0F172A),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          currentIndex: safeIndex,
          // PANDUAN PEMULA:
          // Callback `onTap` dipicu ketika user mengklik salah satu menu.
          // `setState()` memberi tahu Flutter untuk me-rebuild UI dengan nilai `_currentIndex` yang baru.
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: navItems,
        ),
      ),
    );
  }
}
