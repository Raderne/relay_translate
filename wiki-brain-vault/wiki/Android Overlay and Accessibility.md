# Android Overlay and Accessibility

Native Kotlin half of the app, in `app/android/app/src/main/kotlin/com/relay/relay_translate/`.
`Translator` + `TranslateChannel` landed in Phase 1. Phase 3 added `PermissionsChannel` (`relay/permissions`)
and an empty `RelayAccessibilityService` so onboarding can enable it. The bubble is still Phases 7–9.

## Pieces
| Class | Job | Phase |
|---|---|---|
| `Translator` + `TranslateChannel` | ML Kit translate + language-id, model downloads, `relay/translate` channel; shared by the service and Flutter ([[Translation Pipeline]]) | 1 ✅ |
| `BubbleService` | foreground service (`specialUse` type on Android 14+), owns overlay windows, notification with Hide | 7 |
| `BubbleView` / `BubbleGesture` | the bubble + ring; gesture port of [[Bubble Interaction Model]] | 7 |
| `MenuView`, `ToastView`, `HintView` | small overlay windows added on demand | 7 |
| `PermissionsChannel` | overlay + accessibility status, settings intents, `filesDir/onboarded` until Phase 4 | 3 ✅ |
| `RelayAccessibilityService` | on-demand tree read via [translateAllFromBubble] / [translateAtFromBubble]; invalidates overlays on window/scroll events | 8 ✅ |
| `MessageExtractor`, `MessageTreeWalker`, `AppRules` | `[{id, text, bounds}]`, noise filter, per-app view ids — see [[Per-App Message Rules]] | 8 ✅ |
| `TranslationLayer` | `TYPE_ACCESSIBILITY_OVERLAY` boxes + 2 dp progress line; `FLAG_NOT_TOUCHABLE` | 8 ✅ |
| `OverlayEventsChannel` | `relay/overlay/events` → Dart history (`translated`); buffer when engine dead | 8 ✅ |
| `NativeSettings` + `relay/settings` | target language + wifi-only for in-process `Translator` | 8 ✅ |
| `DetailActivity` | translucent Flutter activity hosting the detail/reply sheet over other apps | 9 |
| `Paster` | `ACTION_SET_TEXT` into the app's input; clipboard fallback; never sends | 9 |

## Rules
- Overlay window = bubble's own rect + `FLAG_NOT_FOCUSABLE`, so touches elsewhere reach the app.
- The service calls `Translator` in-process, so translation works when the Flutter engine is dead. (A cloud path to the [[Backend API]] is added only if Phase 12 is built.)
- Service keeps its own settings copy (SharedPreferences) for restart after process death — the only native storage.
- Hide bubble while Relay itself is foreground (in-app Chatter bubble takes over).

## Gotchas
- [[Gotcha - No In-Place Text Replacement]]
- [[Gotcha - Play Accessibility Policy]]
- [[Gotcha - Short Message Language Detection]]
- Message detection is heuristic and per-app; keep a test matrix (Phase 8 file) up to date here once filled.

Links: [[Architecture]], [[Flutter App]], [[Privacy and Permissions]]
