import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_translate/data/db.dart';
import 'package:relay_translate/data/history_repository.dart';
import 'package:relay_translate/native/beta.dart';
import 'package:relay_translate/screens/history_screen.dart';
import 'package:relay_translate/theme/theme.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Phase 10: beta-only Export + 👎 on History rows.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final shared = <MethodCall>[];

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    shared.clear();
    messenger.setMockMethodCallHandler(BetaBridge.channel, (call) async {
      shared.add(call);
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(BetaBridge.channel, null));

  // sqflite_ffi only completes outside fake async.
  Future<HistoryRepository> seeded(WidgetTester tester) async {
    late HistoryRepository repo;
    await tester.runAsync(() async {
      repo = HistoryRepository(await openRelayDatabase(path: ':memory:'));
      await repo.clear();
      await repo.logTranslation(
        src: 'brb',
        tr: 'brb',
        srcLang: 'en',
        targetLang: 'fr',
        ms: 30,
        appPackage: 'com.whatsapp',
        appLabel: 'WhatsApp',
      );
    });
    return repo;
  }

  Future<void> open(WidgetTester tester, HistoryRepository repo, {required bool beta}) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(theme: RelayTheme.data, home: HistoryScreen(repository: repo, beta: beta)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
  }

  testWidgets('release build: no Export, no flag buttons', (tester) async {
    final repo = await seeded(tester);
    await open(tester, repo, beta: false);
    expect(find.text('brb'), findsWidgets);
    expect(find.text('Export'), findsNothing);
    expect(find.byTooltip('Flag bad translation'), findsNothing);
  });

  testWidgets('Export warns about message text, Cancel shares nothing', (tester) async {
    final repo = await seeded(tester);
    await open(tester, repo, beta: true);
    await tester.tap(find.text('Export'));
    await tester.pump();
    expect(find.textContaining('contains the text of your messages'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(shared, isEmpty);
  });

  testWidgets('confirming Export shares the beta JSON', (tester) async {
    final repo = await seeded(tester);
    await open(tester, repo, beta: true);
    await tester.tap(find.text('Export'));
    await tester.pump();
    await tester.tap(find.text('Share file'));
    await tester.pump(); // dialog result
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100))); // ffi export
    await tester.pump();
    expect(shared.single.method, 'shareJson');
    final args = shared.single.arguments as Map;
    expect(args['fileName'], startsWith('relay-beta-feedback-'));
    expect(args['json'], contains('"src":"brb"'));
  });

  testWidgets('👎 on a row flags it in the database', (tester) async {
    final repo = await seeded(tester);
    await open(tester, repo, beta: true);
    await tester.runAsync(() async {
      await tester.tap(find.byTooltip('Flag bad translation'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    late bool flagged;
    await tester.runAsync(() async => flagged = (await repo.fetchAll()).single.flagged);
    expect(flagged, isTrue);
  });
}
