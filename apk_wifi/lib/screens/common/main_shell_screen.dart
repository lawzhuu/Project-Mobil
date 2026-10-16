import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../admin/admin_hub_screen.dart';
import '../customer/customer_home_screen.dart';
import '../customer/customer_invoices_screen.dart';
import '../technician/technician_hub_screen.dart';
import '../technician/technician_map_screen.dart';
import 'feedback_screen.dart';
import 'profile_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final role = user?.role ?? 'pelanggan';

    // Dynamic pages according to role
    List<Widget> pages = [];
    List<BottomNavigationBarItem> navItems = [];

    if (role == 'admin') {
      pages = [
        const AdminHubScreen(), // Beranda Admin (AI & Analytics overview)
        const AdminHubScreen(), // Menu Utama Admin
        const FeedbackScreen(), // Saran & Kesan
        const ProfileScreen(),  // Profil
      ];
      navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings_outlined),
          activeIcon: Icon(Icons.admin_panel_settings),
          label: 'Operasional',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.rate_review_outlined),
          activeIcon: Icon(Icons.rate_review),
          label: 'Saran & Kesan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ];
    } else if (role == 'teknisi') {
      pages = [
        const TechnicianHubScreen(), // Beranda Teknisi (Daftar Tugas)
        const TechnicianMapScreen(), // Menu Utama (Peta & LBS)
        const FeedbackScreen(),      // Saran & Kesan
        const ProfileScreen(),       // Profil
      ];
      navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.engineering_outlined),
          activeIcon: Icon(Icons.engineering),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map),
          label: 'Peta Lapangan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.rate_review_outlined),
          activeIcon: Icon(Icons.rate_review),
          label: 'Saran & Kesan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ];
    } else {
      // Pelanggan
      pages = [
        const CustomerHomeScreen(),   // Beranda (Paket Aktif & Katalog)
        const CustomerInvoicesScreen(), // Menu Utama (Tagihan & Upload Bukti)
        const FeedbackScreen(),        // Saran & Kesan
        const ProfileScreen(),         // Profil
      ];
      navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Tagihan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.rate_review_outlined),
          activeIcon: Icon(Icons.rate_review),
          label: 'Saran & Kesan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ];
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(color: AppTheme.border.withOpacity(0.6), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
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
