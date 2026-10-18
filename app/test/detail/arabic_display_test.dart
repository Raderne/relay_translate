import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_translate/data/db.dart';
import 'package:relay_translate/data/history_repository.dart';
import 'package:relay_translate/detail/detail_sheet.dart';
import 'package:relay_translate/screens/history_screen.dart';
import 'package:relay_translate/theme/theme.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Phase 11: Arabic translations read right to left wherever they're shown.
void main() {
  const arabic = 'هل أنت متفرغ الليلة؟';
  const english = 'Are you free tonight?';

  TextDirection? dirOf(WidgetTester tester, String text) => tester.widget<Text>(find.text(text)).textDirection;

  Widget sheet({bool replyMode = false, String? replyTranslated}) => MaterialApp(
    theme: RelayTheme.data,
    home: Scaffold(
      body: DetailSheet(
        kicker: 'English → Arabic · WhatsApp',
        translation: arabic,
        original: english,
        translationLang: 'ar',
        originalLang: 'en',
        replyMode: replyMode,
        replyFieldLabel: 'Your reply in Arabic',
        replyTranslated: replyTranslated,
        replyLangLabel: 'English',
        replyBusy: false,
        translateLabel: 'Translate to English',
        pasteLabel: 'Paste into WhatsApp',
        onClose: () {},
        onCopy: () {},
        onShowOriginal: () {},
        onReply: () {},
        onReplyChanged: (_) {},
        onTranslateReply: () {},
        onPaste: () {},
      ),
    ),
  );

  testWidgets('detail sheet: Arabic translation RTL, English original LTR', (tester) async {
    await tester.pumpWidget(sheet());
    expect(dirOf(tester, arabic), TextDirection.rtl);
    expect(dirOf(tester, english), TextDirection.ltr);
  });

  testWidgets('detail sheet: the reply is typed in Arabic (RTL) and its translation is LTR', (tester) async {
    await tester.pumpWidget(sheet(replyMode: true, replyTranslated: "Yes, I'm free"));
    expect(tester.widget<TextField>(find.byType(TextField)).textDirection, TextDirection.rtl);
    expect(dirOf(tester, "Yes, I'm free"), TextDirection.ltr);
  });

  testWidgets('History: Arabic translation RTL, source LTR', (tester) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    late HistoryRepository repo;
    await tester.runAsync(() async {
      repo = HistoryRepository(await openRelayDatabase(path: ':memory:'));
      await repo.clear();
      await repo.logTranslation(src: english, tr: arabic, srcLang: 'en', targetLang: 'ar', ms: 30);
      await tester.pumpWidget(MaterialApp(theme: RelayTheme.data, home: HistoryScreen(repository: repo, beta: false)));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    expect(dirOf(tester, arabic), TextDirection.rtl);
    expect(dirOf(tester, english), TextDirection.ltr);
  });
}
