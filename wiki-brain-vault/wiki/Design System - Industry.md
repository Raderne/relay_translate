# Design System — Industry

"Wireframe / blueprint" look: steel-blue accent `#5980a6` on light ground `#f2f2f3`, text `#1d1f20`,
**Barlow Condensed** 600 headings over **Barlow** body, **square corners everywhere**, 1 px hairline
borders, and "+" registration marks at the corners of cards, figures and primary buttons.

Source: `wiki-brain-vault/raw/design/styles.css` + `readme.md`. Flutter port lives in
`app/lib/theme/` (Phase 2). The gallery (`screens/gallery.dart`) is a debug route from Home, not the start screen.

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
| `RelayFonts`, `RelayType` | `tokens.dart`, `type.dart` | Barlow body, Barlow Condensed headings. `h1`–`h6`, `body`, `bodyMuted`, `row`, `caption`, `kicker`, `button`, `cta` (17 px), `step` (18 px), `onboardTitle` (40 px), `brand` (24 px) |
| `RelayTheme.data` | `theme.dart` | `ThemeData`. Not `ColorScheme.fromSeed` |
| `Blueprint` | `widgets.dart` | frame + four `+` marks |
| `RelayButton.primary/secondary/ghost/icon` | `widgets.dart` | primary wears `Blueprint`. `large` is 48 px / `RelayType.cta`. Ghost takes `expand` and `height` (Back is 40). `preview` forces hover/press/focus for the gallery |
| `RelayTag.accent`, `Kicker` | `widgets.dart` | |
| `RelaySquareSwitch`, `RelaySegmented`, `RelayInput` | `widgets.dart` | |
| `RelaySheet` / `.show` | `widgets.dart` | scrim is neutral-900 @ 45% |
| `RelayToast` / `.show` | `widgets.dart` | 3.5 s |
| `RelayIcon`, `RelayIcons` | `icons.dart` | Lucide SVG, stroke 1.5, via `flutter_svg`. Includes `check` (granted permission rows) |

Native overlay views ([[Android Overlay and Accessibility]]) reuse the same values via the Kotlin mirror
`ui/RelayColors.kt`. Android XML resources use a second mirror, `res/values/relay_colors.xml`
(`relay_bg`, `relay_accent_400/500/700/900`) — keep both identical to `tokens.dart`.

## App icon and launch screen
From the design's "Launch" screen and app-icon tile (120 px, accent-900 ground): blueprint frame
(accent-700, accent-400 marks), two message lines (accent-500), accent-500 bubble with a 2 px accent-900
ring and the Lucide languages glyph in bg.
- `drawable/ic_launcher_foreground.xml` — the mark. Viewport 180 with the 120 tile at 30,30, so the tile fills
  the launcher's visible 72 of 108 dp. `ic_launcher_monochrome.xml` = Android 13 themed icon (bubble as outline).
- `mipmap-anydpi/ic_launcher.xml` — adaptive icon; minSdk 26 so there are no PNG mipmaps.
- Launch screen: `LaunchTheme` (light + night) → API 26–30 `launch_background.xml` (mark at 180 dp = 120 dp tile),
  API 31+ `windowSplashScreen*` with `splash_icon.xml` (inset so the tile lands at 120 of 288 dp).
  Native only shows the mark; see [[Deviations from Prototype]].

Links: [[Design Source]], [[Flutter App]], [[Screens and Flows]]
