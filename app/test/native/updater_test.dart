import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_translate/native/updater.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(Updater.channel, null));

  test('isNewer compares x.y.z and ignores flavor/build suffixes', () {
    expect(isNewer('0.2.0', '0.1.0-beta'), isTrue);
    expect(isNewer('0.10.0', '0.9.9'), isTrue);
    expect(isNewer('1.0.0', '0.99.99'), isTrue);
    expect(isNewer('0.1.0', '0.1.0-beta'), isFalse);
    expect(isNewer('0.1.0', '0.2.0'), isFalse);
    expect(isNewer('0.1.1+5', '0.1'), isTrue);
  });

  test('check parses the channel map; no APK for this ABI means no update', () async {
    Object? url = 'https://example/app-arm64-v8a.apk';
    messenger.setMockMethodCallHandler(Updater.channel, (_) async => {
      'current': '0.1.0-beta',
      'latest': '0.2.0',
      'notes': '### Added\n- x',
      'url': url,
    });
    final info = (await const Updater().check())!;
    expect(info.latest, '0.2.0');
    expect(info.available, isTrue);

    url = null;
    expect((await const Updater().check())!.available, isFalse);
  });

  test('check swallows failures', () async {
    messenger.setMockMethodCallHandler(Updater.channel, (_) async => throw PlatformException(code: 'update_failed'));
    expect(await const Updater().check(), isNull);
  });
}
