# Phases Roadmap

The build plan lives in `phases/` (one file per phase, each with tasks + exit criteria). Overview in
`phases/README.md`.

| # | Phase | File | Status |
|---|---|---|---|
| 0 | Foundations | `phases/00-foundations.md` | done (2026-09-27) |
| 1 | On-device translation (ML Kit) | `phases/01-on-device-translation.md` | done (2026-09-27) |
| 2 | Flutter shell + design system | `phases/02-flutter-design-system.md` | done (2026-09-27) |
| 3 | Onboarding + permissions | `phases/03-onboarding-permissions.md` | done (2026-09-28) |
| 4 | Settings + local DB | `phases/04-settings-local-db.md` | done (2026-09-28) |
| 5 | Chatter demo + in-app bubble | `phases/05-chatter-demo.md` | code + tests done; emulator sign-off pending |
| 6 | History | `phases/06-history.md` | done (2026-09-28) |
| 7 | System overlay bubble | `phases/07-overlay-service.md` | not started |
| 8 | Accessibility translate | `phases/08-accessibility-translate.md` | code + JVM tests; Phase 7 bubble wiring + device matrix pending |
| 9 | Reply + paste | `phases/09-reply-paste.md` | not started |
| 10 | Tester beta + ML Kit evaluation (**decision gate**) | `phases/10-tester-beta.md` | not started |
| 11 | Hardening | `phases/11-hardening.md` | not started |
| 12 | Azure backup, Node + SQLite (**conditional**) | `phases/12-azure-fallback.md` | not started |
| 13 | Release | `phases/13-release.md` | not started |

Critical path: 0 → 1 → 2 → 4 → 5 → 7 → 8 → 9 → 10 → 11 → 13. Phase 12 is only on it if Phase 10 decides.
Update the Status column when a phase's exit criteria are all met.

## Decision log
- 2026-09-27: translation engine = Google ML Kit on-device for the tester beta; Azure Translator (via
  Node + SQLite backend) is the backup. Originally planned: an LLM via a backend. See [[Translation Pipeline]].
- 2026-09-28: `onboarded` is a file at `filesDir/onboarded` until Phase 4's sqflite `settings` row replaces it.
  No `shared_preferences`. See [[Database Schema]].

Links: [[Relay Translate]], [[Architecture]], [[Gotcha - Play Accessibility Policy]]
