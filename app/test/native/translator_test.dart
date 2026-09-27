import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_translate/native/translator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const translator = Translator();
  final calls = <MethodCall>[];

  void mock(Object? Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(Translator.channel, (call) async {
      calls.add(call);
      return handler(call);
    });
  }

  setUp(calls.clear);
  tearDown(() => messenger.setMockMethodCallHandler(Translator.channel, null));

  test('translate sends texts/target/wifiOnly and parses results in order', () async {
    mock((_) => [
      {'text': 'Salut !', 'source': 'en'},
      {'text': 'ok see u', 'source': 'und'},
    ]);

    final out = await translator.translate(['Hey!', 'ok see u'], 'fr', wifiOnly: false);

    expect(calls.single.method, 'translate');
    expect(calls.single.arguments, {
      'texts': ['Hey!', 'ok see u'],
      'target': 'fr',
      'wifiOnly': false,
    });
    expect(out.map((t) => t.text), ['Salut !', 'ok see u']);
    expect(out.map((t) => t.source), ['en', 'und']);
    expect(out[1].undetected, isTrue);
  });

  test('wifiOnly defaults to true', () async {
    mock((_) => <Object?>[]);
    await translator.translate([], 'de');
    expect((calls.single.arguments as Map)['wifiOnly'], isTrue);
  });

  test('modelStatus maps the native string to the enum', () async {
    mock((_) => 'downloading');
    expect(await translator.modelStatus('fr'), ModelStatus.downloading);
    expect(calls.single.arguments, {'lang': 'fr'});
  });

  test('ensureModel and deleteModel pass the language', () async {
    mock((_) => null);
    await translator.ensureModel('pt');
    await translator.deleteModel('pt');
    expect(calls.map((c) => c.method), ['ensureModel', 'deleteModel']);
    expect(calls.first.arguments, {'lang': 'pt', 'wifiOnly': true});
    expect(calls.last.arguments, {'lang': 'pt'});
  });

  test('PlatformException becomes a typed TranslateException', () async {
    mock((_) => throw PlatformException(code: 'no_network', message: 'offline'));
    await expectLater(
      translator.ensureModel('fr'),
      throwsA(
        isA<TranslateException>()
            .having((e) => e.code, 'code', TranslateException.noNetwork)
            .having((e) => e.message, 'message', 'offline'),
      ),
    );
  });
}
