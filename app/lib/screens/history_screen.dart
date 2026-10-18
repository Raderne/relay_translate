import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/history_grouping.dart';
import '../data/history_models.dart';
import '../data/history_repository.dart';
import '../data/languages.dart';
import '../native/beta.dart';
import '../routes.dart';
import '../theme/theme.dart';

class HistoryScreen extends StatefulWidget {
  HistoryScreen({super.key, this.repository, bool? beta, this.bridge = const BetaBridge()})
    : beta = beta ?? isBetaBuild;

  /// When set (tests), skips async [HistoryRepository.open].
  final HistoryRepository? repository;

  /// Phase 10 feedback tools: Export + 👎 per row.
  final bool beta;
  final BetaBridge bridge;

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

  Future<void> _toggleFlag(HistoryEntry e) async {
    final repo = _repo;
    if (repo == null) return;
    await repo.setFlag(
      src: e.src,
      tr: e.tr,
      srcLang: e.srcLang,
      targetLang: e.targetLang,
      appPackage: e.appPackage,
      appLabel: e.appLabel,
      flagged: !e.flagged,
    );
    final entries = await repo.fetchAll();
    if (mounted) setState(() => _groups = groupHistoryByDay(entries));
  }

  Future<void> _export() async {
    final repo = _repo;
    if (repo == null) return;
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: RelayColors.scrim,
      builder: (_) => const _ExportDialog(),
    );
    if (ok != true) return;
    final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
    await widget.bridge.shareJson(await repo.exportBetaJson(), fileName: 'relay-beta-feedback-$stamp.json');
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
                  if (!empty && widget.beta)
                    RelayButton.ghost(label: 'Export', onPressed: () => unawaited(_export())),
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
                          for (final entry in group.entries)
                            _HistoryRow(
                              entry: entry,
                              onFlag: widget.beta ? () => unawaited(_toggleFlag(entry)) : null,
                            ),
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
  const _HistoryRow({required this.entry, this.onFlag});
  final HistoryEntry entry;
  final VoidCallback? onFlag;

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
                  if (onFlag != null)
                    RelayButton.icon(
                      icon: RelayIcon(
                        RelayIcons.thumbsDown,
                        size: 16,
                        color: entry.flagged ? RelayColors.accent700 : RelayColors.neutral600,
                      ),
                      onPressed: onFlag,
                      tooltip: 'Flag bad translation',
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(entry.tr, style: RelayType.historyTranslation, textDirection: textDirectionFor(entry.targetLang)),
              const SizedBox(height: 4),
              Text(entry.src, style: RelayType.historySource, textDirection: textDirectionFor(entry.srcLang)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Export warning (Phase 10): the file holds real message text.
class _ExportDialog extends StatelessWidget {
  const _ExportDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Export beta feedback', style: RelayType.h4),
            const SizedBox(height: 8),
            const Text(
              'The file contains the text of your messages and their translations. '
              'Share it only with the Relay team.',
              style: RelayType.bodyMuted,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: RelayButton.ghost(label: 'Cancel', onPressed: () => Navigator.of(context).pop(false)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RelayButton.primary(label: 'Share file', onPressed: () => Navigator.of(context).pop(true)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
