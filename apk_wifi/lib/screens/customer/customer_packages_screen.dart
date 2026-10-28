import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/package_model.dart';
import '../../models/package_request_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/currency_time_service.dart';
import 'ai_bandwidth_advisor_screen.dart';
import '../../widgets/termination_request_modal.dart';

class CustomerPackagesScreen extends StatefulWidget {
  final String? initialCategory;
  final bool autoFocusSearch;

  const CustomerPackagesScreen({
    super.key,
    this.initialCategory,
    this.autoFocusSearch = false,
  });

  @override
  State<CustomerPackagesScreen> createState() => _CustomerPackagesScreenState();
}

class _CustomerPackagesScreenState extends State<CustomerPackagesScreen> {
  List<PackageModel> _packages = [];
  PackageRequestModel? _pendingRequest;
  bool _isLoading = true;
  String _selectedCategory = 'Semua';
  String _selectedCurrency = 'IDR';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

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
    _selectedCurrency = AuthService.instance.currentUser?.mataUang ?? 'IDR';
    if (widget.initialCategory != null &&
        _categories.contains(widget.initialCategory)) {
      _selectedCategory = widget.initialCategory!;
    }
    _loadPackages();
    CurrencyTimeService.instance.fetchLatestRates().then((_) {
      if (mounted) setState(() {});
    });

