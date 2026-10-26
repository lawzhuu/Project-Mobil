import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../config/app_theme.dart';
import '../../models/invoice_model.dart';
import '../../models/package_model.dart';
import '../../models/package_request_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../common/feedback_screen.dart';
import 'ai_bandwidth_advisor_screen.dart';
import 'customer_chatbot_screen.dart';
import 'customer_game_screen.dart';
import 'customer_invoices_screen.dart';
import 'customer_packages_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  List<PackageModel> _packages = [];
  List<InvoiceModel> _invoices = [];
  PackageRequestModel? _pendingRequest;
  UserModel? _currentUser;
  bool _isLoading = true;
  String _selectedCategory = 'Semua';

  List<String> get _categories {
    final set = <String>{'Semua'};
    for (final p in _packages) {
      if (p.kategori.trim().isNotEmpty) {
        set.add(p.kategori.trim());
      }
    }
    return set.toList();
  }

  String _formatRupiah(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatZeroBalance(String mataUang) {
    if (mataUang == 'USD') return '\$0.00';
    if (mataUang == 'EUR') return '€0.00';
    return 'Rp 0';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final profileFuture = ApiService.instance.getMe();
      final pkgsFuture = ApiService.instance.getPackages();
      final invsFuture = ApiService.instance.getInvoices();
      final pendingFuture = ApiService.instance.getCustomerPendingPackageRequest();
      final results = await Future.wait([pkgsFuture, invsFuture, pendingFuture, profileFuture]);

      if (mounted) {
        final profile = results[3] as UserModel?;
        if (profile != null) {
          AuthService.instance.updateUserProfile(profile);
        }

        setState(() {
          _packages = results[0] as List<PackageModel>;
          _invoices = results[1] as List<InvoiceModel>;
          _pendingRequest = results[2] as PackageRequestModel?;
          _currentUser = profile ?? AuthService.instance.currentUser;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InvoiceModel? get _unpaidInvoice {
    try {
      return _invoices.firstWhere((i) => i.status == 'belum');
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser ?? AuthService.instance.currentUser;

    if (user == null && _isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final safeUser = user ??
        UserModel(
          id: 0,
          nama: 'Pelanggan Sima.net',
          email: '',
          noHp: '',
          role: 'pelanggan',
          negara: 'Indonesia',
          mataUang: 'IDR',
          zonaWaktu: 'WIB',
          alamat: '',
          lat: -7.7956,
          lng: 110.3695,
          foto: '',
          status: 'active',
          paketId: null,
        );

    final bool isTerminatedOrNoPackage =
        safeUser.status == 'inactive' || safeUser.paketId == null || safeUser.paketId! <= 0;

    final activePackage = isTerminatedOrNoPackage
        ? PackageModel(
            id: 0,
            nama: safeUser.status == 'inactive'
                ? 'Layanan Berhenti (Nonaktif)'
                : 'Belum Berlangganan Paket',
            kecepatanMbps: 0,
            hargaIdr: 0,
            deskripsi: safeUser.status == 'inactive'
                ? 'Layanan internet Anda telah diputus/dihentikan.'
                : 'Pilih paket internet terbaik untuk mulai berlangganan.',
          )
        : _packages.firstWhere(
            (p) => p.id == safeUser.paketId,
            orElse: () => PackageModel(
              id: 0,
              nama: 'Belum Ada Paket Aktif',
              kecepatanMbps: 0,
              hargaIdr: 0,
              deskripsi: 'Pilih paket internet terbaik untuk mulai berlangganan.',
            ),
          );

    final unpaid = _unpaidInvoice;

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: _buildGameCtaFloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. TOP CURVED BLUE HEADER + OVERLAY HERO CARD
              _buildCurvedHeader(safeUser, activePackage, unpaid),

              // PADDING FOR CONTENT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_pendingRequest != null) ...[
                      const SizedBox(height: 14),
                      _buildPendingRequestCard(),
                    ],
                    const SizedBox(height: 18),

                    // 2. CATEGORY PILL TABS (Horizontal Scroll & Filter)
                    _buildCategoryPills(),

                    const SizedBox(height: 20),

                    // 3. "PAKET KHUSUS UNTUKMU" SECTION (With 'Lihat Semua' CTA to full catalog)
                    _buildSpecialPackagesSection(activePackage),

                    const SizedBox(height: 24),

                    // 4. MENU LAYANAN SIMA.NET (Minimalist, Clean, High UX)
                    _buildServiceGrid(),

                    const SizedBox(height: 90), // Spacing for floating game CTA
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET: TOP CURVED BLUE HEADER ---
  Widget _buildCurvedHeader(
    UserModel user,
    PackageModel activePackage,
    InvoiceModel? unpaidInvoice,
  ) {
    final firstName = user.nama.split(' ').first;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Blue Gradient Curved Container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 52, 18, 80),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0940AA), Color(0xFF1E6BEB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Color(0x260940AA),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: User Profile + Action Icons
              Row(
                children: [
                  // Profile Avatar with Ring (displays real user photo or initials fallback)
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: ClipOval(
                      child: user.foto.isNotEmpty
                          ? Image.network(
                              AppConfig.resolveImageUrl(user.foto),
                              width: 46,
                              height: 46,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    firstName.isNotEmpty
                                        ? firstName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Text(
                                firstName.isNotEmpty
                                    ? firstName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Greeting & Phone
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, $firstName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.noHp.isNotEmpty
                              ? user.noHp
                              : 'Pelanggan Fiber Sima.net',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Icons (Lapor Gangguan, Search, Chatbot Headset, Notification Bell)
                  IconButton(
                    icon: const Icon(
                      Icons.report_problem_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    tooltip: 'Lapor Gangguan Jaringan',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FeedbackScreen(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 22,
                    ),
                    tooltip: 'Cari Paket',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerPackagesScreen(
                            autoFocusSearch: true,
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.headset_mic_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    tooltip: 'Chatbot AI CS',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerChatbotScreen(),
                        ),
                      );
                    },
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                          size: 22,
                        ),
                        tooltip: 'Notifikasi',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CustomerInvoicesScreen(),
                            ),
                          );
                        },
                      ),
                      if (unpaidInvoice != null)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),

        // FLOATING WHITE CARD (MyTelkomsel-like Balance & Quota Card)
        Container(
          margin: const EdgeInsets.only(top: 115, left: 16, right: 16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140F172A),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                if (user.status == 'inactive') ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.power_settings_new_rounded, color: Color(0xFFDC2626), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Status Langganan: Nonaktif / Berhenti. Perangkat modem siap ditarik oleh teknisi.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF991B1B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Top Row: Tagihan & Paket Aktif Links
                Row(
                  children: [
                    // Left: Tagihan Info
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CustomerInvoicesScreen(),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tagihan Anda',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              unpaidInvoice != null
                                  ? unpaidInvoice.formattedAmount
                                  : _formatZeroBalance(user.mataUang),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  unpaidInvoice != null
                                      ? 'Bayar Tagihan'
                                      : 'Semua Lunas',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 14,
                                  color: AppTheme.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Divider
                    Container(
                      height: 42,
                      width: 1,
                      color: const Color(0xFFE2E8F0),
                    ),
                    const SizedBox(width: 14),

                    // Right: Paket Aktif Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Paket Saat Ini',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activePackage.nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                activePackage.id > 0
                                    ? '${activePackage.kecepatanMbps} Mbps Simetris (1:1)'
                                    : (user.status == 'inactive'
                                        ? 'Langganan Nonaktif'
                                        : 'Belum Berlangganan'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: activePackage.id > 0
                                      ? const Color(0xFF059669)
                                      : (user.status == 'inactive'
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFFD97706)),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 14),

                // 4 Circle Metrics (Internet, Status Akun, Valuta, Zona)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCircularMetric(
                      title: 'Kecepatan',
                      value: '${activePackage.kecepatanMbps}',
                      unit: 'Mbps',
                      icon: Icons.speed,
                      iconColor: AppTheme.primary,
                    ),
                    _buildCircularMetric(
                      title: 'Status Akun',
                      value: user.status == 'active'
                          ? 'Aktif'
                          : (user.status == 'inactive' ? 'Nonaktif' : 'Pending'),
                      unit: 'Akun',
                      icon: Icons.verified_user_outlined,
                      iconColor: user.status == 'active'
                          ? const Color(0xFF059669)
                          : (user.status == 'inactive'
                              ? const Color(0xFFDC2626)
                              : const Color(0xFFD97706)),
                    ),
                    _buildCircularMetric(
                      title: 'Mata Uang',
                      value: user.mataUang,
                      unit: 'Valuta',
                      icon: Icons.currency_exchange,
                      iconColor: const Color(0xFFD97706),
                    ),
                    _buildCircularMetric(
                      title: 'Zona Jam',
                      value: user.zonaWaktu,
                      unit: 'Waktu',
                      icon: Icons.schedule,
                      iconColor: const Color(0xFF6366F1),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action Buttons: Riwayat Transaksi & Bayar Tagihan
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CustomerInvoicesScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(
                            color: AppTheme.primary,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        child: const Text(
                          'Riwayat Transaksi',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CustomerInvoicesScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        child: const Text(
                          'Bayar Tagihan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- CIRCULAR METRIC WIDGET ---
  Widget _buildCircularMetric({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconColor.withOpacity(0.08),
            border: Border.all(color: iconColor.withOpacity(0.2), width: 1.5),
          ),
          child: Center(child: Icon(icon, color: iconColor, size: 22)),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        Text(
          unit,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  // --- FLOATING CTA: MINI GAME TILT FIBER (PROMO DISKON) ---
  Widget _buildGameCtaFloatingButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withOpacity(0.38),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomerGameScreen()),
            );
          },
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sports_esports_rounded,
                    color: Color(0xFFEA580C),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Ayo Main Game!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Raih Diskon Tagihan 🎁',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- CATEGORY PILLS (Horizontal Scroll) ---
  Widget _buildCategoryPills() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedCategory = cat;
              });
            },
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- PAKET KHUSUS UNTUKMU (Cards with Badges) ---
  Widget _buildSpecialPackagesSection(PackageModel activePackage) {
    List<PackageModel> filtered = _packages;
    if (_selectedCategory != 'Semua') {
      final sel = _selectedCategory.toLowerCase();
      filtered = _packages.where((p) {
        final cat = p.kategori.toLowerCase();
        final name = p.nama.toLowerCase();
        if (sel == 'internet fiber')
          return cat.contains('fiber') || name.contains('fiber');
        if (sel == 'turbo home')
          return cat.contains('turbo') || name.contains('turbo');
        if (sel == 'gamer sakti')
          return cat.contains('gamer') || name.contains('gamer');
        if (sel == 'promo hemat')
          return cat.contains('promo') ||
              cat.contains('hemat') ||
              name.contains('promo') ||
              name.contains('hemat') ||
              name.contains('pelajar');
        return cat == sel;
      }).toList();
    }
    final promoPackages = filtered.isNotEmpty
        ? filtered
        : (_packages.isNotEmpty ? _packages.take(3).toList() : [activePackage]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Paket Khusus Untukmu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerPackagesScreen(
                      initialCategory: _selectedCategory,
                    ),
                  ),
                );
              },
              child: const Row(
                children: [
                  Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 16, color: AppTheme.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Horizontal Card Carousel
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: promoPackages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final pkg = promoPackages[index];
              final isCurrent = pkg.id == activePackage.id;

              return Container(
                width: 175,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isCurrent
                        ? AppTheme.primary
                        : const Color(0xFFE2E8F0),
                    width: isCurrent ? 1.5 : 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C0F172A),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge: Real Category from Backend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppTheme.primary
                                : (pkg.kategori == 'Gamer Sakti'
                                    ? const Color(0xFF7C3AED)
                                    : (pkg.kategori == 'Promo Hemat'
                                        ? const Color(0xFFEA580C)
                                        : const Color(0xFF0284C7))),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            pkg.kategori,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isCurrent)
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.primary,
                            size: 16,
                          ),
                      ],
                    ),

                    // Name & Speed
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pkg.nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${pkg.kecepatanMbps} Mbps Simetris',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Price & Action Button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rp ${_formatRupiah(pkg.hargaIdr)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          height: 30,
                          child: ElevatedButton(
                            onPressed: () {
                              _showPackageDetailModal(pkg);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCurrent
                                  ? const Color(0xFFE2E8F0)
                                  : AppTheme.primary,
                              foregroundColor: isCurrent
                                  ? const Color(0xFF475569)
                                  : Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              isCurrent ? 'Paket Aktif' : 'Beli Paket',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- MENU LAYANAN SIMA.NET (MINIMALIS & COMPACT HIGH UX) ---
  Widget _buildServiceGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu Layanan Sima.net',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMinimalServiceItem(
                title: 'AI Advisor',
                subtitle: 'Cek Mbps 💡',
                icon: Icons.auto_awesome_rounded,
                iconColor: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFF5F3FF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AiBandwidthAdvisorScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMinimalServiceItem(
                title: 'Tagihan & Bayar',
                subtitle: 'Upload Bukti',
                icon: Icons.receipt_long_rounded,
                iconColor: AppTheme.primary,
                bgColor: const Color(0xFFEFF6FF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CustomerInvoicesScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMinimalServiceItem(
                title: 'Tilt Fiber',
                subtitle: 'Diskon 🎁',
                icon: Icons.sports_esports_rounded,
                iconColor: const Color(0xFFEA580C),
                bgColor: const Color(0xFFFFF7ED),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CustomerGameScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMinimalServiceItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x080F172A),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPackageDetailModal(PackageModel pkg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      pkg.nama,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF2FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${pkg.kecepatanMbps} Mbps',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                pkg.deskripsi,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Harga Berlangganan',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  Text(
                    'Rp ${_formatRupiah(pkg.hargaIdr)} / bulan',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  final user = AuthService.instance.currentUser;
                  final isCurrent = user?.paketId == pkg.id;

                  if (isCurrent) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ini adalah paket aktif Anda saat ini.'),
                        backgroundColor: Color(0xFF475569),
                      ),
                    );
                    return;
                  }

                  if (_pendingRequest != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Anda masih memiliki pengajuan ke "${_pendingRequest!.paketBaruNama}" yang sedang ditinjau admin.',
                        ),
                        backgroundColor: const Color(0xFFD97706),
                      ),
                    );
                    return;
                  }

                  // Arahkan ke daftar paket untuk mengajukan perubahan
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CustomerPackagesScreen(),
                    ),
                  ).then((_) => _loadData());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Ajukan Perubahan Paket',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingRequestCard() {
    final req = _pendingRequest!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08F59E0B),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.pending_actions, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pengajuan Sedang Ditinjau Admin',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: const Text(
                        'Menunggu Persetujuan',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${req.tipe}: Beralih ke "${req.paketBaruNama}" (${req.paketBaruKecepatan} Mbps)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF78350F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Alasan: "${req.alasan}"',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB45309),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
