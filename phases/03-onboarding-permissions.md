# Phase 3 — Onboarding + permissions

**Goal:** first-run flow from the prototype, wired to the *real* Android permission screens.

## Screens (see raw design `isOb1`, `isOb2`, `isPerm`)

### Onboard 1 — "Translate inside any app"
- Kicker `Relay · 1 of 2`, H1 40 px "Translate inside any app".
- Blueprint illustration (230 px): 4 message outlines, the 2nd one highlighted accent-100 with
  "Tu es bien arrivé ?", round accent bubble (44 px, languages icon, shadow-md) at right.
- Body 15 px neutral-800: "Relay puts a small bubble on top of WhatsApp, Telegram, email and any other
  app. Hold it to translate the whole screen, or drag it onto a single message."
- Primary blueprint button 48 px "Continue" pinned at bottom.

### Onboard 2 — "Let Relay appear on top of other apps"
- Kicker `Relay · 2 of 2`.
- Body: Android asks for the "Display over other apps" permission… Relay reads on-screen text only when
  you hold or drop the bubble.
- Numbered list (01 / 02, Barlow Condensed 18 px accent-700) with divider rules:
  - 01 Display over other apps — shows the bubble
  - 02 Screen text access — reads messages when you ask for a translation
- Primary "Open Android settings", ghost "Back".

### Permission step (real, replaces the prototype's fake settings screen)
The prototype mocks Android's settings page; in the app we launch the real one:

1. **Overlay**: `Settings.canDrawOverlays()` → if false, start
   `ACTION_MANAGE_OVERLAY_PERMISSION` with `package:` URI.
2. **Accessibility**: check if `RelayAccessibilityService` is enabled
   (`Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES`) → else open `ACTION_ACCESSIBILITY_SETTINGS`.
   **Before** this, show the prominent-disclosure dialog required by Play (Phase 13) — exact wording
   lives in the wiki `Privacy and Permissions`.
3. On `AppLifecycleState.resumed`, re-check both; when both granted → wait 650 ms → Home.
4. Partial grant: stay on Onboard 2, turn the granted row's number into a check, keep the button for the
   missing one.

A tiny `MethodChannel('relay/permissions')` in `MainActivity.kt`: `status()` → `{overlay, accessibility}`,
`openOverlay()`, `openAccessibility()`. The accessibility service class can be an empty stub until Phase 8.

## Routing

- First launch → Onboard 1. `settings.onboarded = true` once both permissions granted.
- Later launches → Home; if a permission was revoked, Home shows a warning row linking back to Onboard 2.
- Plain `Navigator` with named routes; no router package.

## Exit criteria

- [x] Fresh install walks Onboard 1 → 2 → real settings → back → Home automatically.
- [x] Revoking overlay permission in Android settings shows the warning on Home.
- [x] Back button behaviour matches prototype (Onboard 2 "Back" → Onboard 1).
- [x] Wiki `Screens and Flows` + `Privacy and Permissions` updated.
