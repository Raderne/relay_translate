# Deviations from Prototype

Recorded when the shipped app intentionally differs from `wiki-brain-vault/raw/design/`.

## Home translate-into card caption (Phase 4)

| Prototype | App |
|---|---|
| Always "From any language · detected automatically" | **Ready model:** "From any language · works offline". **Downloading:** "Downloading for offline use…". **Otherwise:** prototype line. |

Reason: the card reflects ML Kit model download state after the user picks a language (`Translator.ensureModel`).

Links: [[Screens and Flows]], [[Translation Pipeline]], [[Flutter App]]

## Update available sheet (Phase 13)

Not in the prototype. Bottom sheet on Home when a newer GitHub release exists: kicker "Update available",
"Version x.y.z", "Installed: …", release notes, buttons **Later** / **Update** (→ "Downloading n%" → **Install**).
Errors: "Couldn't download the update. Try again." / "Allow Relay to install apps, then tap Install."
See [[App Updates]].

## System overlay bubble (Phase 7)

No drop-target highlight while dragging over other apps, silent drops on nothing, smaller shadow, toast
without action. Details and reasons: [[Bubble Interaction Model]] → "System overlay deviations".

## No "Translated · EN → AR" line (2026-10-18, user decision)
Removed from translated boxes over other apps and from Chatter bubbles: redundant. The accent outline marks a
translated message; the pair is in the detail sheet kicker. Toasts keep it.

## Permission hints (1.0.0)
Not in the prototype: Onboard 2's overlay-list hint and restricted-settings help, and Home's "Turn on
notifications" sheet. See [[Privacy and Permissions]].

## Detail sheet over other apps (Phase 9)

| Prototype | App |
|---|---|
| Tapping a message keeps the other translations on screen | Tapping a translated box **clears all boxes**, then opens the sheet. Accessibility overlays draw above every activity, so they would cover the sheet. Hold again to re-translate. |
| Show original reverts that message | Closes the sheet (the boxes are already gone). |
| Toasts inside the chat | Native overlay toast (bubble running) or Android system toast. |

## Launch screen

The prototype's Launch screen shows the mark, "Relay", "Translate inside any app" and a 1.7 s loading line
("Starting" → "Loading languages"), then goes to Onboard 1 / Home after 1.9 s. The app uses the native
Android launch window, which can only show the mark on accent-900 — no wordmark, tagline or loading line,
and no forced 1.9 s wait. See [[Design System - Industry]] → "App icon and launch screen".
