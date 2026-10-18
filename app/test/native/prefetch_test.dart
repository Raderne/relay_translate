import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_translate/native/translator.dart';

/// Phase 11: the featured languages (Arabic, French) download right after onboarding.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  tearDown(() {
    calls.clear();
    messenger.setMockMethodCallHandler(Translator.channel, null);
  });

  void mock(Map<String, String> status, {bool wifiRequired = false}) {
    messenger.setMockMethodCallHandler(Translator.channel, (call) async {
      calls.add(call);
      final lang = (call.arguments as Map)['lang'] as String;
      if (call.method == 'modelStatus') return status[lang];
      if (call.method == 'ensureModel' && wifiRequired) {
        throw PlatformException(code: TranslateException.wifiRequired);
      }
      return null;
    });
  }

  test('downloads only the featured models that are missing', () async {
    mock({'ar': 'missing', 'fr': 'ready'});
    await const Translator().prefetchFeatured(wifiOnly: true);
    final ensured = calls.where((c) => c.method == 'ensureModel').map((c) => c.arguments);
    expect(ensured, [
      {'lang': 'ar', 'wifiOnly': true},
    ]);
  });

  test('a download that cannot start (Wi-Fi only on mobile data) is silent', () async {
    mock({'ar': 'missing', 'fr': 'missing'}, wifiRequired: true);
    await const Translator().prefetchFeatured(wifiOnly: true); // no throw
    expect(calls.where((c) => c.method == 'ensureModel'), hasLength(2));
  });
}
