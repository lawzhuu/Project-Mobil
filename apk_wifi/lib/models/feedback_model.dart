import 'package:intl/intl.dart';

class FeedbackModel {
  final int id;
  final int userId;
  final String userNama;
  final String saran;
  final String kesan;
  final String createdAt;

  FeedbackModel({
    required this.id,
    required this.userId,
    this.userNama = 'Pengguna',
    required this.saran,
    required this.kesan,
    required this.createdAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      userNama: json['user_nama'] ?? 'Pengguna',
      saran: json['saran'] ?? '',
      kesan: json['kesan'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_nama': userNama,
      'saran': saran,
      'kesan': kesan,
      'created_at': createdAt,
    };
  }

  String get formattedDate {
    if (createdAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt);
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return createdAt;
    }
  }
}
