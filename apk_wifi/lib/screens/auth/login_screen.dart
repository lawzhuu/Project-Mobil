import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/glowing_button.dart';
import '../common/main_shell_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default to admin credentials for swift testing
    _usernameController.text = 'admin@sima.net';
    _passwordController.text = '123';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showToast('Username/Email dan password wajib diisi!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final success = await AuthService.instance.login(
      username: username,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _showToast('Login Berhasil! Selamat datang di Sima.net');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShellScreen()),
      );
    } else {
      _showToast('Login Gagal! Periksa kredensial atau koneksi backend.', isError: true);
    }
  }

  Future<void> _handleBiometricLogin() async {
    final success = await AuthService.instance.authenticateWithBiometrics();
    if (!mounted) return;

    if (success) {
      _showToast('Login Biometrik Berhasil!');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShellScreen()),
      );
    } else {
      _showToast('Autentikasi biometrik gagal atau belum ada sesi tersimpan.', isError: true);
    }
  }

  void _quickFill(String email, String roleName) {
    setState(() {
      _usernameController.text = email;
      _passwordController.text = '123';
    });
    _showToast('Kredensial $roleName terisi.');
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: AppConfig.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('Konfigurasi Backend Server', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan alamat URL backend Express:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'http://localhost:3000',
                prefixIcon: Icon(Icons.link, color: AppTheme.primary),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('localhost:3000'),
                  onPressed: () => controller.text = 'http://localhost:3000',
                ),
                ActionChip(
                  label: const Text('10.0.2.2:3000 (Android)'),
                  onPressed: () => controller.text = 'http://10.0.2.2:3000',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              AppConfig.setBaseUrl(controller.text.trim());
              Navigator.pop(ctx);
              _showToast('Base URL diperbarui ke ${AppConfig.baseUrl}');
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Server config icon top right
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.settings_ethernet, color: AppTheme.textSecondary),
                      tooltip: 'Atur URL Backend',
                      onPressed: _showServerConfigDialog,
                    ),
                  ),

                  // Brand Hero Header
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryGlow,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.3),
                                blurRadius: 28,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.wifi_tethering, color: Colors.white, size: 36),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Sima.net',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sistem Operasional Reseller ISP & Smart Billing',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Login Form Card
                  CustomCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Masuk ke Akun',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _usernameController,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Username / Email / IP',
                            hintText: 'admin@sima.net atau 192.168.1.1',
                            prefixIcon: Icon(Icons.person_outline, color: AppTheme.primary),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: AppTheme.textMuted,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          onSubmitted: (_) => _handleLogin(),
                        ),
                        const SizedBox(height: 20),
                        GlowingButton(
                          text: 'MASUK SEKARANG',
                          icon: Icons.login,
                          isLoading: _isLoading,
                          width: double.infinity,
                          onPressed: _handleLogin,
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: _handleBiometricLogin,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            side: BorderSide(color: AppTheme.border.withOpacity(0.8)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.fingerprint, color: AppTheme.accent),
                          label: const Text(
                            'Masuk dengan Biometrik / Sidik Jari',
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Demo Quick Autofill Chips
                  CustomCard(
                    backgroundColor: AppTheme.surfaceElevated.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.bolt, color: AppTheme.warning, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Pintasan Uji Role Demo:',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ActionChip(
                              backgroundColor: AppTheme.surfaceCard,
                              avatar: const Icon(Icons.admin_panel_settings, size: 14, color: AppTheme.primary),
                              label: const Text('Admin', style: TextStyle(fontSize: 11)),
                              onPressed: () => _quickFill('admin@sima.net', 'Admin'),
                            ),
                            ActionChip(
                              backgroundColor: AppTheme.surfaceCard,
                              avatar: const Icon(Icons.person, size: 14, color: AppTheme.success),
                              label: const Text('Pelanggan IDR', style: TextStyle(fontSize: 11)),
                              onPressed: () => _quickFill('budi@gmail.com', 'Pelanggan IDR'),
                            ),
                            ActionChip(
                              backgroundColor: AppTheme.surfaceCard,
                              avatar: const Icon(Icons.public, size: 14, color: AppTheme.accent),
                              label: const Text('Diaspora USD', style: TextStyle(fontSize: 11)),
                              onPressed: () => _quickFill('sarah@gmail.com', 'Diaspora USD'),
                            ),
                            ActionChip(
                              backgroundColor: AppTheme.surfaceCard,
                              avatar: const Icon(Icons.handyman, size: 14, color: AppTheme.warning),
                              label: const Text('Teknisi', style: TextStyle(fontSize: 11)),
                              onPressed: () => _quickFill('teknisi@sima.net', 'Teknisi'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Belum berlangganan Sima.net? ',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          'Daftar Pasang Baru',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
