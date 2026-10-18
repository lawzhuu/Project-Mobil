import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/invoice_model.dart';
import '../../models/package_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_card.dart';
import '../common/currency_time_screen.dart';
import '../common/feedback_screen.dart';
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
  bool _isLoading = true;
  String _selectedCategory = 'Semua';

  final List<String> _categories = [
    'Semua',
    'Internet Fiber',
    'Turbo Home',
    'Gamer Sakti',
    'Promo Hemat',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final pkgsFuture = ApiService.instance.getPackages();
      final invsFuture = ApiService.instance.getInvoices();
      final results = await Future.wait([pkgsFuture, invsFuture]);

      if (mounted) {
        setState(() {
          _packages = results[0] as List<PackageModel>;
          _invoices = results[1] as List<InvoiceModel>;
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
      return _invoices.isNotEmpty ? _invoices.first : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser ??
        UserModel(
          id: 2,
          nama: 'Budi Santoso',
          email: 'budi@sima.net',
          noHp: '0812-3456-7890',
          role: 'pelanggan',
          negara: 'Indonesia',
          mataUang: 'IDR',
          zonaWaktu: 'WIB',
          alamat: 'Jl. Malioboro No. 45, Yogyakarta',
          lat: -7.7956,
          lng: 110.3695,
          foto: '',
          status: 'active',
          paketId: 2,
        );

    final activePackage = _packages.firstWhere(
      (p) => p.id == user.paketId,
      orElse: () => _packages.isNotEmpty
          ? _packages.first
          : PackageModel(
              id: 2,
              nama: 'Paket Turbo Home 50',
              kecepatanMbps: 50,
              hargaIdr: 275000,
              deskripsi: 'Streaming 4K lancar & gaming stabil 24/7',
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
              _buildCurvedHeader(user, activePackage, unpaid),

              // PADDING FOR CONTENT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
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
                  // Profile Avatar with Ring
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: Center(
                      child: Text(
                        firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
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
                          user.noHp.isNotEmpty ? user.noHp : 'Pelanggan Fiber Sima.net',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Icons (Saran SIMA.NET, Search, Chatbot Headset, Notification Bell)
                  IconButton(
                    icon: const Icon(Icons.rate_review_outlined, color: Colors.white, size: 22),
                    tooltip: 'Saran & Masukan Sima.net',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white, size: 22),
                    tooltip: 'Cari Paket',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerPackagesScreen(autoFocusSearch: true),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.headset_mic_outlined, color: Colors.white, size: 22),
                    tooltip: 'Chatbot AI CS',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CustomerChatbotScreen()),
                      );
                    },
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: Colors.white, size: 22),
                        tooltip: 'Notifikasi',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CustomerInvoicesScreen()),
                          );
                        },
                      ),
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
                // Top Row: Tagihan & Paket Aktif Links
                Row(
                  children: [
                    // Left: Tagihan Info
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CustomerInvoicesScreen()),
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
                                  : 'Rp 0',
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
                                  unpaidInvoice != null ? 'Bayar Tagihan' : 'Semua Lunas',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.chevron_right, size: 14, color: AppTheme.primary),
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
                            children: const [
                              Text(
                                'Unlimited 24 Jam',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF059669),
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

                // 4 Circle Metrics (Internet, Fiber, Valuta, Zona)
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
                      title: 'Koneksi',
                      value: 'Fiber',
                      unit: 'Optic',
                      icon: Icons.wifi,
                      iconColor: const Color(0xFF059669),
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
                            MaterialPageRoute(builder: (_) => const CustomerInvoicesScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        child: const Text(
                          'Riwayat Transaksi',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CustomerInvoicesScreen()),
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
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
          child: Center(
            child: Icon(icon, color: iconColor, size: 22),
          ),
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
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF64748B),
          ),
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
                  color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0),
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
        if (sel == 'internet fiber') return cat.contains('fiber') || name.contains('fiber');
        if (sel == 'turbo home') return cat.contains('turbo') || name.contains('turbo');
        if (sel == 'gamer sakti') return cat.contains('gamer') || name.contains('gamer');
        if (sel == 'promo hemat') return cat.contains('promo') || cat.contains('hemat') || name.contains('promo') || name.contains('hemat') || name.contains('pelajar');
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
                    color: isCurrent ? AppTheme.primary : const Color(0xFFE2E8F0),
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
                    // Badge: Promo / Best Seller
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: index == 0
                                ? const Color(0xFFEF4444)
                                : (index == 1 ? AppTheme.primary : const Color(0xFFD97706)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            index == 0 ? 'Promo' : (index == 1 ? 'Best Seller' : 'Super Cepat'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isCurrent)
                          const Icon(Icons.check_circle, color: AppTheme.primary, size: 16),
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
                          '${pkg.kecepatanMbps} Mbps | 30 Hari',
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
                          'Rp ${pkg.hargaIdr}',
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
                title: 'Tagihan & Bayar',
                subtitle: 'Upload Bukti',
                icon: Icons.receipt_long_rounded,
                iconColor: AppTheme.primary,
                bgColor: const Color(0xFFEFF6FF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomerInvoicesScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMinimalServiceItem(
                title: 'Tilt Fiber Game',
                subtitle: 'Raih Diskon 🎁',
                icon: Icons.sports_esports_rounded,
                iconColor: const Color(0xFFEA580C),
                bgColor: const Color(0xFFFFF7ED),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomerGameScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMinimalServiceItem(
                title: 'Kurs & Waktu',
                subtitle: 'Valuta Global',
                icon: Icons.public_rounded,
                iconColor: const Color(0xFF0284C7),
                bgColor: const Color(0xFFF0F9FF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CurrencyTimeScreen()),
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
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    'Rp ${pkg.hargaIdr} / bulan',
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Permintaan upgrade ke ${pkg.nama} dicatat!'),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
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
                  'Konfirmasi Berlangganan',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
