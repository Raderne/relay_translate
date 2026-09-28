import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';
import 'type.dart';

/// Forces a hover, press, or focus look so the gallery can show every state.
enum RelayPreview { hover, pressed, focused }

/// Hairline frame plus "+" registration marks 11×11, offset −6, in text @ 55%.
class Blueprint extends StatelessWidget {
  const Blueprint({required this.child, this.borderColor = RelayColors.divider, this.fill, super.key});

  final Widget child;
  final Color borderColor;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: borderColor),
          ),
          child: child,
        ),
        const Positioned(top: -6, left: -6, child: _CornerMark()),
        const Positioned(top: -6, right: -6, child: _CornerMark()),
        const Positioned(bottom: -6, left: -6, child: _CornerMark()),
        const Positioned(bottom: -6, right: -6, child: _CornerMark()),
      ],
    );
  }
}

class _CornerMark extends StatelessWidget {
  const _CornerMark();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(size: Size(11, 11), painter: _CornerMarkPainter());
  }
}

class _CornerMarkPainter extends CustomPainter {
  const _CornerMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = RelayColors.mark
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.square;
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), paint);
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _Kind { primary, secondary, ghost, icon }

class RelayButton extends StatelessWidget {
  const RelayButton._({
    required this._kind,
    required this.onPressed,
    this.label,
    this.icon,
    this.expand = false,
    this.large = false,
    this.height,
    this.preview,
    super.key,
  });

  factory RelayButton.primary({
    required String label,
    required VoidCallback? onPressed,
    Widget? icon,
    bool expand = false,
    bool large = false,
    RelayPreview? preview,
    Key? key,
  }) => RelayButton._(
    key: key,
    kind: _Kind.primary,
    label: label,
    onPressed: onPressed,
    icon: icon,
    expand: expand,
    large: large,
    preview: preview,
  );

  factory RelayButton.secondary({
    required String label,
    required VoidCallback? onPressed,
    Widget? icon,
    bool expand = false,
    RelayPreview? preview,
    Key? key,
  }) => RelayButton._(
    key: key,
    kind: _Kind.secondary,
    label: label,
    onPressed: onPressed,
    icon: icon,
    expand: expand,
    preview: preview,
  );

  factory RelayButton.ghost({
    required String label,
    required VoidCallback? onPressed,
    Widget? icon,
    bool expand = false,
    double? height,
    RelayPreview? preview,
    Key? key,
  }) => RelayButton._(
    key: key,
    kind: _Kind.ghost,
    label: label,
    onPressed: onPressed,
    icon: icon,
    expand: expand,
    height: height,
    preview: preview,
  );

  factory RelayButton.icon({
    required Widget icon,
    required VoidCallback? onPressed,
    String? tooltip,
    RelayPreview? preview,
    Key? key,
  }) => RelayButton._(key: key, kind: _Kind.icon, label: tooltip, onPressed: onPressed, icon: icon, preview: preview);

  final _Kind _kind;
  final String? label;
  final Widget? icon;
  final VoidCallback? onPressed;
  final bool expand;

  /// 48 px tall, [RelayType.cta]. Onboard primary actions.
  final bool large;

  /// Fixed height for a ghost row such as Back (40).
  final double? height;
  final RelayPreview? preview;

  @override
  Widget build(BuildContext context) {
    final button = _Hit(
      onPressed: onPressed,
      preview: preview,
      builder: (flags) {
        final face = _face(flags);
        if (!expand) return face;
        return SizedBox(width: double.infinity, child: face);
      },
    );
    final enabled = onPressed != null;
    final shown = enabled ? button : Opacity(opacity: 0.45, child: button);
    final tip = _kind == _Kind.icon ? label : null;
    if (tip == null) return shown;
    return Tooltip(message: tip, child: shown);
  }

  Widget _face(_Flags flags) {
    final primary = _kind == _Kind.primary;
    final ghost = _kind == _Kind.ghost;
    final fg = primary
        ? RelayColors.bg
        : ghost
        ? RelayColors.accent
        : RelayColors.text;
    final fill = primary
        ? (flags.pressed
              ? RelayColors.accent700
              : flags.hovered
              ? RelayColors.accent600
              : RelayColors.accent)
        : ghost
        ? (flags.pressed
              ? RelayColors.accent18
              : flags.hovered
              ? RelayColors.accent10
              : Colors.transparent)
        : (flags.pressed
              ? RelayColors.text14
              : flags.hovered
              ? RelayColors.text7
              : Colors.transparent);

    if (_kind == _Kind.icon) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: RelayColors.divider),
        ),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(child: IconTheme(data: IconThemeData(color: fg, size: 20), child: icon!)),
        ),
      );
    }

    final fixedHeight = height ?? (large ? 48.0 : null);
    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ghost ? RelaySpace.s1 : RelaySpace.s3 * 1.2,
        vertical: fixedHeight == null ? RelaySpace.s2 : 0,
      ),
      child: Row(
        mainAxisSize: expand && fixedHeight == null ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            IconTheme(data: IconThemeData(color: fg, size: 18), child: icon!),
            const SizedBox(width: 6),
          ],
          Text(label ?? '', style: (large ? RelayType.cta : RelayType.button).copyWith(color: fg)),
        ],
      ),
    );
    final framedChild = fixedHeight == null
        ? content
        : SizedBox(height: fixedHeight, width: double.infinity, child: Center(child: content));

    if (primary) {
      return Blueprint(borderColor: RelayColors.accent, fill: fill, child: framedChild);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        border: ghost ? null : Border.all(color: RelayColors.divider),
      ),
      child: framedChild,
    );
  }
}

