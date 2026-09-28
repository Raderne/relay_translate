# Screens and Flows

All from [[Design Source]]. Implementation phases in brackets.

## Screens
| Screen | Purpose | Phase |
|---|---|---|
| Onboard 1 | "Translate inside any app" + blueprint illustration → Continue | 3 ✅ |
| Onboard 2 | Explains 2 permissions (01 overlay, 02 screen text) → Open Android settings / Back | 3 ✅ |
| Android settings | real system screens (overlay, accessibility); auto-return to Home 650 ms after grant | 3 ✅ |
| Home (Settings) | Translate-into card → language sheet; Bubble: show/snap/size; History row; "Try it in Chatter" | 4 |
| Language sheet | French, Spanish, German, Portuguese (source auto-detected) | 4 |
| History | grouped by day, dedupe, Clear, empty state → Open Chatter | 6 |
| Chatter | in-app demo chat with the bubble; the sandbox | 5 |
| Detail sheet | translation + original; Copy / Show original / Reply → translate back → Paste | 5, 9 |

## Main flows
1. **First run** (Phase 3, in the app): Onboard 1 → Onboard 2 → real overlay settings → back to the app
   (row 01 becomes a check; accessibility is not opened automatically) → tap again → prominent disclosure
   → Agree opens accessibility settings, Not now stays on Onboard 2 → when both are granted, wait 650 ms →
   Home, and the onboard routes are removed. Back on Onboard 2 (button and system back) returns to Onboard 1.
   `onboarded` is a file in the app files dir until Phase 4. Home is only the wordmark plus a warning row
   until Phase 4; if overlay or accessibility is later revoked, that row links back to Onboard 2.
2. **Translate screen**: hold bubble 550 ms → all messages translated → toast "N messages · English → French" [Show original]. Hold again = originals.
3. **Translate one**: drag bubble onto a message → that message translated, flash outline, toast [Undo]. Dropping on an already-translated one opens the detail sheet.
4. **Reply**: tap translated message → Reply → write in your language → "Translate to English" → "Paste into <App>" → text in the app's input, user taps send.
5. **Bubble menu** (tap): Translate screen / Language (→ Home + sheet) / History / Hide bubble (→ Home, bubble off).

Gesture details: [[Bubble Interaction Model]]. Cross-app mechanics: [[Android Overlay and Accessibility]].

Links: [[Relay Translate]], [[Flutter App]]
