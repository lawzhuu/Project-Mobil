import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../admin/admin_hub_screen.dart';
import '../customer/customer_chatbot_screen.dart';
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
      // Pelanggan: 4 Nav items
      pages = [
        const CustomerHomeScreen(),     // Beranda
        const CustomerInvoicesScreen(), // Tagihan & Belanja
        const FeedbackScreen(),         // Saran & Kesan
        const ProfileScreen(),          // Akun Profil
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
          label: 'Saran',
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
