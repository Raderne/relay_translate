import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_translate/data/settings_store.dart';
import 'package:relay_translate/native/overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const overlay = BubbleOverlay();
  final calls = <MethodCall>[];

  void mock(Object? Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(BubbleOverlay.channel, (call) async {
      calls.add(call);
      return handler(call);
    });
  }

  setUp(calls.clear);
  tearDown(() => messenger.setMockMethodCallHandler(BubbleOverlay.channel, null));

  test('apply is a no-op before onboarding', () async {
    mock((_) => true);
    final store = SettingsStore.inMemory();
    expect(await overlay.apply(store), isFalse);
    expect(calls, isEmpty);
  });

  test('apply sends the bubble settings', () async {
    mock((_) => true);
    final store = SettingsStore.inMemory();
    await store.setOnboarded(true);
    await store.setSnap(false);
    expect(await overlay.apply(store), isTrue);
    expect(calls.single.method, 'apply');
    expect(calls.single.arguments, {
      'on': true,
      'size': 'M',
      'snap': false,
      'x': 300.0,
      'y': 600.0,
      'hintSeen': false,
    });
  });

  test('pullInto adopts Hide, position and hint from native', () async {
    mock((_) => {'on': false, 'x': 6.0, 'y': 410.0, 'hintSeen': true});
    final store = SettingsStore.inMemory();
    await overlay.pullInto(store, screenWidth: 400);
    expect(store.bubbleOn, isFalse);
    expect(store.bubbleX, 6.0);
    expect(store.bubbleY, 410.0);
    expect(store.hintSeen, isTrue);
  });

  test('pullInto leaves settings alone when the bubble never ran', () async {
    mock((_) => null);
    final store = SettingsStore.inMemory();
    await overlay.pullInto(store, screenWidth: 400);
    expect(store.bubbleOn, isTrue);
    expect(store.bubbleX, 300.0);
  });

  test('takeRoute maps the menu routes', () async {
    for (final (raw, route) in [('language', BubbleRoute.language), ('history', BubbleRoute.history), (null, null)]) {
      mock((_) => raw);
      expect(await overlay.takeRoute(), route);
    }
  });
}
