import 'package:intl/intl.dart';

import 'api_service.dart';

class CurrencyTimeService {
  static final CurrencyTimeService instance = CurrencyTimeService._internal();
  CurrencyTimeService._internal();

  Map<String, double> _idrRates = {'IDR': 1.0, 'USD': 18138.0, 'EUR': 20263.0};

  Map<String, double> get rates => _idrRates;

  Future<void> fetchLatestRates() async {
    try {
      final fetched = await ApiService.instance.getExchangeRates();
      if (fetched.isNotEmpty) {
        _idrRates = fetched;
      }
    } catch (_) {}
  }

  // Convert an amount from fromCurrency to toCurrency
  double convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) {
    if (fromCurrency == toCurrency) return amount;

    // Convert from source currency to IDR base
    final fromRate = _idrRates[fromCurrency] ?? 1.0;
    final toRate = _idrRates[toCurrency] ?? 1.0;

    final inIdr = amount * fromRate;
    final inTarget = inIdr / toRate;
    return inTarget;
  }

  String formatCurrency(double amount, String currency) {
    if (currency == 'USD') {
      return NumberFormat.currency(
        locale: 'en_US',
        symbol: '\$',
        decimalDigits: 2,
      ).format(amount);
    } else if (currency == 'EUR') {
      return NumberFormat.currency(
        locale: 'de_DE',
        symbol: '€',
        decimalDigits: 2,
      ).format(amount);
    } else {
      return NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(amount);
    }
  }

  // Timezone clocks: WIB (UTC+7), WITA (UTC+8), WIT (UTC+9), London (UTC+1 BST)
  static Map<String, DateTime> getWorldTimes() {
    final utc = DateTime.now().toUtc();
    return {
      'WIB': utc.add(const Duration(hours: 7)),
      'WITA': utc.add(const Duration(hours: 8)),
      'WIT': utc.add(const Duration(hours: 9)),
      'London': utc.add(const Duration(hours: 1)),
    };
  }

  static String formatTimeForZone(String zone) {
    final times = getWorldTimes();
    final dt = times[zone] ?? DateTime.now();
    return DateFormat('HH:mm:ss').format(dt);
  }

  static String formatDateForZone(String zone) {
    final times = getWorldTimes();
    final dt = times[zone] ?? DateTime.now();
    return DateFormat('EEEE, dd MMM yyyy').format(dt);
  }
}
