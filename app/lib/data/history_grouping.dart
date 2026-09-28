import 'package:intl/intl.dart';

import 'history_models.dart';

class HistoryDayGroup {
  const HistoryDayGroup({required this.heading, required this.entries});
  final String heading;
  final List<HistoryEntry> entries;
}

/// Groups [entries] (newest-first) under Today / Yesterday / `EEE d MMM`.
List<HistoryDayGroup> groupHistoryByDay(List<HistoryEntry> entries, {DateTime? clock}) {
  if (entries.isEmpty) return const [];

  final now = clock ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final dateFmt = DateFormat('EEE d MMM');

  final groups = <HistoryDayGroup>[];
  String? currentHeading;
  final bucket = <HistoryEntry>[];

  void flush() {
    if (bucket.isEmpty || currentHeading == null) return;
    groups.add(HistoryDayGroup(heading: currentHeading, entries: List.of(bucket)));
    bucket.clear();
  }

  for (final e in entries) {
    final dt = DateTime.fromMillisecondsSinceEpoch(e.createdAt);
    final day = DateTime(dt.year, dt.month, dt.day);
    final heading = day == today
        ? 'Today'
        : day == yesterday
        ? 'Yesterday'
        : dateFmt.format(day);

    if (heading != currentHeading) {
      flush();
      currentHeading = heading;
    }
    bucket.add(e);
  }
  flush();
  return groups;
}
