# Backend API

**Status: conditional.** Built only if the Phase 10 tester beta decides ML Kit isn't enough
(`phases/12-azure-fallback.md`). As of 2026-09-27 the app is planned fully on-device ([[Architecture]]).

Node.js ≥ 22.5 in `server/`: `node:http`, built-in `node:sqlite`, `fetch` to Azure, tests with `node --test`.

## Endpoints
| Method | Path | Notes |
|---|---|---|
| GET | `/health` | `{ ok: true }` |
| POST | `/v1/devices` | anonymous install → `{ deviceId, token }`; token stored hashed |
| POST | `/v1/translate` | Bearer token; `{ texts[], target, source? }` → `{ items: [{ text, source, cached }] }` |

Limits: ≤ 50 texts, ≤ 2 000 chars each, ≤ 10 000 total (413); daily char budget per device (429); bad token (401).

## Azure
Translator v3 `/translate?api-version=3.0&to=<target>`, batch body `[{Text}]`, auto-detect (omit `from`).
Key + region in `server/.env` only (`AZURE_TRANSLATOR_KEY`, `AZURE_TRANSLATOR_REGION`).

## App routing (depends on Phase 10 outcome)
Hybrid: ML Kit first, cloud for weak pairs and a "Better translation" button. Azure-primary: cloud first,
ML Kit when offline / on errors.

Links: [[Database Schema]], [[Translation Pipeline]], [[Privacy and Permissions]]
