import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dart:async';

import 'data/history_repository.dart';
import 'data/settings_store.dart';
import 'native/overlay_events.dart';
import 'native/permissions.dart';
import 'native/settings_bridge.dart';
import 'screens/gallery.dart';
import 'screens/home_screen.dart';
import 'routes.dart';
import 'screens/onboarding.dart';
import 'screens/chatter_screen.dart';
import 'screens/history_screen.dart';
import 'theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final permissions = Permissions();
  final permissionStatus = await permissions.status();
  final settings = await SettingsStore.open();
  await settings.adoptLegacyOnboardedFile(permissionStatus.onboarded);
  if (settings.onboarded) {
    await permissions.clearOnboardedFile();
  }
  final history = await HistoryRepository.open();
  await const NativeSettingsBridge().sync(settings);
  OverlayEvents.listen(history);
  runApp(
    RelayApp(
      controller: PermissionsController(permissions, permissionStatus),
      settings: settings,
    ),
  );
}

class RelayApp extends StatelessWidget {
  const RelayApp({required this.controller, required this.settings, super.key});

  final PermissionsController controller;
  final SettingsStore settings;

  @override
  Widget build(BuildContext context) {
    final start = settings.onboarded ? HomeScreen.route : Onboard1Screen.route;
    return RelayScope(
      controller: controller,
      child: SettingsScope(
        store: settings,
        child: MaterialApp(
          title: 'Relay Translate',
          theme: RelayTheme.data,
          initialRoute: start,
          routes: {
            Onboard1Screen.route: (_) => const Onboard1Screen(),
            Onboard2Screen.route: (_) => const Onboard2Screen(),
            HomeScreen.route: (_) => const HomeScreen(),
            AppRoutes.history: (_) => const HistoryScreen(),
            AppRoutes.chatter: (_) => const ChatterScreen(),
            if (kDebugMode) GalleryScreen.route: (_) => const GalleryScreen(),
          },
        ),
      ),
    );
  }
}
