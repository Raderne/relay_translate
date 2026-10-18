import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_translate/native/beta.dart';
import 'package:relay_translate/screens/beta_survey_row.dart';
import 'package:relay_translate/theme/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(BetaBridge.channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(BetaBridge.channel, null));

  Widget host(Widget child) => MaterialApp(theme: RelayTheme.data, home: Scaffold(body: child));

  testWidgets('tapping the survey row opens the form', (tester) async {
    await tester.pumpWidget(host(const BetaSurveyRow(url: 'https://forms.gle/abc')));
    await tester.tap(find.text('Beta survey'));
    await tester.pump();
    expect(calls.single.method, 'openUrl');
    expect(calls.single.arguments, {'url': 'https://forms.gle/abc'});
  });

  testWidgets('hidden until a survey URL is set', (tester) async {
    await tester.pumpWidget(host(const BetaSurveyRow(url: '')));
    expect(find.text('Beta survey'), findsNothing);
  });
}
