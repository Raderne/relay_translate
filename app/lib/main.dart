import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'native/permissions.dart';
import 'screens/gallery.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding.dart';
import 'theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final permissions = Permissions();
  final status = await permissions.status();
  runApp(RelayApp(controller: PermissionsController(permissions, status)));
}

class RelayApp extends StatelessWidget {
  const RelayApp({required this.controller, super.key});

  final PermissionsController controller;

  @override
  Widget build(BuildContext context) {
    final start = controller.status.onboarded ? HomeScreen.route : Onboard1Screen.route;
    return RelayScope(
      controller: controller,
      child: MaterialApp(
        title: 'Relay Translate',
        theme: RelayTheme.data,
        initialRoute: start,
        routes: {
          Onboard1Screen.route: (_) => const Onboard1Screen(),
          Onboard2Screen.route: (_) => const Onboard2Screen(),
          HomeScreen.route: (_) => const HomeScreen(),
          if (kDebugMode) GalleryScreen.route: (_) => const GalleryScreen(),
        },
      ),
    );
  }
}
