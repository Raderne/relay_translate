# Per-App Message Rules

`AppRules.kt` maps host app packages to **view-id allow lists**. When a package has rules,
only nodes with those ids are kept; everything else in that app is ignored. Unknown apps use the
generic leaf-text heuristic in [[Android Overlay and Accessibility]] (`MessageTreeWalker`).

| Package | View ids | Notes |
|---|---|---|
| `com.whatsapp`, `com.whatsapp.w4b` | `com.whatsapp:id/message_text` | Primary chat bubbles |
| `com.google.android.gm` | `conversation_message_text`, `message_body` | Open-email body |
| `com.google.android.apps.messaging` | `message_text`, `conversation_text` | Google Messages |

Ids match on the part after `:id/`: Compose apps (Google Messages) report the bare id, e.g. `message_text`
(seen with `uiautomator dump`). Covered by `AppRulesTest`.

Google Messages reuses `message_text` for info lines; real bubbles always carry a (localized) content description
("555-1234 said …"), so that app also requires a non-empty description (`AppRules.needsDescription`). The noise
filter drops 12-hour timestamps ("4:03 PM"). Both fixed 2026-10-18 (`AppRulesTest`, `MessageNoiseFilterTest`).

Telegram draws many bubbles with custom views — no stable id yet; falls back to generic extraction
(content descriptions + visible text leaves). Update this table when the Phase 8 manual matrix finds
a reliable id.

Links: [[Android Overlay and Accessibility]], [[Gotcha - No In-Place Text Replacement]], [[Phases Roadmap]]
