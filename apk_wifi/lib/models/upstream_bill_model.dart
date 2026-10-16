import 'package:intl/intl.dart';

class UpstreamBillModel {
  final int id;
  final String periode;
  final int nominalIdr;
  final String providerName;
  final String status; // 'belum', 'lunas'

  UpstreamBillModel({
    required this.id,
    required this.periode,
    required this.nominalIdr,
    this.providerName = 'Indibizz Dedicated',
    this.status = 'belum',
  });

  factory UpstreamBillModel.fromJson(Map<String, dynamic> json) {
    return UpstreamBillModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      periode: json['periode'] ?? '',
      nominalIdr: json['nominal_idr'] is int ? json['nominal_idr'] : int.tryParse(json['nominal_idr'].toString()) ?? 0,
      providerName: json['provider_name'] ?? 'Indibizz Dedicated',
      status: json['status'] ?? 'belum',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'periode': periode,
      'nominal_idr': nominalIdr,
      'provider_name': providerName,
      'status': status,
    };
  }

  String get formattedAmount {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(nominalIdr);
  }
}
