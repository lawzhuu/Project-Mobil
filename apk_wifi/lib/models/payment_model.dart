class PaymentModel {
  final int id;
  final int invoiceId;
  final int userId;
  final String buktiPath;
  final int nominalIdr;
  final String status; // 'menunggu', 'diverifikasi', 'ditolak'
  final String? verifiedAt;

  PaymentModel({
    required this.id,
    required this.invoiceId,
    required this.userId,
    required this.buktiPath,
    required this.nominalIdr,
    required this.status,
    this.verifiedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      invoiceId: json['invoice_id'] is int ? json['invoice_id'] : int.tryParse(json['invoice_id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      buktiPath: json['bukti_path'] ?? '',
      nominalIdr: json['nominal_idr'] is int ? json['nominal_idr'] : int.tryParse(json['nominal_idr'].toString()) ?? 0,
      status: json['status'] ?? 'menunggu',
      verifiedAt: json['verified_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'user_id': userId,
      'bukti_path': buktiPath,
      'nominal_idr': nominalIdr,
      'status': status,
      'verified_at': verifiedAt,
    };
  }

  bool get isVerified => status == 'diverifikasi';
  bool get isPending => status == 'menunggu';
  bool get isRejected => status == 'ditolak';
}
