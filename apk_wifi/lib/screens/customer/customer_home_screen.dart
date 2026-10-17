import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/invoice_model.dart';
import '../../models/package_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_card.dart';
import '../common/currency_time_screen.dart';
import 'customer_chatbot_screen.dart';
import 'customer_game_screen.dart';
import 'customer_invoices_screen.dart';

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
                    const SizedBox(height: 16),

                    // 2. DAILY CHECK-IN / FIBER HEALTH BANNER
                    _buildDailyCheckInBanner(),

                    const SizedBox(height: 20),

                    // 3. CATEGORY PILL TABS (Horizontal Scroll)
                    _buildCategoryPills(),

                    const SizedBox(height: 20),

                    // 4. "PAKET KHUSUS UNTUKMU" SECTION (Cards with Promo Badge)
                    _buildSpecialPackagesSection(activePackage),

                    const SizedBox(height: 24),

                    // 5. MENU LAYANAN PELANGGAN (Interactive Quick Grid)
                    _buildServiceGrid(),

                    const SizedBox(height: 24),

                    // 6. PILIHAN PAKET LAINNYA
                    _buildOtherPackagesList(activePackage),

                    const SizedBox(height: 28),
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

                  // Action Icons (Search, Chatbot Headset, Notification Bell)
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white, size: 22),
                    tooltip: 'Cari Paket',
                    onPressed: () {},
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

  // --- DAILY CHECK-IN / HEALTH BANNER ---
  Widget _buildDailyCheckInBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF2FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_outlined, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Koneksi Fiber Optic Terverifikasi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Status jaringan prima • Latensi stabil 3ms',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
        ],
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
    final promoPackages = _packages.isNotEmpty
        ? _packages.take(3).toList()
        : [activePackage];

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
              onTap: () {},
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
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

  // --- SERVICE QUICK ACTION GRID ---
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
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            _buildActionCard(
              title: 'Tagihan & Bayar',
              subtitle: 'Upload struk bukti transfer',
              icon: Icons.receipt_long,
              iconColor: AppTheme.primary,
              badgeText: 'Penting',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerInvoicesScreen()),
                );
              },
            ),
            _buildActionCard(
              title: 'Chatbot AI CS',
              subtitle: 'Bantuan 24/7 router & ODP',
              icon: Icons.smart_toy_outlined,
              iconColor: const Color(0xFF6366F1),
              badgeText: '24/7',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerChatbotScreen()),
                );
              },
            ),
            _buildActionCard(
              title: 'Game Tilt Fiber',
              subtitle: 'Sambungkan kabel ODP',
              icon: Icons.sports_esports_outlined,
              iconColor: const Color(0xFFD97706),
              badgeText: 'Mini Game',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerGameScreen()),
                );
              },
            ),
            _buildActionCard(
              title: 'Kurs & Waktu',
              subtitle: 'Konversi mata uang dunia',
              icon: Icons.public,
              iconColor: const Color(0xFF0284C7),
              badgeText: 'Global',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CurrencyTimeScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- PILIHAN PAKET INTERNET LAINNYA ---
  Widget _buildOtherPackagesList(PackageModel activePackage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Pilihan Paket Internet Lainnya',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Fiber Optic',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          )
        else
          ..._packages.where((p) => p.id != activePackage.id).map((pkg) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x080F172A),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF2FD),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Icon(Icons.wifi, color: AppTheme.primary, size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pkg.nama,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${pkg.kecepatanMbps} Mbps Unlimited • ${pkg.deskripsi}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rp ${pkg.hargaIdr} / bln',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _showPackageDetailModal(pkg),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEBF2FD),
                      foregroundColor: AppTheme.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Pilih',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
      ],
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
