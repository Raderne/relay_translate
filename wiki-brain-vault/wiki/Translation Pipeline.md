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

## Spike findings (2026-09-27, emulator, ML Kit translate 17.0.3 + language-id 17.0.6)

Sample: 7 WhatsApp-style lines (slang, emoji, one French sentence in an English batch).

**Detection rule works.** The French line ("Merci beaucoup, à demain !") was detected `fr` on its own and
did not inherit the batch's `en`: returned unchanged when the target was French, translated when the
target was German or Portuguese. Short lines ("ok see u", "lol 😂") correctly inherited `en`.

**Slang is the quality gap, not detection.** Tokens ML Kit doesn't know pass through verbatim in every
language tried: "brb", "tbh", "pls", "u", "lol". Idioms are inconsistent — "Did you make it to London
okay?" became the good "Hast du es nach London geschafft?" in German but the broken "Avez-vous fait à
Londres d'accord?" in French. Emoji are preserved. This is the risk Phase 10 has to measure.

**Latency** (Pixel 10 emulator, batch of 7):
- First translation, model not on device: ~36 s for two models (en + target), ~24 s when English was
  already cached. Dominated by the ~30 MB download.
- Models present: 300–1100 ms per batch, including language identification. Emulator numbers; a real
  device should be faster. The Phase 10 p90 < 1 s target looks reachable once models are cached.

## Deviation: downloads fail fast when offline
ML Kit's `RemoteModelManager.download` does **not** fail offline — it hands the download to
`DownloadManager`, which waits for connectivity indefinitely (confirmed: airplane mode, still
"Downloading…" after 40 s, no error, no log). `Translator.ensureModel` therefore checks connectivity
itself before downloading and throws immediately:
- `no_network` — no connection at all
- `wifi_required` — `wifi_only_downloads` is on and the device is on mobile data

Translation of already-downloaded models is unaffected and works in airplane mode.

## State (2026-09-27)
Phase 1 done. The decision and its numbers go here after Phase 10.

Links: [[Architecture]], [[Bubble Interaction Model]], [[Privacy and Permissions]]
