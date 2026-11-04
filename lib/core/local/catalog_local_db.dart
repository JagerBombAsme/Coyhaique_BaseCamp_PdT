import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Copia local de solo lectura del catálogo turístico (HU-09, HU-10, RNF-04).
///
/// Supabase es la fuente oficial. Esta base nunca se edita registro a
/// registro: se reemplaza completa en una sola transacción cada vez que la
/// descarga termina bien. Si la descarga falla, se conserva la copia
/// anterior. No guarda datos personales (PS-06).
class CatalogLocalDb {
  CatalogLocalDb._();

  static final CatalogLocalDb instance = CatalogLocalDb._();

  static const String _dbName = 'catalogo_local.db';
  static const int _version = 1;

  static const String _lastSyncKey = 'last_sync_at';

  Database? _db;

  Future<Database> get database async {
    final current = _db;
    if (current != null) return current;

    final opened = await openDatabase(
      p.join(await getDatabasesPath(), _dbName),
      version: _version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories (
            id TEXT PRIMARY KEY,
            name_es TEXT NOT NULL,
            group_type TEXT,
            data TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE places (
            id TEXT PRIMARY KEY,
            kind TEXT NOT NULL,
            category_id TEXT NOT NULL,
            name_es TEXT NOT NULL,
            data TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_places_kind ON places(kind)');
        await db.execute(
          'CREATE INDEX idx_places_category ON places(category_id)',
        );
        await db.execute('''
          CREATE TABLE informational_content (
            id TEXT PRIMARY KEY,
            content_type TEXT,
            data TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE sync_meta (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
    );

    _db = opened;
    return opened;
  }

  /// Reemplaza toda la copia local en una sola transacción.
  /// Si algo falla, SQLite revierte la transacción y la copia anterior queda
  /// intacta.
  Future<void> replaceAll({
    required List<Map<String, dynamic>> categories,
    required List<Map<String, dynamic>> places,
    required List<Map<String, dynamic>> informationalContent,
    required DateTime syncedAt,
  }) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete('categories');
      await txn.delete('places');
      await txn.delete('informational_content');

      final batch = txn.batch();

      for (final row in categories) {
        batch.insert('categories', {
          'id': row['id'].toString(),
          'name_es': (row['name_es'] ?? '').toString(),
          'group_type': row['group_type']?.toString(),
          'data': jsonEncode(row),
        });
      }

      for (final row in places) {
        batch.insert('places', {
          'id': row['id'].toString(),
          'kind': (row['kind'] ?? 'place').toString(),
          'category_id': (row['category_id'] ?? '').toString(),
          'name_es': (row['name_es'] ?? '').toString(),
          'data': jsonEncode(row),
        });
      }

      for (final row in informationalContent) {
        batch.insert('informational_content', {
          'id': row['id'].toString(),
          'content_type': row['content_type']?.toString(),
          'data': jsonEncode(row),
        });
      }

      batch.insert(
        'sync_meta',
        {'key': _lastSyncKey, 'value': syncedAt.toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await batch.commit(noResult: true);
    });
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'name_es');
    return rows.map(_decode).toList();
  }

  Future<List<Map<String, dynamic>>> getPlaces({
    String? kind,
    String? categoryId,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <Object>[];

    if (kind != null) {
      where.add('kind = ?');
      args.add(kind);
    }
    if (categoryId != null) {
      where.add('category_id = ?');
      args.add(categoryId);
    }

    final rows = await db.query(
      'places',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'name_es',
    );
    return rows.map(_decode).toList();
  }

  Future<Map<String, dynamic>?> getPlaceById(String id) async {
    final db = await database;
    final rows = await db.query(
      'places',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _decode(rows.first);
  }

  Future<List<Map<String, dynamic>>> getInformationalContent({
    String? contentType,
  }) async {
    final db = await database;
    final rows = await db.query(
      'informational_content',
      where: contentType == null ? null : 'content_type = ?',
      whereArgs: contentType == null ? null : [contentType],
    );
    return rows.map(_decode).toList();
  }

  Future<DateTime?> getLastSyncAt() async {
    final db = await database;
    final rows = await db.query(
      'sync_meta',
      where: 'key = ?',
      whereArgs: [_lastSyncKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first['value']?.toString() ?? '');
  }

  /// Hay copia local cuando existe al menos una descarga completa.
  Future<bool> hasData() async => (await getLastSyncAt()) != null;

  /// Cantidad de registros guardados por tabla (verificación de RNF-04).
  Future<Map<String, int>> counts() async {
    final db = await database;
    Future<int> count(String table) async =>
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $table'),
        ) ??
        0;

    return {
      'categories': await count('categories'),
      'places': await count('places'),
      'informational_content': await count('informational_content'),
    };
  }

  /// Cierra y elimina la base local. Solo para pruebas automatizadas.
  @visibleForTesting
  Future<void> deleteForTesting() async {
    await _db?.close();
    _db = null;
    await deleteDatabase(p.join(await getDatabasesPath(), _dbName));
  }

  Map<String, dynamic> _decode(Map<String, Object?> row) {
    return Map<String, dynamic>.from(
      jsonDecode(row['data'] as String) as Map,
    );
  }
}

/// Se lanza cuando no hay conexión y tampoco existe una copia descargada.
/// Las pantallas la muestran como error con la opción de reintentar
/// (RNF-13), en lugar de mostrar datos de ejemplo.
class CatalogUnavailableException implements Exception {
  const CatalogUnavailableException();

  @override
  String toString() =>
      'No hay conexión ni información descargada. '
      'Conéctate a Internet y vuelve a intentarlo.';
}
