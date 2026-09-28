import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_translate/chatter/chatter_session.dart';
import 'package:relay_translate/data/db.dart';
import 'package:relay_translate/data/history_repository.dart';
import 'package:relay_translate/data/settings_store.dart';
import 'package:relay_translate/native/translator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('translateAll swaps incoming text and sets toast', () async {
    final settings = SettingsStore.inMemory();
    final db = await openRelayDatabase(path: ':memory:');
    final history = HistoryRepository(db);
    final session = ChatterSession(settings: settings, history: history);

    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(Translator.channel, (call) async {
      if (call.method != 'translate') return null;
      final texts = (call.arguments as Map)['texts'] as List;
      return texts
          .map((t) => {'text': '[FR] $t', 'source': 'en'})
          .toList(growable: false);
    });

    await session.translateAll();

    expect(session.incoming.first.display, startsWith('[FR]'));
    expect(session.toastMessage, contains('messages · English → French'));

    messenger.setMockMethodCallHandler(Translator.channel, null);
  });

  testWidgets('translateAll updates bound widgets and toast', (tester) async {
    final settings = SettingsStore.inMemory();
    final db = await openRelayDatabase(path: ':memory:');
    final history = HistoryRepository(db);
    final session = ChatterSession(settings: settings, history: history);

    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(Translator.channel, (call) async {
      if (call.method != 'translate') return null;
      final texts = (call.arguments as Map)['texts'] as List;
      return texts
          .map((t) => {'text': '[FR] $t', 'source': 'en'})
          .toList(growable: false);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ListenableBuilder(
          listenable: session,
          builder: (context, _) => Text(session.incoming.first.display ?? session.incoming.first.src),
        ),
      ),
    );

    unawaited(session.translateAll());
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (session.incoming.first.display != null) break;
    }

    expect(find.textContaining('[FR]'), findsOneWidget);

    messenger.setMockMethodCallHandler(Translator.channel, null);
  });
}
