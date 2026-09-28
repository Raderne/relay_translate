import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../bubble/bubble_controller.dart';
import '../bubble/bubble_tokens.dart';
import '../chatter/chatter_models.dart';
import '../chatter/chatter_session.dart';
import '../data/chatter_seed.dart';
import '../data/history_repository.dart';
import '../data/languages.dart';
import '../data/settings_store.dart';
import '../routes.dart';
import '../theme/theme.dart';
import 'home_screen.dart';

class ChatterScreen extends StatefulWidget {
  const ChatterScreen({super.key, this.historyRepository});

  /// When set (tests), skips async [HistoryRepository.open].
  final HistoryRepository? historyRepository;

  static const route = AppRoutes.chatter;

  @override
  State<ChatterScreen> createState() => _ChatterScreenState();
}

class _ChatterScreenState extends State<ChatterScreen> with TickerProviderStateMixin {
  ChatterSession? _session;
  BubbleController? _bubble;
  final _messageKeys = <String, GlobalKey>{};
  final _composer = TextEditingController();
  Stopwatch? _pressWatch;
  Ticker? _pressTicker;
  var _ringProgress = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_bootstrap()));
  }

  Future<void> _bootstrap() async {
    final settings = SettingsScope.of(context);
    final history = widget.historyRepository ?? await HistoryRepository.open();
    final session = ChatterSession(settings: settings, history: history);
    for (final m in session.messages) {
      _messageKeys[m.id] = GlobalKey();
    }
    final bubble = BubbleController(
      sizeCode: settings.size,
      snapEnabled: settings.snap,
      initialX: settings.bubbleX,
      initialY: settings.bubbleY,
      onTapMenu: () => setState(() {}),
      onTranslateAll: () => unawaited(session.translateAll()),
      onTranslateOne: (id) => unawaited(session.translateOne(id)),
      onInteraction: () => unawaited(_dismissHint()),
      onPositionPersist: (x, y) {
        final w = MediaQuery.sizeOf(context).width;
        unawaited(settings.setBubblePosition(x, y, screenWidth: w));
      },
    );
    if (!mounted) return;
    setState(() {
      _session = session;
      _bubble = bubble;
    });
  }

  Future<void> _dismissHint() async {
    if (SettingsScope.of(context).hintSeen) return;
    await SettingsScope.of(context).setHintSeen(true);
  }

  @override
  void dispose() {
    _pressTicker?.dispose();
    _bubble?.dispose();
    _session?.dispose();
    _composer.dispose();
    super.dispose();
  }

  Map<String, Rect> _incomingRects(ChatterSession session) {
    final map = <String, Rect>{};
    for (final m in session.incoming) {
      final box = _messageKeys[m.id]?.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final topLeft = box.localToGlobal(Offset.zero);
        map[m.id] = topLeft & box.size;
      }
    }
    return map;
  }

  void _pointerDown(PointerDownEvent e) {
    final session = _session;
    final bubble = _bubble;
    if (session == null || bubble == null) return;
    if (!SettingsScope.of(context).bubbleOn || session.detailMessageId != null) return;
    bubble.setIncomingTargets(_incomingRects(session));
    _pressWatch = Stopwatch()..start();
    bubble.pointerDown(e.position);
    _pressTicker?.dispose();
    _pressTicker = createTicker((_) {
      final ms = _pressWatch!.elapsedMilliseconds;
      bubble.tickPressing(ms);
      setState(() => _ringProgress = bubble.ringProgress(ms));
    });
    _pressTicker!.start();
  }

  void _pointerMove(PointerMoveEvent e) => _bubble?.pointerMove(e.position);

  void _pointerEnd(PointerEvent e) {
    final bubble = _bubble;
    final sw = _pressWatch;
    _pressTicker?.stop();
    _pressTicker?.dispose();
    _pressTicker = null;
    _pressWatch = null;
    _ringProgress = 0;
    if (bubble != null && sw != null) {
      bubble.pointerUp(elapsedMs: sw.elapsedMilliseconds, global: e.position);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final bubble = _bubble;
    if (session == null || bubble == null) {
      return const Scaffold(body: Center(child: Text('Loading…', style: RelayType.bodyMuted)));
    }

    final settings = SettingsScope.of(context);
    bubble.setViewport(MediaQuery.sizeOf(context));

    return ListenableBuilder(
      listenable: Listenable.merge([session, bubble, settings]),
      builder: (context, _) {
        final showBubble = settings.bubbleOn && session.detailMessageId == null;
        final showHint = showBubble && !settings.hintSeen;
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(onBack: () => Navigator.of(context).pop()),
                    _ProgressBar(visible: session.translating, progress: session.progress),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        children: [
                          Center(
                            child: Text('TODAY', style: RelayType.kicker.copyWith(color: RelayColors.neutral600)),
                          ),
                          const SizedBox(height: 10),
                          for (final m in session.messages)
                            _MessageBubble(
                              key: _messageKeys[m.id],
                              message: m,
                              targetLang: settings.targetLang,
                              dimmed: session.translating && m.incoming,
                              flash: session.flashMessageId == m.id,
                              onTap: m.incoming && m.isTranslated ? () => session.openDetail(m.id) : null,
                            ),
                        ],
                      ),
                    ),
                    _ComposerBar(controller: _composer, session: session),
                  ],
                ),
                if (session.toastMessage != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 92,
                    child: _ChatterToast(
                      message: session.toastMessage!,
                      action: session.toastAction,
                      onAction: session.toastOnAction,
                    ),
                  ),
                if (showBubble)
                  Positioned(
                    left: bubble.x,
                    top: bubble.y,
                    child: _BubbleView(
                      controller: bubble,
                      ringProgress: _ringProgress,
                      onDown: _pointerDown,
                      onMove: _pointerMove,
                      onUp: _pointerEnd,
                      onCancel: _pointerEnd,
                    ),
                  ),
                if (showBubble && bubble.phase == BubblePhase.menuOpen)
                  Positioned(
                    left: bubble.menuOrigin().dx,
                    top: bubble.menuOrigin().dy,
                    child: _BubbleMenu(
                      translateLabel: session.allIncomingTranslated ? 'Show original' : 'Translate screen',
                      langCode: settings.targetLang.toUpperCase(),
                      onTranslate: () {
                        bubble.dismissMenu();
                        unawaited(session.translateAll());
                      },
                      onLanguage: () {
                        bubble.dismissMenu();
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          HomeScreen.route,
                          (_) => false,
                          arguments: const HomeRouteArgs(openLanguageSheet: true),
                        );
                      },
                      onHistory: () {
                        bubble.dismissMenu();
                        Navigator.of(context).pushNamed(AppRoutes.history);
                      },
                      onHide: () async {
                        bubble.dismissMenu();
                        await settings.setBubbleOn(false);
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(HomeScreen.route, (_) => false);
                        }
                      },
                    ),
                  ),
                if (showHint)
                  Positioned(
                    left: bubble.hintOrigin().dx,
                    top: bubble.hintOrigin().dy,
                    child: const _BubbleHint(),
                  ),
                if (session.detailMessageId != null) _DetailSheet(session: session),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: RelayColors.divider))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          children: [
            RelayButton.icon(icon: const RelayIcon(RelayIcons.arrowLeft), onPressed: onBack, tooltip: 'Back'),
            const SizedBox(width: 12),
            DecoratedBox(
              decoration: BoxDecoration(border: Border.all(color: RelayColors.divider)),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Center(child: Text(kChatterPeerInitials, style: RelayType.sheetMark)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kChatterPeerName, style: RelayType.h4.copyWith(fontSize: 18)),
                  const Text('online', style: RelayType.messageMeta),
                ],
              ),
            ),
            Text('CHATTER', style: RelayType.kicker.copyWith(color: RelayColors.neutral600)),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.visible, required this.progress});
  final bool visible;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: visible
          ? FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0, 1),
              child: const ColoredBox(color: RelayColors.accent),
            )
          : null,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.message,
    required this.targetLang,
    required this.dimmed,
    required this.flash,
    this.onTap,
  });

  final ChatMessage message;
  final String targetLang;
  final bool dimmed;
  final bool flash;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final outgoing = message.outgoing;
    final borderColor = message.isTranslated ? RelayColors.accent : RelayColors.divider;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: dimmed && message.incoming ? 0.35 : 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: outgoing ? RelayColors.accent100 : null,
                border: Border.all(color: outgoing ? RelayColors.accent300 : borderColor, width: flash ? 2 : 1),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * (outgoing ? 0.78 : 0.8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.viaRelay && message.sentViaPair != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text('Sent via Relay · ${message.sentViaPair}', style: RelayType.messageTag),
                        ),
                      if (message.isTranslated && message.sourceLang != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            children: [
                              const RelayIcon(RelayIcons.languages, size: 11, color: RelayColors.accent700),
                              const SizedBox(width: 4),
                              Text(
                                'Translated · ${message.sourceLang!.toUpperCase()} → ${targetLang.toUpperCase()}',
                                style: RelayType.messageTag,
                              ),
                            ],
                          ),
                        ),
                      Text(message.shown, style: RelayType.message),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(message.time, style: RelayType.messageMeta),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({required this.controller, required this.session});
  final TextEditingController controller;
  final ChatterSession session;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: RelayColors.divider))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final hasDraft = controller.text.trim().isNotEmpty;
            return Row(
              children: [
                Expanded(child: RelayInput(controller: controller, hint: 'Message')),
                const SizedBox(width: 8),
                SizedBox(
                  width: 42,
                  height: 42,
                  child: RelayButton.primary(
                    label: ' ',
                    onPressed: hasDraft
                        ? () {
                            session.setDraft(controller.text);
                            session.sendDraft();
                            controller.clear();
                          }
                        : null,
                    icon: RelayIcon(
                      hasDraft ? RelayIcons.send : RelayIcons.mic,
                      size: 18,
                      color: RelayColors.bg,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BubbleView extends StatelessWidget {
  const _BubbleView({
    required this.controller,
    required this.ringProgress,
    required this.onDown,
    required this.onMove,
    required this.onUp,
    required this.onCancel,
  });

  final BubbleController controller;
  final double ringProgress;
  final void Function(PointerDownEvent) onDown;
  final void Function(PointerMoveEvent) onMove;
  final void Function(PointerEvent) onUp;
  final void Function(PointerEvent) onCancel;

  @override
  Widget build(BuildContext context) {
    final size = controller.diameter;
    final ringBox = size + BubbleTokens.ringPad * 2;
    final ringR = size / 2 + BubbleTokens.ringPad;
    final icon = size * BubbleTokens.iconFraction;
    return Listener(
      key: const Key('chatter-bubble'),
      onPointerDown: onDown,
      onPointerMove: onMove,
      onPointerUp: onUp,
      onPointerCancel: onCancel,
      child: Transform.scale(
        scale: controller.scale,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -BubbleTokens.ringPad,
                top: -BubbleTokens.ringPad,
                child: Transform.rotate(
                  angle: -math.pi / 2,
                  child: CustomPaint(
                    size: Size(ringBox, ringBox),
                    painter: _RingPainter(progress: ringProgress, radius: ringR),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: controller.fillAccent ? RelayColors.accent700 : RelayColors.accent,
                  border: Border.all(color: RelayColors.bg, width: 2),
                  boxShadow: RelayShadows.lg,
                ),
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Center(child: RelayIcon(RelayIcons.languages, size: icon, color: RelayColors.bg)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.radius});
  final double progress;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = RelayColors.accent700
      ..style = PaintingStyle.stroke
      ..strokeWidth = BubbleTokens.ringStroke;
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawArc(Rect.fromCircle(center: c, radius: radius), 0, 2 * math.pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

class _BubbleMenu extends StatelessWidget {
  const _BubbleMenu({
    required this.translateLabel,
    required this.langCode,
    required this.onTranslate,
    required this.onLanguage,
    required this.onHistory,
    required this.onHide,
  });

  final String translateLabel;
  final String langCode;
  final VoidCallback onTranslate;
  final VoidCallback onLanguage;
  final VoidCallback onHistory;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    return Blueprint(
      child: SizedBox(
        width: BubbleTokens.menuWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MenuRow(label: translateLabel, onTap: onTranslate),
            _MenuRow(
              label: 'Language',
              trailing: langCode,
              onTap: onLanguage,
            ),
            _MenuRow(label: 'History', onTap: onHistory),
            _MenuRow(label: 'Hide bubble', onTap: onHide, showDivider: false),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.label, required this.onTap, this.trailing, this.showDivider = true});
  final String label;
  final String? trailing;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: showDivider ? const Border(bottom: BorderSide(color: RelayColors.divider)) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Expanded(child: Text(label, style: RelayType.row)),
              if (trailing != null) Text(trailing!, style: RelayType.sheetMark),
            ],
          ),
        ),
      ),
    );
  }
}

class _BubbleHint extends StatelessWidget {
  const _BubbleHint();

  @override
  Widget build(BuildContext context) {
    return Blueprint(
      child: SizedBox(
        width: BubbleTokens.hintWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text.rich(
            TextSpan(
              style: RelayType.cardCaption.copyWith(fontSize: 13),
              children: [
                TextSpan(text: 'Hold', style: RelayType.h5.copyWith(fontSize: 15)),
                const TextSpan(text: ' to translate this screen. '),
                TextSpan(text: 'Drag', style: RelayType.h5.copyWith(fontSize: 15)),
                const TextSpan(text: ' onto a message to translate one.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatterToast extends StatelessWidget {
  const _ChatterToast({required this.message, this.action, this.onAction});
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: RelayColors.neutral900, boxShadow: RelayShadows.md),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(message, style: RelayType.toastOnDark),
            ),
            if (action != null)
              GestureDetector(
                onTap: onAction,
                child: Text(action!, style: RelayType.button.copyWith(color: RelayColors.accent300)),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailSheet extends StatefulWidget {
  const _DetailSheet({required this.session});
  final ChatterSession session;

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  final _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final m = session.messageById(session.detailMessageId);
    if (m == null) return const SizedBox.shrink();
    final settings = SettingsScope.of(context);
    final srcLang = m.sourceLang ?? 'und';
    final pair = '${langName(srcLang)} → ${langName(settings.targetLang)}';

    return Stack(
      children: [
        GestureDetector(
          onTap: session.closeDetail,
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
                        Expanded(child: Kicker('$pair · $kChatterLabel')),
                        RelayButton.icon(
                          icon: const RelayIcon(RelayIcons.x),
                          onPressed: session.closeDetail,
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    Text(m.display ?? m.src, style: RelayType.detailTranslation),
                    const SizedBox(height: 12),
                    Text('ORIGINAL', style: RelayType.h6.copyWith(color: RelayColors.neutral600)),
                    Text(m.src, style: RelayType.bodyMuted.copyWith(fontSize: 14)),
                    if (!session.detailReplyMode) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RelayButton.secondary(
                              label: 'Copy',
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: m.display ?? m.src));
                                session.markCopied();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RelayButton.secondary(
                              label: 'Show original',
                              onPressed: () {
                                session.revertMessage(m.id);
                                session.revertAllIncoming();
                                session.closeDetail();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RelayButton.primary(label: 'Reply', onPressed: session.startReply),
                          ),
                        ],
                      ),
                    ],
                    if (session.detailReplyMode) ...[
                      const SizedBox(height: 8),
                      RelayInput(
                        controller: _replyController,
                        label: 'Your reply in ${langName(settings.targetLang)}',
                        maxLines: 3,
                        onChanged: session.setReplyDraft,
                      ),
                      if (session.replyTranslated != null) ...[
                        const SizedBox(height: 8),
                        Blueprint(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Kicker(langName(srcLang)),
                                Text(session.replyTranslated!, style: RelayType.rowLabel),
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
                              label: session.replyBusy ? 'Translating…' : 'Translate to ${langName(srcLang)}',
                              onPressed: session.replyBusy ? null : () => unawaited(session.translateReply()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RelayButton.primary(
                              label: 'Paste into Chatter',
                              onPressed: session.replyTranslated == null
                                  ? null
                                  : () => session.pasteReply(session.replyTranslated!),
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
