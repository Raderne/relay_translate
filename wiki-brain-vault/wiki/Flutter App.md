# Flutter App

Lives in `app/`. Android only, `minSdk 26`, flavors `beta` and `prod`.

`main.dart` opens `SettingsStore` (sqflite), migrates a legacy onboarded file if needed, then routes to
Onboard 1 or Home from `settings.onboarded`. Overlay/accessibility still come from `relay/permissions`.
`RelayTheme.data` wraps the app. The design-system gallery (`screens/gallery.dart`, [[Design System - Industry]])
is a debug-only route from Home (`/gallery`); the gallery still links to the ML Kit spike.

## Planned layout
```
app/lib/
├── main.dart
├── theme/     tokens + Blueprint widgets   → [[Design System - Industry]]
├── routes.dart
├── screens/   onboarding.dart, home_screen.dart, history_screen.dart, chatter_screen.dart, gallery (debug), spike
├── chatter/   chatter_session.dart, chatter_models.dart
├── bubble/    bubble_controller.dart, bubble_tokens.dart → [[Bubble Interaction Model]]
├── data/      db.dart, settings_store.dart, history_repository.dart, chatter_seed.dart, languages.dart → [[Database Schema]]
└── native/    translator.dart, permissions.dart (overlay.dart still planned)
```

## Conventions
- State: `ChangeNotifier` + `ListenableBuilder`; no Riverpod/Bloc unless a real need appears.
- Routing: plain `Navigator` named routes. Native opens routes via intent extras (`/home?sheet=lang`, `/history`).
- Settings + history in one sqflite DB; no `shared_preferences`.
- Fonts bundled (Barlow, Barlow Condensed); icons = Lucide SVGs at stroke 1.5.
- Translation is never done in Dart: always the `relay/translate` channel → `Translator.kt` ([[Translation Pipeline]]).
- Flavors: `beta` (tester feedback: flag, export) and `prod`.

## Channels (to native)
| Channel | Methods / events | Phase |
|---|---|---|
| `relay/translate` | `translate(texts, target)`, `ensureModel`, `modelStatus`, `deleteModel` | 1 |
| `relay/permissions` | `status` → `{overlay, accessibility, onboarded}`, `openOverlay`, `openAccessibility`, `clearOnboarded` | 3 ✅ |
| `relay/overlay` | `start(settings)`, `stop`, `update`, `isRunning` | 7 |
| `relay/overlay/events` | `positionChanged`, `menu:*`, `translated` | 7–8 |

Links: [[Architecture]], [[Screens and Flows]], [[Android Overlay and Accessibility]]
