# Phase 0 — Foundations

**Goal:** an empty-but-runnable repo that every later phase drops code into.

## Repo layout

```
relay_translate/
├── app/                 # Flutter app (Android first; iOS out of scope — no system overlays on iOS)
├── tools/               # team-only scripts (e.g. Phase 10 Azure comparison) — created when needed
├── phases/              # this plan
├── wiki-brain-vault/    # knowledge base (see CLAUDE.md)
├── CLAUDE.md
└── .gitignore
```

`server/` (Node.js + SQLite) is **not** created now. It only exists if Phase 12 (Azure backup) is built.

## Tasks

1. `git init`, first commit with `phases/`, `CLAUDE.md`, `wiki-brain-vault/`, `.gitignore`.
2. **Flutter app**
   - `flutter create --org com.relay --project-name relay_translate --platforms android app`
   - `minSdk 26` (Android 8, needed for `TYPE_APPLICATION_OVERLAY`), `targetSdk` = latest stable.
   - Kotlin coroutines available in the Android module (used by `Translator.kt`, Phase 1).
   - Keep `analysis_options.yaml` = `flutter_lints` defaults.
   - Folder convention inside `app/lib/`:
     ```
     lib/
     ├── main.dart
     ├── theme/        # tokens, ThemeData, Blueprint widgets (Phase 2)
     ├── screens/      # onboarding, home, history, chatter
     ├── bubble/       # bubble gesture logic shared by demo + native bridge
     ├── data/         # sqflite db
     └── native/       # MethodChannel / EventChannel wrappers (translator, permissions, overlay)
     ```
   - Build flavors `beta` and `prod` (the beta flavor enables tester feedback tools in Phase 10).
3. **.gitignore**: Flutter defaults, `node_modules/`, `*.db`, `.env`, `wiki-brain-vault/graphify-out/`.
4. **CI (GitHub Actions, optional until there is a remote)**: `flutter analyze && flutter test` in `app/`.

## Decisions

- **Android only.** iOS forbids drawing over other apps and reading their text; the Chatter demo could
  run on iOS later but is not a goal.
- **No state-management package.** `ChangeNotifier` + `ListenableBuilder` is enough for 5 screens. Add
  Riverpod only if a real cross-screen dependency problem appears.
- **Translation on-device first (ML Kit)**: free, offline, private. Azure is a measured fallback, not a
  default (Phase 10 decides).

## Exit criteria

- [ ] `flutter run --flavor beta` shows the default app on an Android emulator/device (API 26+).
- [ ] Repo committed; wiki `Architecture` page reflects the real layout.
