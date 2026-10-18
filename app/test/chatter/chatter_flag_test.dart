import 'package:flutter_test/flutter_test.dart';
import 'package:relay_translate/chatter/chatter_session.dart';
import 'package:relay_translate/data/db.dart';
import 'package:relay_translate/data/history_repository.dart';
import 'package:relay_translate/data/settings_store.dart';
import 'package:relay_translate/native/translator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Phase 10: 👎 in Chatter's detail sheet lands on the history row.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() => messenger.setMockMethodCallHandler(Translator.channel, null));

  Future<(ChatterSession, HistoryRepository)> translatedSession() async {
    final history = HistoryRepository(await openRelayDatabase(path: ':memory:'));
    await history.clear(); // ffi shares one :memory: DB across opens
    final session = ChatterSession(settings: SettingsStore.inMemory(), history: history);
    messenger.setMockMethodCallHandler(Translator.channel, (call) async {
      final texts = (call.arguments as Map)['texts'] as List;
      return [for (final t in texts) {'text': '[FR] $t', 'source': 'en'}];
    });
    await session.translateAll();
    session.openDetail(session.incoming.first.id);
    return (session, history);
  }

  test('flagging the open message flags its history row', () async {
    final (session, history) = await translatedSession();
    final src = session.incoming.first.src;

    await session.setDetailFlag(true);

    expect(session.detailFlagged, isTrue);
    final row = (await history.fetchAll()).singleWhere((e) => e.src == src);
    expect(row.flagged, isTrue);
  });

  test('the note is stored with the flag, unflag clears both', () async {
    final (session, history) = await translatedSession();
    final src = session.incoming.first.src;

    await session.setDetailFlag(true);
    await session.setDetailNote('too literal');
    var row = (await history.fetchAll()).singleWhere((e) => e.src == src);
    expect(row.note, 'too literal');

    await session.setDetailFlag(false);
    row = (await history.fetchAll()).singleWhere((e) => e.src == src);
    expect(row.flagged, isFalse);
    expect(row.note, isNull);
    expect(session.detailFlagged, isFalse);
  });

  test('reopening a flagged message shows it flagged; another message does not', () async {
    final (session, _) = await translatedSession();
    final first = session.incoming.first.id;
    await session.setDetailFlag(true);
    session.closeDetail();

    session.openDetail(session.incoming[1].id);
    expect(session.detailFlagged, isFalse);
    session.openDetail(first);
    expect(session.detailFlagged, isTrue);
  });
}
