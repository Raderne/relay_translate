import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_translate/native/translator.dart';
import 'package:relay_translate/data/settings_store.dart';
import 'package:relay_translate/main.dart';
import 'package:relay_translate/native/permissions.dart';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      Translator.channel,
      (call) async {
        if (call.method == 'modelStatus') return 'ready';
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      Translator.channel,
      null,
    );
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<({RelayApp app, SettingsStore settings})> harness(
    FakePermissions fake, {
    bool onboarded = false,
  }) async {
    final settings = SettingsStore.inMemory();
    if (onboarded) await settings.setOnboarded(true);
    final app = RelayApp(controller: PermissionsController(fake, fake.current), settings: settings);
    return (app: app, settings: settings);
  }

  testWidgets('Back returns to onboard 1', (tester) async {
    final fake = FakePermissions(const PermissionStatus(overlay: false, accessibility: false, onboarded: false));
    final h = await harness(fake);
    await tester.pumpWidget(h.app);
    await tester.tap(find.text('Continue'));
    await settle(tester);

    expect(find.text('Let Relay appear on top of other apps'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await settle(tester);
    expect(find.text('Translate inside any app'), findsOneWidget);
  });

  testWidgets('missing overlay opens overlay settings and skips the disclosure', (tester) async {
    final fake = FakePermissions(const PermissionStatus(overlay: false, accessibility: false, onboarded: false));
    final h = await harness(fake);
    await tester.pumpWidget(h.app);
    await tester.tap(find.text('Continue'));
    await settle(tester);

    await tester.tap(find.text('Open Android settings'));
    await settle(tester);

    expect(fake.opened, ['overlay']);
    expect(find.text(accessibilityDisclosure), findsNothing);
    expect(find.text('Let Relay appear on top of other apps'), findsOneWidget);
  });

  testWidgets('accessibility step shows the disclosure and Not now stays put', (tester) async {
    final fake = FakePermissions(const PermissionStatus(overlay: true, accessibility: false, onboarded: false));
    final h = await harness(fake);
    await tester.pumpWidget(h.app);
    await tester.tap(find.text('Continue'));
    await settle(tester);

    expect(find.byKey(const Key('check-01')), findsOneWidget);
    expect(find.text('01'), findsNothing);
    expect(find.text('02'), findsOneWidget);

    await tester.tap(find.text('Open Android settings'));
    await settle(tester);
    expect(find.text(accessibilityDisclosure), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await settle(tester);
    expect(fake.opened, isEmpty);
    expect(find.text('Let Relay appear on top of other apps'), findsOneWidget);

    await tester.tap(find.text('Open Android settings'));
    await settle(tester);
    await tester.tap(find.text('Agree'));
    await settle(tester);
    expect(fake.opened, ['accessibility']);
  });

  testWidgets('both granted waits 650 ms then replaces the stack with Home', (tester) async {
    final fake = FakePermissions(const PermissionStatus(overlay: true, accessibility: true, onboarded: false));
    final h = await harness(fake);
    await tester.pumpWidget(h.app);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(permissionGrantDelay);
    await tester.pump();
    await settle(tester);

    expect(find.text('Try it in Chatter'), findsOneWidget);
    expect(h.settings.onboarded, isTrue);
    expect(fake.clearedOnboarded, isTrue);
    expect(find.byKey(const Key('permission-warning')), findsNothing);
  });

  testWidgets('revoked overlay shows a warning that opens onboard 2', (tester) async {
    final fake = FakePermissions(const PermissionStatus(overlay: false, accessibility: true, onboarded: true));
    final h = await harness(fake, onboarded: true);
    await tester.pumpWidget(h.app);

    expect(find.text('Display over other apps is off'), findsOneWidget);
    await tester.tap(find.byKey(const Key('permission-warning')));
    await settle(tester);

    expect(find.text('Let Relay appear on top of other apps'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(find.byKey(const Key('check-02')), findsOneWidget);
  });
}

class FakePermissions extends Permissions {
  FakePermissions(this.current);

  PermissionStatus current;
  final opened = <String>[];
  var clearedOnboarded = false;

  @override
  Future<PermissionStatus> status() async => current;

  @override
  Future<void> openOverlay() async => opened.add('overlay');

  @override
  Future<void> openAccessibility() async => opened.add('accessibility');

  @override
  Future<void> clearOnboardedFile() async {
    clearedOnboarded = true;
  }
}
