import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';

import 'chatter_seed.dart';
import 'db.dart';
import 'history_models.dart';

String historyDedupeKey(String targetLang, String src) {
  final digest = sha1.convert(utf8.encode('$targetLang\n$src'));
  return digest.toString();
}

class HistoryRepository {
  HistoryRepository(this._db);

  static const maxRows = 1000;

  final Database _db;

  static Future<HistoryRepository> open({Database? database}) async {
    final db = database ?? await openRelayDatabase();
    return HistoryRepository(db);
  }

  Future<void> logTranslation({
    required String src,
    required String tr,
    required String srcLang,
    required String targetLang,
    required int? ms,
    String appPackage = kChatterPackage,
    String appLabel = kChatterLabel,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final key = historyDedupeKey(targetLang, src);
    final values = {
      'tr': tr,
      'src_lang': srcLang,
      'app_package': appPackage,
      'app_label': appLabel,
      'engine': 'mlkit',
      'ms': ms,
      'created_at': now,
    };
    await _db.transaction((txn) async {
      // Update-then-insert, not REPLACE: a re-translation must keep the tester's flag + note (Phase 10).
      // (No ON CONFLICT DO UPDATE: Android 8's SQLite predates it.)
      final updated = await txn.update('history', values, where: 'dedupe_key = ?', whereArgs: [key]);
      if (updated == 0) {
        await txn.insert('history', {
          ...values,
          'dedupe_key': key,
          'src': src,
          'target_lang': targetLang,
          'flagged': 0,
          'note': null,
        });
      }
      await _trimToMaxRows(txn);
    });
  }

  /// Beta 👎: flag (or unflag) one translation. Inserts the row when it isn't there yet — over another app
  /// the sheet can open before the buffered history row lands; [logTranslation] then keeps the flag.
  Future<void> setFlag({
    required String src,
    required String tr,
    required String srcLang,
    required String targetLang,
    required String appPackage,
    required String appLabel,
    required bool flagged,
    String? note,
  }) async {
    final key = historyDedupeKey(targetLang, src);
    final flag = {'flagged': flagged ? 1 : 0, 'note': flagged ? note : null};
    await _db.transaction((txn) async {
      final updated = await txn.update('history', flag, where: 'dedupe_key = ?', whereArgs: [key]);
      if (updated == 0) {
        await txn.insert('history', {
          ...flag,
          'dedupe_key': key,
          'src': src,
          'tr': tr,
          'src_lang': srcLang,
          'target_lang': targetLang,
          'app_package': appPackage,
          'app_label': appLabel,
          'engine': 'mlkit',
          'ms': null,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
        await _trimToMaxRows(txn);
      }
    });
  }

  /// "Export beta feedback": the Phase 10 fields, oldest first. Contains message text — the UI warns.
  Future<String> exportBetaJson() async {
    final rows = await _db.query(
      'history',
      columns: ['src', 'tr', 'src_lang', 'target_lang', 'app_label', 'engine', 'ms', 'flagged', 'note'],
      orderBy: 'created_at ASC, id ASC',
    );
    return jsonEncode([
      for (final r in rows) {...r, 'flagged': r['flagged'] == 1},
    ]);
  }

  Future<List<HistoryEntry>> fetchAll() async {
    final rows = await _db.query('history', orderBy: 'created_at DESC, id DESC');
    return rows.map(HistoryEntry.fromMap).toList(growable: false);
  }

  Future<void> clear() => _db.delete('history');

  Future<int> count() async {
    final row = await _db.rawQuery('SELECT COUNT(*) AS c FROM history');
    return row.first['c']! as int;
  }

  Future<void> _trimToMaxRows(DatabaseExecutor txn) async {
    final total = Sqflite.firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM history')) ?? 0;
    if (total <= maxRows) return;
    final excess = total - maxRows;
    await txn.rawDelete(
      '''
      DELETE FROM history WHERE id IN (
        SELECT id FROM history ORDER BY created_at ASC, id ASC LIMIT ?
      )
      ''',
      [excess],
    );
  }
}
