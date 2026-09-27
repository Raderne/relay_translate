# Phase 10 — Tester beta + ML Kit evaluation (decision gate)

**Goal:** real testers use Relay in their own chats with on-device ML Kit, and we collect enough evidence
to decide: **keep ML Kit**, **add Azure**, or **switch to Azure**.

## Distribution

- Google Play **internal testing** track (up to 100 testers, email list, fast rollout). This also starts
  the Play review of the accessibility declaration early ([wiki gotcha](../wiki-brain-vault/wiki/Gotcha%20-%20Play%20Accessibility%20Policy.md)).
- Fallback if Play blocks it: sideload a signed APK (Firebase App Distribution or a direct link).
- Build flavor `beta` (`--flavor beta`) turns on the feedback tools below. Release builds don't have them.

## Feedback tools (beta flavor only, no server needed)

- **Flag bad translation**: a 👎 button in the detail sheet and on History rows → sets `flagged = 1`
  (+ optional short note) on the history row.
- **Timing**: store `ms` (translate duration) and `engine = 'mlkit'` on each history row.
- **Export**: History → overflow → "Export beta feedback" → JSON (`src`, `tr`, `src_lang`, `target_lang`,
  `app_label`, `ms`, `flagged`, `note`) through the Android share sheet. Testers send it to the team.
  Warn in the export dialog that it contains message text.
- Short survey (Google Form, linked from the beta build's Home): quality 1–5 per language, "would you
  keep using it", speed, download annoyance.

## Metrics to compute from exports

| Metric | Target to stay on ML Kit |
|---|---|
| Flagged translations / all translations | < 10% |
| Survey quality score (avg) | ≥ 3.5 / 5 |
| Language-detection failures (`und` or wrong language) | < 5% |
| Translate-screen latency p90 (models already downloaded) | < 1 s |
| Complaints about model download size/time | minor |

## A/B comparison without building the backend

`tools/compare_azure.mjs` (a ~50-line Node script run by the team, not shipped): reads the exported JSON,
sends the flagged (and a random sample of unflagged) source texts to Azure Translator, and writes a
side-by-side CSV (`src`, `mlkit`, `azure`). Team reviews it blind. Uses the Azure free tier; key in a local `.env`.

## Decision (record in the wiki with the numbers)

| Outcome | Next |
|---|---|
| Targets met | Stay on ML Kit. Skip Phase 12; release on-device only (big privacy win). |
| Quality OK for most languages, bad for some | **Hybrid**: ML Kit default, Azure for weak pairs + a "Better translation" button in the detail sheet → Phase 12. |
| Quality broadly not good enough | Azure primary, ML Kit as offline fallback → Phase 12. |

## Exit criteria

- [ ] ≥ 10 testers active for ≥ 1 week across ≥ 3 target languages and ≥ 3 chat apps.
- [ ] Exports collected, comparison CSV reviewed.
- [ ] Decision written in wiki `Translation Pipeline` with the numbers behind it.
