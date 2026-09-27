# Phase 1 — On-device translation (Google ML Kit)

**Goal:** translate text fully on the phone — free, offline, nothing leaves the device — behind one
native `Translator` that both the Flutter UI and the Kotlin overlay service use.

Azure Translator (via a Node + SQLite backend) is the **backup plan**, built only if the tester beta
(Phase 10) says ML Kit quality isn't good enough. See [Phase 12](12-azure-fallback.md).

## Why one Kotlin implementation (not the Flutter ML Kit plugins)

The overlay/accessibility service (Phases 7–9) must translate while the Flutter engine may be dead, so
translation has to live in Kotlin anyway. Flutter calls the same code over a channel → one
implementation, one set of models, no `google_mlkit_*` Dart plugins.

## Dependencies (`app/android/app/build.gradle`)

- `com.google.mlkit:translate` — on-device translation (~59 languages, ~30 MB model per language,
  English is the pivot).
- `com.google.mlkit:language-id` — on-device language detection.

Use the latest stable versions at implementation time.

## `Translator.kt` (`app/android/app/src/main/kotlin/com/relay/relay_translate/`)

```
translate(texts: List<String>, target: String): List<Result(text, source)>
ensureModel(lang: String, wifiOnly: Boolean)   // download if missing
modelStatus(lang): "ready" | "downloading" | "missing"
deleteModel(lang)
```

1. **Detect** source language:
   - Run `identifyLanguage` on the **whole batch joined together** first (a chat is usually one
     language, and short messages detect badly).
   - For messages ≥ 20 chars, also detect per message; if confident (≥ 0.5) and different from the
     batch language, use the per-message result.
   - `"und"` (unknown) → return the original text with `source = "und"`; UI shows "Couldn't detect language".
2. **Skip** texts where `source == target`.
3. **Models**: target model and each detected source model must be downloaded. If one is missing →
   `ensureModel` then translate. The first translation from a new language is slow, so show
   "Downloading German (~30 MB)…" in the toast.
4. **Translate** with a `Translator` client per `(source, target)` pair, cached in a map and closed in
   `onDestroy`. Run the batch concurrently (coroutines); keep input order.
5. Errors (model download failed, no network for first download) → typed error codes the UI turns into toasts.

No translation cache: ML Kit is local and fast, and History already stores results.

## Flutter bridge (`app/lib/native/translator.dart`)

`MethodChannel('relay/translate')`: `translate`, `ensureModel`, `modelStatus`, `deleteModel`.
Every Dart screen (Chatter demo, detail/reply) goes through this; nothing in Dart knows ML Kit exists,
so switching to Azure later is a native-side change (+ one setting).

## Model download UX (small addition to the design)

- On language pick (Home sheet) → `ensureModel(target)`; the Home caption under the language shows
  "Downloading for offline use…" → "Works offline". Deviation from the prototype; record it in the wiki.
- Setting `wifi_only_downloads` (default on). v1 has no model-management screen; add one if testers
  complain about storage.
- Reply direction (Phase 5/9) needs the conversation's language model. It's already downloaded
  because we translated from it.

## Language list

The prototype offers FR / ES / DE / PT. ML Kit supports far more; v1 keeps the 4 (plus EN for replies).
Adding a language = one line in `kLangs` (Dart) — nothing server-side.

## Spike first (1 day, before the rest of this phase)

A throwaway screen: text field + language picker → translate. Paste real WhatsApp-style messages
(slang, emoji, short "ok see u", mixed language) and time it. Record quality notes and latency in the
wiki page `Translation Pipeline`. This gives an early read on ML Kit before testers do.

## Tests

- JVM unit tests for the detection rule (batch vs. per-message, `und`, same-language skip). Put the
  ML Kit calls behind lambdas so the tests inject fakes.
- Instrumented smoke test on an emulator: FR model download + one translation.

## Exit criteria

- [x] From Dart: `translate(["Hey! Did you make it to London okay?"], "fr")` → French, `source = "en"`.
  Verified on the emulator: "Hé! Avez-vous fait à Londres d'accord?", labelled EN.
- [x] Works in airplane mode once models are downloaded. (300–1100 ms per 7-message batch.)
- [x] First-time source language triggers download and then translates. (~24 s for one model, ~36 s for two.)
- [x] Spike findings recorded in the wiki (`Translation Pipeline`).
