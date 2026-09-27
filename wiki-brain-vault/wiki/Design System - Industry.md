# Design System — Industry

"Wireframe / blueprint" look: steel-blue accent `#5980a6` on light ground `#f2f2f3`, text `#1d1f20`,
**Barlow Condensed** 600 headings over **Barlow** body, **square corners everywhere**, 1 px hairline
borders, and "+" registration marks at the corners of cards, figures and primary buttons.

Source: `wiki-brain-vault/raw/design/styles.css` + `readme.md`. Flutter port planned in
`app/lib/theme/` (Phase 2 — `phases/02-flutter-design-system.md`).

## Rules that matter for the app
- Tokens only; no hex/font literals outside `app/lib/theme/`.
- Radius 0 (the blueprint override beats `--radius-*`).
- Primary button = the only solid fill (accent), still wears corner marks.
- Accent on bg is ~3:1 → body-size accent text uses `accent-700`.
- Icons: Lucide, stroke **1.5** (hence SVG assets, not an icon font).
- Divider = text @ 16% alpha. Scrim = neutral-900 @ 45%.
- Accent-2 ramp is a stand-in for a mono palette — ignore it.

## Planned Dart names
`RelayColors`, `RelayShadows`, `RelaySpace`, `Blueprint`, `RelayButton.*`, `RelayTag`,
`RelaySquareSwitch`, `RelaySegmented`, `RelayInput`, `RelaySheet`, `RelayToast`, `Kicker`.

Native overlay views ([[Android Overlay and Accessibility]]) must reuse the same values — keep a Kotlin
`RelayColors.kt` mirror and note it here when created.

Links: [[Design Source]], [[Flutter App]], [[Screens and Flows]]
