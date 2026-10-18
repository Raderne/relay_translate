# Android Overlay and Accessibility

Native Kotlin half of the app, in `app/android/app/src/main/kotlin/com/relay/relay_translate/`.
`Translator` + `TranslateChannel` landed in Phase 1. Phase 3 added `PermissionsChannel` (`relay/permissions`)
and an empty `RelayAccessibilityService` so onboarding can enable it. Phase 7 added the system bubble
(`bubble/` package); Phase 9 adds reply + paste.

## Pieces
| Class | Job | Phase |
|---|---|---|
| `Translator` + `TranslateChannel` | ML Kit translate + language-id, model downloads, `relay/translate` channel; shared by the service and Flutter ([[Translation Pipeline]]) | 1 ✅ |
| `bubble/BubbleService` | foreground service (`specialUse` on Android 14+), notification "Relay bubble is on" + Hide; owns the bubble/menu/hint/toast windows; hides while a Relay activity is resumed or the screen is off/locked | 7 ✅ code |
| `bubble/BubbleGesture` (+ `BubbleTokens`) | line-for-line port of `bubble_controller.dart`, pure Kotlin, JVM-tested (`BubbleGestureTest`) — [[Bubble Interaction Model]] | 7 ✅ |
| `bubble/BubbleViews.kt` | `BubbleView` (circle + ring), `BlueprintFrame`, `menuView`, `hintView`, `toastView` | 7 ✅ code |
| `bubble/BubblePrefs` | the service's own settings copy (`relay_bubble` SharedPreferences) | 7 ✅ |
| `OverlayChannel` (`relay/overlay`) | `apply` (start/update/stop), `state` (pull), `takeRoute` (menu Language/History) | 7 ✅ |
| `PermissionsChannel` | overlay + accessibility status, settings intents, `filesDir/onboarded` until Phase 4 | 3 ✅ |
| `RelayAccessibilityService` | on-demand tree read via [translateAllFromBubble] / [translateAtFromBubble]; invalidates overlays on window/scroll events | 8 ✅ |
| `MessageExtractor`, `MessageTreeWalker`, `AppRules` | `[{id, text, bounds}]`, noise filter, per-app view ids — see [[Per-App Message Rules]] | 8 ✅ |
| `TranslationLayer` | `TYPE_ACCESSIBILITY_OVERLAY` boxes + 2 dp progress line; Phase 9: one touchable window per box (tap → detail), progress line not touchable | 8 ✅ |
| `OverlayEventsChannel` | `relay/overlay/events` → Dart history (`translated`); buffer when engine dead | 8 ✅ |
| `NativeSettings` + `relay/settings` | target language + wifi-only for in-process `Translator` | 8 ✅ |
| `DetailActivity` (`relay/detail`) | transparent Flutter activity, own task + engine (`detailMain`); `args`, `paste`, `toast`, `close`; hides the bubble while resumed | 9 ✅ |
| `paste/Paster` + `PasteNode` | find field, merge draft, `ACTION_SET_TEXT`; pure, JVM-tested (`PasterTest`); `AccessibilityPasteNode` adapts real nodes | 9 ✅ |
| `paste/awaitForeground` | poll until the chat app is in front after the sheet closes (`AwaitForegroundTest`) | 9 ✅ |
| `accessibility/OverlayInvalidation` | when boxes clear: scroll in the translated app or any window-state change; never content changes or Relay's own windows (`OverlayInvalidationTest`) | 9 ✅ |

## Bubble ↔ Flutter sync (Phase 7)
- Dart `BubbleOverlay` (`lib/native/overlay.dart`) + `OverlaySync` in `main.dart`. Every `SettingsStore` change →
  `apply` (no-op before onboarding). On start and every resume Dart first **pulls** `state` (position, hint seen,
  "Hide" from menu/notification) into the store, then applies, then `takeRoute`.
- Pull instead of the planned `positionChanged` / `menu:*` events: it works whether the engine was alive or dead,
  so there is one path, not two.
- Menu Language / History start `MainActivity` with extra `relay_route`; Dart opens Home + language sheet or History.
- Hold / menu "Translate screen" → `RelayAccessibilityService.translateAllFromBubble`; when boxes are showing it
  reverts ("Showing original text"). Accessibility off → toast "Screen text access is off".
- Accessibility toasts go to the bubble's native toast when the service runs (Flutter can't show them over other apps).
- Android 13+: `apply` asks for `POST_NOTIFICATIONS` the first time it starts the service (needed for the Hide action).

## Rules
- Overlay window = bubble's own rect + `FLAG_NOT_FOCUSABLE`, so touches elsewhere reach the app.
- The service calls `Translator` in-process, so translation works when the Flutter engine is dead. (A cloud path to the [[Backend API]] is added only if Phase 12 is built.)
- Service keeps its own settings copy (SharedPreferences) for restart after process death — the only native storage.
- Hide bubble while Relay itself is foreground (in-app Chatter bubble takes over).
- Every overlay window is touchable (bubble, menu, hint, toast; tap dismisses hint/toast). Android 12+ blocks
  touches through *untrusted* `FLAG_NOT_TOUCHABLE` app overlays, so a pass-through toast would freeze the app below.
- `RelayColors.kt` / `RelayFonts` mirror `tokens.dart`; fonts load from the bundled `flutter_assets/assets/fonts/`.

## Bugs found on the first device run (2026-10-18, Phase 9)
- `RelayAccessibilityService` built `HistoryEventBuffer(this)` as a field → NPE (no Context yet) → crash the
  moment accessibility was enabled. Now `by lazy`.
- Boxes vanished instantly ("Scrolled · hold again"): every `TYPE_WINDOW_CONTENT_CHANGED` cleared them. Now
  [OverlayInvalidation] and the service no longer subscribes to content changes.
- App names showed as package names: Android 11 package visibility. Manifest `<queries>` for launcher apps
  (not `QUERY_ALL_PACKAGES`, which Play restricts).
- Compose apps report bare view ids — see [[Per-App Message Rules]].

## Gotchas
- [[Gotcha - No In-Place Text Replacement]]
- [[Gotcha - Play Accessibility Policy]]
- [[Gotcha - Short Message Language Detection]]
- Message detection is heuristic and per-app; keep a test matrix (Phase 8 file) up to date here once filled.

Links: [[Architecture]], [[Flutter App]], [[Privacy and Permissions]]
