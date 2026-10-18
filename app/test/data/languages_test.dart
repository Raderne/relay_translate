import 'package:flutter_test/flutter_test.dart';
import 'package:relay_translate/data/languages.dart';

/// Phase 11: Arabic + French are the featured (pre-downloaded) targets; the rest are optional.
void main() {
  test('Arabic is a target with its native name', () {
    final ar = kLangs.singleWhere((l) => l.code == 'ar');
    expect(ar.name, 'Arabic');
    expect(ar.native, 'العربية');
    expect(langName('ar'), 'Arabic');
  });

  test('featured = Arabic, French; more = Spanish, German, Portuguese', () {
    expect(kFeaturedLangs.map((l) => l.code), ['ar', 'fr']);
    expect(kMoreLangs.map((l) => l.code), ['es', 'de', 'pt']);
    expect(kLangs.map((l) => l.code), ['ar', 'fr', 'es', 'de', 'pt']);
  });

  test('Arabic reads right to left, the others left to right', () {
    expect(isRtlLang('ar'), isTrue);
    for (final code in ['fr', 'es', 'de', 'pt', 'en', 'und']) {
      expect(isRtlLang(code), isFalse, reason: code);
    }
  });
}
