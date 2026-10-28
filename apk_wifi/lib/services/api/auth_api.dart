import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/feedback_model.dart';
import '../../models/user_model.dart';
import 'http_client.dart';

class AuthApi {
  final ApiClient _client;
  AuthApi([ApiClient? client]) : _client = client ?? ApiClient.instance;

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final res = await _client.post('/auth/login', body: {
        'username': username,
        'password': password,
      });
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[AuthApi] Login error: $e');
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server backend ($e)',
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String nama,
    required String email,
    required String noHp,
    required String password,
    required String negara,
    required String alamat,
    required double lat,
    required double lng,
    int? paketId,
  }) async {
    try {
      final res = await _client.post('/auth/register', body: {
        'nama': nama,
        'email': email,
        'no_hp': noHp,
        'password': password,
        'negara': negara,
        'alamat': alamat,
        'lat': lat,
        'lng': lng,
        if (paketId != null) 'paket_id': paketId,
      });
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[AuthApi] Register error: $e');
      return {'success': false, 'message': 'Gagal mendaftar: $e'};
    }
  }

  Future<UserModel?> getMe() async {
    try {
      final res = await _client.get('/me');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['user'] != null) {
          return UserModel.fromJson(data['user']);
        }
      }
    } catch (e) {
      debugPrint('[AuthApi] getMe error: $e');
    }
    return null;
  }

  Future<UserModel?> getProfile() => getMe();

  Future<Map<String, dynamic>> updateProfile({
    required String nama,
    required String noHp,
    required String negara,
    required String mataUang,
    required String zonaWaktu,
    required String alamat,
    required double lat,
    required double lng,
  }) async {
    try {
      final res = await _client.put('/me', body: {
        'nama': nama,
        'no_hp': noHp,
        'negara': negara,
        'mata_uang': mataUang,
        'zona_waktu': zonaWaktu,
        'alamat': alamat,
        'lat': lat,
        'lng': lng,
      });
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[AuthApi] updateProfile error: $e');
      return {'success': false, 'message': 'Gagal memperbarui profil: $e'};
    }
  }

  Future<Map<String, dynamic>> uploadProfilePhoto({
    File? file,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    try {
      final url = _client.buildUri('/me/photo');
      final req = http.MultipartRequest('POST', url);

      if (fileBytes != null && fileBytes.isNotEmpty) {
        req.files.add(http.MultipartFile.fromBytes(
          'foto',
          fileBytes,
          filename: fileName ?? 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));
      } else if (file != null && !kIsWeb) {
        req.files.add(await http.MultipartFile.fromPath('foto', file.path));
      } else {
        return {'success': false, 'message': 'Tidak ada berkas foto yang dipilih'};
      }

      final res = await _client.sendMultipart(req);
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[AuthApi] uploadProfilePhoto error: $e');
      return {'success': false, 'message': 'Gagal mengunggah foto profil: $e'};
    }
  }

  Future<Map<String, dynamic>> sendChatMessage(String message) async {
    try {
      final res = await _client.post(
        '/chat',
        body: {'message': message},
        timeout: const Duration(seconds: 15),
      );
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[AuthApi] sendChatMessage error: $e');
      return {
        'success': false,
        'reply': 'Maaf, terjadi kendala saat menghubungi AI Customer Support ($e). Silakan coba lagi.',
      };
    }
  }

  Future<List<FeedbackModel>> getFeedbacks() async {
    try {
      final res = await _client.get('/feedback');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['feedbacks'] is List) {
          return (data['feedbacks'] as List)
              .map((f) => FeedbackModel.fromJson(f))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[AuthApi] getFeedbacks error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> submitFeedback({
    required String saran,
    required String kesan,
  }) async {
    try {
      final res = await _client.post('/feedback', body: {
        'saran': saran,
        'kesan': kesan,
      });
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[AuthApi] submitFeedback error: $e');
      return {'success': false, 'message': 'Gagal mengirim saran & kesan: $e'};
    }
  }
}
