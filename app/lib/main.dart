import 'package:flutter/material.dart';

import 'screens/spike_screen.dart';

void main() {
  runApp(const RelayApp());
}

class RelayApp extends StatelessWidget {
  const RelayApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Phase 1: the ML Kit spike is the whole app. Real shell arrives in Phase 2.
    return const MaterialApp(title: 'Relay Translate', home: SpikeScreen());
  }
}
