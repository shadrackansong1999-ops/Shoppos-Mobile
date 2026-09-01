import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'database_helper.dart';

const _uuid = Uuid();

/// Common CRUD plumbing shared by every entity repository. Works on plain
/// Map<String,dynamic> rows so each repository stays a thin, readable
/// wrapper instead of fighting generic type inference.
///
/// Every write here marks the row is_dirty=1 and stamps updated_at, which
/// is exactly what SyncEngine looks for when it pushes local changes up
/// to the cloud.
class BaseRepository {
  BaseRepository(this.table);
  final String table;

  Future<Database> get _db async => DatabaseHelper.instance.database;

  String newId() => _uuid.v4();

  String nowIso() => DateTime.now().toUtc().toIso8601String();

  Future<List<Map<String, dynamic>>> getAll({
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    bool includeDeleted = false,
  }) async {
    final db = await _db;
    final clauses = <String>[];
    final args = <Object?>[];
    if (!includeDeleted) clauses.add('is_deleted = 0');
    if (where != null) {
      clauses.add(where);
      if (whereArgs != null) args.addAll(whereArgs);
    }
    return db.query(
      table,
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: orderBy,
    );
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final db = await _db;
    final rows = await db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  /// Inserts a new row. `data` should NOT include id/created_at/updated_at/
  /// is_dirty/is_deleted - those are stamped here.
  Future<String> insert(Map<String, dynamic> data, {bool hasCreatedAt = true}) async {
    final db = await _db;
    final id = newId();
    final now = nowIso();
    final row = {
      ...data,
      'id': id,
      if (hasCreatedAt) 'created_at': now,
      'updated_at': now,
      'is_dirty': 1,
      'is_deleted': 0,
    };
    await db.insert(table, row);
    return id;
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final db = await _db;
    final row = {
      ...data,
      'updated_at': nowIso(),
      'is_dirty': 1,
    };
    await db.update(table, row, where: 'id = ?', whereArgs: [id]);
  }

  /// Soft delete - keeps the row as a tombstone so the deletion syncs to
  /// the cloud and other devices instead of just vanishing locally.
  Future<void> softDelete(String id) async {
    final db = await _db;
    await db.update(
      table,
      {'is_deleted': 1, 'updated_at': nowIso(), 'is_dirty': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> dirtyRows() async {
    final db = await _db;
    return db.query(table, where: 'is_dirty = 1');
  }

  Future<void> markClean(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await _db;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.rawUpdate(
      'UPDATE $table SET is_dirty = 0 WHERE id IN ($placeholders)',
      ids,
    );
  }

  /// Applies a row pulled from the cloud. Cloud always wins for rows the
  /// device hasn't touched locally (is_dirty = 0); a row with unpushed
  /// local edits is left alone so the next push doesn't clobber it - it
  /// will reconcile once that push completes.
  Future<void> upsertFromCloud(Map<String, dynamic> row) async {
    final db = await _db;
    final existing = await getById(row['id'] as String);
    if (existing != null && (existing['is_dirty'] as int) == 1) {
      return; // local edit pending - don't overwrite, let push settle it first
    }
    await db.insert(table, {...row, 'is_dirty': 0}, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
