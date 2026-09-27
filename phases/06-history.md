# Phase 6 — History

**Goal:** every translation (demo and real apps) is saved on-device and browsable.

## Behaviour (raw design `isHist`)

- Header: back arrow, "History" (24 px), ghost **Clear** only when non-empty.
- Empty state: Blueprint card "Nothing yet" / "Every message you translate with the bubble is saved
  here." + secondary "Open Chatter".
- Grouped by day: h6 "Today", "Yesterday", then `EEE d MMM` (use `intl` — Flutter already pulls it for
  localizations).
- Row: `EN → FR · WhatsApp` (11 px uppercase accent-700) + time right (neutral-600); translation
  17 px Barlow Condensed 600; source 13 px neutral-700.
- Newest first. **Dedupe**: re-translating the same text into the same language moves it to the top
  (`INSERT … ON CONFLICT(dedupe_key) DO UPDATE SET created_at = excluded.created_at, tr = excluded.tr`).
- Home "History" row count = rows created today.

## Additions beyond prototype (small, useful)

- Long-press row → copy translation. (Skip swipe-to-delete until asked.)
- Retention: keep last 1 000 rows (delete oldest on insert). `ponytail:` hard cap; make configurable if users ask.

## Writers

- Phase 5 demo: `app_package = 'relay.chatter'`, `app_label = 'Chatter'`.
- Phase 8 native: package/label of the foreground app, sent over the EventChannel.

## Exit criteria

- [ ] Translating in Chatter populates History; duplicates move to top instead of repeating.
- [ ] Clear empties list and Home shows "Empty".
- [ ] Test: dedupe + retention cap on in-memory DB.
