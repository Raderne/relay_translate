# Phase 2 — Flutter shell + "Industry" design system

**Goal:** port the design system (`wiki-brain-vault/raw/design/styles.css` + `readme.md`) to Flutter so
every screen in later phases is built from shared tokens and widgets, never hard-coded values.

## Tokens → `app/lib/theme/tokens.dart`

Straight port of `:root` in `styles.css`:

| CSS | Dart |
|---|---|
| `--color-bg #f2f2f3`, `--color-surface #e9e9ea`, `--color-text #1d1f20` | `RelayColors.bg/surface/text` |
| `--color-accent #5980a6` | `RelayColors.accent` |
| `--color-divider` = text @ 16% | `RelayColors.divider = Color(0x291D1F20)` |
| neutral 100–900, accent 100–900 | `RelayColors.neutral[100]…[900]`, `accent[100]…[900]` |
| `--shadow-sm/md/lg` | `RelayShadows.sm/md/lg` (`BoxShadow` lists, color `#2b2b2d` @ 14/16/22%) |
| `--space-1..8` (3.4 … 27.2) | `RelaySpace.s1…s8` |
| radius | **0 everywhere** (the blueprint override wins over `--radius-*`) |

Accent-2 is a mono stand-in — don't port it.

## Typography

- Bundle **Barlow** (400/500/700) and **Barlow Condensed** (400/600) as font assets (offline; no `google_fonts` dep).
- `TextTheme`: h1 42, h2 32, h3 25, h4 20, h5 16 (Barlow Condensed 600, height 1.12, letterSpacing −0.015em);
  h6 13 uppercase letterSpacing .08em; body 15 / 1.55 Barlow.
- "Kicker" style: 11 px, 600, letterSpacing .1em, uppercase, `accent[700]`.

## Icons

Lucide at stroke-width **1.5**. Needed set: `languages` (bubble), `arrow-left`, `chevron-right`, `x`,
`send`, `mic`, `wifi`, `battery`. Ship them as SVG assets rendered with `flutter_svg` (font icon packs
can't do 1.5 stroke).

## Widgets → `app/lib/theme/widgets.dart`

| Widget | Mirrors | Notes |
|---|---|---|
| `Blueprint(child)` | `.blueprint` + 4 `.corner` | 1 px divider border, square, **"+" registration marks** 11×11 at each corner offset −6 px, color text @ 55%. `CustomPainter` in a `Stack(clipBehavior: none)`. |
| `RelayButton.primary/secondary/ghost/icon` | `.btn-*` | Barlow Condensed 600 14 px; primary = accent fill, hover/press accent 600/700; primary buttons in screens also wear `Blueprint` marks. Disabled = 45% opacity. |
| `RelayTag.accent` | `.tag-accent` | accent-100 bg / accent-800 text, 11 px. |
| `RelaySquareSwitch` | Home toggles | 40×22, 1 px divider border, 16×16 square knob; on = accent track + bg knob; off = transparent + neutral-500 knob. |
| `RelaySegmented` | `.seg` | S / M / L; selected = accent fill + bg text. |
| `RelayInput` | `.input` | surface fill, divider border, square, 14 px; focus border accent. |
| `RelaySheet` | bottom sheets | bg, top 1 px divider, scrim neutral-900 @ 45%. |
| `RelayToast` | toast | neutral-900 bg, neutral-100 text 13.5 px, action in accent-300 Barlow Condensed 600. |
| `Kicker(text)` | `.card-kicker` | |

Focus: 2 px accent outline (use `FocusableActionDetector` / theme `focusColor`) — no default Material ripple
color; set `splashFactory: NoSplash.splashFactory` or tint from accent ramp.

## ThemeData

`useMaterial3: true`, `scaffoldBackgroundColor: bg`, `colorScheme` seeded manually from tokens (not
`fromSeed` — it would re-tone the accent), `dividerColor: divider`, zero radius shapes on buttons/inputs/sheets.

## Dev gallery

`app/lib/screens/gallery.dart` (debug builds only): every widget in every state, for visual QA against
the prototype. Delete-able later — it replaces a Widgetbook dependency.

## Exit criteria

- [x] Gallery renders all widgets; side-by-side screenshot vs. prototype looks the same (font, marks, colors).
  Verified 2026-09-27 on the Pixel 10 emulator: condensed headings, square controls, registration marks, accent ramp.
- [x] No hex literal or font name outside `theme/`. (`test/theme/no_literals_test.dart`)
- [x] Golden test for `Blueprint` and `RelayButton.primary` (`flutter test --update-goldens` once).
- [x] Wiki `Design System - Industry` lists the Dart names.
