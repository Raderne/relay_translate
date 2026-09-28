# Phase 4 — Settings (Home) + local SQLite

**Goal:** the Home/Settings screen from the prototype, with every setting persisted on-device.

## Local DB (`app/lib/data/db.dart`, package `sqflite`)

One file `relay.db`, versioned with `onCreate`/`onUpgrade`:

```sql
CREATE TABLE settings (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
-- keys: target_lang ('fr'), bubble_on ('1'), snap ('1'), size ('M'),
--       bubble_x, bubble_y, onboarded, hint_seen, wifi_only_downloads ('1')

CREATE TABLE history (          -- used from Phase 6
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  dedupe_key  TEXT NOT NULL UNIQUE,   -- sha1(target + source text)
  src         TEXT NOT NULL,
  tr          TEXT NOT NULL,
  src_lang    TEXT NOT NULL,
  target_lang TEXT NOT NULL,
  app_package TEXT NOT NULL,          -- 'relay.chatter' for the demo
  app_label   TEXT NOT NULL,          -- 'Chatter', 'WhatsApp', …
  engine      TEXT NOT NULL DEFAULT 'mlkit',  -- 'mlkit' | 'cloud' (Phase 12)
  ms          INTEGER,                -- translate duration, for the Phase 10 evaluation
  flagged     INTEGER NOT NULL DEFAULT 0,     -- beta "bad translation" flag (Phase 10)
  note        TEXT,                   -- optional tester note
  created_at  INTEGER NOT NULL
);
```

No `shared_preferences` — the k/v table covers it and the native service (Phase 7) needs to read the
same settings (pass them over the channel; don't open the DB from Kotlin).

`SettingsStore extends ChangeNotifier` loads all rows once at startup, exposes typed getters, writes
through on change.

## Home screen (raw design `isHome`)

- Header: `Relay` (nav-brand 24 px) + tag `Bubble on` / `Bubble off`.
- **Translate-into card** (Blueprint button): kicker "Translate into", language name 36 px Barlow
  Condensed, "Change" in accent-700, caption "From any language · detected automatically". Tap → sheet.
- **Language sheet**: title "Translate into"; rows `French Français`, `Spanish Español`, `German Deutsch`,
  `Portuguese Português`; selected row shows "Selected". Tap = pick + close. Scrim tap closes.
  Picking a language calls `Translator.ensureModel(lang)` (Phase 1). The card caption shows
  "Downloading for offline use…" until the model is ready, then "From any language · works offline".
  This is a deviation from the prototype; record it in the wiki.
- **Bubble section** (h6 "Bubble"):
  - "Show bubble over apps" square switch → starts/stops the overlay service (Phase 7; in this phase
    just persists).
  - "Snap to screen edge" switch.
  - "Size" segmented S / M / L (44/52/60). Changing size clamps stored `bubble_x` so it stays on screen.
  - "History" row → count `"N today"` or `"Empty"`, chevron → History screen.
- Primary blueprint CTA pinned at bottom: "Try it in Chatter".

Language list lives in one Dart const (`kLangs`) with `code`, `name`, `native`. Adding a language =
one line here (ML Kit supports ~59).

## Exit criteria

- [x] Every control persists across app kill/restart.
- [x] Sheet open/close/scrim matches prototype.
- [x] Unit test: `SettingsStore` round-trips each key through an in-memory sqflite (`sqflite_common_ffi`).
- [x] Wiki `Flutter App` + `Database Schema` (device section) updated.
