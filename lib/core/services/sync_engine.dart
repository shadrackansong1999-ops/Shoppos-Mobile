import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../db/base_repository.dart';
import '../db/database_helper.dart';
import 'api_client.dart';

class SyncResult {
  final bool ranAtAll;
  final int pushed;
  final int pulled;
  final List<String> errors;
  SyncResult({required this.ranAtAll, required this.pushed, required this.pulled, required this.errors});
  bool get hasErrors => errors.isNotEmpty;
}

/// Drives the whole app's offline-first behaviour:
///   1. Every screen writes to the local SQLite DB first (via a
///      BaseRepository), instantly, whether or not there's a connection.
///   2. Changed rows are flagged is_dirty = 1.
///   3. SyncEngine, whenever it gets a chance (app open, pull-to-refresh,
///      periodic timer), pushes dirty rows to the cloud, then pulls
///      whatever changed remotely (from this device or any other
///      terminal) since the last successful pull.
///
/// This intentionally does NOT try to resolve conflicting edits with a
/// merge UI - it uses last-write-wins on the pull side, and never lets an
/// incoming pull clobber a row with unpushed local edits (see
/// BaseRepository.upsertFromCloud) - the local edit always gets its turn
/// to push first.
class SyncEngine {
  SyncEngine._internal();
  static final SyncEngine instance = SyncEngine._internal();

  bool _running = false;

  Future<bool> get hasConnectivity async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<SyncResult> runFullSync() async {
    if (_running) {
      return SyncResult(ranAtAll: false, pushed: 0, pulled: 0, errors: ['Sync already running']);
    }
    _running = true;
    try {
      if (!await ApiClient.instance.isConfigured) {
        return SyncResult(ranAtAll: false, pushed: 0, pulled: 0, errors: ['Server not configured']);
      }
      if (!await hasConnectivity) {
        return SyncResult(ranAtAll: false, pushed: 0, pulled: 0, errors: ['No network connection']);
      }

      int pushed = 0;
      int pulled = 0;
      final errors = <String>[];

      for (final table in DatabaseHelper.syncableTables) {
        try {
          pushed += await _pushTable(table);
        } catch (e) {
          errors.add('Push $table failed: $e');
        }
      }
      for (final table in DatabaseHelper.syncableTables) {
        try {
          pulled += await _pullTable(table);
        } catch (e) {
          errors.add('Pull $table failed: $e');
        }
      }

      return SyncResult(ranAtAll: true, pushed: pushed, pulled: pulled, errors: errors);
    } finally {
      _running = false;
    }
  }

  Future<int> _pushTable(String table) async {
    final repo = BaseRepository(table);
    final dirty = await repo.dirtyRows();
    if (dirty.isEmpty) return 0;

    final res = await ApiClient.instance.post('/api/sync/push', {
      'table': table,
      'rows': dirty,
    });
    if (!res.ok) {
      throw Exception(res.error ?? 'push rejected');
    }
    await repo.markClean(dirty.map((r) => r['id'] as String).toList());
    return dirty.length;
  }

  Future<int> _pullTable(String table) async {
    final db = await DatabaseHelper.instance.database;
    final cursorRows = await db.query('sync_state', where: 'table_name = ?', whereArgs: [table]);
    final since = cursorRows.isEmpty ? null : cursorRows.first['last_pulled_at'] as String?;

    final res = await ApiClient.instance.get('/api/sync/pull', query: {
      'table': table,
      if (since != null) 'since': since,
    });
    if (!res.ok) {
      throw Exception(res.error ?? 'pull rejected');
    }

    final data = res.data as Map<String, dynamic>;
    final rows = (data['rows'] as List<dynamic>? ?? []);
    final serverTime = data['server_time'] as String?;

    final repo = BaseRepository(table);
    for (final r in rows) {
      await repo.upsertFromCloud(Map<String, dynamic>.from(r as Map));
    }

    if (serverTime != null) {
      await db.insert(
        'sync_state',
        {'table_name': table, 'last_pulled_at': serverTime},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    return rows.length;
  }
}
