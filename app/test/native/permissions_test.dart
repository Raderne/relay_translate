import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_translate/native/permissions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const permissions = Permissions();
  final calls = <MethodCall>[];

  void mock(Object? Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(Permissions.channel, (call) async {
      calls.add(call);
      return handler(call);
    });
  }

  setUp(calls.clear);
  tearDown(() => messenger.setMockMethodCallHandler(Permissions.channel, null));

  test('status parses overlay, accessibility, and onboarded', () async {
    mock(
      (_) => {'overlay': true, 'accessibility': false, 'onboarded': true},
    );
    final status = await permissions.status();
    expect(calls.single.method, 'status');
    expect(status.overlay, isTrue);
    expect(status.accessibility, isFalse);
    expect(status.onboarded, isTrue);
    expect(status.ready, isFalse);
  });

  test('open and setOnboarded call the matching methods', () async {
    mock((_) => null);
    await permissions.openOverlay();
    await permissions.openAccessibility();
    await permissions.setOnboarded();
    expect(calls.map((c) => c.method), ['openOverlay', 'openAccessibility', 'setOnboarded']);
  });

  test('next step is overlay, then disclosure, then home', () {
    const missing = PermissionStatus(overlay: false, accessibility: false, onboarded: false);
    const overlayOnly = PermissionStatus(overlay: true, accessibility: false, onboarded: false);
    const ready = PermissionStatus(overlay: true, accessibility: true, onboarded: false);
    expect(nextStep(missing), PermissionStep.overlay);
    expect(nextStep(overlayOnly), PermissionStep.disclosure);
    expect(nextStep(ready), PermissionStep.home);
    expect(nextStep(const PermissionStatus(overlay: false, accessibility: true, onboarded: true)), PermissionStep.overlay);
  });

  test('warning names the permission that is off', () {
    expect(
      permissionWarning(const PermissionStatus(overlay: true, accessibility: true, onboarded: true)),
      isNull,
    );
    expect(
      permissionWarning(const PermissionStatus(overlay: false, accessibility: true, onboarded: true)),
      'Display over other apps is off',
    );
    expect(
      permissionWarning(const PermissionStatus(overlay: true, accessibility: false, onboarded: true)),
      'Screen text access is off',
    );
    expect(
      permissionWarning(const PermissionStatus(overlay: false, accessibility: false, onboarded: true)),
      'Display over other apps and screen text access are off',
    );
  });

  test('disclosure wording is the privacy promise', () {
    expect(
      accessibilityDisclosure,
      "Relay uses Android's Accessibility service to read the text of messages on your screen, "
      'only when you hold the bubble or drop it on a message, and to paste replies you write '
      "into the app's message box. Translation happens on your phone. Your messages are not "
      "sent anywhere. Relay doesn't collect anything else from your screen.",
    );
  });
}
