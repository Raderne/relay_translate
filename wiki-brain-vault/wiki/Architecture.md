# Architecture

## Current plan: fully on-device (decided 2026-09-27)
```
┌──────────────────── Android device ───────────────────────────┐
│ Flutter UI (MainActivity)            Native Kotlin             │
│  onboarding · home · history   ◀──▶  BubbleService (overlay)   │
│  chatter demo · detail sheet   ch.   RelayAccessibilityService │
│  sqflite: settings, history          Translator.kt ── ML Kit   │
│         └── relay/translate channel ──▶  (translate + lang-id, │
│                                           models on device)    │
└────────────────────────────────────────────────────────────────┘
```
No server. Translation, language detection and history all stay on the phone.

## Backup plan (Phase 12, only if the tester beta says so)
`Translator.kt` gains a cloud path → **Node.js** (`node:http`) + **SQLite** (`node:sqlite`) proxy →
**Azure Translator**. See [[Backend API]].

## Repo layout (Phase 0, done)
- `app/` — Flutter project, Android only, `minSdk 26`, flavors `beta` (`com.relay.relay_translate.beta`) and `prod`; native code in `app/android/app/src/main/kotlin/com/relay/relay_translate/` → [[Flutter App]], [[Android Overlay and Accessibility]]
- `tools/` — team-only scripts (Phase 10 Azure comparison)
- `server/` — only if Phase 12 is built → [[Backend API]]
- `phases/` — build plan → [[Phases Roadmap]]
- `wiki-brain-vault/` — this vault → [[Wiki-Brain Setup]]

## Key decisions (and why)
- **Android only**: iOS doesn't allow overlays over other apps or reading their text.
- **ML Kit on-device first, Azure as measured fallback** (user decision 2026-09-27): free, offline, and
  message text never leaves the device. The trade-off is lower quality, which the tester beta measures
  ([[Translation Pipeline]]).
- **One translator, in Kotlin**: the overlay service must translate while the Flutter engine may be dead,
  so ML Kit lives in `Translator.kt` and Flutter calls it over a channel (no `google_mlkit_*` Dart plugins).
- **Native Kotlin overlay, not a second Flutter engine**: a lighter always-on bubble with full control of window touch flags.
- **Minimal deps**: `ChangeNotifier` (no state library), `sqflite`, `flutter_svg`; ML Kit translate + language-id on Android.

Links: [[Relay Translate]], [[Privacy and Permissions]]
