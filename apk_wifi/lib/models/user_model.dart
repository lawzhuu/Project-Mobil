class UserModel {
  final int id;
  final String nama;
  final String email;
  final String noHp;
  final String role; // 'admin', 'pelanggan', 'teknisi'
  final String negara;
  final String mataUang; // 'IDR', 'USD', 'EUR'
  final String zonaWaktu; // 'WIB', 'WITA', 'WIT', 'London'
  final String alamat;
  final double lat;
  final double lng;
  final String foto;
  final String status; // 'pending', 'active'
  final int? paketId;

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.noHp,
    required this.role,
    required this.negara,
    required this.mataUang,
    required this.zonaWaktu,
    required this.alamat,
    required this.lat,
    required this.lng,
    required this.foto,
    required this.status,
    this.paketId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      noHp: json['no_hp'] ?? '',
      role: json['role'] ?? 'pelanggan',
      negara: json['negara'] ?? 'Indonesia',
      mataUang: json['mata_uang'] ?? 'IDR',
      zonaWaktu: json['zona_waktu'] ?? 'WIB',
      alamat: json['alamat'] ?? '',
      lat: (json['lat'] != null) ? double.tryParse(json['lat'].toString()) ?? -7.7956 : -7.7956,
      lng: (json['lng'] != null) ? double.tryParse(json['lng'].toString()) ?? 110.3695 : 110.3695,
      foto: json['foto'] ?? '',
      status: json['status'] ?? 'pending',
      paketId: json['paket_id'] != null ? int.tryParse(json['paket_id'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'no_hp': noHp,
      'role': role,
      'negara': negara,
      'mata_uang': mataUang,
      'zona_waktu': zonaWaktu,
      'alamat': alamat,
      'lat': lat,
      'lng': lng,
      'foto': foto,
      'status': status,
      'paket_id': paketId,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isTeknisi => role == 'teknisi';
  bool get isPelanggan => role == 'pelanggan';
  bool get isActive => status == 'active';
}
