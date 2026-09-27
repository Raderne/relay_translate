# Relay Translate

Android app: a floating bubble over any app that translates on-screen messages (hold = whole screen,
drag = one message, tap = copy / reply-and-paste). Flutter UI + native Kotlin overlay/accessibility
services + **on-device Google ML Kit translation**. Azure Translator behind a Node.js + SQLite backend
is the backup plan (Phase 12), built only if the tester beta (Phase 10) says ML Kit isn't good enough.

- Behaviour spec: `wiki-brain-vault/raw/design/Relay Translate.dc.html` (Claude Design prototype).
- Build plan: `phases/README.md` — work **one phase at a time**; a phase is done only when all of its
  exit criteria pass.
- Architecture & decisions: `wiki-brain-vault/wiki/index.md`.

## Layout
```
app/        Flutter (Android only, minSdk 26); native code in app/android/app/src/main/kotlin/
            (Translator.kt = ML Kit; flavors: beta, prod)
tools/      team-only scripts (Phase 10 Azure comparison)
server/     ONLY if Phase 12: Node.js ≥ 22.5 (node:http, node:sqlite, node --test) → Azure Translator
phases/     phase-by-phase plan
wiki-brain-vault/   knowledge base (see below)
```

## Commands
| What | Command |
|---|---|
| Run app | `cd app && flutter run --flavor beta` |
| App checks | `cd app && flutter analyze && flutter test` |
| Server (Phase 12 only) | `cd server && node --env-file=.env src/index.js` / `node --test` |

(`app/` is created in Phase 0.)

## Hard rules
1. **Match the prototype.** Copy text, timings and sizes come from the design (see wiki
   `Bubble Interaction Model`). Deviations get recorded in the wiki.
2. **Design tokens only.** No hex colours or font names outside `app/lib/theme/` (and the Kotlin mirror
   `RelayColors.kt`). Square corners, blueprint corner marks, Lucide icons at stroke 1.5.
3. **Bubble logic lives in two places** — `app/lib/bubble/bubble_controller.dart` and `BubbleGesture.kt`.
   Change both in the same commit.
4. **Privacy promises are code requirements:** read screen text only on hold/drop; never auto-send a
   reply; with ML Kit, message text never leaves the device; history stays on-device. (If Phase 12
   ships: the server stores only hashes of source text.)
5. **One translation path.** All translation goes through `Translator.kt`; Dart calls it over the
   `relay/translate` channel and never talks to ML Kit or any translation API directly.
6. **Minimal dependencies.** Stdlib/platform first. Ask before adding any package to `pubspec.yaml`,
   `build.gradle`, or `server/package.json`.
7. **Secrets** (`AZURE_TRANSLATOR_KEY`, etc.) live only in `.env` files, never in the app or git.
8. Never modify `wiki-brain-vault/raw/`.

## Wiki-Brain — knowledge base (READ FIRST, KEEP UPDATED)

This repo has a persistent, cross-linked knowledge base at **`wiki-brain-vault/`**. It is the
accumulated understanding of this solution and exists to reduce token usage — consult it
instead of re-reading the whole codebase. Treat it as primary context.

### Use it

- **At the start of a task, consult the wiki before spelunking the code.** Entry point:
  `wiki-brain-vault/wiki/index.md`. Follow `[[Page]]` links to the relevant pages.
- Only read files in `wiki-brain-vault/raw/` if a page points you there or the user says
  "read the raw file". **Never modify `raw/`** — sources are immutable.

### Keep it updated (mandatory)

- **Claude fully owns `wiki-brain-vault/wiki/`.** When a task produces durable knowledge —
  a decision, a resolved bug, an architecture/state change, a new subsystem — create or update
  the relevant wiki page(s) before finishing. Don't ask permission per page; just report what changed.
- **Cross-link aggressively** with Obsidian `[[Page Name]]` syntax. A page with no inbound links
  is a dead end.
- **Always update `wiki-brain-vault/wiki/index.md`** when you create or rename a page.
- **End every session with a log line** appended to `wiki-brain-vault/log.md`:

  ```text
  ## [YYYY-MM-DD HH:MM] session | <title in 3-8 words>
  Touched: <comma-separated wiki pages, or "none">
  ```

  If the session was trivial (one-off fix, routine chore, pure exploration), just add the log line
  and skip the wiki update.
- **Flag contradictions, don't silently resolve them.** If new info conflicts with an existing page,
  surface it to the user.

### Ingesting docs

To fold a source doc into the wiki: summarize a file under `wiki-brain-vault/raw/` (or `docs/`)
into a wiki page, cross-link it, update `index.md`, and add a log line.