    if (widget.autoFocusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPackages() async {
    try {
      final pkgsFuture = ApiService.instance.getPackages();
      final pendingFuture = ApiService.instance
          .getCustomerPendingPackageRequest();
      final ratesFuture = CurrencyTimeService.instance.fetchLatestRates();
      final res = await Future.wait([pkgsFuture, pendingFuture, ratesFuture]);
      if (mounted) {
        setState(() {
          _packages = res[0] as List<PackageModel>;
          _pendingRequest = res[1] as PackageRequestModel?;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<PackageModel> _getFilteredPackages() {
    final query = _searchController.text.trim().toLowerCase();

    return _packages.where((pkg) {
      // 1. Filter by category
      if (_selectedCategory != 'Semua') {
        final cat = pkg.kategori.toLowerCase();
        final sel = _selectedCategory.toLowerCase();
        if (sel == 'internet fiber') {
          if (!cat.contains('fiber') &&
              !pkg.nama.toLowerCase().contains('fiber')) {
            return false;
          }
        } else if (sel == 'turbo home') {
          if (!cat.contains('turbo') &&
              !pkg.nama.toLowerCase().contains('turbo')) {
            return false;
          }
        } else if (sel == 'gamer sakti') {
          if (!cat.contains('gamer') &&
              !pkg.nama.toLowerCase().contains('gamer')) {
            return false;
          }
        } else if (sel == 'promo hemat') {
          if (!cat.contains('promo') &&
              !cat.contains('hemat') &&
              !pkg.nama.toLowerCase().contains('promo') &&
              !pkg.nama.toLowerCase().contains('hemat') &&
              !pkg.nama.toLowerCase().contains('pelajar')) {
            return false;
          }
        } else if (cat != sel) {
          return false;
        }
      }

      // 2. Filter by search query
      if (query.isNotEmpty) {
        final matchName = pkg.nama.toLowerCase().contains(query);
        final matchDesc = pkg.deskripsi.toLowerCase().contains(query);
        final matchSpeed =
            '${pkg.kecepatanMbps} mbps'.contains(query) ||
            pkg.kecepatanMbps.toString().contains(query);
        final matchCategory = pkg.kategori.toLowerCase().contains(query);

        if (!matchName && !matchDesc && !matchSpeed && !matchCategory) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.instance.currentUser;
    final activePackageId =
        (currentUser?.status == 'inactive' || currentUser?.paketId == null)
        ? null
        : currentUser?.paketId;
    final filtered = _getFilteredPackages();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Pilihan Paket Internet',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
        ),
      ),
      body: Column(
        children: [
          _buildPendingRequestBanner(),
          // 1. TOP SEARCH & FILTER BAR
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                // Search Input Field
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari paket, kecepatan Mbps, atau kebutuhan...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Color(0xFF64748B),
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Category Filter Pills
                SizedBox(
                  height: 36,
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
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // Global Currency Switcher Strip (Diaspora & Multi-Currency)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.currency_exchange,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Valuta:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 8),
                      for (final curr in ['IDR', 'USD', 'EUR']) ...[
                        InkWell(
                          onTap: () async {
                            setState(() => _selectedCurrency = curr);
                            await CurrencyTimeService.instance.fetchLatestRates();
                            if (mounted) setState(() {});
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedCurrency == curr
                                  ? AppTheme.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _selectedCurrency == curr
                                  ? AppTheme.primary
                                  : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Text(
                              curr == 'IDR'
                                  ? '🇮🇩 IDR'
                                  : (curr == 'USD' ? '🇺🇸 USD' : '🇪🇺 EUR'),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: _selectedCurrency == curr
                                    ? Colors.white
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        _selectedCurrency == 'USD'
                            ? '1 USD = Rp ${_formatRupiah((CurrencyTimeService.instance.rates['USD'] ?? 18138).round())}'
                            : (_selectedCurrency == 'EUR'
                                  ? '1 EUR = Rp ${_formatRupiah((CurrencyTimeService.instance.rates['EUR'] ?? 20263).round())}'
                                  : 'Kurs Live ECB'),
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF64748B),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // AI Advisor Interactive Banner
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AiBandwidthAdvisorScreen(),
                      ),
                    ).then((_) => _loadPackages());
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x207C3AED),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Bingung Pilih Kecepatan Mbps?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Konsultasi gratis dengan AI Bandwidth Advisor 💡',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. PACKAGE LIST OR EMPTY STATE
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadPackages,
                    color: AppTheme.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final pkg = filtered[index];
                        final isCurrent = pkg.id == activePackageId;
                        return _buildPackageCard(pkg, isCurrent);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak Ada Paket Ditemukan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Coba gunakan kata kunci lain atau ubah kategori filter paket.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _selectedCategory = 'Semua';
                });
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset Filter & Pencarian'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(PackageModel pkg, bool isCurrent) {
    Color badgeColor = const Color(0xFF2563EB);
    IconData categoryIcon = Icons.wifi;

    if (pkg.kategori == 'Turbo Home') {
      badgeColor = const Color(0xFF0D9488);
      categoryIcon = Icons.bolt;
    } else if (pkg.kategori == 'Gamer Sakti') {
      badgeColor = const Color(0xFF7C3AED);
      categoryIcon = Icons.sports_esports;
    } else if (pkg.kategori == 'Promo Hemat') {
      badgeColor = const Color(0xFFEA580C);
      categoryIcon = Icons.local_offer;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent ? AppTheme.primary : const Color(0xFFE2E8F0),
          width: isCurrent ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrent
                ? AppTheme.primary.withOpacity(0.08)
                : const Color(0x0A0F172A),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category Tag & Speed Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(categoryIcon, size: 13, color: badgeColor),
                          const SizedBox(width: 4),
                          Text(
                            pkg.kategori,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Color(0xFF16A34A),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Paket Aktif',
                              style: TextStyle(
                                color: Color(0xFF16A34A),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                // Speed Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    '${pkg.kecepatanMbps} Mbps',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Package Title
            Text(
              pkg.nama,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),

            // Description
            Text(
              pkg.deskripsi,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.35,
              ),
            ),

            const SizedBox(height: 14),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),

            // Benefits checklist
            Row(
              children: [
                _buildBenefitItem(Icons.all_inclusive, 'Unlimited 24/7'),
                const SizedBox(width: 14),
                _buildBenefitItem(Icons.speed, 'Ping Rendah'),
                const SizedBox(width: 14),
                _buildBenefitItem(Icons.support_agent, 'Support 24/7'),
              ],
            ),

            const SizedBox(height: 16),

            // Bottom Price & Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Biaya Langganan',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedCurrency == 'IDR'
                          ? 'Rp ${_formatRupiah(pkg.hargaIdr)}'
                          : CurrencyTimeService.instance.formatCurrency(
                              CurrencyTimeService.instance.convertCurrency(
                                amount: pkg.hargaIdr.toDouble(),
                                fromCurrency: 'IDR',
                                toCurrency: _selectedCurrency,
                              ),
                              _selectedCurrency,
                            ),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      _selectedCurrency == 'IDR'
                          ? '/ bulan'
                          : '/ bln (Dasar: Rp ${_formatRupiah(pkg.hargaIdr)})',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),

                ElevatedButton(
                  onPressed: () => _showPackageDetailModal(pkg, isCurrent),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrent
                        ? const Color(0xFFF1F5F9)
                        : AppTheme.primary,
                    foregroundColor: isCurrent
                        ? const Color(0xFF64748B)
                        : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isCurrent
                        ? 'Detail Paket'
                        : (AuthService.instance.currentUser?.paketId == null
                              ? 'Beli & Pasang'
                              : 'Pilih Paket'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (isCurrent &&
                AuthService.instance.currentUser?.paketId != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  if (_pendingRequest != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Anda masih memiliki pengajuan pending yang sedang ditinjau admin.',
                        ),
                        backgroundColor: AppTheme.warning,
                      ),
                    );
                    return;
                  }
                  TerminationRequestModal.show(
                    context,
                    currentPackageName: pkg.nama,
                    onSubmitted: _loadPackages,
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.power_settings_new_rounded,
                        size: 14,
                        color: Color(0xFFDC2626),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Ajukan Berhenti Berlangganan',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF10B981)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF475569),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatRupiah(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  void _showPackageDetailModal(PackageModel pkg, bool isCurrent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
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
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
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
              const SizedBox(height: 10),

              Text(
                pkg.deskripsi,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildModalSpecRow('Kategori', pkg.kategori),
                    const Divider(color: Color(0xFFE2E8F0), height: 16),
                    _buildModalSpecRow(
                      'Bandwidth',
                      '${pkg.kecepatanMbps} Mbps Simetris (1:1)',
                    ),
                    const Divider(color: Color(0xFFE2E8F0), height: 16),
                    _buildModalSpecRow('Kuota / FUP', 'Unlimited Tanpa FUP'),
                    const Divider(color: Color(0xFFE2E8F0), height: 16),
                    _buildModalSpecRow(
                      'Harga',
                      _selectedCurrency == 'IDR'
                          ? 'Rp ${_formatRupiah(pkg.hargaIdr)} / bulan'
                          : '${CurrencyTimeService.instance.formatCurrency(CurrencyTimeService.instance.convertCurrency(amount: pkg.hargaIdr.toDouble(), fromCurrency: 'IDR', toCurrency: _selectedCurrency), _selectedCurrency)} / bulan (Rp ${_formatRupiah(pkg.hargaIdr)})',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
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

                  _showChangeRequestSheet(pkg);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrent
                      ? const Color(0xFF64748B)
                      : (_pendingRequest != null
                            ? const Color(0xFFF59E0B)
                            : AppTheme.primary),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isCurrent
                      ? 'Tutup'
                      : (_pendingRequest != null
                            ? 'Pengajuan Sedang Ditinjau Admin'
                            : ((AuthService.instance.currentUser?.status ==
                                          'inactive' ||
                                      AuthService
                                              .instance
                                              .currentUser
                                              ?.paketId ==
                                          null)
                                  ? 'Beli & Pasang Paket Ini'
                                  : 'Ajukan Perubahan Paket')),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingRequestBanner() {
    if (_pendingRequest == null) return const SizedBox.shrink();
    final req = _pendingRequest!;
    final isTerm = req.isTermination;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTerm ? const Color(0xFFFEF2F2) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTerm
              ? const Color(0xFFEF4444).withValues(alpha: 0.4)
              : const Color(0xFFF59E0B).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isTerm ? const Color(0xFFDC2626) : const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isTerm ? Icons.power_settings_new_rounded : Icons.hourglass_top,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTerm
                      ? 'Pengajuan Pemutusan Layanan Sedang Ditinjau'
                      : 'Pengajuan Paket Sedang Ditinjau Admin',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isTerm
                        ? const Color(0xFF991B1B)
                        : const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isTerm
                      ? 'Paket: ${req.paketLamaNama} • Alasan: ${req.alasan}'
                      : '${req.tipe}: ${req.paketLamaNama} ➔ ${req.paketBaruNama} (${req.paketBaruKecepatan} Mbps)',
                  style: TextStyle(
                    fontSize: 11,
                    color: isTerm
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isTerm
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFF59E0B),
              ),
            ),
            child: Text(
              'Pending',
              style: TextStyle(
                color: isTerm
                    ? const Color(0xFFDC2626)
                    : const Color(0xFFB45309),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangeRequestSheet(PackageModel targetPkg) {
    final user = AuthService.instance.currentUser;
    final bool isFirstSubscription =
        user?.status == 'inactive' ||
        user?.paketId == null ||
        user?.paketId == 0;
    final currentPkgId = user?.paketId;
    final currentPkg = _packages.firstWhere(
      (p) => p.id == currentPkgId,
      orElse: () => _packages.isNotEmpty ? _packages.first : targetPkg,
    );

    final isUpgrade =
        !isFirstSubscription &&
        targetPkg.kecepatanMbps > currentPkg.kecepatanMbps;
    String selectedTipe = isFirstSubscription
        ? 'Langganan Baru'
        : (isUpgrade ? 'Upgrade Kecepatan' : 'Hemat Biaya (Downgrade)');
    final reasonController = TextEditingController(
      text: isFirstSubscription
          ? 'Pemasangan baru koneksi internet fiber optik di alamat saya.'
          : (isUpgrade
                ? 'Membutuhkan bandwidth lebih tinggi untuk streaming 4K dan gaming stabil.'
                : 'Penyesuaian kebutuhan penggunaan internet keluarga.'),
    );
    final diffPrice = isFirstSubscription
        ? targetPkg.hargaIdr
        : (targetPkg.hargaIdr - currentPkg.hargaIdr);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
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
                  const SizedBox(height: 16),
                  Text(
                    isFirstSubscription
                        ? 'Beli & Pasang Paket Baru'
                        : 'Pengajuan Perubahan Paket (Approval Admin)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isFirstSubscription
                        ? 'Permintaan pasang baru akan dikirimkan ke Admin Hub untuk dijadwalkan teknisi.'
                        : 'Permintaan akan dikirimkan ke Admin Hub untuk ditinjau dan disetujui.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Perbandingan Paket
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Paket Saat Ini:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isFirstSubscription
                                    ? 'Belum Berlangganan (0M)'
                                    : '${currentPkg.nama} (${currentPkg.kecepatanMbps}M)',
                                textAlign: TextAlign.end,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        Row(
                          children: [
                            const Text(
                              'Paket Tujuan:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${targetPkg.nama} (${targetPkg.kecepatanMbps}M)',
                                textAlign: TextAlign.end,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              isFirstSubscription
                                  ? 'Biaya Langganan:'
                                  : 'Selisih Harga:',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isFirstSubscription
                                    ? 'Rp ${_formatRupiah(targetPkg.hargaIdr)} / bln'
                                    : (diffPrice >= 0
                                          ? '+Rp ${_formatRupiah(diffPrice)} / bln'
                                          : '-Rp ${_formatRupiah(-diffPrice)} / bln'),
                                textAlign: TextAlign.end,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isFirstSubscription
                                      ? AppTheme.primary
                                      : (diffPrice >= 0
                                            ? const Color(0xFF059669)
                                            : const Color(0xFF2563EB)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Tipe Pengajuan
                  const Text(
                    'Tipe Pengajuan:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedTipe,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    items: isFirstSubscription
                        ? const [
                            DropdownMenuItem(
                              value: 'Langganan Baru',
                              child: Text(
                                '🚀 Langganan Baru (Pasang Baru)',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ]
                        : const [
                            DropdownMenuItem(
                              value: 'Upgrade Kecepatan',
                              child: Text(
                                '🚀 Upgrade Kecepatan (Koneksi Lebih Cepat)',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Hemat Biaya (Downgrade)',
                              child: Text(
                                '💰 Hemat Biaya (Penyesuaian Budget)',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Ganti Paket Khusus',
                              child: Text(
                                '✨ Ganti Paket Khusus (Promo / Gamer)',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                    onChanged: (v) {
                      if (v != null) setModalState(() => selectedTipe = v);
                    },
                  ),

                  const SizedBox(height: 12),

                  // Alasan
                  Text(
                    isFirstSubscription
                        ? 'Catatan / Alamat Tambahan:'
                        : 'Alasan / Kebutuhan:',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: isFirstSubscription
                          ? 'Tuliskan catatan tambahan atau preferensi jadwal pasang...'
                          : 'Tuliskan alasan pengajuan perubahan paket...',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(ctx);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Mengirimkan pengajuan ke admin...'),
                          duration: Duration(seconds: 1),
                        ),
                      );

                      final res = await ApiService.instance
                          .submitPackageChangeRequest(
                            packageId: targetPkg.id,
                            tipe: selectedTipe,
                            alasan: reasonController.text.trim(),
                          );

                      if (!mounted) return;

                      if (res['success'] == true) {
                        await _loadPackages();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              res['message'] ?? 'Pengajuan berhasil dikirim!',
                            ),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              res['message'] ?? 'Gagal mengajukan paket',
                            ),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isFirstSubscription
                          ? 'Kirim Pengajuan Pasang Baru'
                          : 'Kirim Pengajuan ke Admin',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalSpecRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
