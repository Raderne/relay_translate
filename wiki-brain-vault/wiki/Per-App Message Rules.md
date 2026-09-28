# Per-App Message Rules

`AppRules.kt` maps host app packages to **view-id allow lists**. When a package has rules,
only nodes with those ids are kept; everything else in that app is ignored. Unknown apps use the
generic leaf-text heuristic in [[Android Overlay and Accessibility]] (`MessageTreeWalker`).

| Package | View ids | Notes |
|---|---|---|
| `com.whatsapp`, `com.whatsapp.w4b` | `com.whatsapp:id/message_text` | Primary chat bubbles |
| `com.google.android.gm` | `conversation_message_text`, `message_body` | Open-email body |
| `com.google.android.apps.messaging` | `message_text`, `conversation_text` | Google Messages |

Telegram draws many bubbles with custom views — no stable id yet; falls back to generic extraction
(content descriptions + visible text leaves). Update this table when the Phase 8 manual matrix finds
a reliable id.

Links: [[Android Overlay and Accessibility]], [[Gotcha - No In-Place Text Replacement]], [[Phases Roadmap]]
