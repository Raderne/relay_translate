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
| 7 | System overlay bubble | `phases/07-overlay-service.md` | code + JVM/Dart tests (2026-10-18); device checks pending |
| 8 | Accessibility translate | `phases/08-accessibility-translate.md` | code + JVM tests; first device run 2026-10-18 fixed 3 bugs (see [[Android Overlay and Accessibility]]); device matrix pending |
| 9 | Reply + paste | `phases/09-reply-paste.md` | code + tests; verified end-to-end on emulator in Google Messages (2026-10-18); WhatsApp on a phone pending |
| 10 | Tester beta + ML Kit evaluation (**decision gate**) | `phases/10-tester-beta.md` | tooling built + tested (2026-10-18, [[Beta Feedback and Metrics]]); testers, survey URL, decision pending |
| 11 | Hardening | `phases/11-hardening.md` | partly (2026-10-18): Arabic + RTL, featured FR/AR prefetch, box wrapping, Messages noise, permission asking, R8 fix. Open: Translate-from picker, Wi-Fi toast + retry, 50-text cap, Privacy row/storage, TalkBack/48 dp/200 % text, device matrix |
| 12 | Azure backup, Node + SQLite (**conditional**) | `phases/12-azure-fallback.md` | not started |
| 13 | Release | `phases/13-release.md` | not started |

**1.0.0 (2026-10-18)** — first tester version: `pubspec` 1.0.0+2, CHANGELOG `[1.0.0]`; Gallery + Phase 1 spike
screen removed. Ship by tagging `v1.0.0` on `develop` (release workflow).

Critical path: 0 → 1 → 2 → 4 → 5 → 7 → 8 → 9 → 10 → 11 → 13. Phase 12 is only on it if Phase 10 decides.
Update the Status column when a phase's exit criteria are all met.

## Decision log
- 2026-09-27: translation engine = Google ML Kit on-device for the tester beta; Azure Translator (via
  Node + SQLite backend) is the backup. Originally planned: an LLM via a backend. See [[Translation Pipeline]].
- 2026-09-28: `onboarded` is a file at `filesDir/onboarded` until Phase 4's sqflite `settings` row replaces it.
  No `shared_preferences`. See [[Database Schema]].

Links: [[Relay Translate]], [[Architecture]], [[Gotcha - Play Accessibility Policy]]

## Release pipeline (added 2026-10-18, ahead of Phase 13)
Tag `vX.Y.Z` on `develop` → `.github/workflows/release.yml`: checks that `app/pubspec.yaml` has the same version,
takes the release notes from `CHANGELOG.md` (`tools/changelog-section.mjs`), runs analyze + test, signs with the
`ANDROID_KEYSTORE_BASE64` / `ANDROID_KEYSTORE_PASSWORD` / `ANDROID_KEY_ALIAS` / `ANDROID_KEY_PASSWORD` secrets,
builds `--flavor beta --split-per-abi` (arm64-v8a, armeabi-v7a, x86_64), refuses debug-signed APKs and publishes
a GitHub Release (a version with `-` becomes a prerelease). `build.gradle.kts` reads `android/key.properties` and
uses debug keys when that file is missing. Play signing (AAB, `prod` flavor) is still [[Phases Roadmap|Phase 13]] work.
