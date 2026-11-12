import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/invoice_model.dart';
import '../models/package_model.dart';
import '../models/task_model.dart';

// ==============================================================================
// PANDUAN PEMULA: DATABASE LOKAL SQLITE (OFFLINE-FIRST ARCHITECTURE)
// ==============================================================================
// File ini mengelola database relasional SQLite bawaan perangkat (menggunakan package `sqflite`).
//
// KONSEP UTAMA ARSITEKTUR OFFLINE-FIRST:
// 1. Single Source of Truth Online : Supabase PostgreSQL (via Node.js Backend API).
// 2. High-Performance Local Cache   : SQLite Lokal di HP (`simanet_offline.db`).
//
// ALUR DATA:
// - SAAT ONLINE (Network Available):
//   Aplikasi fetch data terbaru dari REST API -> disimpan / di-upsert ke tabel SQLite -> ditampilkan ke UI.
// - SAAT OFFLINE (Airplane Mode / Tidak Ada Sinyal):
//   Aplikasi langsung membaca dari SQLite lokal, sehingga user tetap bisa melihat tagihan, paket, dan tugas.
// - SAAT MUTASI (Bayar / Ganti Status / Approve):
//   Kirim ke API -> saat sukses, SQLite lokal seketika di-update (Instant Consistency) tanpa perlu spam refresh!
// ==============================================================================

class LocalDbService {
  static final LocalDbService instance = LocalDbService._internal();
  LocalDbService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Inisialisasi FFI jika dijalankan di platform Desktop (Windows / Linux / macOS)
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dbPath;
    if (kIsWeb) {
      dbPath = 'simanet_offline.db';
    } else {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      dbPath = join(documentsDirectory.path, 'simanet_offline.db');
    }

