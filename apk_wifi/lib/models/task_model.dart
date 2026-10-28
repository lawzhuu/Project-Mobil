class TaskModel {
  final int id;
  final int? teknisiId;
  final int pelangganId;
  final String jenis; // 'instalasi', 'perbaikan'
  final String status; // 'baru', 'dikerjakan', 'selesai'
  final String catatan;
  final String pelangganNama;
  final String pelangganAlamat;
  final String pelangganNoHp;
  final double pelangganLat;
  final double pelangganLng;
  final String? teknisiNama;
  final bool isMyTask;

  TaskModel({
    required this.id,
    this.teknisiId,
    required this.pelangganId,
    required this.jenis,
    required this.status,
    required this.catatan,
    this.pelangganNama = 'Pelanggan',
    this.pelangganAlamat = '',
    this.pelangganNoHp = '',
    this.pelangganLat = -7.7956,
    this.pelangganLng = 110.3695,
    this.teknisiNama,
    this.isMyTask = false,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      teknisiId: json['teknisi_id'] != null
          ? (json['teknisi_id'] is int
              ? json['teknisi_id']
              : int.tryParse(json['teknisi_id'].toString()))
          : null,
      pelangganId: json['pelanggan_id'] is int ? json['pelanggan_id'] : int.tryParse(json['pelanggan_id'].toString()) ?? 0,
      jenis: json['jenis'] ?? 'instalasi',
      status: json['status'] ?? 'baru',
      catatan: json['catatan'] ?? '',
      pelangganNama: json['pelanggan_nama'] ?? 'Pelanggan',
      pelangganAlamat: json['pelanggan_alamat'] ?? '',
      pelangganNoHp: json['pelanggan_no_hp'] ?? '',
      pelangganLat: (json['pelanggan_lat'] != null)
          ? double.tryParse(json['pelanggan_lat'].toString()) ?? -7.7956
          : -7.7956,
      pelangganLng: (json['pelanggan_lng'] != null)
          ? double.tryParse(json['pelanggan_lng'].toString()) ?? 110.3695
          : 110.3695,
      teknisiNama: json['teknisi_nama'],
      isMyTask: json['is_my_task'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teknisi_id': teknisiId,
      'pelanggan_id': pelangganId,
      'jenis': jenis,
      'status': status,
      'catatan': catatan,
      'pelanggan_nama': pelangganNama,
      'pelanggan_alamat': pelangganAlamat,
      'pelanggan_no_hp': pelangganNoHp,
      'pelanggan_lat': pelangganLat,
      'pelanggan_lng': pelangganLng,
      'teknisi_nama': teknisiNama,
      'is_my_task': isMyTask,
    };
  }

  bool get isNew => status == 'baru';
  bool get isInProgress => status == 'dikerjakan';
  bool get isDone => status == 'selesai';
  bool get isAvailable => teknisiId == null || teknisiId == 0;
  bool get isTakenByOther => !isAvailable && !isMyTask;
  bool get isPencopotan => jenis == 'pencopotan' || catatan.toLowerCase().contains('pencopotan');

  String get displayJenis {
    if (isPencopotan) return 'Pencopotan Perangkat';
    if (jenis == 'instalasi') return 'Instalasi & Pasang Baru';
    if (jenis == 'perbaikan') return 'Perbaikan Gangguan';
    return 'Pemeliharaan Jaringan';
  }
}
