import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_translate/theme/theme.dart';

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> assets) async {
    final loader = FontLoader(family);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }

  await load('Barlow', const [
    'assets/fonts/Barlow-Regular.ttf',
    'assets/fonts/Barlow-Medium.ttf',
    'assets/fonts/Barlow-SemiBold.ttf',
    'assets/fonts/Barlow-Bold.ttf',
  ]);
  await load('Barlow Condensed', const [
    'assets/fonts/BarlowCondensed-Regular.ttf',
    'assets/fonts/BarlowCondensed-SemiBold.ttf',
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadFonts);

  testWidgets('Blueprint golden', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: RelayColors.bg,
          body: Center(
            child: Padding(
              key: Key('frame'),
              padding: EdgeInsets.all(12),
              child: Blueprint(
                child: SizedBox(
                  width: 160,
                  height: 48,
                  child: Center(child: Text('Frame', style: TextStyle(fontFamily: RelayFonts.body))),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(find.byKey(const Key('frame')), matchesGoldenFile('goldens/blueprint.png'));
  });

  testWidgets('RelayButton.primary golden', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: RelayTheme.data,
        home: Scaffold(
          backgroundColor: RelayColors.bg,
          body: Center(
            child: Padding(
              key: const Key('button'),
              padding: const EdgeInsets.all(12),
              child: RelayButton.primary(label: 'Reply', onPressed: _noop),
            ),
          ),
        ),
      ),
    );
    await expectLater(find.byKey(const Key('button')), matchesGoldenFile('goldens/relay_button_primary.png'));
  });

  testWidgets('primary button wears four registration marks', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: RelayButton.primary(label: 'Reply', onPressed: _noop))),
      ),
    );
    expect(
      find.descendant(of: find.byType(Blueprint), matching: find.byType(CustomPaint)),
      findsNWidgets(4),
    );
    expect(find.text('Reply'), findsOneWidget);
  });
}

void _noop() {}
