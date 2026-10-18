import 'package:flutter/services.dart';

import '../data/settings_store.dart';

/// Where the system bubble's menu asked Relay to go (`MainActivity.EXTRA_ROUTE`).
enum BubbleRoute { language, history }

/// System overlay bubble (`relay/overlay` → `OverlayChannel.kt` / `BubbleService`, Phase 7).
///
/// Dart pushes settings with [apply]; the service keeps its own copy so it survives the Flutter engine.
/// What changed natively while Relay was away (drag, hint, "Hide") is pulled back with [pullInto].
class BubbleOverlay {
  const BubbleOverlay();

  static const channel = MethodChannel('relay/overlay');

  /// Starts, updates or stops the bubble to match [store]. Returns whether it is running.
  /// No-op before onboarding: sending "off" then would come back through [pullInto] as the user hiding it.
  Future<bool> apply(SettingsStore store) async {
    if (!store.onboarded) return false;
    final running = await channel.invokeMethod<bool>('apply', {
      'on': store.bubbleOn,
      'size': store.size,
      'snap': store.snap,
      'x': store.bubbleX,
      'y': store.bubbleY,
      'hintSeen': store.hintSeen,
    });
    return running ?? false;
  }

  /// Copies native bubble state into [store]. Call before [apply] so stale values are not pushed back.
  Future<void> pullInto(SettingsStore store, {required double screenWidth}) async {
    final state = await channel.invokeMapMethod<String, Object?>('state');
    if (state == null) return; // never started
    if (state['on'] == false && store.bubbleOn) await store.setBubbleOn(false);
    final x = (state['x']! as num).toDouble();
    final y = (state['y']! as num).toDouble();
    if (x != store.bubbleX || y != store.bubbleY) {
      await store.setBubblePosition(x, y, screenWidth: screenWidth);
    }
    if (state['hintSeen'] == true && !store.hintSeen) await store.setHintSeen(true);
  }

  /// The bubble menu's Language / History, once.
  Future<BubbleRoute?> takeRoute() async {
    final route = await channel.invokeMethod<String>('takeRoute');
    return switch (route) {
      'language' => BubbleRoute.language,
      'history' => BubbleRoute.history,
      _ => null,
    };
  }
}
