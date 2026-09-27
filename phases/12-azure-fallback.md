# Phase 12 — Azure Translator backup (Node.js + SQLite) — CONDITIONAL

**Only build this if Phase 10's decision says so** (hybrid or Azure-primary). If ML Kit passes, skip it.

**Goal:** a small Node service that calls Azure Translator so the API key never ships in the app, caches
results in SQLite, and rate-limits per device. The app gets a second engine behind the same `Translator`.

## Why a backend (instead of calling Azure from the phone)

- The Azure key would be extractable from the APK.
- Shared cache + per-install rate limits keep the bill bounded.

## Endpoints

| Method | Path | Body | Returns |
|---|---|---|---|
| GET | `/health` | — | `{ ok: true }` |
| POST | `/v1/devices` | `{}` | `{ deviceId, token }` (anonymous install registration) |
| POST | `/v1/translate` | `{ texts: string[], target, source? }` | `{ items: [{ text, source, cached }] }` in input order |

- `Authorization: Bearer <token>`; tokens stored hashed (sha256).
- Limits: ≤ 50 texts, ≤ 2 000 chars each, ≤ 10 000 total → 413; daily char budget → 429; bad token → 401.

## Azure call (`server/src/translate.js`)

- `POST https://api.cognitive.microsofttranslator.com/translate?api-version=3.0&to=<target>` with headers
  `Ocp-Apim-Subscription-Key`, `Ocp-Apim-Subscription-Region`; body `[{ "Text": "…" }, …]` (one request
  per batch; omit `from` → auto-detect, response carries `detectedLanguage.language`).
- Same-language (`detected == target`) → return original.
- Uses `fetch` (built into Node). No SDK.

## SQLite (`server/data/relay.db`, built-in `node:sqlite`)

```sql
CREATE TABLE devices (
  id TEXT PRIMARY KEY, token_hash TEXT NOT NULL UNIQUE,
  created_at INTEGER NOT NULL, last_seen_at INTEGER NOT NULL
);
CREATE TABLE translations (          -- cache; no source text stored, only its hash
  key TEXT PRIMARY KEY,              -- sha256(target + '\n' + normalized text)
  source TEXT NOT NULL, target TEXT NOT NULL, text_out TEXT NOT NULL,
  created_at INTEGER NOT NULL, hits INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE usage (
  device_id TEXT NOT NULL REFERENCES devices(id), day TEXT NOT NULL, chars INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (device_id, day)
);
```

WAL + foreign keys on; migrations = ordered SQL array + `PRAGMA user_version`; purge cache rows > 30 days.

## Env (`server/.env.example`)

```
PORT=8787
DB_PATH=./data/relay.db
AZURE_TRANSLATOR_KEY=
AZURE_TRANSLATOR_REGION=
DAILY_CHAR_LIMIT=50000
```

## App side

- `Translator.kt` gains `translateCloud(texts, target)` (`HttpURLConnection` + `org.json`, device token
  from settings). Routing rule depends on the Phase 10 decision:
  - **Hybrid**: ML Kit first; cloud for language pairs listed as weak, and when the user taps
    "Better translation" in the detail sheet.
  - **Azure primary**: cloud first; ML Kit when offline or on 5xx/429.
- Setting `engine` (`mlkit` | `cloud` | `auto`) in the settings table. Hidden in release unless testers
  need it.
- Onboarding/disclosure text must change: text now leaves the device for cloud translations
  (update wiki `Privacy and Permissions` and the Play data-safety form).

## Tests (`node --test`, Azure call injected as a fake function)

Cache hit skips Azure; order kept with mixed hits/misses; same-language passthrough; 413 / 429 / 401.

## Exit criteria

- [ ] App routes per the chosen rule; airplane mode still works via ML Kit.
- [ ] Server deployed (see Phase 13), cache visible in logs, tests pass.
- [ ] Wiki `Backend API`, `Database Schema`, `Translation Pipeline`, `Privacy and Permissions` updated.
