import 'package:flutter/material.dart';

import '../data/languages.dart';
import '../data/settings_store.dart';
import '../theme/theme.dart';

/// "Translate into" picker from the Home screen prototype.
Future<String?> showLanguageSheet(BuildContext context) {
  final selected = SettingsScope.of(context).targetLang;
  return RelaySheet.show<String>(
    context,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Translate into', style: RelayType.h4),
            const SizedBox(height: 8),
            for (final lang in kLangs) _LangRow(lang: lang, selected: lang.code == selected),
          ],
        ),
      );
    },
  );
}

class _LangRow extends StatelessWidget {
  const _LangRow({required this.lang, required this.selected});

  final Lang lang;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return _SheetHit(
      onTap: () => Navigator.pop(context, lang.code),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: RelayColors.divider)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: lang.name, style: RelayType.sheetRow),
                      const TextSpan(text: ' '),
                      TextSpan(text: lang.native, style: RelayType.sheetNative),
                    ],
                  ),
                ),
              ),
              if (selected) Text('Selected', style: RelayType.sheetMark),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHit extends StatefulWidget {
  const _SheetHit({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_SheetHit> createState() => _SheetHitState();
}

class _SheetHitState extends State<_SheetHit> {
  var _hover = false;
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final fill = _pressed
        ? RelayColors.accent18
        : _hover
        ? RelayColors.accent100
        : Colors.transparent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: ColoredBox(color: fill, child: widget.child),
      ),
    );
  }
}
