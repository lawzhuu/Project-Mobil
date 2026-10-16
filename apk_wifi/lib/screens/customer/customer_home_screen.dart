import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/package_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/status_badge.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final pkgs = await ApiService.instance.getPackages();
    if (mounted) {
      setState(() {
        _packages = pkgs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser ??
        UserModel(
          id: 0,
          nama: 'Pelanggan',
          email: 'user@sima.net',
          noHp: '-',
          role: 'pelanggan',
          negara: 'Indonesia',
          mataUang: 'IDR',
          zonaWaktu: 'WIB',
          alamat: 'Alamat Pelanggan',
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
              deskripsi: 'Streaming 4K lancar & gaming stabil',
            ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.wifi, color: AppTheme.primary, size: 22),
            SizedBox(width: 8),
            Text('Sima.net Pelanggan'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome & Status Banner
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ${user.nama.split(' ').first}!',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Koneksi Fiber Optic Terhubung',
                            style: TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                  StatusBadge(status: user.status),
                ],
              ),

              const SizedBox(height: 18),

              // Active Package Hero Card (P2)
              CustomCard(
                padding: const EdgeInsets.all(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF132238), Color(0xFF1E2D4A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderColor: AppTheme.primary.withOpacity(0.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                          ),
                          child: const Text(
                            'PAKET AKTIF SAAT INI',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Icon(Icons.speed, color: AppTheme.primary, size: 28),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      activePackage.nama,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${activePackage.kecepatanMbps}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.accent,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Mbps Unlimited',
                          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      activePackage.deskripsi,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.border, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mata Uang Tagihan', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                            Text('${user.mataUang} (${user.zonaWaktu})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CustomerInvoicesScreen()),
                            );
                          },
                          icon: const Icon(Icons.receipt, size: 16),
                          label: const Text('Cek Tagihan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Interactive Action Grid
              const Text(
                'Menu Layanan Pelanggan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: [
                  _buildActionTile(
                    title: 'Tagihan & Bayar',
                    subtitle: 'Upload struk transfer',
                    icon: Icons.receipt_long,
                    color: AppTheme.primary,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerInvoicesScreen()));
                    },
                  ),
                  _buildActionTile(
                    title: 'Chatbot AI CS',
                    subtitle: 'Bantuan 24/7 router & FO',
                    icon: Icons.smart_toy,
                    color: AppTheme.secondary,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerChatbotScreen()));
                    },
                  ),
                  _buildActionTile(
                    title: 'Game Tilt Fiber',
                    subtitle: 'Sambungkan kabel ODP',
                    icon: Icons.sports_esports,
                    color: AppTheme.warning,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerGameScreen()));
                    },
                  ),
                  _buildActionTile(
                    title: 'Kurs & Waktu',
                    subtitle: 'IDR/USD/EUR & Dunia',
                    icon: Icons.public,
                    color: AppTheme.accent,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CurrencyTimeScreen()));
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // OTHER PACKAGES CATALOG (P2)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Katalog Paket Lainnya',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  Text('Fiber Optic Sima.net', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ..._packages.where((p) => p.id != activePackage.id).map((pkg) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: CustomCard(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.rocket_launch, color: AppTheme.primary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      pkg.nama,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      '${pkg.kecepatanMbps} Mbps',
                                      style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rp ${pkg.hargaIdr} / bulan',
                                  style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pkg.deskripsi,
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      borderColor: color.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
