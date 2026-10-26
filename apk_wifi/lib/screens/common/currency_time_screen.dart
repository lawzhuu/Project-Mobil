import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/currency_time_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/glowing_button.dart';
import '../customer/customer_invoices_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _recalculate();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
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
        title: const Text('Diaspora Hub & Valuta Global'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // DIASPORA SPONSORSHIP CONTEXT BANNER
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.public, color: AppTheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Diaspora Cross-Border Sponsorship',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Kalkulator biaya paket WiFi keluarga di Indonesia dalam valuta asing (USD/EUR) dengan sinkronisasi jam penagihan resmi.',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // CURRENCY CONVERTER CARD
            CustomCard(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.12),
                  AppTheme.secondary.withValues(alpha: 0.12),
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
                          'Konversi Mata Uang',
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
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceCard,
                          decoration: const InputDecoration(
                            labelText: 'Dari',
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'IDR', child: Text('🇮🇩 IDR', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'USD', child: Text('🇺🇸 USD', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'EUR', child: Text('🇪🇺 EUR', overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _fromCurrency = v);
                              _recalculate();
                            }
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: IconButton(
                          icon: const Icon(Icons.swap_horiz, color: AppTheme.accent),
                          onPressed: _swapCurrencies,
                          tooltip: 'Tukar Mata Uang',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _toCurrency,
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceCard,
                          decoration: const InputDecoration(
                            labelText: 'Ke',
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'IDR', child: Text('🇮🇩 IDR', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'USD', child: Text('🇺🇸 USD', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'EUR', child: Text('🇪🇺 EUR', overflow: TextOverflow.ellipsis)),
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
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Hasil Konversi:',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            CurrencyTimeService.instance.formatCurrency(_convertedResult, _toCurrency),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Kurs Referensi: 1 USD ≈ Rp 15.500 | 1 EUR ≈ Rp 16.800',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
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
                Expanded(
                  child: Text(
                    'Zona Waktu Operasional',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                SizedBox(width: 8),
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
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.15,
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
                  utcOffset: 'UTC+8 (Bali)',
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

            const SizedBox(height: 24),

            // DIRECT ACTION BUTTON TO INVOICES
            GlowingButton(
              text: 'LIHAT TAGIHAN & PEMBAYARAN SPONSOR',
              icon: Icons.receipt_long,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CustomerInvoicesScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(10),
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$flag $zoneName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  utcOffset.split(' ').first,
                  style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Text(
            date,
            style: const TextStyle(fontSize: 9.5, color: AppTheme.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
