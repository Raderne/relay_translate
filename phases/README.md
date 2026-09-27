# Relay Translate — Build Phases

Source of truth for the product: the Claude Design prototype
(`wiki-brain-vault/raw/design/Relay Translate.dc.html`).

**Stack:** Flutter (Android) + native Kotlin + **Google ML Kit on-device translation** + sqflite.
**Backup plan:** Azure Translator behind a Node.js + SQLite backend (Phase 12). It's built only if the
tester beta (Phase 10) shows ML Kit quality isn't good enough.

Each phase is one file. A phase is **done** only when every box in its *Exit criteria* is ticked
and the wiki (`wiki-brain-vault/wiki/`) is updated.

| # | Phase | Outcome | Depends on |
|---|-------|---------|-----------|
| 0 | [Foundations](00-foundations.md) | Repo layout, toolchain, conventions | — |
| 1 | [On-device translation (ML Kit)](01-on-device-translation.md) | `Translator.kt` + Dart channel; offline translation works | 0 |
| 2 | [Flutter shell + design system](02-flutter-design-system.md) | Industry tokens + Blueprint widgets + gallery screen | 0 |
| 3 | [Onboarding + permissions](03-onboarding-permissions.md) | Onboard 1 → 2 → Android settings → Home | 2 |
| 4 | [Settings (Home) + local DB](04-settings-local-db.md) | Language sheet (+ model download), bubble toggles, size, persisted in sqflite | 1, 2 |
| 5 | [Chatter demo + in-app bubble](05-chatter-demo.md) | Full prototype behaviour inside the app, real ML Kit translations | 1, 4 |
| 6 | [History](06-history.md) | History list, dedupe, clear, empty state | 4, 5 |
| 7 | [System overlay bubble (native)](07-overlay-service.md) | Bubble floats over every app, same gestures as demo | 3, 5 |
| 8 | [Accessibility: read + overlay translations](08-accessibility-translate.md) | Hold/drag translate real WhatsApp/Telegram/email text | 7, 1 |
| 9 | [Reply + paste into other apps](09-reply-paste.md) | Detail sheet over other apps, reply, paste into field | 8 |
| 10 | [Tester beta + ML Kit evaluation](10-tester-beta.md) | Testers use it for real; **decision gate: ML Kit / hybrid / Azure** | 9 |
| 11 | [Hardening](11-hardening.md) | Errors, offline, privacy, battery, a11y, tests | 10 |
| 12 | [Azure backup (Node + SQLite)](12-azure-fallback.md) | **Conditional** on Phase 10: cloud engine behind the same `Translator` | 10 |
| 13 | [Release](13-release.md) | Play Store policy, signing (+ server deploy if Phase 12 was built) | 11 (12) |

## Critical path

`0 → 1 → 2 → 4 → 5 → 7 → 8 → 9 → 10 → 11 → 13`. Phases 3 and 6 can run in parallel with 5.
Phase 12 is only on the path if the Phase 10 decision requires it.

## Biggest risks (read before Phase 7)

1. **Android cannot rewrite text inside another app.** "Replace every message" is done by drawing
   translated boxes *over* each message's on-screen bounds. See wiki `Gotcha - No In-Place Text Replacement`.
2. **Google Play restricts AccessibilityService.** Needs a prominent disclosure + Play Console declaration.
   See wiki `Gotcha - Play Accessibility Policy`. The Phase 10 internal-testing upload surfaces this early.
3. **Message detection is heuristic per app.** WhatsApp/Telegram/Gmail node trees differ and change.
4. **ML Kit quality and language detection on short chat messages.** See wiki
   `Gotcha - Short Message Language Detection`. Phase 1 starts with a 1-day quality spike; Phase 10 measures it.

## Design numbers to preserve (from the prototype)

| Thing | Value |
|---|---|
| Hold-to-translate | 550 ms, progress ring fills around bubble |
| Drag threshold | 6 px before a press becomes a drag |
| Bubble sizes | S 44 / M 52 / L 60 dp |
| Edge snap margin | 6 dp |
| Vertical clamp | top ≥ 36 dp, bottom ≤ H − size − 30 dp |
| Translate-all "working" state | ~700 ms min, incoming messages dimmed to 0.35, 2 dp progress bar |
| Single-message flash | 2 dp accent outline, 900 ms |
| Toast | 3.5 s, with optional action (Undo / Show original) |
| Scale | pressing 0.94, dragging 1.08, over a target 1.18 (fill → accent-700) |
| Permission granted → Home | 650 ms delay |
| Target languages (v1) | French, Spanish, German, Portuguese; source auto-detected |
