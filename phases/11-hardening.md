# Phase 11 — Hardening

**Goal:** it survives real users: missing models, killed processes, long messages, TalkBack. Start from
the problems testers reported in Phase 10.

## Reliability
- Model downloads: retry once and resume after a failure; respect `wifi_only_downloads`. On mobile data with
  Wi-Fi-only on, show the toast "Connect to Wi-Fi to download German" (no spinner forever).
- Language detection `und`, or a wrong detection, → a "Translate from…" picker in the detail sheet so the
  user can override the source language.
- Service restart after process death (`START_STICKY`) restores bubble position/settings.
- Very long screens: cap a translate-all at the visible nodes, max ~50 texts per batch.
- If Phase 12 was built: cloud timeout 10 s → fall back to ML Kit; `429` → toast "Daily limit reached".

## Privacy
- Screen text is read only on hold/drop and is never logged (strip it from release logs).
- ML Kit path: text never leaves the device. Say so in onboarding and the privacy page.
- In-app **Privacy** row on Home → short explanation + "Clear history".
- Remove the beta feedback/export tools from the `prod` flavor (they export message text).
- Privacy policy page (required for Play; host as a static page).

## Storage / battery / performance
- Models ~30 MB each: show the total in Privacy/Storage, and add "Remove downloaded languages" if
  testers asked for it.
- No accessibility tree walks outside user actions (verify with the Android Studio profiler).
- Bubble idle = zero timers/animations; close unused ML Kit `Translator` clients.

## Accessibility (of Relay itself)
- Semantics labels on the bubble ("Relay translate bubble. Double-tap for menu, hold to translate screen"),
  switches, segmented control; 48 dp touch targets (the S bubble is 44, so extend its hit area invisibly).
- Text scales to 200% without clipping on Home/History/Detail.
- Contrast: accent on bg is only ~3:1 → use accent-700 for any body-size accent text (already in design).

## Tests
- App: controller tests, DB tests, a widget test per screen, golden tests for design widgets.
- Native: JVM tests for extractor/gesture/detection rule; re-run the manual matrix from Phase 8.
- Server (only if Phase 12 exists): `node --test` suite + purge job.

## Exit criteria
- [ ] All automated tests green; manual matrix re-run on 2 devices (Android 10 and 14+).
- [ ] Airplane mode, Wi-Fi-only download, and kill-process scenarios behave per above.
- [ ] Every issue from the tester feedback is fixed or ticketed.
