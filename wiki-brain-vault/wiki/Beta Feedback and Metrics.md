# Beta Feedback and Metrics

Phase 10 tooling for the ML Kit decision gate ([[Translation Pipeline]]). Built 2026-10-18.

## In the app (beta flavor only)
`isBetaBuild` (`lib/native/beta.dart`) = `appFlavor == 'beta'`; native checks `packageName.endsWith(".beta")`.
Release (`prod`) builds show none of this.

| Tool | Where | Code |
|---|---|---|
| 👎 flag + optional note | detail sheet (Chatter and over other apps), History rows | `DetailSheet.onFlag/onNoteChanged`, `HistoryRepository.setFlag` |
| Export | History → **Export** → warning dialog ("The file contains the text of your messages…") → **Share file** → Android share sheet | `exportBetaJson`, `relay/beta` `shareJson` → `BetaChannel.kt` (`cache/exports/`, FileProvider `${applicationId}.updates`) |
| Survey | Home row "Beta survey" → browser | `BetaSurveyRow`, `kBetaSurveyUrl` — **empty = row hidden; needs the Google Form URL** |

Export rows: `src, tr, src_lang, target_lang, app_label, engine, ms, flagged, note`, oldest first.
The export holds message text; only the latest file is kept in the cache.

## Data rules that keep the numbers honest
- **Flags survive re-translation**: `logTranslation` is update-then-insert, not `REPLACE` (which wiped the flag).
  No `ON CONFLICT DO UPDATE` because Android 8's SQLite predates it.
- **Flag before the row exists** (sheet over another app opens before the buffered history row lands):
  `setFlag` inserts the row; the later log keeps the flag. `DetailActivity`'s engine opens the same DB.
- **`ms` = latency with models present**: `Translator.Result.downloaded` (native → `relay/translate` →
  Dart `Translation.downloaded`); a call that downloaded a model logs `ms = null`. Chatter's single-message
  `ms` used to include the 900 ms flash; now measured right after `translate`.
- **`und` is measurable**: the beta also logs undetected messages (`src_lang = 'und'`, `tr = src`);
  release builds skip them (`ChatterSession.beta`, `HistoryRows.build`).
- Only `und` shows in the export; a confidently *wrong* detection shows up only as flags/notes.

## Team scripts (`tools/`, Node ≥ 22, no packages, `node --test "tools/test/*.test.mjs"`)
- `node tools/beta_metrics.mjs <exports folder>` → flagged %, `und` %, latency p90 (nearest rank, rows
  with `ms`), per target language, apps, testers (file name = tester). Marks each target met / MISSED.
- `node --env-file=tools/.env tools/compare_azure.mjs <exports> --sample 50 [--seed 1] --out comparison.csv`
  → every flagged message + N random unflagged (deduped), Azure Translator v3 (batches of 100 per language
  pair, `und` left for Azure to detect), **blind** sheet `id,target,src,a,b` + `comparison.key.csv`
  (`id, a = mlkit|azure, flagged, note`). Key from `tools/.env` ([tools/.env.example], gitignored).
  Sends message text to Azure — only for exports testers agreed to share.

## Known data noise (fix before testers start)
On Google Messages the Phase 8 extractor also logs the "4:03 PM" divider and "Texting with … (SMS/MMS)"
line ([[Per-App Message Rules]]). They inflate the denominator of every rate.

Links: [[Translation Pipeline]], [[Phases Roadmap]], [[Database Schema]], [[Privacy and Permissions]]
