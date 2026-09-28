# Gotcha — Play Accessibility Policy

## Symptom
Apps using `AccessibilityService` for non-accessibility purposes are frequently rejected or removed from
Google Play.

## Root cause
Play policy requires: accessibility use tied to core functionality, a **prominent in-app disclosure with
affirmative consent** before enabling, an Accessibility API declaration in Play Console (with video),
and honest `isAccessibilityTool` (Relay = false).

## Fix
- Disclosure dialog before opening accessibility settings (text in [[Privacy and Permissions]]).
- Read the tree only on explicit user action.
- Submit an internal-testing build with the declaration **right after Phase 8**, before polishing, so a
  rejection is discovered early.
- Fallback if rejected: distribute outside Play, or reduce to overlay + "share/copy text into Relay"
  (no accessibility) — a big UX downgrade; decide with the product owner.

## State (2026-09-28)
Disclosure dialog and `isAccessibilityTool=false` are in the app (Phase 3). The service is an empty
stub: it does not read the tree yet. The Play Console declaration and the internal-testing build are
still due right after Phase 8.

Links: [[Android Overlay and Accessibility]], [[Phases Roadmap]]
