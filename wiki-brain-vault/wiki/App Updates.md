# App Updates

The app updates itself from **GitHub Releases** (no Play Store). Releases come from
`.github/workflows/release.yml`: one signed `beta` APK per ABI, named `relay-translate-<version>-<abi>.apk`,
release body = the version's `CHANGELOG.md` section.

## Flow
1. Home opens → `Updater.check()` (`lib/native/updater.dart`) → `relay/update` `check` (`UpdateChannel.kt`).
2. Native GETs `api.github.com/repos/Raderne/relay_translate/releases/latest`, picks the asset ending in
   `-<abi>.apk` for the first match in `Build.SUPPORTED_ABIS`, and returns `{current, latest, notes, url}`.
3. Dart shows the sheet (`screens/update_sheet.dart`) only if `isNewer(latest, current)` and an APK matched.
   `isNewer` compares `x.y.z` and ignores `-beta` / `+build` suffixes.
4. **Update** → `download` streams the APK to `cacheDir/updates/update.apk` (progress 0..1 back to Dart) →
   `install` hands it to the system installer through a `FileProvider` (`${applicationId}.updates`).
5. If "Install unknown apps" is off, `install` opens that settings screen and returns false; the button
   becomes **Install** and the user taps it again after allowing.

## Rules / gotchas
- Every release must be signed with the **same key** or Android refuses the update (see `build.gradle.kts`).
- Version comes from `pubspec.yaml`; release.yml rejects a tag that doesn't match it.
- `/releases/latest` skips pre-releases (tags with `-`), so testers only get stable tags.
- `install` refuses an APK whose package name isn't ours (a `prod` app won't install the `beta` APK as a second app).
- Check failures (offline, 60 req/h unauthenticated rate limit, no release) are silent: no sheet.
- `REQUEST_INSTALL_PACKAGES` is restricted on Google Play — remove it (and this feature) from any Play build.
- No message text is involved; the only network calls are GitHub's public API and the APK download.

Links: [[Flutter App]], [[Privacy and Permissions]], [[Phases Roadmap]], [[Deviations from Prototype]]