class RelayTag extends StatelessWidget {
  const RelayTag.accent(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: RelayColors.accent100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: RelayFonts.body,
            fontSize: 11,
            letterSpacing: 0.22,
            color: RelayColors.accent800,
          ),
        ),
      ),
    );
  }
}

class RelaySquareSwitch extends StatelessWidget {
  const RelaySquareSwitch({required this.value, required this.onChanged, super.key});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: value,
      enabled: onChanged != null,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Container(
          width: 40,
          height: 22,
          padding: const EdgeInsets.all(2),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: value ? RelayColors.accent : Colors.transparent,
            border: Border.all(color: RelayColors.divider),
          ),
          child: ColoredBox(
            color: value ? RelayColors.bg : RelayColors.neutral500,
            child: const SizedBox.square(dimension: 16),
          ),
        ),
      ),
    );
  }
}

class RelaySegmented extends StatelessWidget {
  const RelaySegmented({required this.options, required this.selected, required this.onChanged, super.key});

  final List<String> options;
  final int selected;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(border: Border.fromBorderSide(BorderSide(color: RelayColors.divider))),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 1, child: ColoredBox(color: RelayColors.divider)),
            _Hit(
              onPressed: onChanged == null ? null : () => onChanged!(i),
              builder: (flags) {
                final on = i == selected;
                return ColoredBox(
                  color: on
                      ? RelayColors.accent
                      : flags.pressed
                      ? RelayColors.text14
                      : flags.hovered
                      ? RelayColors.text7
                      : Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Text(
                      options[i],
                      style: TextStyle(
                        fontFamily: RelayFonts.body,
                        fontSize: 13,
                        color: on ? RelayColors.bg : RelayColors.text,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
        ),
      ),
    );
  }
}

class RelayInput extends StatefulWidget {
  const RelayInput({this.controller, this.label, this.hint, this.maxLines = 1, this.onChanged, super.key});

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  State<RelayInput> createState() => _RelayInputState();
}

class _RelayInputState extends State<RelayInput> {
  final _focus = FocusNode();
  var _hover = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _focus.hasFocus
        ? RelayColors.accent
        : _hover
        ? RelayColors.text45
        : RelayColors.divider;
    final field = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        maxLines: widget.maxLines,
        onChanged: widget.onChanged,
        cursorColor: RelayColors.accent,
        style: const TextStyle(fontFamily: RelayFonts.body, fontSize: 14, color: RelayColors.text),
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hint,
          hintStyle: const TextStyle(fontFamily: RelayFonts.body, fontSize: 14, color: RelayColors.neutral600),
          filled: true,
          fillColor: RelayColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: RelayColors.accent),
          ),
        ),
      ),
    );
    final label = widget.label;
    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: RelayFonts.body, fontSize: 12, color: RelayColors.text70),
        ),
        const SizedBox(height: 5),
        field,
      ],
    );
  }
}

/// Bottom sheet chrome: paper ground, 1 px divider along the top edge.
class RelaySheet extends StatelessWidget {
  const RelaySheet({required this.child, super.key});

  final Widget child;

  static Future<T?> show<T>(BuildContext context, {required WidgetBuilder builder}) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: RelayColors.bg,
      barrierColor: RelayColors.scrim,
      shape: const RoundedRectangleBorder(),
      builder: (context) => RelaySheet(child: builder(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: RelayColors.bg,
        border: Border(top: BorderSide(color: RelayColors.divider)),
      ),
      child: child,
    );
  }
}

/// Neutral-900 bar, neutral-100 message, optional accent-300 action. Stays 3.5 s.
class RelayToast extends StatelessWidget {
  const RelayToast({required this.message, this.actionLabel, this.onAction, super.key});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  static const duration = Duration(milliseconds: 3500);

  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        left: 12,
        right: 12,
        bottom: 92,
        child: RelayToast(
          message: message,
          actionLabel: actionLabel,
          onAction: () {
            entry.remove();
            onAction?.call();
          },
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(duration, () {
      if (entry.mounted) entry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: RelayColors.neutral900, boxShadow: RelayShadows.md),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: RelayFonts.body, fontSize: 13.5, color: RelayColors.neutral100),
              ),
            ),
            if (actionLabel != null)
              GestureDetector(
                onTap: onAction,
                child: Text(actionLabel!, style: RelayType.button.copyWith(color: RelayColors.accent300)),
              ),
          ],
        ),
      ),
    );
  }
}

class Kicker extends StatelessWidget {
  const Kicker(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: RelayType.kicker);
  }
}

class _Flags {
  const _Flags({required this.hovered, required this.pressed, required this.focused});

  final bool hovered;
  final bool pressed;
  final bool focused;
}

class _Hit extends StatefulWidget {
  const _Hit({required this.onPressed, required this.builder, this.preview});

  final VoidCallback? onPressed;
  final RelayPreview? preview;
  final Widget Function(_Flags flags) builder;

  @override
  State<_Hit> createState() => _HitState();
}

class _HitState extends State<_Hit> {
  var _hover = false;
  var _down = false;
  var _focus = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final flags = _Flags(
      hovered: widget.preview == RelayPreview.hover || _hover,
      pressed: widget.preview == RelayPreview.pressed || _down,
      focused: widget.preview == RelayPreview.focused || _focus,
    );
    return FocusableActionDetector(
      enabled: enabled,
      mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      shortcuts: enabled
          ? const {
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
            }
          : const {},
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed?.call();
            return null;
          },
        ),
      },
      onShowFocusHighlight: (value) => setState(() => _focus = value),
      onShowHoverHighlight: (value) => setState(() => _hover = value),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: widget.onPressed,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            widget.builder(flags),
            if (flags.focused)
              const Positioned(
                left: -4,
                top: -4,
                right: -4,
                bottom: -4,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(border: Border.fromBorderSide(BorderSide(color: RelayColors.accent, width: 2))),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
