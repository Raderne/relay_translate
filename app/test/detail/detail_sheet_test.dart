import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_translate/detail/detail_sheet.dart';
import 'package:relay_translate/theme/theme.dart';

void main() {
  final taps = <String>[];
  final typed = <String>[];

  setUp(() {
    taps.clear();
    typed.clear();
  });

  Widget sheet({bool replyMode = false, String? replyTranslated, bool replyBusy = false}) {
    return MaterialApp(
      theme: RelayTheme.data,
      home: Scaffold(
        body: DetailSheet(
          kicker: 'English → French · WhatsApp',
          translation: 'Tu es libre ce soir ?',
          original: 'Are you free tonight?',
          replyMode: replyMode,
          replyFieldLabel: 'Your reply in French',
          replyTranslated: replyTranslated,
          replyLangLabel: 'English',
          replyBusy: replyBusy,
          translateLabel: 'Translate to English',
          pasteLabel: 'Paste into WhatsApp',
          onClose: () => taps.add('close'),
          onCopy: () => taps.add('copy'),
          onShowOriginal: () => taps.add('original'),
          onReply: () => taps.add('reply'),
          onReplyChanged: typed.add,
          onTranslateReply: () => taps.add('translate'),
          onPaste: () => taps.add('paste'),
        ),
      ),
    );
  }

  testWidgets('shows translation and original, and routes the three actions', (tester) async {
    await tester.pumpWidget(sheet());
    expect(find.text('Tu es libre ce soir ?'), findsOneWidget);
    expect(find.text('Are you free tonight?'), findsOneWidget);
    await tester.tap(find.text('Copy'));
    await tester.tap(find.text('Show original'));
    await tester.tap(find.text('Reply'));
    expect(taps, ['copy', 'original', 'reply']);
  });

  testWidgets('tapping the scrim or the X closes', (tester) async {
    await tester.pumpWidget(sheet());
    await tester.tap(find.byTooltip('Close'));
    await tester.tapAt(const Offset(10, 10));
    expect(taps, ['close', 'close']);
  });

  testWidgets('reply mode: typing, translating, paste disabled until translated', (tester) async {
    await tester.pumpWidget(sheet(replyMode: true));
    expect(find.text('Copy'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Oui');
    expect(typed.last, 'Oui');
    await tester.tap(find.text('Translate to English'));
    await tester.tap(find.text('Paste into WhatsApp'));
    expect(taps, ['translate']);
  });

  testWidgets('reply mode with a translation shows it and pastes', (tester) async {
    await tester.pumpWidget(sheet(replyMode: true, replyTranslated: "Yes, I'm free"));
    expect(find.text("Yes, I'm free"), findsOneWidget);
    await tester.tap(find.text('Paste into WhatsApp'));
    expect(taps, ['paste']);
  });

  testWidgets('busy reply shows Translating… and cannot be tapped', (tester) async {
    await tester.pumpWidget(sheet(replyMode: true, replyBusy: true));
    await tester.tap(find.text('Translating…'));
    expect(taps, isEmpty);
  });
}
