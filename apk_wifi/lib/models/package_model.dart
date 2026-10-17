class PackageModel {
  final int id;
  final String nama;
  final int kecepatanMbps;
  final int hargaIdr;
  final String deskripsi;
  final String kategori;

  PackageModel({
    required this.id,
    required this.nama,
    required this.kecepatanMbps,
    required this.hargaIdr,
    required this.deskripsi,
    String? kategori,
  }) : kategori = kategori ?? inferCategory(nama);

  static String inferCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('gamer') || lower.contains('gaming')) {
      return 'Gamer Sakti';
    } else if (lower.contains('turbo')) {
      return 'Turbo Home';
    } else if (lower.contains('promo') || lower.contains('pelajar') || lower.contains('hemat')) {
      return 'Promo Hemat';
    }
    return 'Internet Fiber';
  }

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    final name = json['nama'] ?? '';
    return PackageModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nama: name,
      kecepatanMbps: json['kecepatan_mbps'] is int ? json['kecepatan_mbps'] : int.tryParse(json['kecepatan_mbps'].toString()) ?? 10,
      hargaIdr: json['harga_idr'] is int ? json['harga_idr'] : int.tryParse(json['harga_idr'].toString()) ?? 0,
      deskripsi: json['deskripsi'] ?? '',
      kategori: json['kategori'] ?? inferCategory(name),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'kecepatan_mbps': kecepatanMbps,
      'harga_idr': hargaIdr,
      'deskripsi': deskripsi,
      'kategori': kategori,
    };
  }
}
