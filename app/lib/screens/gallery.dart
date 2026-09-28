import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../routes.dart';
import '../theme/theme.dart';
import 'spike_screen.dart';

/// Every design widget, in every state. Debug builds only — this stands in for Widgetbook.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  static const route = AppRoutes.gallery;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  var _on = true;
  var _size = 1;
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(kDebugMode, 'The gallery is compiled into debug builds only.');
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(RelaySpace.s6, RelaySpace.s4, RelaySpace.s6, RelaySpace.s8),
        children: [
          const Kicker('Type'),
          const SizedBox(height: RelaySpace.s2),
          Text('Translate inside any app', style: RelayType.h1),
          Text('Heading two', style: RelayType.h2),
          Text('Heading three', style: RelayType.h3),
          Text('Heading four', style: RelayType.h4),
          Text('Heading five', style: RelayType.h5),
          Text('Section'.toUpperCase(), style: RelayType.h6),
          const SizedBox(height: RelaySpace.s2),
          const Text('Body at 15 / 1.55. The bubble reads a message, then the translation stays on the phone.'),
          const SizedBox(height: RelaySpace.s6),
          const Kicker('Color'),
          const SizedBox(height: RelaySpace.s2),
          const _Ramp(name: 'Neutral', colors: RelayColors.neutral),
          const SizedBox(height: RelaySpace.s2),
          const _Ramp(name: 'Accent', colors: RelayColors.accentRamp),
          const SizedBox(height: RelaySpace.s6),
          const Kicker('Blueprint'),
          const SizedBox(height: RelaySpace.s3),
          const Blueprint(
            child: Padding(
              padding: EdgeInsets.all(RelaySpace.s4),
              child: Text('A line drawing. Marks sit outside the frame.'),
            ),
          ),
          const SizedBox(height: RelaySpace.s6),
          const Kicker('Buttons'),
          const SizedBox(height: RelaySpace.s3),
          Wrap(
            spacing: RelaySpace.s3,
            runSpacing: RelaySpace.s3,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              RelayButton.primary(label: 'Primary', onPressed: () {}),
              RelayButton.primary(label: 'Hover', onPressed: () {}, preview: RelayPreview.hover),
              RelayButton.primary(label: 'Pressed', onPressed: () {}, preview: RelayPreview.pressed),
              RelayButton.primary(label: 'Focused', onPressed: () {}, preview: RelayPreview.focused),
              RelayButton.primary(label: 'Disabled', onPressed: null),
              RelayButton.secondary(label: 'Secondary', onPressed: () {}),
              RelayButton.secondary(label: 'Hover', onPressed: () {}, preview: RelayPreview.hover),
              RelayButton.ghost(label: 'Ghost', onPressed: () {}),
              RelayButton.ghost(label: 'Hover', onPressed: () {}, preview: RelayPreview.hover),
              RelayButton.icon(icon: const RelayIcon(RelayIcons.arrowLeft), tooltip: 'Back', onPressed: () {}),
              RelayButton.icon(icon: const RelayIcon(RelayIcons.x), tooltip: 'Close', onPressed: () {}),
            ],
          ),
          const SizedBox(height: RelaySpace.s3),
          RelayButton.primary(label: 'Try it in Chatter', expand: true, onPressed: () {}),
          const SizedBox(height: RelaySpace.s6),
          const Kicker('Tag'),
          const SizedBox(height: RelaySpace.s2),
          const RelayTag.accent('EN → FR'),
          const SizedBox(height: RelaySpace.s6),
          const Kicker('Switch'),
          const SizedBox(height: RelaySpace.s2),
          Row(
            children: [
              const Expanded(child: Text('Show bubble over apps')),
              RelaySquareSwitch(value: _on, onChanged: (v) => setState(() => _on = v)),
            ],
          ),
          const SizedBox(height: RelaySpace.s2),
          const Row(
            children: [
              Expanded(child: Text('Disabled')),
              RelaySquareSwitch(value: false, onChanged: null),
            ],
          ),
          const SizedBox(height: RelaySpace.s6),
          const Kicker('Segmented'),
          const SizedBox(height: RelaySpace.s2),
          RelaySegmented(
            options: const ['S', 'M', 'L'],
            selected: _size,
            onChanged: (i) => setState(() => _size = i),
          ),
          const SizedBox(height: RelaySpace.s6),
          const Kicker('Input'),
          const SizedBox(height: RelaySpace.s2),
          RelayInput(controller: _input, label: 'Message', hint: 'Type a reply'),
          const SizedBox(height: RelaySpace.s6),
          const Kicker('Sheet'),
          const SizedBox(height: RelaySpace.s3),
          const RelaySheet(
            child: Padding(
              padding: EdgeInsets.all(RelaySpace.s4),
              child: Text('Paper ground, hairline along the top.'),
            ),
          ),
          const SizedBox(height: RelaySpace.s3),
          RelayButton.secondary(
            label: 'Open sheet',
            onPressed: () => RelaySheet.show(
              context,
              builder: (context) => Padding(
                padding: const EdgeInsets.fromLTRB(RelaySpace.s6, RelaySpace.s4, RelaySpace.s6, RelaySpace.s8),
                child: Text('Translate into', style: RelayType.h4),
              ),
            ),
          ),
          const SizedBox(height: RelaySpace.s6),
          const Kicker('Toast'),
          const SizedBox(height: RelaySpace.s3),
          RelayToast(
            message: '3 messages · English → French',
            actionLabel: 'Undo',
            onAction: () {},
          ),
          const SizedBox(height: RelaySpace.s3),
          RelayButton.secondary(
            label: 'Show toast',
            onPressed: () => RelayToast.show(context, message: 'Copied', actionLabel: 'Undo'),
          ),
          const SizedBox(height: RelaySpace.s6),
          const Kicker('Icons'),
          const SizedBox(height: RelaySpace.s2),
          const Wrap(
            spacing: RelaySpace.s4,
            runSpacing: RelaySpace.s3,
            children: [
              RelayIcon(RelayIcons.languages),
              RelayIcon(RelayIcons.arrowLeft),
              RelayIcon(RelayIcons.chevronRight),
              RelayIcon(RelayIcons.x),
              RelayIcon(RelayIcons.send),
              RelayIcon(RelayIcons.mic),
              RelayIcon(RelayIcons.wifi),
              RelayIcon(RelayIcons.battery),
            ],
          ),
          const SizedBox(height: RelaySpace.s8),
          RelayButton.ghost(
            label: 'ML Kit spike',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SpikeScreen())),
          ),
        ],
      ),
    );
  }
}

class _Ramp extends StatelessWidget {
  const _Ramp({required this.name, required this.colors});

  final String name;
  final Map<int, Color> colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name.toUpperCase(), style: RelayType.h6),
        const SizedBox(height: RelaySpace.s2),
        Row(
          children: [
            for (final step in colors.entries)
              Expanded(
                child: Column(
                  children: [
                    ColoredBox(color: step.value, child: const SizedBox(height: 36, width: double.infinity)),
                    const SizedBox(height: RelaySpace.s1),
                    Text('${step.key}', style: const TextStyle(fontSize: 10, fontFamily: RelayFonts.body)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
