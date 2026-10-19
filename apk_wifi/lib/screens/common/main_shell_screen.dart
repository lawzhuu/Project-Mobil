import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../admin/admin_hub_screen.dart';
import '../customer/customer_home_screen.dart';
import '../technician/technician_hub_screen.dart';
import '../technician/technician_my_tasks_screen.dart';
import 'course_feedback_screen.dart';
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

    List<Widget> pages;
    List<BottomNavigationBarItem> navItems;

    if (role == 'admin') {
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
      pages = [
        TechnicianHubScreen(
          onGoToMyTasks: () => setState(() => _currentIndex = 1),
        ),
        TechnicianMyTasksScreen(
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
      // Pelanggan
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

    final safeIndex = _currentIndex.clamp(0, pages.length - 1);

    return Scaffold(
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
