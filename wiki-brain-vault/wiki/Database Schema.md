# Database Schema

The sqflite database does not exist yet. Definitions are the plan in `phases/04-settings-local-db.md`
(device) and `phases/12-azure-fallback.md` (server, conditional).

Until that database exists, `onboarded` is a file at `context.filesDir/onboarded`, written by
`relay/permissions` `setOnboarded` once both permissions are granted ([[Privacy and Permissions]]).
Phase 4 should copy that flag into the `settings` row and stop using the file.

## Device: `relay.db` via `sqflite` (the only DB in the current plan)
| Table | Columns | Notes |
|---|---|---|
| `settings` | `key` PK, `value` | `target_lang`, `bubble_on`, `snap`, `size`, `bubble_x/y`, `onboarded`, `hint_seen`, `wifi_only_downloads` (+ `engine`, `device_token` if Phase 12) |
| `history` | `id`, `dedupe_key` UNIQUE, `src`, `tr`, `src_lang`, `target_lang`, `app_package`, `app_label`, `engine`, `ms`, `flagged`, `note`, `created_at` | upsert moves duplicates to the top; cap 1 000 rows. `engine/ms/flagged/note` feed the Phase 10 evaluation |

ML Kit models are managed by ML Kit itself (not in this DB).

## Server: `server/data/relay.db` (only if Phase 12 is built)
| Table | Columns | Notes |
|---|---|---|
| `devices` | `id` PK, `token_hash` UNIQUE, `created_at`, `last_seen_at` | anonymous installs |
| `translations` | `key` PK = sha256(target + normalized text), `source`, `target`, `text_out`, `created_at`, `hits` | cache; **no source text**; purge > 30 days |
| `usage` | (`device_id`, `day`) PK, `chars` | daily rate limit |

Links: [[Flutter App]], [[Backend API]], [[Privacy and Permissions]]
