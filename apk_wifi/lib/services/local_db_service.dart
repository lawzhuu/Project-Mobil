import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
    // If running on desktop (Windows, Linux, macOS), initialize FFI
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
      version: 1,
      onCreate: (db, version) async {
        // Table for key-value offline caching (invoices, packages, rates, tasks, reports)
        await db.execute('''
          CREATE TABLE cache_entries (
            key TEXT PRIMARY KEY,
            json_content TEXT,
            updated_at TEXT
          )
        ''');
      },
    );
  }

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
    } catch (e) {
      debugPrint('[LocalDb] Error clearing cache: $e');
    }
  }
}
