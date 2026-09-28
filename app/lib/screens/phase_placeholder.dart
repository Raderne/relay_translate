import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Routes that land in a later phase. Keeps Home navigation wired without faking UI.
class PhasePlaceholderScreen extends StatelessWidget {
  const PhasePlaceholderScreen({required this.title, required this.phase, super.key});

  final String title;
  final String phase;

  static Widget history() => const PhasePlaceholderScreen(title: 'History', phase: '6');

  static Widget chatter() => const PhasePlaceholderScreen(title: 'Chatter', phase: '5');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  RelayButton.icon(
                    icon: const RelayIcon(RelayIcons.arrowLeft),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 12),
                  Text(title, style: RelayType.brand),
                ],
              ),
              const Spacer(),
              Text('$title ships in Phase $phase.', style: RelayType.bodyMuted, textAlign: TextAlign.center),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
