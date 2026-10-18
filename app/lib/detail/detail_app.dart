import 'package:flutter/material.dart';

import '../data/languages.dart';
import '../theme/theme.dart';
import 'cross_app_detail.dart';
import 'detail_sheet.dart';

/// Root widget of `DetailActivity`'s own engine (entrypoint `detailMain` in main.dart): the detail sheet
/// over another app, on a transparent window.
class DetailApp extends StatefulWidget {
  const DetailApp({super.key, this.bridge = const DetailBridge()});

  final DetailBridge bridge;

  @override
  State<DetailApp> createState() => _DetailAppState();
}

class _DetailAppState extends State<DetailApp> {
  CrossAppDetailSession? _session;

  @override
  void initState() {
    super.initState();
    widget.bridge.args().then((args) {
      if (mounted) setState(() => _session = CrossAppDetailSession(args: args, bridge: widget.bridge));
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
                  );
                },
              ),
      ),
    );
  }
}
