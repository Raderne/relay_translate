# Privacy and Permissions

## Permissions
| Permission | Why | Asked in |
|---|---|---|
| `SYSTEM_ALERT_WINDOW` (Display over other apps) | draw the bubble + translations | Onboard 2 → `ACTION_MANAGE_OVERLAY_PERMISSION` |
| Accessibility service | read on-screen message text; paste replies | Onboard 2 → disclosure dialog → `ACTION_ACCESSIBILITY_SETTINGS` |
| `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_SPECIAL_USE` | keep the bubble alive | manifest |
| `POST_NOTIFICATIONS` (Android 13+) | foreground-service notification | runtime prompt when the bubble is first turned on |
| `INTERNET` | ML Kit model downloads (and cloud translation only if Phase 12) | manifest |

## Promises (shown to users; keep the code honest to these)
- "Relay reads on-screen text only when you hold or drop the bubble." → no continuous tree reads.
- **Translation happens on your phone; message text never leaves the device** (ML Kit plan).
  If Phase 12 (Azure) ships, this promise changes: text goes to our server for cloud translations, only the hash is stored,
  and the cache is purged after 30 days. Update onboarding, the disclosure, and Play data safety together.
- Replies are pasted, **never sent** automatically.
- History stays on the device; Clear deletes it.
- Beta flavor only: testers can export history JSON (contains message text) for evaluation. Removed from `prod`.

## Prominent disclosure (draft, needed before accessibility settings)
"Relay uses Android's Accessibility service to read the text of messages on your screen, only when you
hold the bubble or drop it on a message, and to paste replies you write into the app's message box.
Translation happens on your phone. Your messages are not sent anywhere. Relay doesn't collect anything
else from your screen." [Agree] [Not now]

See [[Gotcha - Play Accessibility Policy]].

Links: [[Android Overlay and Accessibility]], [[Translation Pipeline]], [[Screens and Flows]]
