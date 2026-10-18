import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Detail / reply sheet from the prototype. Pure view: used by Chatter (Phase 5) and over other apps in
/// `DetailActivity` (Phase 9); each passes its own actions.
class DetailSheet extends StatefulWidget {
  const DetailSheet({
    required this.kicker,
    required this.translation,
    required this.original,
    required this.replyMode,
    required this.replyFieldLabel,
    required this.replyTranslated,
    required this.replyLangLabel,
    required this.replyBusy,
    required this.translateLabel,
    required this.pasteLabel,
    required this.onClose,
    required this.onCopy,
    required this.onShowOriginal,
    required this.onReply,
    required this.onReplyChanged,
    required this.onTranslateReply,
    required this.onPaste,
    super.key,
  });

  /// "English → French · WhatsApp"
  final String kicker;
  final String translation;
  final String original;
  final bool replyMode;

  /// "Your reply in French"
  final String replyFieldLabel;
  final String? replyTranslated;

  /// Language the reply is translated into ("English").
  final String replyLangLabel;
  final bool replyBusy;

  /// "Translate to English"
  final String translateLabel;

  /// "Paste into WhatsApp"
  final String pasteLabel;
  final VoidCallback onClose;
  final VoidCallback onCopy;
  final VoidCallback onShowOriginal;
  final VoidCallback onReply;
  final ValueChanged<String> onReplyChanged;
  final VoidCallback onTranslateReply;
  final VoidCallback onPaste;

  @override
  State<DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<DetailSheet> {
  final _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    return Stack(
      children: [
        GestureDetector(
          onTap: w.onClose,
          child: const ColoredBox(color: RelayColors.scrim, child: SizedBox.expand()),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: RelayColors.bg,
            child: DecoratedBox(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: RelayColors.divider))),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Kicker(w.kicker)),
                        RelayButton.icon(
                          icon: const RelayIcon(RelayIcons.x),
                          onPressed: w.onClose,
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    Text(w.translation, style: RelayType.detailTranslation),
                    const SizedBox(height: 12),
                    Text('ORIGINAL', style: RelayType.h6.copyWith(color: RelayColors.neutral600)),
                    Text(w.original, style: RelayType.bodyMuted.copyWith(fontSize: 14)),
                    if (!w.replyMode) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: RelayButton.secondary(label: 'Copy', onPressed: w.onCopy)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RelayButton.secondary(label: 'Show original', onPressed: w.onShowOriginal),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: RelayButton.primary(label: 'Reply', onPressed: w.onReply)),
                        ],
                      ),
                    ],
                    if (w.replyMode) ...[
                      const SizedBox(height: 8),
                      RelayInput(
                        controller: _replyController,
                        label: w.replyFieldLabel,
                        maxLines: 3,
                        onChanged: w.onReplyChanged,
                      ),
                      if (w.replyTranslated != null) ...[
                        const SizedBox(height: 8),
                        Blueprint(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Kicker(w.replyLangLabel),
                                Text(w.replyTranslated!, style: RelayType.rowLabel),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RelayButton.secondary(
                              label: w.replyBusy ? 'Translating…' : w.translateLabel,
                              onPressed: w.replyBusy ? null : w.onTranslateReply,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RelayButton.primary(
                              label: w.pasteLabel,
                              onPressed: w.replyTranslated == null ? null : w.onPaste,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
