import 'package:flutter/material.dart';

import '../data/history_repository.dart';
import '../data/languages.dart';
import '../native/beta.dart';
import '../theme/theme.dart';
import 'cross_app_detail.dart';
import 'detail_sheet.dart';

/// Root widget of `DetailActivity`'s own engine (entrypoint `detailMain` in main.dart): the detail sheet
/// over another app, on a transparent window.
class DetailApp extends StatefulWidget {
  DetailApp({super.key, this.bridge = const DetailBridge(), bool? beta}) : beta = beta ?? isBetaBuild;

  final DetailBridge bridge;

  /// Phase 10: 👎 writes to the same on-device history DB as the main app.
  final bool beta;

  @override
  State<DetailApp> createState() => _DetailAppState();
}

class _DetailAppState extends State<DetailApp> {
  CrossAppDetailSession? _session;

  @override
  void initState() {
    super.initState();
    widget.bridge.args().then((args) async {
      final history = widget.beta ? await HistoryRepository.open() : null;
      if (mounted) {
        setState(() => _session = CrossAppDetailSession(args: args, bridge: widget.bridge, history: history));
      }
    });
  }

  @override
  void dispose() {
    _session?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    return MaterialApp(
      theme: RelayTheme.data,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: s == null
            ? const SizedBox.shrink()
            : ListenableBuilder(
                listenable: s,
                builder: (context, _) {
                  final a = s.args;
                  final source = langName(a.source);
                  return DetailSheet(
                    kicker: '$source → ${langName(a.target)} · ${a.appLabel}',
                    translation: a.tr,
                    original: a.src,
                    translationLang: a.target,
                    originalLang: a.source,
                    replyMode: s.replyMode,
                    replyFieldLabel: 'Your reply in ${langName(a.target)}',
                    replyTranslated: s.replyTranslated,
                    replyLangLabel: source,
                    replyBusy: s.replyBusy,
                    translateLabel: 'Translate to $source',
                    pasteLabel: 'Paste into ${a.appLabel}',
                    onClose: s.close,
                    onCopy: s.copy,
                    onShowOriginal: s.showOriginal,
                    onReply: s.startReply,
                    onReplyChanged: s.setReplyDraft,
                    onTranslateReply: s.translateReply,
                    onPaste: s.paste,
                    flagged: s.flagged,
                    onFlag: s.history == null ? null : s.setFlag,
                    onNoteChanged: s.setNote,
                  );
                },
              ),
      ),
    );
  }
}
