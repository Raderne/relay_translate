# Gotcha — Short Message Language Detection

## Symptom
Chat messages like "ok", "lol see u", "😂 yes" get detected as the wrong language or `und` (undetermined)
by ML Kit language-id. The wrong source model gets used, or nothing is translated.

## Root cause
Statistical language ID needs text. A few characters, slang, emoji and names give it almost nothing to work with.

## Fix (planned, Phase 1)
- Detect once on the **whole batch** (all visible messages joined together). A conversation is usually one language.
- Override per message only when the message is ≥ 20 chars and confidence is ≥ 0.5.
- `und` → keep the original and show "Couldn't detect language".
- Phase 11: a "Translate from…" override picker in the detail sheet.

## State (2026-09-27)
Design only. Measure the detection failure rate in the Phase 10 beta (target < 5%). If it fails, that
pushes toward Azure, which has its own detection.

Links: [[Translation Pipeline]], [[Android Overlay and Accessibility]]
