import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/languages.dart';
import '../data/settings_store.dart';
import '../native/permissions.dart';
import '../native/translator.dart';
import '../routes.dart';
import '../theme/theme.dart';
import 'gallery.dart';
import 'language_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.translator = const Translator()});

  static const route = AppRoutes.home;

  final Translator translator;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  ModelStatus? _modelStatus;
  Timer? _modelPoll;
  var _historyToday = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_refreshModelStatus());
      unawaited(_loadHistoryCount());
    });
  }

  @override
  void dispose() {
    _modelPoll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(RelayScope.of(context).refresh());
      unawaited(_refreshModelStatus());
      unawaited(_loadHistoryCount());
    }
  }

  Future<void> _loadHistoryCount() async {
    final count = await SettingsScope.of(context).historyCountToday();
    if (mounted) setState(() => _historyToday = count);
  }

  Future<void> _refreshModelStatus() async {
    final settings = SettingsScope.of(context);
    final status = await widget.translator.modelStatus(settings.targetLang);
    if (!mounted) return;
    setState(() => _modelStatus = status);
    _modelPoll?.cancel();
    if (status == ModelStatus.downloading) {
      _modelPoll = Timer.periodic(const Duration(seconds: 1), (_) => unawaited(_refreshModelStatus()));
    }
  }

  Future<void> _pickLanguage() async {
    final code = await showLanguageSheet(context);
    if (code == null || !mounted) return;
    final settings = SettingsScope.of(context);
    await settings.setTargetLang(code);
    unawaited(widget.translator.ensureModel(code, wifiOnly: settings.wifiOnlyDownloads));
    await _refreshModelStatus();
  }

  String _cardCaption() {
    switch (_modelStatus) {
      case ModelStatus.downloading:
        return 'Downloading for offline use…';
      case ModelStatus.ready:
        return 'From any language · works offline';
      case ModelStatus.missing:
      case null:
        return 'From any language · detected automatically';
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = RelayScope.of(context);
    final settings = SettingsScope.of(context);
    final warning = permissionWarning(permissions.status);
    final lang = kLangs.firstWhere((l) => l.code == settings.targetLang);
    final width = MediaQuery.sizeOf(context).width;
    final histLabel = _historyToday == 0 ? 'Empty' : '$_historyToday today';

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Text('Relay', style: RelayType.brand),
                      const Spacer(),
                      RelayTag.accent(settings.bubbleOn ? 'Bubble on' : 'Bubble off'),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (warning != null) ...[
                          _WarningRow(
                            text: warning,
                            onTap: () => Navigator.of(context).pushNamed(AppRoutes.onboard2),
                          ),
                          const SizedBox(height: 24),
                        ],
                        _TranslateCard(
                          langName: lang.name,
                          caption: _cardCaption(),
                          onTap: () => unawaited(_pickLanguage()),
                        ),
                        const SizedBox(height: 24),
                        Text('Bubble', style: RelayType.h6.copyWith(color: RelayColors.neutral700)),
                        const SizedBox(height: 4),
                        _SettingsRow(
                          label: 'Show bubble over apps',
                          child: RelaySquareSwitch(
                            value: settings.bubbleOn,
                            onChanged: (v) => unawaited(settings.setBubbleOn(v)),
                          ),
                        ),
                        _SettingsRow(
                          label: 'Snap to screen edge',
                          child: RelaySquareSwitch(
                            value: settings.snap,
                            onChanged: (v) => unawaited(settings.setSnap(v)),
                          ),
                        ),
                        _SettingsRow(
                          label: 'Size',
                          child: RelaySegmented(
                            options: const ['S', 'M', 'L'],
                            selected: switch (settings.size) {
                              'S' => 0,
                              'L' => 2,
                              _ => 1,
                            },
                            onChanged: (i) {
                              final size = switch (i) {
                                0 => 'S',
                                2 => 'L',
                                _ => 'M',
                              };
                              unawaited(settings.setSize(size, screenWidth: width));
                            },
                          ),
                        ),
                        _HistoryRow(
                          label: histLabel,
                          onTap: () => Navigator.of(context).pushNamed(AppRoutes.history),
                        ),
                        if (kDebugMode) ...[
                          const SizedBox(height: 24),
                          RelayButton.ghost(
                            label: 'Gallery',
                            expand: true,
                            height: 40,
                            onPressed: () => Navigator.of(context).pushNamed(GalleryScreen.route),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: RelayButton.primary(
                    label: 'Try it in Chatter',
                    large: true,
                    expand: true,
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.chatter),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TranslateCard extends StatefulWidget {
  const _TranslateCard({required this.langName, required this.caption, required this.onTap});

  final String langName;
  final String caption;
  final VoidCallback onTap;

  @override
  State<_TranslateCard> createState() => _TranslateCardState();
}

class _TranslateCardState extends State<_TranslateCard> {
  var _hover = false;
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final fill = _pressed
        ? RelayColors.accent18
        : _hover
        ? RelayColors.accent100
        : Colors.transparent;
    return Semantics(
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: Blueprint(
            fill: fill,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Kicker('Translate into'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(child: Text(widget.langName, style: RelayType.langDisplay)),
                      Text('Change', style: RelayType.button.copyWith(color: RelayColors.accent700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(widget.caption, style: RelayType.cardCaption),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: RelayColors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(child: Text(label, style: RelayType.rowLabel)),
            child,
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatefulWidget {
  const _HistoryRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_HistoryRow> createState() => _HistoryRowState();
}

class _HistoryRowState extends State<_HistoryRow> {
  var _hover = false;
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final fill = _pressed
        ? RelayColors.accent18
        : _hover
        ? RelayColors.accent100
        : Colors.transparent;
    return Semantics(
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: ColoredBox(
            color: fill,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: RelayColors.divider)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Expanded(child: Text('History', style: RelayType.rowLabel)),
                    Text(widget.label, style: RelayType.cardCaption),
                    const SizedBox(width: 6),
                    const RelayIcon(RelayIcons.chevronRight, size: 16, color: RelayColors.neutral700),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WarningRow extends StatelessWidget {
  const _WarningRow({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('permission-warning'),
      onTap: onTap,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: RelayColors.divider),
            bottom: BorderSide(color: RelayColors.divider),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Expanded(child: Text(text, style: RelayType.row)),
              const SizedBox(width: 10),
              const RelayIcon(RelayIcons.chevronRight, size: 18, color: RelayColors.accent700),
            ],
          ),
        ),
      ),
    );
  }
}
