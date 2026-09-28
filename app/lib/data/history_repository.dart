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
    required int ms,
    String appPackage = kChatterPackage,
    String appLabel = kChatterLabel,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final key = historyDedupeKey(targetLang, src);
    await _db.transaction((txn) async {
      await txn.insert(
        'history',
        {
          'dedupe_key': key,
          'src': src,
          'tr': tr,
          'src_lang': srcLang,
          'target_lang': targetLang,
          'app_package': appPackage,
          'app_label': appLabel,
          'engine': 'mlkit',
          'ms': ms,
          'flagged': 0,
          'note': null,
          'created_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _trimToMaxRows(txn);
    });
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
