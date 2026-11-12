import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../local_db_service.dart';
import 'http_client.dart';

class TaskApi {
  final ApiClient _client;
  TaskApi([ApiClient? client]) : _client = client ?? ApiClient.instance;

  Future<List<TaskModel>> getTasks({bool myTasks = false}) async {
    final cacheKey = myTasks ? 'my_tasks' : 'tasks';
    try {
      final endpoint = myTasks ? '/tasks?my_tasks=true' : '/tasks';
      final res = await _client.get(endpoint, timeout: const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['tasks'] is List) {
          final list = (data['tasks'] as List)
              .map((t) => TaskModel.fromJson(t))
              .toList();
          // Simpan ke SQLite lokal (Offline-First)
          await LocalDbService.instance.syncTasks(list, isMyTasks: myTasks);
          await LocalDbService.instance.saveCache(cacheKey, data['tasks']);
          return list;
        }
      }
    } catch (e) {
      debugPrint('[TaskApi] getTasks error: $e. Loading from local SQLite database...');
    }

    // Fallback Offline: Membaca langsung dari tabel SQLite lokal
    final localTasks = await LocalDbService.instance.getLocalTasks(myTasksOnly: myTasks);
    if (localTasks.isNotEmpty) {
      debugPrint('[TaskApi] Serving ${localTasks.length} tasks from local SQLite.');
      return localTasks;
    }

    final cached = await LocalDbService.instance.getCache(cacheKey);
    if (cached is List) {
      return cached.map((t) => TaskModel.fromJson(t)).toList();
    }
    return [];
  }

  Future<List<UserModel>> getTechnicians() async {
    try {
      final res = await _client.get('/technicians', timeout: const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['technicians'] is List) {
          return (data['technicians'] as List)
              .map((u) => UserModel.fromJson(u))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[TaskApi] getTechnicians error: $e');
    }
    return [];
  }

  Future<bool> claimTask(int taskId) async {
    try {
      final res = await _client.post('/tasks/$taskId/claim', timeout: const Duration(seconds: 6));
      if (res.statusCode == 200) {
        // Write-through update ke SQLite lokal seketika
        await LocalDbService.instance.updateLocalTaskStatus(taskId, 'dikerjakan');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[TaskApi] claimTask error: $e');
      return false;
    }
  }

  Future<bool> createTask({
    int? teknisiId,
    required int pelangganId,
    required String jenis,
    required String catatan,
  }) async {
    try {
      final res = await _client.post('/tasks', body: {
        // PANDUAN PEMULA: Collection-if memastikan 'teknisi_id' hanya dikirim ke backend jika bernilai tidak null.
        // ignore: use_null_aware_elements
        if (teknisiId != null) 'teknisi_id': teknisiId,
        'pelanggan_id': pelangganId,
        'jenis': jenis,
        'catatan': catatan,
      });
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('[TaskApi] createTask error: $e');
      return false;
    }
  }

  Future<bool> assignTaskTechnician(int taskId, int teknisiId) async {
    return updateTaskStatus(taskId, 'dikerjakan', teknisiId: teknisiId);
  }

  Future<bool> updateTaskStatus(int taskId, String status, {int? teknisiId}) async {
    try {
      final Map<String, dynamic> body = {'status': status};
      if (teknisiId != null) {
        body['teknisi_id'] = teknisiId;
      }
      final res = await _client.patch('/tasks/$taskId', body: body);
      if (res.statusCode == 200) {
        // Write-through update ke SQLite lokal seketika
        await LocalDbService.instance.updateLocalTaskStatus(taskId, status, teknisiId: teknisiId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[TaskApi] updateTaskStatus error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> reportTrouble({
    required String kategori,
    required String deskripsi,
    String? noKontak,
  }) async {
    try {
      final res = await _client.post('/customer/report-trouble', body: {
        'kategori': kategori,
        'deskripsi': deskripsi,
        'no_kontak': noKontak,
      });
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[TaskApi] reportTrouble error: $e');
      return {'success': false, 'message': 'Gagal mengirim laporan gangguan: $e'};
    }
  }
}
