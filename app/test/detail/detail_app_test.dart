import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_translate/detail/cross_app_detail.dart';
import 'package:relay_translate/detail/detail_app.dart';
import 'package:relay_translate/native/translator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(DetailBridge.channel, (call) async {
      calls.add(call);
      if (call.method == 'args') {
        return {
          'src': 'Are you free tonight?',
          'tr': 'Tu es libre ce soir ?',
          'source': 'en',
          'target': 'fr',
          'appLabel': 'WhatsApp',
          'appPackage': 'com.whatsapp',
          'wifiOnly': true,
        };
      }
      return null;
    });
    messenger.setMockMethodCallHandler(Translator.channel, (call) async => [
      {'text': "Yes, I'm free", 'source': 'fr'},
    ]);
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(DetailBridge.channel, null);
    messenger.setMockMethodCallHandler(Translator.channel, null);
  });

  testWidgets('loads the message, then reply → translate → paste into the app', (tester) async {
    await tester.pumpWidget(const DetailApp());
    await tester.pump();

    expect(find.text('English → French · WhatsApp'.toUpperCase()), findsOneWidget);
    expect(find.text('Tu es libre ce soir ?'), findsOneWidget);

    await tester.tap(find.text('Reply'));
    await tester.pump();
    expect(find.text('Your reply in French'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Oui, je suis libre');
    await tester.tap(find.text('Translate to English'));
    await tester.pump();
    await tester.tap(find.text('Paste into WhatsApp'));
    await tester.pump();

    expect(calls.last.method, 'paste');
    expect(calls.last.arguments, {'text': "Yes, I'm free"});
  });
}
