import 'dart:async';

import 'package:flutter/material.dart';

import '../data/settings_store.dart';
import '../native/permissions.dart';
import '../routes.dart';
import '../theme/theme.dart';

class Onboard1Screen extends StatelessWidget {
  const Onboard1Screen({super.key});

  static const route = AppRoutes.onboard1;

  @override
  Widget build(BuildContext context) {
    return _OnboardFrame(
      children: [
        const Kicker('Relay · 1 of 2'),
        const SizedBox(height: 22),
        Text('Translate inside any app', style: RelayType.onboardTitle),
        const SizedBox(height: 22),
        const _Illustration(),
        const SizedBox(height: 22),
        const Text(
          'Relay puts a small bubble on top of WhatsApp, Telegram, email and any other app. '
          'Hold it to translate the whole screen, or drag it onto a single message.',
          style: RelayType.bodyMuted,
        ),
        const Spacer(),
        const _Continue(),
      ],
    );
  }
}

class _Continue extends StatelessWidget {
  const _Continue();

  @override
  Widget build(BuildContext context) {
    return RelayButton.primary(
      label: 'Continue',
      large: true,
      expand: true,
      onPressed: () => Navigator.of(context).pushNamed(Onboard2Screen.route),
    );
  }
}

class Onboard2Screen extends StatefulWidget {
  const Onboard2Screen({super.key});

  static const route = AppRoutes.onboard2;

  @override
  State<Onboard2Screen> createState() => _Onboard2ScreenState();
}

class _Onboard2ScreenState extends State<Onboard2Screen> with WidgetsBindingObserver {
  var _gen = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_maybeLeave());
    });
  }

  @override
  void dispose() {
    _gen++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_maybeLeave());
  }

  Future<void> _maybeLeave() async {
    final gen = ++_gen;
    final scope = RelayScope.of(context);
    await scope.refresh();
    if (!mounted || gen != _gen || !scope.status.ready) return;
    final settings = SettingsScope.of(context);
    await settings.setOnboarded(true);
    await scope.permissions.clearOnboardedFile();
    scope.syncOnboardedFromSettings(true);
    await Future<void>.delayed(permissionGrantDelay);
    if (!mounted || gen != _gen) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
  }

  Future<void> _openSettings() async {
    final scope = RelayScope.of(context);
    switch (nextStep(scope.status)) {
      case PermissionStep.overlay:
        await scope.permissions.openOverlay();
      case PermissionStep.disclosure:
        final agreed = await showAccessibilityDisclosure(context);
        if (!agreed || !mounted) return;
        await scope.permissions.openAccessibility();
      case PermissionStep.home:
        await _maybeLeave();
    }
  }

  void _backToOnboard1() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.onboard1,
      (route) => route.settings.name == AppRoutes.home,
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = RelayScope.of(context).status;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToOnboard1();
      },
      child: _OnboardFrame(
        children: [
          const Kicker('Relay · 2 of 2'),
          const SizedBox(height: 22),
          Text('Let Relay appear on top of other apps', style: RelayType.onboardTitle),
          const SizedBox(height: 22),
          const Text(
            'Android asks for the "Display over other apps" permission before the bubble can show. '
            'Relay reads on-screen text only when you hold or drop the bubble.',
            style: RelayType.bodyMuted,
          ),
          const SizedBox(height: 22),
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: RelayColors.divider)),
            ),
            child: Column(
              children: [
                _PermRow(
                  number: '01',
                  label: 'Display over other apps — shows the bubble',
                  granted: status.overlay,
                ),
                _PermRow(
                  number: '02',
                  label: 'Screen text access — reads messages when you ask for a translation',
                  granted: status.accessibility,
                ),
              ],
            ),
          ),
          const Spacer(),
          RelayButton.primary(
            label: 'Open Android settings',
            large: true,
            expand: true,
            onPressed: () => unawaited(_openSettings()),
          ),
          const SizedBox(height: 8),
          RelayButton.ghost(label: 'Back', expand: true, height: 40, onPressed: _backToOnboard1),
        ],
      ),
    );
  }
}

class _OnboardFrame extends StatelessWidget {
  const _OnboardFrame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    return Blueprint(
      child: SizedBox(
        height: 230,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final inner = constraints.maxWidth - 52;
            return Stack(
              children: [
                Positioned(left: 26, top: 18, child: _outline(inner * 0.62)),
                Positioned(left: 26, top: 54, child: _highlight(inner * 0.52)),
                Positioned(right: 26, top: 90, child: _outline(inner * 0.55)),
                Positioned(left: 26, top: 126, child: _outline(inner * 0.70)),
                const Positioned(right: 26, top: 74, child: _Bubble()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _outline(double width) {
    return Container(
      width: width,
      height: 26,
      decoration: BoxDecoration(border: Border.all(color: RelayColors.divider)),
    );
  }

  Widget _highlight(double width) {
    return Container(
      width: width,
      height: 26,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: RelayColors.accent100,
        border: Border.all(color: RelayColors.accent),
      ),
      child: const Text('Tu es bien arrivé ?', maxLines: 1, overflow: TextOverflow.clip, style: RelayType.caption),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: RelayColors.accent,
        boxShadow: RelayShadows.md,
      ),
      child: const RelayIcon(RelayIcons.languages, size: 22, color: RelayColors.bg),
    );
  }
}

class _PermRow extends StatelessWidget {
  const _PermRow({required this.number, required this.label, required this.granted});

  final String number;
  final String label;
  final bool granted;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: RelayColors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: granted
                  ? RelayIcon(RelayIcons.check, key: Key('check-$number'), size: 18, color: RelayColors.accent700)
                  : Text(number, style: RelayType.step),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: RelayType.row)),
          ],
        ),
      ),
    );
  }
}

/// Prominent disclosure. Agree is the only path to accessibility settings.
Future<bool> showAccessibilityDisclosure(BuildContext context) async {
  final agreed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: RelayColors.scrim,
    builder: (context) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Screen text access', style: RelayType.h4),
              const SizedBox(height: 12),
              const Text(accessibilityDisclosure, style: RelayType.bodyMuted),
              const SizedBox(height: 20),
              RelayButton.primary(
                label: 'Agree',
                large: true,
                expand: true,
                onPressed: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 8),
              RelayButton.ghost(
                label: 'Not now',
                expand: true,
                height: 40,
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      );
    },
  );
  return agreed ?? false;
}
