# Phase 13 — Release

## Google Play — the hard part
- **Accessibility API declaration** (Play Console → App content): Relay is *not* an accessibility tool,
  so it must justify the use as core functionality, with a **prominent in-app disclosure + affirmative consent**
  shown before sending the user to Accessibility settings, plus a demo video. Rejection risk is real.
  The Phase 10 internal-testing upload should already have surfaced problems.
- `SYSTEM_ALERT_WINDOW` and `FOREGROUND_SERVICE_SPECIAL_USE`: declare the use case.
- **Data safety form**:
  - ML Kit only: message text is processed on-device and not collected. Say that.
  - If Phase 12 shipped: message text is sent to our server/Azure for translation, not stored in plain
    form, and not sold.
- Privacy policy URL.

## Build
- Upload key + Play App Signing; `flutter build appbundle --flavor prod --release --obfuscate --split-debug-info=build/symbols`.
- Version from `pubspec.yaml`; tag the git commit.

## Server deploy (only if Phase 12 was built)
- A small VPS/container host with a persistent volume for `relay.db` (SQLite needs a real disk, so no
  serverless). HTTPS via the host or Caddy.
- `node --env-file=.env src/index.js` under systemd/Docker, restart always.
- Backup: nightly `VACUUM INTO` to object storage; verify by restoring once.
- App build points at the prod URL via `--dart-define=API_URL=...`.

## Exit criteria
- [ ] Production track approved, including the accessibility declaration.
- [ ] (If server) prod server healthy, backup restore verified.
- [ ] Wiki `Deployment` page written.
