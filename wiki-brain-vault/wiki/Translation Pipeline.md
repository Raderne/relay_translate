# Translation Pipeline

**Engine: Google ML Kit, on-device** (Phase 1, `phases/01-on-device-translation.md`).
**Fallback: Azure Translator via backend**, only if the Phase 10 beta decides so ([[Backend API]]).

## Flow (`Translator.kt`, planned)
1. Caller (Flutter over `relay/translate`, or the accessibility service directly) passes `texts[]` +
   `target` (the user's language), or `target = message source` for replies.
2. **Detect** with ML Kit language-id: once on the whole batch joined together, then per message for
   texts ≥ 20 chars (use the per-message result if confidence ≥ 0.5). `und` → return the original + "Couldn't detect language".
   Why: [[Gotcha - Short Message Language Detection]].
3. Skip texts already in the target language.
4. Make sure the source and target models are downloaded (~30 MB each, English pivot). Respect `wifi_only_downloads`.
5. Translate with a cached ML Kit `Translator` per (source, target) pair, concurrently, keeping input order.
6. Return `[{text, source}]`. The caller logs to History with `engine='mlkit'` and `ms`.

No cache: it's local and fast, and History already stores results.

## Why this shape
- Batch detection fixes short-message detection; the detected `source` drives the "EN → FR" labels and the reply direction.
- The Dart side knows nothing about ML Kit, so adding Azure is a native change plus one `engine` setting.

## Evaluation (Phase 10 — decision gate)
Beta flavor logs `ms`, lets testers flag bad translations, and exports JSON. `tools/compare_azure.mjs`
replays samples through Azure for a blind side-by-side. Targets: < 10% flagged, survey ≥ 3.5/5,
detection failures < 5%, p90 < 1 s. Outcome options: stay on ML Kit / hybrid / Azure primary.

## State (2026-09-27)
Planned. Spike findings (quality notes, latency) go here after the Phase 1 spike; the decision and its
numbers go here after Phase 10.

Links: [[Architecture]], [[Bubble Interaction Model]], [[Privacy and Permissions]]
