import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/package_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

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
  bool _isLoading = true;
  String _selectedCategory = 'Semua';
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
    if (widget.initialCategory != null && _categories.contains(widget.initialCategory)) {
      _selectedCategory = widget.initialCategory!;
    }
    _loadPackages();

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
      final list = await ApiService.instance.getPackages();
      if (mounted) {
        setState(() {
          _packages = list;
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
          if (!cat.contains('fiber') && !pkg.nama.toLowerCase().contains('fiber')) {
            return false;
          }
        } else if (sel == 'turbo home') {
          if (!cat.contains('turbo') && !pkg.nama.toLowerCase().contains('turbo')) {
            return false;
          }
        } else if (sel == 'gamer sakti') {
          if (!cat.contains('gamer') && !pkg.nama.toLowerCase().contains('gamer')) {
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
        final matchSpeed = '${pkg.kecepatanMbps} mbps'.contains(query) ||
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
    final activePackageId = currentUser?.paketId ?? 2;
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
                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Cari paket, kecepatan Mbps, atau kebutuhan...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primary : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
            color: isCurrent ? AppTheme.primary.withOpacity(0.08) : const Color(0x0A0F172A),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 12, color: Color(0xFF16A34A)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      'Rp ${_formatRupiah(pkg.hargaIdr)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Text(
                      '/ bulan',
                      style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                    ),
                  ],
                ),

                ElevatedButton(
                  onPressed: () => _showPackageDetailModal(pkg, isCurrent),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrent ? const Color(0xFFF1F5F9) : AppTheme.primary,
                    foregroundColor: isCurrent ? const Color(0xFF64748B) : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isCurrent ? 'Detail Paket' : 'Pilih Paket',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
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
                    _buildModalSpecRow('Bandwidth', '${pkg.kecepatanMbps} Mbps Simetris (1:1)'),
                    const Divider(color: Color(0xFFE2E8F0), height: 16),
                    _buildModalSpecRow('Kuota / FUP', 'Unlimited Tanpa FUP'),
                    const Divider(color: Color(0xFFE2E8F0), height: 16),
                    _buildModalSpecRow('Harga', 'Rp ${_formatRupiah(pkg.hargaIdr)} / bulan'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isCurrent
                            ? 'Ini adalah paket aktif Anda saat ini.'
                            : 'Permintaan berlangganan paket "${pkg.nama}" berhasil diajukan!',
                      ),
                      backgroundColor: isCurrent ? const Color(0xFF475569) : AppTheme.primary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrent ? const Color(0xFF64748B) : AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isCurrent ? 'Tutup' : 'Konfirmasi Pilih Paket',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
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
