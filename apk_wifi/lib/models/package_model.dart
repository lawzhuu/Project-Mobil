class PackageModel {
  final int id;
  final String nama;
  final int kecepatanMbps;
  final int hargaIdr;
  final String deskripsi;

  PackageModel({
    required this.id,
    required this.nama,
    required this.kecepatanMbps,
    required this.hargaIdr,
    required this.deskripsi,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nama: json['nama'] ?? '',
      kecepatanMbps: json['kecepatan_mbps'] is int ? json['kecepatan_mbps'] : int.tryParse(json['kecepatan_mbps'].toString()) ?? 10,
      hargaIdr: json['harga_idr'] is int ? json['harga_idr'] : int.tryParse(json['harga_idr'].toString()) ?? 0,
      deskripsi: json['deskripsi'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'kecepatan_mbps': kecepatanMbps,
      'harga_idr': hargaIdr,
      'deskripsi': deskripsi,
    };
  }
}
