import 'package:flutter_test/flutter_test.dart';
import 'package:relay_translate/data/db.dart';
import 'package:relay_translate/data/history_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<HistoryRepository> repo() async {
    final db = await openRelayDatabase(path: ':memory:');
    return HistoryRepository(db);
  }

  test('dedupe replaces row and bumps created_at to the top', () async {
    final history = await repo();
    await history.logTranslation(
      src: 'Hello',
      tr: 'Salut',
      srcLang: 'en',
      targetLang: 'fr',
      ms: 10,
    );
    final first = (await history.fetchAll()).single;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await history.logTranslation(
      src: 'Hello',
      tr: 'Bonjour',
      srcLang: 'en',
      targetLang: 'fr',
      ms: 12,
    );

    final rows = await history.fetchAll();
    expect(rows.length, 1);
    expect(rows.single.tr, 'Bonjour');
    expect(rows.single.createdAt, greaterThan(first.createdAt));
  });

  test('retention keeps only the newest maxRows entries', () async {
    final history = await repo();
    for (var i = 0; i < HistoryRepository.maxRows + 1; i++) {
      await history.logTranslation(
        src: 'msg-$i',
        tr: 'tr-$i',
        srcLang: 'en',
        targetLang: 'fr',
        ms: 1,
      );
    }

    expect(await history.count(), HistoryRepository.maxRows);
    final rows = await history.fetchAll();
    expect(rows.any((r) => r.src == 'msg-0'), isFalse);
    expect(rows.any((r) => r.src == 'msg-${HistoryRepository.maxRows}'), isTrue);
  });

  test('clear removes all rows', () async {
    final history = await repo();
    await history.logTranslation(
      src: 'x',
      tr: 'y',
      srcLang: 'en',
      targetLang: 'fr',
      ms: 1,
    );
    await history.clear();
    expect(await history.count(), 0);
  });
}
