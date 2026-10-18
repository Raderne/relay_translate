import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dart:async';

import 'data/history_repository.dart';
import 'data/settings_store.dart';
import 'native/overlay.dart';
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
  final navigatorKey = GlobalKey<NavigatorState>();
  runApp(
    RelayApp(
      controller: PermissionsController(permissions, permissionStatus),
      settings: settings,
      navigatorKey: navigatorKey,
    ),
  );
  unawaited(OverlaySync(settings, navigatorKey).start());
}

/// Keeps the system bubble (Phase 7) and [SettingsStore] in step: pulls native state and the menu's
/// route on start + resume, pushes every settings change.
class OverlaySync with WidgetsBindingObserver {
  OverlaySync(this.settings, this.navigatorKey, {this.overlay = const BubbleOverlay()});

  final SettingsStore settings;
  final GlobalKey<NavigatorState> navigatorKey;
  final BubbleOverlay overlay;
  var _pulling = false;

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    await resync();
    settings.addListener(_push);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(resync());
  }

  Future<void> resync() async {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    _pulling = true;
    try {
      await overlay.pullInto(settings, screenWidth: view.physicalSize.width / view.devicePixelRatio);
    } finally {
      _pulling = false;
    }
    await overlay.apply(settings);
    final route = await overlay.takeRoute();
    if (route != null && settings.onboarded) _open(route);
  }

  void _push() {
    if (!_pulling) unawaited(overlay.apply(settings));
  }

  void _open(BubbleRoute route) {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open(route));
      return;
    }
    switch (route) {
      case BubbleRoute.language:
        nav.pushNamedAndRemoveUntil(
          HomeScreen.route,
          (_) => false,
          arguments: const HomeRouteArgs(openLanguageSheet: true),
        );
      case BubbleRoute.history:
        nav.pushNamed(AppRoutes.history);
    }
  }
}

class RelayApp extends StatelessWidget {
  const RelayApp({required this.controller, required this.settings, this.navigatorKey, super.key});

  final PermissionsController controller;
  final SettingsStore settings;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    final start = settings.onboarded ? HomeScreen.route : Onboard1Screen.route;
    return RelayScope(
      controller: controller,
      child: SettingsScope(
        store: settings,
        child: MaterialApp(
          navigatorKey: navigatorKey,
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
