import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/gallery.dart';
import 'screens/spike_screen.dart';
import 'theme/theme.dart';

void main() {
  runApp(const RelayApp());
}

class RelayApp extends StatelessWidget {
  const RelayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Relay Translate',
      theme: RelayTheme.data,
      home: kDebugMode ? const GalleryScreen() : const SpikeScreen(),
    );
  }
}
