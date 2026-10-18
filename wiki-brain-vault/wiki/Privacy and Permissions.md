# Privacy and Permissions

## Permissions
| Permission | Why | Asked in |
|---|---|---|
| `SYSTEM_ALERT_WINDOW` (Display over other apps) | draw the bubble + translations | Onboard 2 → `ACTION_MANAGE_OVERLAY_PERMISSION` |
| Accessibility service | read on-screen message text; paste replies | Onboard 2 → disclosure dialog → `ACTION_ACCESSIBILITY_SETTINGS` |
| `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_SPECIAL_USE` | keep the bubble alive | manifest |
| `POST_NOTIFICATIONS` (Android 13+) | foreground-service notification + Hide | Home, once: "Turn on notifications" sheet (Continue / Not now) → system prompt; `settings.notifications_asked` |
| `INTERNET` | ML Kit model downloads, [[App Updates]] check/download (and cloud translation only if Phase 12) | manifest |
| `REQUEST_INSTALL_PACKAGES` | install a downloaded update ([[App Updates]]) | system "Install unknown apps" screen on first update |

## Promises (shown to users; keep the code honest to these)
- "Relay reads on-screen text only when you hold or drop the bubble." → no continuous tree reads.
- **Translation happens on your phone; message text never leaves the device** (ML Kit plan).
  If Phase 12 (Azure) ships, this promise changes: text goes to our server for cloud translations, only the hash is stored,
  and the cache is purged after 30 days. Update onboarding, the disclosure, and Play data safety together.
- Replies are pasted, **never sent** automatically.
- History stays on the device; Clear deletes it.
- Beta flavor only: testers can export history JSON (contains message text) for evaluation. Removed from `prod`.

## Asking properly (1.0.0, verified on a fresh install)
- Overlay: Android 11+ ignores the `package:` URI and shows the full list → Onboard 2 says "tap Relay Translate,
  then turn it on".
- Accessibility: sideloaded APKs (GitHub releases) hit Android 13+ **"Restricted setting"**. After a visit to
  accessibility settings that leaves it off, Onboard 2 explains "Allow restricted settings" + **Open App info**
  (`relay/permissions` `openAppInfo`).
- Notifications: never prompted without the explanation sheet; `OverlayChannel` no longer asks on its own.

## Prominent disclosure (in the app, before accessibility settings)
Shown only when the user taps "Open Android settings" and overlay is already granted. Overlay itself
has no disclosure. Not now stays on Onboard 2 and does not open settings.

"Relay uses Android's Accessibility service to read the text of messages on your screen, only when you
hold the bubble or drop it on a message, and to paste replies you write into the app's message box.
Translation happens on your phone. Your messages are not sent anywhere. Relay doesn't collect anything
else from your screen." [Agree] [Not now]

The string is `accessibilityDisclosure` in `app/lib/native/permissions.dart`. The service description
in `res/values/strings.xml` is the shorter line Android shows in the accessibility list.

See [[Gotcha - Play Accessibility Policy]].

Links: [[Android Overlay and Accessibility]], [[Translation Pipeline]], [[Screens and Flows]]
