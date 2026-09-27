# Design System — Industry

"Wireframe / blueprint" look: steel-blue accent `#5980a6` on light ground `#f2f2f3`, text `#1d1f20`,
**Barlow Condensed** 600 headings over **Barlow** body, **square corners everywhere**, 1 px hairline
borders, and "+" registration marks at the corners of cards, figures and primary buttons.

Source: `wiki-brain-vault/raw/design/styles.css` + `readme.md`. Flutter port lives in
`app/lib/theme/` (Phase 2). Debug builds open `screens/gallery.dart`, which shows every widget.

## Rules that matter for the app
- Tokens only; no hex/font literals outside `app/lib/theme/`.
- Radius 0 (the blueprint override beats `--radius-*`).
- Primary button = the only solid fill (accent), still wears corner marks.
- Accent on bg is ~3:1 → body-size accent text uses `accent-700`.
- Icons: Lucide, stroke **1.5** (hence SVG assets, not an icon font).
- Divider = text @ 16% alpha. Scrim = neutral-900 @ 45%.
- Accent-2 ramp is a stand-in for a mono palette — ignore it.

## Dart names
| Name | File | Notes |
|---|---|---|
| `RelayColors` | `tokens.dart` | `bg`, `surface`, `text`, `accent`, `divider`, `scrim`, `mark`. Ramps: `neutral[100…900]`, `accentRamp[100…900]`. |
| `RelayShadows` | `tokens.dart` | `sm` / `md` / `lg` |
| `RelaySpace` | `tokens.dart` | `s1` `s2` `s3` `s4` `s6` `s8` — the CSS scale has no 5 or 7 |
| `RelayFonts`, `RelayType` | `tokens.dart`, `type.dart` | Barlow body, Barlow Condensed headings. `h1`–`h6`, `body`, `kicker`, `button` |
| `RelayTheme.data` | `theme.dart` | `ThemeData`. Not `ColorScheme.fromSeed` |
| `Blueprint` | `widgets.dart` | frame + four `+` marks |
| `RelayButton.primary/secondary/ghost/icon` | `widgets.dart` | primary wears `Blueprint`. `preview` forces hover/press/focus for the gallery |
| `RelayTag.accent`, `Kicker` | `widgets.dart` | |
| `RelaySquareSwitch`, `RelaySegmented`, `RelayInput` | `widgets.dart` | |
| `RelaySheet` / `.show` | `widgets.dart` | scrim is neutral-900 @ 45% |
| `RelayToast` / `.show` | `widgets.dart` | 3.5 s |
| `RelayIcon`, `RelayIcons` | `icons.dart` | Lucide SVG, stroke 1.5, via `flutter_svg` |

Native overlay views ([[Android Overlay and Accessibility]]) must reuse the same values — keep a Kotlin
`RelayColors.kt` mirror and note it here when created. Not built yet; the overlay is Phase 7.

Links: [[Design Source]], [[Flutter App]], [[Screens and Flows]]
