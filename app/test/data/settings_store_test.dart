import 'package:flutter_test/flutter_test.dart';
import 'package:relay_translate/data/db.dart';
import 'package:relay_translate/data/settings_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('each settings key round-trips through in-memory sqflite', () async {
    final db = await openRelayDatabase(path: ':memory:');
    final store = await SettingsStore.open(database: db);

    expect(store.targetLang, 'fr');
    expect(store.bubbleOn, isTrue);
    expect(store.snap, isTrue);
    expect(store.size, 'M');
    expect(store.bubbleX, 300);
    expect(store.bubbleY, 600);
    expect(store.onboarded, isFalse);
    expect(store.hintSeen, isFalse);
    expect(store.wifiOnlyDownloads, isTrue);

    await store.setTargetLang('es');
    await store.setBubbleOn(false);
    await store.setSnap(false);
    await store.setSize('L', screenWidth: 400);
    await store.setBubblePosition(50, 120, screenWidth: 400);
    await store.setOnboarded(true);
    await store.setHintSeen(true);
    await store.setWifiOnlyDownloads(false);

    final reloaded = await SettingsStore.open(database: db);
    expect(reloaded.targetLang, 'es');
    expect(reloaded.bubbleOn, isFalse);
    expect(reloaded.snap, isFalse);
    expect(reloaded.size, 'L');
    expect(reloaded.bubbleX, 50);
    expect(reloaded.bubbleY, 120);
    expect(reloaded.onboarded, isTrue);
    expect(reloaded.hintSeen, isTrue);
    expect(reloaded.wifiOnlyDownloads, isFalse);
  });

  test('setSize clamps bubble_x inside the screen', () async {
    final db = await openRelayDatabase(path: ':memory:');
    final store = await SettingsStore.open(database: db);
    await store.setBubblePosition(380, 100, screenWidth: 400);
    await store.setSize('L', screenWidth: 400);
    expect(store.bubbleX, 340);
  });

  test('adoptLegacyOnboardedFile sets onboarded once', () async {
    final db = await openRelayDatabase(path: ':memory:');
    final store = await SettingsStore.open(database: db);
    await store.adoptLegacyOnboardedFile(true);
    expect(store.onboarded, isTrue);
    await store.adoptLegacyOnboardedFile(false);
    expect(store.onboarded, isTrue);
  });
}
