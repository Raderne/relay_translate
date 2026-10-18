import 'package:flutter/material.dart';

import '../native/beta.dart';
import '../theme/theme.dart';

/// Home, beta flavor only (Phase 10): opens the tester survey.
class BetaSurveyRow extends StatelessWidget {
  const BetaSurveyRow({super.key, this.url = kBetaSurveyUrl, this.bridge = const BetaBridge()});

  final String url;
  final BetaBridge bridge;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => bridge.openUrl(url),
      child: const DecoratedBox(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: RelayColors.divider))),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(child: Text('Beta survey', style: RelayType.rowLabel)),
              Text('2 min', style: RelayType.cardCaption),
              SizedBox(width: 6),
              RelayIcon(RelayIcons.chevronRight, size: 16, color: RelayColors.neutral700),
            ],
          ),
        ),
      ),
    );
  }
}
