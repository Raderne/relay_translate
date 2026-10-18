# Phase 13 — Release

## Git hub Release

- Tag the commit with the version from `pubspec.yaml`.

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
