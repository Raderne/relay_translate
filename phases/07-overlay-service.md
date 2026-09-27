# Phase 7 — System overlay bubble (native Android)

**Goal:** the bubble floats over **every** app, with the same gestures/visuals as the Chatter demo.

## Decision: native Kotlin overlay, Flutter for full-screen UI

| Option | Verdict |
|---|---|
| `flutter_overlay_window` (2nd Flutter engine in the overlay) | Rejected: one window, awkward resizing/touch pass-through, heavy memory for an always-on bubble. |
| **Native Kotlin `View`s in `WindowManager`** | **Chosen.** Small, fast, full control of touch flags. Bubble/ring/menu/toast/translated boxes are simple views. |
| Detail sheet + reply over other apps | Flutter, in a translucent `Activity` (Phase 9). |

## Components (`app/android/app/src/main/kotlin/com/relay/relay_translate/`)

- `BubbleService` — foreground service (`FOREGROUND_SERVICE_SPECIAL_USE` on Android 14+, with the
  `PROPERTY_SPECIAL_USE_FGS_SUBTYPE` explanation), persistent low-priority notification
  "Relay bubble is on" with a "Hide" action.
- `BubbleView` — circle (accent, 2 dp bg border, shadow), languages icon at 46% of size, progress ring
  (`Canvas.drawArc`, 550 ms), scale animations. Window params:
  `TYPE_APPLICATION_OVERLAY`, `FLAG_NOT_FOCUSABLE | FLAG_LAYOUT_NO_LIMITS`, `WRAP_CONTENT` — **only the
  bubble's own rect** so touches elsewhere pass to the app underneath.
- `BubbleGesture.kt` — **line-for-line port of `bubble_controller.dart`** (same thresholds: 550 ms,
  6 dp, clamps, 6 dp snap). Keep a comment at the top of both files pointing to each other.
- `MenuView`, `ToastView`, `HintView` — separate overlay windows, added/removed on demand.

## Flutter ↔ native bridge (`app/lib/native/overlay.dart`)

- `MethodChannel('relay/overlay')`: `start(settings)`, `stop()`, `update(settings)`, `isRunning()`.
  Settings = `{target, size, snap, x, y, hintSeen}`.
- `EventChannel('relay/overlay/events')`: `positionChanged`, `menu:language`, `menu:history`,
  `menu:hide`, `translated:[history items]` → Dart writes to sqflite.
- Service must survive the Flutter UI being closed: it keeps its own copy of settings (passed on
  start/update; stored in the service's own `SharedPreferences` for restart after process death — the
  one place native storage is allowed, because the Dart DB is not reachable when the engine is dead).

## Lifecycle

- Home "Show bubble over apps" on → `start`; off / menu "Hide bubble" → `stop`.
- Boot: optional `RECEIVE_BOOT_COMPLETED` restart — **skip in v1**, add if users ask.
- Hide the bubble when Relay's own app is in the foreground (the in-app Chatter bubble takes over).
- Hide on the lock screen / during full-screen video? v1: hide only when screen off.

## Menu over other apps

Same 4 items. "Language" and "History" launch `MainActivity` with an intent extra route
(`/home?sheet=lang`, `/history`).

## Exit criteria

- [ ] Bubble drags smoothly over the launcher, WhatsApp, Chrome; taps elsewhere reach the app below.
- [ ] Hold shows the ring and fires a (stub) translateAll event; drag/snap/clamp identical to demo.
- [ ] Killing the Flutter UI keeps the bubble alive; toggling off from notification works.
- [ ] Wiki `Android Overlay and Accessibility` written with the real class names.
