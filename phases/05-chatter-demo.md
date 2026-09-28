# Phase 5 — Chatter demo + in-app bubble

**Goal:** the whole prototype interaction, inside the app, translating with on-device ML Kit (`Translator`, Phase 1). This is the
sandbox users try before trusting the system overlay, and it's where the gesture logic gets built and
tested before being ported to native in Phase 7.

## Chatter screen (raw design `isChat`)

- Header: back arrow, `SC` square avatar, "Sam Carter" / "online", right label `CHATTER`.
- 2 dp progress bar under header (accent, animates 0 → 100% over 650 ms while translating).
- "Today" divider, then the 6 seed messages (English incoming, French outgoing) — copy from raw design `MSGS`.
  Keep only `src`; translations now come from `Translator` (the hard-coded ones become reference translations to
  compare ML Kit against in the Phase 1 spike).
- Incoming bubble: square, 1 px divider border (accent when translated), 14.5 px, time bottom-right.
  Translated → tag line with languages icon "Translated · EN → FR".
- Outgoing: accent-100 fill, accent-300 border, right-aligned. Sent-via-Relay messages get
  "Sent via Relay · FR → EN".
- Composer: input (placeholder "Message"), square primary button — send icon if draft, mic icon if empty.
  Send appends the draft as an outgoing message.

## Bubble state machine (`app/lib/bubble/bubble_controller.dart`)

Pure Dart, no widgets, so Phase 7 can mirror it 1:1 in Kotlin and tests can drive it.

```
idle ──pointerDown──▶ pressing (scale .94, ring fills 550 ms)
pressing ──550 ms elapsed──▶ longPress → translateAll() → idle
pressing ──move ≥ 6 px──▶ dragging (scale 1.08)
dragging ──over incoming msg──▶ dragging+target (scale 1.18, fill accent-700, target outline)
dragging ──pointerUp──▶ snap (if on) → translateOne(target?) → idle
pressing ──pointerUp (<550 ms, <6 px)──▶ toggle menu
```

- Position clamped: x ∈ [0, W − size], y ∈ [36, H − size − 30]. Snap: x = 6 or W − size − 6 by which
  half the centre is in. Animate left/top 250 ms ease-out (not while dragging).
- Hit-testing in-app: each message widget registers a `GlobalKey`; target = message whose rect contains
  the pointer. Only incoming messages are targets.
- Persist final `bubble_x/bubble_y`.

## Actions

- **translateAll** (hold, or menu "Translate screen"):
  - If already all-translated → revert all, toast "Showing original text".
  - Else: dim incoming to .35 + progress bar; call `Translator.translate` with all incoming texts; keep the
    working state ≥ 700 ms so it doesn't flicker; swap texts; log to history; toast
    `"N messages · English → French"` with action **Show original**.
- **translateOne(id)** (drag-drop):
  - If already translated → open detail sheet instead.
  - Else translate that one, 900 ms accent outline flash, log history, toast
    `"Translated · English → French"` with **Undo**.
- Source-language label ("English") comes from the detected `source` returned by `Translator`, not hard-coded.
  `source = "und"` → keep original, toast "Couldn't detect language".
- History rows record `engine = 'mlkit'` and `ms` (time taken) for the Phase 10 evaluation.

## Menu (tap bubble)

Blueprint card 190 px, elevation md, placed left of the bubble if bubble is on the right half, else right;
top clamped to [40, H − 230]:
1. Translate screen / Show original
2. Language `FR` → Home with language sheet open
3. History
4. Hide bubble → bubble off, go Home

## Hint (first run only)

Blueprint card 200 px beside bubble: "**Hold** to translate this screen. **Drag** onto a message to
translate one." Hidden on first interaction; `hint_seen = 1`.

## Detail sheet (tap a translated message)

- Kicker "English → French · Chatter", close ✕.
- Translation 24 px Barlow Condensed; "Original" label + source 14 px.
- Buttons: **Copy** (→ "Copied", real clipboard) · **Show original** (revert that message, also exits
  translate-all) · **Reply** (primary).
- Reply mode: textarea "Your reply in French"; **Translate to English** (→ "Translating…", disabled while
  busy) calls `Translator.translate` with `target = message.source`; result shown in a Blueprint box labelled
  with the target language; **Paste into Chatter** (disabled until result) → sets composer draft, closes
  sheet, toast "Pasted into Chatter · tap send". Editing the text clears the result.
- Bubble hidden while the sheet is open.

## Toast

One at a time, 3.5 s, positioned above composer (bottom 92), action button optional.

## Errors (minimum for this phase)

Translator failure (model download failed, no network for a first-time model) → restore original
texts, toast "Couldn't translate · Retry". Model download in progress → toast "Downloading German
(~30 MB)…", then continue. No silent failures.

## Tests

- `bubble_controller_test.dart`: tap → menu; hold 550 ms → translateAll; move 5 px vs 7 px; snap left/right;
  clamp; drop on outgoing = no-op.
- Widget test: translateAll with a fake translator channel toggles texts and shows the toast.

## Exit criteria

- [ ] Every interaction in the prototype reproducible in the app, with real ML Kit translations, including in airplane mode.
- [ ] Changing language in Home changes the next translation target.
- [x] Controller tests pass.
- [ ] Wiki `Bubble Interaction Model` updated with any deviations from the prototype.
