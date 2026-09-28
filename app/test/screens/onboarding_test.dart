import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_translate/main.dart';
import 'package:relay_translate/native/permissions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Back returns to onboard 1', (tester) async {
    final fake = FakePermissions(const PermissionStatus(overlay: false, accessibility: false, onboarded: false));
    await tester.pumpWidget(RelayApp(controller: PermissionsController(fake, fake.current)));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Let Relay appear on top of other apps'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Translate inside any app'), findsOneWidget);
  });

  testWidgets('missing overlay opens overlay settings and skips the disclosure', (tester) async {
    final fake = FakePermissions(const PermissionStatus(overlay: false, accessibility: false, onboarded: false));
    await tester.pumpWidget(RelayApp(controller: PermissionsController(fake, fake.current)));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Android settings'));
    await tester.pumpAndSettle();

    expect(fake.opened, ['overlay']);
    expect(find.text(accessibilityDisclosure), findsNothing);
    expect(find.text('Let Relay appear on top of other apps'), findsOneWidget);
  });

  testWidgets('accessibility step shows the disclosure and Not now stays put', (tester) async {
    final fake = FakePermissions(const PermissionStatus(overlay: true, accessibility: false, onboarded: false));
    await tester.pumpWidget(RelayApp(controller: PermissionsController(fake, fake.current)));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('check-01')), findsOneWidget);
    expect(find.text('01'), findsNothing);
    expect(find.text('02'), findsOneWidget);

    await tester.tap(find.text('Open Android settings'));
    await tester.pumpAndSettle();
    expect(find.text(accessibilityDisclosure), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(fake.opened, isEmpty);
    expect(find.text('Let Relay appear on top of other apps'), findsOneWidget);

    await tester.tap(find.text('Open Android settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agree'));
    await tester.pumpAndSettle();
    expect(fake.opened, ['accessibility']);
  });

  testWidgets('both granted waits 650 ms then replaces the stack with Home', (tester) async {
    final fake = FakePermissions(const PermissionStatus(overlay: false, accessibility: false, onboarded: false));
    await tester.pumpWidget(RelayApp(controller: PermissionsController(fake, fake.current)));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    fake.current = const PermissionStatus(overlay: true, accessibility: true, onboarded: false);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('Let Relay appear on top of other apps'), findsOneWidget);

    await tester.pump(permissionGrantDelay);
    await tester.pumpAndSettle();

    expect(find.text('Relay'), findsOneWidget);
    expect(find.text('Translate inside any app'), findsNothing);
    expect(find.text('Let Relay appear on top of other apps'), findsNothing);
    expect(fake.current.onboarded, isTrue);
    expect(find.byKey(const Key('permission-warning')), findsNothing);
  });

  testWidgets('revoked overlay shows a warning that opens onboard 2', (tester) async {
    final fake = FakePermissions(const PermissionStatus(overlay: false, accessibility: true, onboarded: true));
    await tester.pumpWidget(RelayApp(controller: PermissionsController(fake, fake.current)));

    expect(find.text('Display over other apps is off'), findsOneWidget);
    await tester.tap(find.byKey(const Key('permission-warning')));
    await tester.pumpAndSettle();

    expect(find.text('Let Relay appear on top of other apps'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(find.byKey(const Key('check-02')), findsOneWidget);
  });
}

class FakePermissions extends Permissions {
  FakePermissions(this.current);

  PermissionStatus current;
  final opened = <String>[];

  @override
  Future<PermissionStatus> status() async => current;

  @override
  Future<void> openOverlay() async => opened.add('overlay');

  @override
  Future<void> openAccessibility() async => opened.add('accessibility');

  @override
  Future<void> setOnboarded() async {
    current = PermissionStatus(overlay: current.overlay, accessibility: current.accessibility, onboarded: true);
  }
}
