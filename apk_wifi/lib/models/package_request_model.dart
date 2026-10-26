class PackageRequestModel {
  final int id;
  final int userId;
  final String userNama;
  final String userEmail;
  final String userAlamat;
  final String userNoHp;
  final int? paketLamaId;
  final String paketLamaNama;
  final int paketLamaKecepatan;
  final int paketLamaHarga;
  final int paketBaruId;
  final String paketBaruNama;
  final int paketBaruKecepatan;
  final int paketBaruHarga;
  final int selisihHarga;
  final String tipe;
  final String alasan;
  final String status; // 'pending', 'approved', 'rejected'
  final String adminCatatan;
  final String createdAt;
  final String updatedAt;

  PackageRequestModel({
    required this.id,
    required this.userId,
    required this.userNama,
    this.userEmail = '',
    this.userAlamat = '',
    this.userNoHp = '',
    this.paketLamaId,
    required this.paketLamaNama,
    required this.paketLamaKecepatan,
    required this.paketLamaHarga,
    required this.paketBaruId,
    required this.paketBaruNama,
    required this.paketBaruKecepatan,
    required this.paketBaruHarga,
    required this.selisihHarga,
    required this.tipe,
    required this.alasan,
    required this.status,
    this.adminCatatan = '',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isTermination =>
      tipe.toLowerCase().contains('berhenti') ||
      tipe.toLowerCase().contains('putus') ||
      tipe.toLowerCase().contains('stop');

  factory PackageRequestModel.fromJson(Map<String, dynamic> json) {
    return PackageRequestModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      userNama: json['user_nama'] ?? 'Pelanggan',
      userEmail: json['user_email'] ?? '',
      userAlamat: json['user_alamat'] ?? '',
      userNoHp: json['user_no_hp'] ?? '',
      paketLamaId: json['paket_lama_id'] is int ? json['paket_lama_id'] : int.tryParse(json['paket_lama_id']?.toString() ?? ''),
      paketLamaNama: json['paket_lama_nama'] ?? 'Belum Ada',
      paketLamaKecepatan: json['paket_lama_kecepatan'] is int ? json['paket_lama_kecepatan'] : int.tryParse(json['paket_lama_kecepatan']?.toString() ?? '0') ?? 0,
      paketLamaHarga: json['paket_lama_harga'] is int ? json['paket_lama_harga'] : int.tryParse(json['paket_lama_harga']?.toString() ?? '0') ?? 0,
      paketBaruId: json['paket_baru_id'] != null
          ? (json['paket_baru_id'] is int
              ? json['paket_baru_id']
              : int.tryParse(json['paket_baru_id'].toString()) ?? 0)
          : 0,
      paketBaruNama: json['paket_baru_nama'] ?? '',
      paketBaruKecepatan: json['paket_baru_kecepatan'] is int ? json['paket_baru_kecepatan'] : int.tryParse(json['paket_baru_kecepatan']?.toString() ?? '0') ?? 0,
      paketBaruHarga: json['paket_baru_harga'] is int ? json['paket_baru_harga'] : int.tryParse(json['paket_baru_harga']?.toString() ?? '0') ?? 0,
      selisihHarga: json['selisih_harga'] is int ? json['selisih_harga'] : int.tryParse(json['selisih_harga']?.toString() ?? '0') ?? 0,
      tipe: json['tipe'] ?? 'Upgrade Kecepatan',
      alasan: json['alasan'] ?? '',
      status: json['status'] ?? 'pending',
      adminCatatan: json['admin_catatan'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_nama': userNama,
      'user_email': userEmail,
      'user_alamat': userAlamat,
      'user_no_hp': userNoHp,
      'paket_lama_id': paketLamaId,
      'paket_lama_nama': paketLamaNama,
      'paket_lama_kecepatan': paketLamaKecepatan,
      'paket_lama_harga': paketLamaHarga,
      'paket_baru_id': paketBaruId,
      'paket_baru_nama': paketBaruNama,
      'paket_baru_kecepatan': paketBaruKecepatan,
      'paket_baru_harga': paketBaruHarga,
      'selisih_harga': selisihHarga,
      'tipe': tipe,
      'alasan': alasan,
      'status': status,
      'admin_catatan': adminCatatan,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
