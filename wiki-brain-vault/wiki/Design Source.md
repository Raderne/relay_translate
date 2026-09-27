# Design Source

The product was designed as an interactive prototype in Claude Design; it is the **behaviour spec**.

- Project: https://claude.ai/design/p/6b649521-bf3f-4a18-9b13-d97a697a53ff (file `Relay Translate.dc.html`).
- Local immutable copies: `wiki-brain-vault/raw/design/` (see `raw/README.md`).
  - `Relay Translate.dc.html` — markup for every screen + a `Component` class with all state/gesture logic.
  - `styles.css`, `readme.md` — the [[Design System - Industry]].
- Re-import: DesignSync `get_file` on the project, then save a *new dated* copy in `raw/` (never overwrite).

## What the prototype fakes (and the real app must do instead)
| Prototype | Real app |
|---|---|
| Hard-coded translations in `MSGS[].tr` | on-device ML Kit via `Translator.kt` ([[Translation Pipeline]]) |
| `window.claude.complete` for reply | same `Translator` with `target = source language` |
| — (not in design) | language-model download status on Home ("Downloading for offline use…") |
| Mock "Display over other apps" settings page | real Android settings intents ([[Privacy and Permissions]]) |
| Bubble only inside the fake Chatter app | native overlay over every app ([[Android Overlay and Accessibility]]) |
| "Replace" message text in the DOM | draw translated boxes over messages ([[Gotcha - No In-Place Text Replacement]]) |
| Source language always "English" | detected per message |

Links: [[Relay Translate]], [[Screens and Flows]], [[Bubble Interaction Model]]
