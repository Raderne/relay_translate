import 'package:flutter_test/flutter_test.dart';
import 'package:relay_translate/bubble/bubble_tokens.dart';
import 'package:relay_translate/chatter/chatter_session.dart';
import 'package:relay_translate/data/db.dart';
import 'package:relay_translate/data/history_models.dart';
import 'package:relay_translate/data/history_repository.dart';
import 'package:relay_translate/data/settings_store.dart';
import 'package:relay_translate/native/translator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Phase 10: what Chatter logs must make the beta metrics honest.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() => messenger.setMockMethodCallHandler(Translator.channel, null));

  Future<(ChatterSession, HistoryRepository)> session({required bool beta}) async {
    final history = HistoryRepository(await openRelayDatabase(path: ':memory:'));
    await history.clear(); // ffi shares one :memory: DB across opens
    return (ChatterSession(settings: SettingsStore.inMemory(), history: history, beta: beta), history);
  }

  void mockTranslate({bool downloaded = false, bool firstUndetected = false}) {
    messenger.setMockMethodCallHandler(Translator.channel, (call) async {
      final texts = (call.arguments as Map)['texts'] as List;
      return [
        for (final (i, t) in texts.indexed)
          {
            'text': i == 0 && firstUndetected ? t : '[FR] $t',
            'source': i == 0 && firstUndetected ? 'und' : 'en',
            'downloaded': downloaded,
          },
      ];
    });
  }

  Future<List<HistoryEntry>> rows(HistoryRepository h) => h.fetchAll();

  test('a call that had to download a model logs no latency', () async {
    final (s, h) = await session(beta: true);
    mockTranslate(downloaded: true);
    await s.translateAll();
    final logged = await rows(h);
    expect(logged, isNotEmpty);
    expect(logged.every((e) => e.ms == null), isTrue);
  });

  test('with models already present the latency is logged', () async {
    final (s, h) = await session(beta: true);
    mockTranslate();
    await s.translateAll();
    expect((await rows(h)).every((e) => e.ms != null), isTrue);
  });

  test('beta logs undetected messages as und rows', () async {
    final (s, h) = await session(beta: true);
    mockTranslate(firstUndetected: true);
    await s.translateAll();
    final und = (await rows(h)).where((e) => e.srcLang == 'und').toList();
    expect(und, hasLength(1));
    expect(und.single.tr, und.single.src);
  });

  test('release builds keep skipping undetected messages', () async {
    final (s, h) = await session(beta: false);
    mockTranslate(firstUndetected: true);
    await s.translateAll();
    expect((await rows(h)).where((e) => e.srcLang == 'und'), isEmpty);
  });

  test('translateOne latency excludes the 900 ms flash', () async {
    final (s, h) = await session(beta: true);
    mockTranslate();
    await s.translateOne(s.incoming.first.id);
    final ms = (await rows(h)).single.ms!;
    expect(ms, lessThan(BubbleTokens.flashMs));
  });
}
