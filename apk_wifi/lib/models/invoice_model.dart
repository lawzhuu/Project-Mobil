import 'package:intl/intl.dart';
import 'payment_model.dart';

class InvoiceModel {
  final int id;
  final int userId;
  final String periode;
  final int nominalIdr;
  final int diskonIdr;
  final String? voucherCode;
  final String mataUang;
  final double kursTerkunci;
  final String jatuhTempo; // ISO String
  final String status; // 'belum', 'lunas'
  final String? pelangganNama;
  final String? pelangganEmail;
  final String? paketNama;
  final PaymentModel? payment;

  InvoiceModel({
    required this.id,
    required this.userId,
    required this.periode,
    required this.nominalIdr,
    this.diskonIdr = 0,
    this.voucherCode,
    required this.mataUang,
    required this.kursTerkunci,
    required this.jatuhTempo,
    required this.status,
    this.pelangganNama,
    this.pelangganEmail,
    this.paketNama,
    this.payment,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      periode: json['periode'] ?? '',
      nominalIdr: json['nominal_idr'] is int ? json['nominal_idr'] : int.tryParse(json['nominal_idr'].toString()) ?? 0,
      diskonIdr: json['diskon_idr'] is int ? json['diskon_idr'] : int.tryParse(json['diskon_idr']?.toString() ?? '0') ?? 0,
      voucherCode: json['voucher_code'],
      mataUang: json['mata_uang'] ?? 'IDR',
      kursTerkunci: (json['kurs_terkunci'] != null)
          ? double.tryParse(json['kurs_terkunci'].toString()) ?? 1.0
          : 1.0,
      jatuhTempo: json['jatuh_tempo'] ?? '',
      status: json['status'] ?? 'belum',
      pelangganNama: json['pelanggan_nama'],
      pelangganEmail: json['pelanggan_email'],
      paketNama: json['paket_nama'],
      payment: json['payment'] != null ? PaymentModel.fromJson(json['payment']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'periode': periode,
      'nominal_idr': nominalIdr,
      'diskon_idr': diskonIdr,
      'voucher_code': voucherCode,
      'mata_uang': mataUang,
      'kurs_terkunci': kursTerkunci,
      'jatuh_tempo': jatuhTempo,
      'status': status,
      'pelanggan_nama': pelangganNama,
      'pelanggan_email': pelangganEmail,
      'paket_nama': paketNama,
      'payment': payment?.toJson(),
    };
  }

  bool get isPaid => status == 'lunas';

  // Check if invoice has discount from game or promo
  bool get hasDiscount => diskonIdr > 0;

  // Net payable IDR after discount
  int get totalBayarIdr => (nominalIdr - diskonIdr).clamp(0, double.infinity).toInt();

  // Amount in customer's local currency based on locked exchange rate (gross)
  double get nominalInCurrency {
    if (mataUang == 'IDR' || kursTerkunci <= 1.0) {
      return nominalIdr.toDouble();
    }
    return nominalIdr / kursTerkunci;
  }

  // Net amount in customer's local currency (after discount)
  double get totalInCurrency {
    if (mataUang == 'IDR' || kursTerkunci <= 1.0) {
      return totalBayarIdr.toDouble();
    }
    return totalBayarIdr / kursTerkunci;
  }

  // Format currency with symbol (net payable)
  String get formattedAmount {
    final amountToFormat = hasDiscount ? totalInCurrency : nominalInCurrency;
    if (mataUang == 'USD') {
      return NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2)
          .format(amountToFormat);
    } else if (mataUang == 'EUR') {
      return NumberFormat.currency(locale: 'de_DE', symbol: '€', decimalDigits: 2)
          .format(amountToFormat);
    } else {
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
          .format(hasDiscount ? totalBayarIdr : nominalIdr);
    }
  }

  // Original gross amount formatted
  String get formattedOriginalAmount {
    if (mataUang == 'USD') {
      return NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2)
          .format(nominalInCurrency);
    } else if (mataUang == 'EUR') {
      return NumberFormat.currency(locale: 'de_DE', symbol: '€', decimalDigits: 2)
          .format(nominalInCurrency);
    } else {
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
          .format(nominalIdr);
    }
  }

  // Format IDR base amount (net payable)
  String get formattedAmountIdr {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(totalBayarIdr);
  }

  // Format discount in IDR
  String get formattedDiscountIdr {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(diskonIdr);
  }

  // Formatted due date string converted to timezone
  String formattedDueDate(String targetTimezone) {
    if (jatuhTempo.isEmpty) return '-';
    try {
      DateTime dt = DateTime.parse(jatuhTempo).toUtc();
      Duration offset = const Duration(hours: 7); // Default WIB (UTC+7)
      if (targetTimezone == 'WITA') offset = const Duration(hours: 8);
      if (targetTimezone == 'WIT') offset = const Duration(hours: 9);
      if (targetTimezone == 'London') offset = const Duration(hours: 1); // BST/GMT (UTC+1)

      DateTime converted = dt.add(offset);
      return DateFormat('dd MMM yyyy, HH:mm').format(converted) + ' ' + targetTimezone;
    } catch (_) {
      return jatuhTempo;
    }
  }
}
