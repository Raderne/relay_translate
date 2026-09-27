# Phase 9 — Detail sheet, reply and paste into other apps

**Goal:** tap a translated message in any app → see original, copy, or write a reply in your language
that gets translated back and pasted into the app's input field.

## Detail sheet over other apps

- `DetailActivity` (Flutter, `FlutterActivity` with transparent theme, `launchMode=singleTop`,
  `excludeFromRecents`) opened with `{src, tr, source, target, appLabel, appPackage}`.
- Reuses the Phase 5 `DetailSheet` widget unchanged; only the actions differ:
  - **Copy** → clipboard.
  - **Show original** → tells the service to remove that box.
  - **Reply** → reply mode; translate with `target = source` through the `relay/translate` channel (same
    `Translator.kt`). The source-language model is already on the device from the incoming translation.
  - **Paste into <App>** → service pastes (below), activity finishes, toast via overlay
    "Pasted into WhatsApp · tap send".
- Bubble hidden while the sheet is open (same as demo).

## Pasting (`Paster.kt`, in the accessibility service)

1. After the activity closes, wait for the target app to be foreground again.
2. Find the focused/first `isEditable` node in the app's window.
3. `ACTION_SET_TEXT` with the translated reply (appending to any existing draft? v1: replace only if
   empty, otherwise append with a space).
4. Fallback if no editable node or action fails: put text on clipboard, toast
   "Copied · long-press the message box to paste".
- Never press Send. The user always sends.

## Exit criteria

- [ ] WhatsApp: tap translated box → Reply → paste lands in the input, not sent.
- [ ] Apps where SET_TEXT fails fall back to clipboard with the toast.
- [ ] Wiki `Screens and Flows` gains the cross-app reply flow.
