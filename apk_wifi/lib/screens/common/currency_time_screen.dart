import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/currency_time_service.dart';
import '../../widgets/custom_card.dart';

class CurrencyTimeScreen extends StatefulWidget {
  const CurrencyTimeScreen({super.key});

  @override
  State<CurrencyTimeScreen> createState() => _CurrencyTimeScreenState();
}

class _CurrencyTimeScreenState extends State<CurrencyTimeScreen> {
  final TextEditingController _amountController = TextEditingController(text: '100000');
  String _fromCurrency = 'IDR';
  String _toCurrency = 'USD';
  double _convertedResult = 0.0;

  Timer? _clockTimer;
  Map<String, DateTime> _worldTimes = CurrencyTimeService.getWorldTimes();

  @override
  void initState() {
    super.initState();
    _recalculate();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _worldTimes = CurrencyTimeService.getWorldTimes();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  void _recalculate() {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    final result = CurrencyTimeService.instance.convertCurrency(
      amount: amount,
      fromCurrency: _fromCurrency,
      toCurrency: _toCurrency,
    );
    setState(() {
      _convertedResult = result;
    });
  }

  void _swapCurrencies() {
    setState(() {
      final tmp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = tmp;
    });
    _recalculate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kurs & Zona Waktu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // CURRENCY CONVERTER CARD
            CustomCard(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withOpacity(0.12),
                  AppTheme.secondary.withOpacity(0.12),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.currency_exchange, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Konversi Mata Uang (IDR, USD, EUR)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Input Amount
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      labelText: 'Nominal yang Dikonversi',
                      prefixIcon: Icon(Icons.monetization_on, color: AppTheme.primary),
                    ),
                    onChanged: (_) => _recalculate(),
                  ),

                  const SizedBox(height: 14),

                  // Currency pickers and swap
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _fromCurrency,
                          dropdownColor: AppTheme.surfaceCard,
                          decoration: const InputDecoration(labelText: 'Dari'),
                          items: const [
                            DropdownMenuItem(value: 'IDR', child: Text('🇮🇩 IDR (Rupiah)')),
                            DropdownMenuItem(value: 'USD', child: Text('🇺🇸 USD (Dollar)')),
                            DropdownMenuItem(value: 'EUR', child: Text('🇪🇺 EUR (Euro)')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _fromCurrency = v);
                              _recalculate();
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.swap_horiz, color: AppTheme.accent),
                        onPressed: _swapCurrencies,
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _toCurrency,
                          dropdownColor: AppTheme.surfaceCard,
                          decoration: const InputDecoration(labelText: 'Ke'),
                          items: const [
                            DropdownMenuItem(value: 'IDR', child: Text('🇮🇩 IDR (Rupiah)')),
                            DropdownMenuItem(value: 'USD', child: Text('🇺🇸 USD (Dollar)')),
                            DropdownMenuItem(value: 'EUR', child: Text('🇪🇺 EUR (Euro)')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _toCurrency = v);
                              _recalculate();
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Result display box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Hasil Konversi:',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyTimeService.instance.formatCurrency(_convertedResult, _toCurrency),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kurs Referensi: 1 USD ≈ Rp 15.500 | 1 EUR ≈ Rp 16.800',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // TIMEZONE CLOCKS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Zona Waktu Operasional Sima.net',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Live UTC Sync',
                  style: TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Pelanggan diaspora dan lokal dapat melihat jadwal jatuh tempo tagihan sesuai zona waktu masing-masing (WIB, WITA, WIT, London).',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),

            // Clock Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildClockCard(
                  flag: '🇮🇩',
                  zoneName: 'WIB (Barat)',
                  utcOffset: 'UTC+7 (Jakarta)',
                  time: CurrencyTimeService.formatTimeForZone('WIB'),
                  date: CurrencyTimeService.formatDateForZone('WIB'),
                  color: AppTheme.primary,
                ),
                _buildClockCard(
                  flag: '🇮🇩',
                  zoneName: 'WITA (Tengah)',
                  utcOffset: 'UTC+8 (Bali / Mks)',
                  time: CurrencyTimeService.formatTimeForZone('WITA'),
                  date: CurrencyTimeService.formatDateForZone('WITA'),
                  color: AppTheme.accent,
                ),
                _buildClockCard(
                  flag: '🇮🇩',
                  zoneName: 'WIT (Timur)',
                  utcOffset: 'UTC+9 (Jayapura)',
                  time: CurrencyTimeService.formatTimeForZone('WIT'),
                  date: CurrencyTimeService.formatDateForZone('WIT'),
                  color: AppTheme.warning,
                ),
                _buildClockCard(
                  flag: '🇬🇧',
                  zoneName: 'London (UK)',
                  utcOffset: 'UTC+1 (BST/Diaspora)',
                  time: CurrencyTimeService.formatTimeForZone('London'),
                  date: CurrencyTimeService.formatDateForZone('London'),
                  color: AppTheme.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClockCard({
    required String flag,
    required String zoneName,
    required String utcOffset,
    required String time,
    required String date,
    required Color color,
  }) {
    return CustomCard(
      padding: const EdgeInsets.all(12),
      borderColor: color.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$flag $zoneName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  utcOffset.split(' ').first,
                  style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1.0,
            ),
          ),
          Text(
            date,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
