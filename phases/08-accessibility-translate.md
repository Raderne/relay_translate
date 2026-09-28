# Phase 8 — Accessibility: read screen text + draw translations

**Goal:** hold the bubble in WhatsApp/Telegram/Gmail → messages appear in your language; drag onto one
message → that one translates.

> **Read `Gotcha - No In-Place Text Replacement` and `Gotcha - Play Accessibility Policy` in the wiki first.**

## Service config (`res/xml/relay_accessibility.xml`)

- `accessibilityEventTypes="typeWindowContentChanged|typeWindowStateChanged"` (for invalidation only)
- `canRetrieveWindowContent="true"`, `accessibilityFlags="flagReportViewIds|flagRetrieveInteractiveWindows"`
- `description` = the disclosure text. **No** `canPerformGestures`. Not an accessibility tool — declare
  honestly in Play Console (Phase 13).
- The service reads the tree **only on demand** (hold / drop), never continuously. This is both the
  privacy promise shown in onboarding and the battery budget.

## Extracting messages (`MessageExtractor.kt`)

1. `rootInActiveWindow` of the app under the bubble (skip our own package, launcher, system UI).
2. Walk visible nodes; collect leaf `TextView`-like nodes with non-empty `text`, `isVisibleToUser`,
   `getBoundsInScreen`.
3. Filter noise: timestamps (`^\d{1,2}:\d{2}`), single emoji, < 2 chars, nodes inside the app's toolbar
   / input field (`isEditable`), our own overlay.
4. **Per-app rules** (`AppRules.kt`, map by package): view-id allow-lists where known, e.g. WhatsApp
   `com.whatsapp:id/message_text`, Telegram (custom-drawn — falls back to content descriptions), Gmail body
   `WebView` text nodes. Unknown apps → generic heuristic above. Keep this table small and documented
   in the wiki page `Per-App Message Rules`.
5. Output: `[{id, text, bounds}]` where `id = hash(text + bounds.top)`.

## Translating

- Call `Translator.kt` (Phase 1) directly from the service. It's in-process, so no channel is needed and
  it works while the Flutter engine is dead.
- Hold = all extracted nodes; drop = node whose bounds contain the drop point (prefer smallest area).
- Loading state: 2 dp progress line at the top of the screen overlay + dim boxes (mirror demo timings).

## Drawing translations (`TranslationLayer.kt`)

- One full-screen overlay window, `FLAG_NOT_TOUCHABLE` except the boxes themselves (use one window per
  box, or a full window with `FLAG_NOT_TOUCH_MODAL` and pass-through by region — spike both, pick the
  one where scrolling the app underneath still works).
- Each box: exactly covers the node bounds, styled from the design (not colour-sampled from the app):
  bg surface, accent 1 dp border, small "Translated · EN → FR" tag, text auto-sized down to fit (min 11 sp).
- Tap a box → detail sheet (Phase 9). "Show original" / hold again → remove all boxes.
- **Invalidation**: on `TYPE_WINDOW_CONTENT_CHANGED` scroll/`TYPE_VIEW_SCROLLED`/window change → remove
  boxes (text no longer lines up). Toast "Scrolled · hold again to translate". Re-positioning on scroll
  is a later improvement.

## History

Each translated node → EventChannel `translated` with `app_package` + human label
(`PackageManager.getApplicationLabel`) → Dart inserts. If the Flutter engine is dead, buffer in the
service and flush on next app launch.

## Test matrix (manual, record results in wiki)

| App | Hold | Drag one | Notes |
|---|---|---|---|
| WhatsApp | | | |
| Telegram | | | |
| Gmail (open email) | | | |
| Messenger / Instagram DM | | | |
| Chrome page | | | |
| SMS (Google Messages) | | | |

## Exit criteria

- [ ] WhatsApp + Telegram + Google Messages: hold translates visible messages, drag translates one.
- [ ] Boxes disappear on scroll; no stale overlays.
- [ ] No tree reads happen except on hold/drop (verify with logs).
- [x] Unit tests for the noise filter + drop-target selection (plain JVM tests, nodes faked as data).
