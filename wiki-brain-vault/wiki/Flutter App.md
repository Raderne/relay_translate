# Flutter App

Lives in `app/`. Android only, `minSdk 26`, flavors `beta` and `prod`.

Debug builds open `screens/gallery.dart` (the design-system gallery, [[Design System - Industry]]).
Release builds still open the ML Kit spike (`screens/spike_screen.dart`, [[Translation Pipeline]])
until the real screens land. `main.dart` applies `RelayTheme.data`.

## Planned layout
```
app/lib/
├── main.dart
├── theme/     tokens + Blueprint widgets   → [[Design System - Industry]]
├── screens/   onboarding, home, history, chatter, gallery (debug)
├── bubble/    bubble_controller.dart       → [[Bubble Interaction Model]]
├── data/      db.dart (sqflite)            → [[Database Schema]]
└── native/    translator.dart, overlay.dart, permissions.dart (MethodChannel/EventChannel)
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
| `relay/permissions` | `status`, `openOverlay`, `openAccessibility` | 3 |
| `relay/overlay` | `start(settings)`, `stop`, `update`, `isRunning` | 7 |
| `relay/overlay/events` | `positionChanged`, `menu:*`, `translated` | 7–8 |

Links: [[Architecture]], [[Screens and Flows]], [[Android Overlay and Accessibility]]
