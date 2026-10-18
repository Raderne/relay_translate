import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_translate/data/settings_store.dart';
import 'package:relay_translate/screens/language_sheet.dart';
import 'package:relay_translate/theme/theme.dart';

void main() {

  Future<List<String?>> open(WidgetTester tester) async {
    final picked = <String?>[];
    await tester.pumpWidget(
      SettingsScope(
        store: SettingsStore.inMemory(),
        child: MaterialApp(
          theme: RelayTheme.data,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => picked.add(await showLanguageSheet(context)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return picked;
  }

  testWidgets('featured Arabic + French come before "More languages"', (tester) async {
    await open(tester);
    // Rows are Text.rich("Arabic العربية").
    double y(String t) => tester.getTopLeft(find.textContaining(t, findRichText: true).first).dy;
    expect(y('Arabic'), lessThan(y('French')));
    expect(y('French'), lessThan(y('More languages')));
    expect(y('More languages'), lessThan(y('Spanish')));
    expect(find.textContaining('العربية', findRichText: true), findsOneWidget);
  });

  testWidgets('the default (Arabic) is marked Selected; picking Spanish returns es', (tester) async {
    final picked = await open(tester);
    final arabicRow = find.ancestor(of: find.textContaining('Arabic', findRichText: true), matching: find.byType(Row));
    expect(find.descendant(of: arabicRow.first, matching: find.text('Selected')), findsOneWidget);
    await tester.tap(find.textContaining('Spanish', findRichText: true));
    await tester.pumpAndSettle();
    expect(picked, ['es']);
  });
}
