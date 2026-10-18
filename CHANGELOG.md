# Changelog

All notable changes to Relay Translate are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-10-18

First version for testers.

### Added

- The bubble floats over every app: hold to translate the screen, drag onto one message, tap for the menu (Translate screen, Language, History, Hide bubble). It keeps running when Relay is closed and hides while Relay is open or the phone is locked.
- "Relay bubble is on" notification with a Hide button.
- Tap a translated message in any app to see the original, copy it, or reply: write in your language, translate it back, and paste it into the app's message box. Relay never sends for you; if the app refuses the paste, the reply is copied instead.
- Arabic. Arabic and French are the featured languages and download right after setup; Spanish, German and Portuguese are under "More languages". New installs translate into Arabic.
- Arabic reads right to left everywhere: translated boxes, the detail sheet, your reply, History.
- In-app updates from GitHub Releases.
- New app icon and launch screen.
- Beta feedback (beta build only): flag a bad translation with 👎 and an optional note, export your feedback from History, beta survey link.

### Changed

- Translated boxes wrap long text and shrink it to fit instead of cutting it off, and no longer show the "Translated · EN → AR" line.
- Setup explains each Android permission before asking: where to find Relay in the "Display over other apps" list, what to do when Android says "Restricted setting" for accessibility, and why Relay asks for notifications.

### Fixed

- The release app crashed on launch (the release build stripped parts of ML Kit).
- Turning on screen text access crashed the app.
- Translated boxes vanished right after appearing.
- No messages were found in Google Messages.
- Timestamps and "Texting with …" lines in Google Messages were translated as messages.
- App names showed as package names (e.g. "com.google.android.apps.messaging").
- Flags were lost when a message was translated again.

## [0.1.0] - 2026-10-18

### Added

- Onboarding with overlay and accessibility permissions.
- Home settings: target language (on-device model download), bubble toggles and size.
- Chatter demo with the in-app bubble and on-device ML Kit translations.
- On-device translation history.
- Hold or drag the bubble to translate messages in other apps through accessibility.
