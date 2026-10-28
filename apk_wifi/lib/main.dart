import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/common/main_shell_screen.dart';
import 'services/auth_service.dart';
import 'services/currency_time_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Notice: .env file not found or failed to load: $e');
  }

  // Initialize notifications
  await NotificationService.instance.initialize();

  // Initialize active session and secure JWT storage
  await AuthService.instance.initSession();

  // Fetch initial exchange rates in background
  CurrencyTimeService.instance.fetchLatestRates();

  runApp(const SimaNetApp());
}

class SimaNetApp extends StatelessWidget {
  const SimaNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final bool hasSession = AuthService.instance.isLoggedIn;

    return MaterialApp(
      title: 'Sima.net - ISP Reseller Operations',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: hasSession ? const MainShellScreen() : const LoginScreen(),
    );
  }
}
