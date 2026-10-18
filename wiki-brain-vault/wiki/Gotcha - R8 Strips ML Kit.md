# Gotcha — R8 strips ML Kit registrars

## Symptom
Release APK (`flutter build apk --release`) shows a white screen and dies at launch:
`NoSuchMethodException … LanguageIdRegistrar.<init>` (ComponentDiscovery), then
`NullPointerException … in Translator.<init>` from `MainActivity.configureFlutterEngine`.
Debug builds are fine because they don't minify. Found 2026-10-18 just before 1.0.0; 0.1.0's release
APK most likely had it too.

## Root cause
ML Kit registers through Firebase `ComponentDiscovery`, which creates each `ComponentRegistrar` by
reflection. R8 (full mode, AGP 8 default) removes their unused no-arg constructors.

## Fix
`app/android/app/proguard-rules.pro`:
`-keep class * implements com.google.firebase.components.ComponentRegistrar { public <init>(); }`,
wired in `build.gradle.kts` `release { proguardFiles(...) }`.

## Rule
Before tagging a release, install a **release** APK on a device and launch it — unit tests and
debug runs can't catch minification bugs.

Links: [[Translation Pipeline]], [[Phases Roadmap]], [[App Updates]]
