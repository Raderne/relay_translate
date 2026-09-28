import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/history_grouping.dart';
import '../data/history_models.dart';
import '../data/history_repository.dart';
import '../routes.dart';
import '../theme/theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.repository});

  /// When set (tests), skips async [HistoryRepository.open].
  final HistoryRepository? repository;

  static const route = AppRoutes.history;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryRepository? _repo;
  List<HistoryDayGroup> _groups = const [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_load()));
  }

  Future<void> _load() async {
    final repo = widget.repository ?? await HistoryRepository.open();
    final entries = await repo.fetchAll();
    if (!mounted) return;
    setState(() {
      _repo = repo;
      _groups = groupHistoryByDay(entries);
      _loading = false;
    });
  }

  Future<void> _clear() async {
    final repo = _repo;
    if (repo == null) return;
    await repo.clear();
    if (!mounted) return;
    setState(() => _groups = const []);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: Text('Loading…', style: RelayType.bodyMuted)));
    }

    final empty = _groups.isEmpty;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                children: [
                  RelayButton.icon(
                    icon: const RelayIcon(RelayIcons.arrowLeft),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text('History', style: RelayType.brand)),
                  if (!empty)
                    RelayButton.ghost(label: 'Clear', onPressed: () => unawaited(_clear())),
                ],
              ),
            ),
            Expanded(
              child: empty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Blueprint(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nothing yet', style: RelayType.h4),
                              const SizedBox(height: 8),
                              const Text(
                                'Every message you translate with the bubble is saved here.',
                                style: RelayType.historySource,
                              ),
                              const SizedBox(height: 14),
                              RelayButton.secondary(
                                label: 'Open Chatter',
                                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.chatter),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      children: [
                        for (final group in _groups) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
                            child: Text(
                              group.heading.toUpperCase(),
                              style: RelayType.h6.copyWith(color: RelayColors.neutral700),
                            ),
                          ),
                          for (final entry in group.entries) _HistoryRow(entry: entry),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});
  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(entry.createdAt));
    return GestureDetector(
      onLongPress: () => Clipboard.setData(ClipboardData(text: entry.tr)),
      child: DecoratedBox(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: RelayColors.divider))),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.metaLine().toUpperCase(),
                      style: RelayType.kicker,
                    ),
                  ),
                  Text(time, style: RelayType.historyTime),
                ],
              ),
              const SizedBox(height: 4),
              Text(entry.tr, style: RelayType.historyTranslation),
              const SizedBox(height: 4),
              Text(entry.src, style: RelayType.historySource),
            ],
          ),
        ),
      ),
    );
  }
}
