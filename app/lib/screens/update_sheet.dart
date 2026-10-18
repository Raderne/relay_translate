import 'package:flutter/material.dart';

import '../native/updater.dart';
import '../theme/theme.dart';

/// "Update available" sheet: release notes, then download → system installer.
Future<void> showUpdateSheet(BuildContext context, UpdateInfo info, {Updater updater = const Updater()}) {
  return RelaySheet.show<void>(context, builder: (_) => _UpdateSheet(info: info, updater: updater));
}

class _UpdateSheet extends StatefulWidget {
  const _UpdateSheet({required this.info, required this.updater});

  final UpdateInfo info;
  final Updater updater;

  @override
  State<_UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<_UpdateSheet> {
  double? _progress; // non-null while downloading
  String? _apk; // set once downloaded
  String? _message;

  Future<void> _update() async {
    try {
      if (_apk == null) {
        setState(() {
          _progress = 0;
          _message = null;
        });
        final path = await widget.updater.download(widget.info.url!, (p) {
          if (mounted) setState(() => _progress = p);
        });
        if (!mounted) return;
        setState(() {
          _apk = path;
          _progress = null;
        });
      }
      final opened = await widget.updater.install(_apk!);
      if (!mounted) return;
      if (opened) {
        Navigator.pop(context);
      } else {
        setState(() => _message = 'Allow Relay to install apps, then tap Install.');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _progress = null;
          _message = "Couldn't download the update. Try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final progress = _progress;
    final label = progress != null
        ? 'Downloading ${(progress * 100).round()}%'
        : _apk != null
        ? 'Install'
        : 'Update';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Kicker('Update available'),
          const SizedBox(height: 4),
          Text('Version ${info.latest}', style: RelayType.h4),
          const SizedBox(height: 2),
          Text('Installed: ${info.current}', style: RelayType.cardCaption),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.4),
            child: SingleChildScrollView(child: ReleaseNotes(info.notes)),
          ),
          if (progress != null) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              color: RelayColors.accent,
              backgroundColor: RelayColors.accent18,
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!, style: RelayType.row),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: RelayButton.ghost(label: 'Later', expand: true, onPressed: () => Navigator.pop(context)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RelayButton.primary(label: label, expand: true, onPressed: progress == null ? _update : null),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Renders a CHANGELOG section: `### Heading`, `- bullet`, plain lines.
class ReleaseNotes extends StatelessWidget {
  const ReleaseNotes(this.markdown, {super.key});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final raw in markdown.split(RegExp(r'\r?\n'))) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#')) {
        if (children.isNotEmpty) children.add(const SizedBox(height: 10));
        children.add(Text(line.replaceFirst(RegExp(r'^#+\s*'), '').toUpperCase(), style: RelayType.h6));
        children.add(const SizedBox(height: 4));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        children.add(Text('•  ${line.substring(2)}', style: RelayType.body));
      } else {
        children.add(Text(line, style: RelayType.body));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}
