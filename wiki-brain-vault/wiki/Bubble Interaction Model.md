# Bubble Interaction Model

The single most important piece of behaviour. Implemented **twice** with identical numbers:
- Dart `app/lib/bubble/bubble_controller.dart` + `bubble_tokens.dart` (Chatter demo, Phase 5) — pure logic;
  covered by `test/bubble/bubble_controller_test.dart`.
- Kotlin `BubbleGesture.kt` (system overlay, Phase 7) — line-for-line port.
Each file must reference the other at the top; change both together.

## State machine
```
idle ──down──▶ pressing   (scale .94, ring fills 550 ms)
pressing ──550 ms──▶ translateAll → idle
pressing ──move ≥ 6 dp──▶ dragging (scale 1.08)
dragging ──over incoming message──▶ target (scale 1.18, fill accent-700, 2 dp outline on message)
dragging ──up──▶ snap? → translateOne(target) if any → idle
pressing ──up (<550 ms, <6 dp)──▶ toggle menu
```

## Numbers (from the prototype)
| | |
|---|---|
| Sizes | S 44 / M 52 / L 60; icon = 46% of size |
| Ring | radius size/2 + 4, 2 dp stroke accent-700, starts at 12 o'clock |
| Clamp | x ∈ [0, W−size]; y ∈ [36, H−size−30] |
| Snap | x = 6 or W−size−6 by which half the centre is in; animate 250 ms ease-out |
| Translate-all | ≥ 700 ms working state, incoming dimmed .35, 2 dp progress bar 650 ms |
| Flash | 900 ms outline on single translation |
| Toast | 3.5 s; one at a time |
| Menu | 190 dp; opens on the side away from the screen edge; top clamped [40, H−230] |
| Hint | first run only; hidden on first interaction |

## Rules
- Only **incoming** messages are drop targets.
- Hold when everything is translated = revert (toast "Showing original text").
- Bubble hidden while the detail sheet is open.
- Size change clamps x so the bubble stays on screen.

Links: [[Screens and Flows]], [[Android Overlay and Accessibility]], [[Flutter App]]
