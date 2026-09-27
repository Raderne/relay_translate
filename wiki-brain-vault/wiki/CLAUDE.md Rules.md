# CLAUDE.md Rules

Summary of the hard rules in the repo-root `CLAUDE.md`:

1. Read `wiki-brain-vault/wiki/index.md` before exploring code; keep the wiki updated; log every session.
2. The prototype in `wiki-brain-vault/raw/design/` is the behaviour spec — match its copy, numbers and flows ([[Design Source]]).
3. Design tokens only; no hex/font literals outside `app/lib/theme/` ([[Design System - Industry]]).
4. Bubble logic changes go into **both** `bubble_controller.dart` and `BubbleGesture.kt` ([[Bubble Interaction Model]]).
5. Never read screen text except on hold/drop; never auto-send; message text stays on-device with ML Kit ([[Privacy and Permissions]]).
6. Translation goes only through `Translator.kt` (Flutter uses the `relay/translate` channel) ([[Translation Pipeline]]).
7. Minimal dependencies; ask before adding a package.
8. Work phase by phase from `phases/`; a phase is done only when its exit criteria pass ([[Phases Roadmap]]).
9. Never modify `wiki-brain-vault/raw/`.

Links: [[Wiki-Brain Setup]]
