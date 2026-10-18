import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../admin/admin_hub_screen.dart';
import '../auth/login_screen.dart';
import '../customer/customer_home_screen.dart';
import '../technician/technician_hub_screen.dart';
import 'course_feedback_screen.dart';
import 'profile_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

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
            child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Keluar',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final role = user?.role ?? 'pelanggan';

    // 1. First Page according to role
    Widget homeScreen;
    IconData homeIcon;
    IconData activeHomeIcon;

    if (role == 'admin') {
      homeScreen = const AdminHubScreen();
      homeIcon = Icons.dashboard_outlined;
      activeHomeIcon = Icons.dashboard;
    } else if (role == 'teknisi') {
      homeScreen = const TechnicianHubScreen();
      homeIcon = Icons.engineering_outlined;
      activeHomeIcon = Icons.engineering;
    } else {
      homeScreen = const CustomerHomeScreen();
      homeIcon = Icons.home_outlined;
      activeHomeIcon = Icons.home;
    }

    // 4 standard pages: Beranda, Saran & Kesan Matkul Mobile, Profile, Placeholder for Logout
    final List<Widget> pages = [
      homeScreen,
      const CourseFeedbackScreen(),
      const ProfileScreen(),
      const SizedBox.shrink(),
    ];

    final List<BottomNavigationBarItem> navItems = [
      BottomNavigationBarItem(
        icon: Icon(homeIcon),
        activeIcon: Icon(activeHomeIcon),
        label: 'Beranda',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.school_outlined),
        activeIcon: Icon(Icons.school),
        label: 'Kesan & Saran',
        tooltip: 'Saran dan Kesan Matakuliah Mobile',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.logout, color: AppTheme.error),
        activeIcon: Icon(Icons.logout, color: AppTheme.error),
        label: 'Logout',
      ),
    ];

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
            if (index == 3) {
              // Logout action
              _handleLogout();
            } else {
              setState(() {
                _currentIndex = index;
              });
            }
          },
          items: navItems,
        ),
      ),
    );
  }
}