    return await openDatabase(
      dbPath,
      version: 2,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onOpen: (db) async {
        // Memastikan tabel relasional terbuat meskipun database sudah ada versi lamanya
        await _createTables(db);
      },
    );
  }

  /// Membuat skema tabel-tabel relasional SQLite lokal
  Future<void> _createTables(Database db) async {
    // 1. Tabel Cache Generic (Key-Value)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cache_entries (
        key TEXT PRIMARY KEY,
        json_content TEXT,
        updated_at TEXT
      )
    ''');

    // 2. Tabel Relasional Tagihan Pelanggan (Invoices)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_invoices (
        id INTEGER PRIMARY KEY,
        user_id INTEGER,
        periode TEXT,
        nominal_idr INTEGER,
        diskon_idr INTEGER,
        voucher_code TEXT,
        mata_uang TEXT,
        kurs_terkunci REAL,
        jatuh_tempo TEXT,
        status TEXT,
        pelanggan_nama TEXT,
        pelanggan_email TEXT,
        paket_nama TEXT,
        raw_json TEXT,
        updated_at TEXT
      )
    ''');

    // 3. Tabel Relasional Katalog Paket WiFi (Packages)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_packages (
        id INTEGER PRIMARY KEY,
        nama TEXT,
        kecepatan_mbps INTEGER,
        harga_idr INTEGER,
        deskripsi TEXT,
        kategori TEXT,
        updated_at TEXT
      )
    ''');

    // 4. Tabel Relasional Tugas Teknisi (Tasks)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_tasks (
        id INTEGER PRIMARY KEY,
        teknisi_id INTEGER,
        pelanggan_id INTEGER,
        jenis TEXT,
        status TEXT,
        catatan TEXT,
        pelanggan_nama TEXT,
        pelanggan_alamat TEXT,
        pelanggan_no_hp TEXT,
        pelanggan_lat REAL,
        pelanggan_lng REAL,
        teknisi_nama TEXT,
        is_my_task INTEGER,
        updated_at TEXT
      )
    ''');
  }

  // ============================================================================
  // OPERASI SQLITE: INVOICES (TAGIHAN)
  // ============================================================================

  /// Menyinkronkan daftar tagihan dari API online ke SQLite lokal secara batch (Upsert)
  Future<void> syncInvoices(List<InvoiceModel> invoices) async {
    try {
      final db = await database;
      final batch = db.batch();
      final now = DateTime.now().toIso8601String();

      for (final inv in invoices) {
        batch.insert(
          'local_invoices',
          {
            'id': inv.id,
            'user_id': inv.userId,
            'periode': inv.periode,
            'nominal_idr': inv.nominalIdr,
            'diskon_idr': inv.diskonIdr,
            'voucher_code': inv.voucherCode,
            'mata_uang': inv.mataUang,
            'kurs_terkunci': inv.kursTerkunci,
            'jatuh_tempo': inv.jatuhTempo,
            'status': inv.status,
            'pelanggan_nama': inv.pelangganNama,
            'pelanggan_email': inv.pelangganEmail,
            'paket_nama': inv.paketNama,
            'raw_json': jsonEncode(inv.toJson()),
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      debugPrint('[LocalDb SQLite] Synchronized ${invoices.length} invoices to local database.');
    } catch (e) {
      debugPrint('[LocalDb SQLite] Error syncing invoices: $e');
    }
  }

  /// Membaca tagihan langsung dari database SQLite lokal (Digunakan saat offline)
  Future<List<InvoiceModel>> getLocalInvoices({int? userId}) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'local_invoices',
        where: userId != null ? 'user_id = ?' : null,
        whereArgs: userId != null ? [userId] : null,
        orderBy: 'id DESC',
      );

      return maps.map((row) {
        if (row['raw_json'] != null) {
          try {
            final parsed = jsonDecode(row['raw_json'] as String);
            return InvoiceModel.fromJson(parsed);
          } catch (_) {}
        }
        return InvoiceModel.fromJson(row);
      }).toList();
    } catch (e) {
      debugPrint('[LocalDb SQLite] Error reading local invoices: $e');
      return [];
    }
  }

  /// Memperbarui status pembayaran invoice secara instan di SQLite lokal (Write-Through)
  Future<void> updateLocalInvoiceStatus(int invoiceId, String status) async {
    try {
      final db = await database;
      await db.update(
        'local_invoices',
        {
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [invoiceId],
      );
      debugPrint('[LocalDb SQLite] Invoice #$invoiceId status updated to "$status" locally.');
    } catch (e) {
      debugPrint('[LocalDb SQLite] Error updating local invoice #$invoiceId: $e');
    }
  }

  // ============================================================================
  // OPERASI SQLITE: PACKAGES (KATALOG PAKET)
  // ============================================================================

  /// Menyinkronkan daftar paket dari API online ke SQLite lokal
  Future<void> syncPackages(List<PackageModel> packages) async {
    try {
      final db = await database;
      final batch = db.batch();
      final now = DateTime.now().toIso8601String();

      for (final pkg in packages) {
        batch.insert(
          'local_packages',
          {
            'id': pkg.id,
            'nama': pkg.nama,
            'kecepatan_mbps': pkg.kecepatanMbps,
            'harga_idr': pkg.hargaIdr,
            'deskripsi': pkg.deskripsi,
            'kategori': pkg.kategori,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      debugPrint('[LocalDb SQLite] Synchronized ${packages.length} packages to local database.');
    } catch (e) {
      debugPrint('[LocalDb SQLite] Error syncing packages: $e');
    }
  }

  /// Membaca katalog paket dari SQLite lokal saat offline
  Future<List<PackageModel>> getLocalPackages() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'local_packages',
        orderBy: 'id ASC',
      );
      if (maps.isNotEmpty) {
        return maps.map((row) => PackageModel.fromJson(row)).toList();
      }
    } catch (e) {
      debugPrint('[LocalDb SQLite] Error reading local packages: $e');
    }
    return [];
  }

  // ============================================================================
  // OPERASI SQLITE: TASKS (PENUGASAN TEKNISI)
  // ============================================================================

  /// Menyinkronkan daftar tugas teknisi dari API online ke SQLite lokal
  Future<void> syncTasks(List<TaskModel> tasks, {bool isMyTasks = false}) async {
    try {
      final db = await database;
      final batch = db.batch();
      final now = DateTime.now().toIso8601String();

      for (final t in tasks) {
        batch.insert(
          'local_tasks',
          {
            'id': t.id,
            'teknisi_id': t.teknisiId,
            'pelanggan_id': t.pelangganId,
            'jenis': t.jenis,
            'status': t.status,
            'catatan': t.catatan,
            'pelanggan_nama': t.pelangganNama,
            'pelanggan_alamat': t.pelangganAlamat,
            'pelanggan_no_hp': t.pelangganNoHp,
            'pelanggan_lat': t.pelangganLat,
            'pelanggan_lng': t.pelangganLng,
            'teknisi_nama': t.teknisiNama,
            'is_my_task': (t.isMyTask || isMyTasks) ? 1 : 0,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      debugPrint('[LocalDb SQLite] Synchronized ${tasks.length} tasks to local database.');
    } catch (e) {
      debugPrint('[LocalDb SQLite] Error syncing tasks: $e');
    }
  }

  /// Membaca tugas teknisi dari SQLite lokal saat offline
  Future<List<TaskModel>> getLocalTasks({bool myTasksOnly = false, int? teknisiId}) async {
    try {
      final db = await database;
      String? where;
      List<dynamic>? whereArgs;

      if (myTasksOnly) {
        where = 'is_my_task = 1';
      } else if (teknisiId != null) {
        where = 'teknisi_id = ?';
        whereArgs = [teknisiId];
      }

      final List<Map<String, dynamic>> maps = await db.query(
        'local_tasks',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'id DESC',
      );

      return maps.map((row) => TaskModel.fromJson(row)).toList();
    } catch (e) {
      debugPrint('[LocalDb SQLite] Error reading local tasks: $e');
      return [];
    }
  }

  /// Memperbarui status tugas teknisi secara instan di SQLite lokal
  Future<void> updateLocalTaskStatus(int taskId, String status, {int? teknisiId}) async {
    try {
      final db = await database;
      final Map<String, dynamic> values = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (teknisiId != null) {
        values['teknisi_id'] = teknisiId;
      }

      await db.update(
        'local_tasks',
        values,
        where: 'id = ?',
        whereArgs: [taskId],
      );
      debugPrint('[LocalDb SQLite] Task #$taskId status updated to "$status" locally.');
    } catch (e) {
      debugPrint('[LocalDb SQLite] Error updating local task #$taskId: $e');
    }
  }

  // ============================================================================
  // OPERASI SQLITE: CACHE GENERIC (KEY-VALUE)
  // ============================================================================

  Future<void> saveCache(String key, dynamic data) async {
    try {
      final db = await database;
      final jsonStr = jsonEncode(data);
      await db.insert(
        'cache_entries',
        {
          'key': key,
          'json_content': jsonStr,
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('[LocalDb] Error saving cache for $key: $e');
    }
  }

  Future<dynamic> getCache(String key) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'cache_entries',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (maps.isNotEmpty && maps.first['json_content'] != null) {
        return jsonDecode(maps.first['json_content'] as String);
      }
    } catch (e) {
      debugPrint('[LocalDb] Error reading cache for $key: $e');
    }
    return null;
  }

  Future<void> clearCache() async {
    try {
      final db = await database;
      await db.delete('cache_entries');
      await db.delete('local_invoices');
      await db.delete('local_packages');
      await db.delete('local_tasks');
    } catch (e) {
      debugPrint('[LocalDb] Error clearing cache: $e');
    }
  }
}
