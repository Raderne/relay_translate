import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:relay_translate/data/db.dart';
import 'package:relay_translate/data/history_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Phase 10 beta feedback: flags survive re-translation and the export carries them.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // sqflite_ffi hands every `:memory:` open the same shared DB, so start each test empty.
  Future<HistoryRepository> repo() async {
    final h = HistoryRepository(await openRelayDatabase(path: ':memory:'));
    await h.clear();
    return h;
  }

  Future<void> log(HistoryRepository h, {String src = 'Hello', String tr = 'Salut', int ms = 40}) =>
      h.logTranslation(
        src: src,
        tr: tr,
        srcLang: 'en',
        targetLang: 'fr',
        ms: ms,
        appPackage: 'com.whatsapp',
        appLabel: 'WhatsApp',
      );

  Future<void> flag(HistoryRepository h, {bool flagged = true, String? note, String src = 'Hello'}) => h.setFlag(
    src: src,
    tr: 'Salut',
    srcLang: 'en',
    targetLang: 'fr',
    appPackage: 'com.whatsapp',
    appLabel: 'WhatsApp',
    flagged: flagged,
    note: note,
  );

  test('flagging an existing row stores the flag and note', () async {
    final h = await repo();
    await log(h);
    await flag(h, note: 'too formal');
    final row = (await h.fetchAll()).single;
    expect(row.flagged, isTrue);
    expect(row.note, 'too formal');
  });

  test('unflagging clears the flag and the note', () async {
    final h = await repo();
    await log(h);
    await flag(h, note: 'too formal');
    await flag(h, flagged: false);
    final row = (await h.fetchAll()).single;
    expect(row.flagged, isFalse);
    expect(row.note, isNull);
  });

  test('re-translating a flagged message keeps the flag and note', () async {
    final h = await repo();
    await log(h);
    await flag(h, note: 'wrong meaning');
    await log(h, tr: 'Bonjour', ms: 55);
    final row = (await h.fetchAll()).single;
    expect(row.tr, 'Bonjour');
    expect(row.flagged, isTrue);
    expect(row.note, 'wrong meaning');
  });

  // Over another app the sheet can open before the buffered history row reaches the DB.
  test('flagging a message not in history yet inserts it, and the later log keeps the flag', () async {
    final h = await repo();
    await flag(h, note: 'slang');
    expect((await h.fetchAll()).single.flagged, isTrue);
    await log(h, ms: 70);
    final rows = await h.fetchAll();
    expect(rows, hasLength(1));
    expect(rows.single.flagged, isTrue);
    expect(rows.single.note, 'slang');
  });

  test('exportBetaJson lists the beta fields, oldest first', () async {
    final h = await repo();
    await log(h, src: 'Hello', tr: 'Salut', ms: 40);
    await Future<void>.delayed(const Duration(milliseconds: 3));
    await log(h, src: 'brb', tr: 'brb', ms: 25);
    await flag(h, src: 'brb', note: 'not translated');

    final exported = jsonDecode(await h.exportBetaJson()) as List<Object?>;
    expect(exported, [
      {
        'src': 'Hello',
        'tr': 'Salut',
        'src_lang': 'en',
        'target_lang': 'fr',
        'app_label': 'WhatsApp',
        'engine': 'mlkit',
        'ms': 40,
        'flagged': false,
        'note': null,
      },
      {
        'src': 'brb',
        'tr': 'brb',
        'src_lang': 'en',
        'target_lang': 'fr',
        'app_label': 'WhatsApp',
        'engine': 'mlkit',
        'ms': 25,
        'flagged': true,
        'note': 'not translated',
      },
    ]);
  });
}
