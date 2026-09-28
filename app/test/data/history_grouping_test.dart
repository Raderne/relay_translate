import 'package:flutter_test/flutter_test.dart';
import 'package:relay_translate/data/history_grouping.dart';
import 'package:relay_translate/data/history_models.dart';

void main() {
  test('groups Today and Yesterday headings', () {
    final clock = DateTime(2026, 3, 15, 14, 0);
    final today = DateTime(2026, 3, 15, 10).millisecondsSinceEpoch;
    final yesterday = DateTime(2026, 3, 14, 10).millisecondsSinceEpoch;
    final older = DateTime(2026, 3, 10, 10).millisecondsSinceEpoch;

    HistoryEntry e(int id, int createdAt) => HistoryEntry(
      id: id,
      src: 's',
      tr: 't',
      srcLang: 'en',
      targetLang: 'fr',
      appLabel: 'Chatter',
      createdAt: createdAt,
    );

    final groups = groupHistoryByDay(
      [e(1, today), e(2, yesterday), e(3, older)],
      clock: clock,
    );

    expect(groups.map((g) => g.heading), ['Today', 'Yesterday', 'Tue 10 Mar']);
    expect(groups[0].entries.length, 1);
  });
}
