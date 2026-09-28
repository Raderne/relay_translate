import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';

import 'chatter_seed.dart';
import 'db.dart';

String historyDedupeKey(String targetLang, String src) {
  final digest = sha1.convert(utf8.encode('$targetLang\n$src'));
  return digest.toString();
}

class HistoryRepository {
  HistoryRepository(this._db);

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
    await _db.insert(
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
  }
}
