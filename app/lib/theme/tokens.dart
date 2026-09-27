import 'package:flutter/painting.dart';

/// Port of `:root` in `wiki-brain-vault/raw/design/styles.css`.
/// Hex lives only in this file.
class RelayColors {
  const RelayColors._();

  static const bg = Color(0xFFF2F2F3);
  static const surface = Color(0xFFE9E9EA);
  static const text = Color(0xFF1D1F20);
  static const accent = Color(0xFF5980A6);

  /// Text @ 16%. Phase pins this exact value.
  static const divider = Color(0x291D1F20);

  static const text7 = Color(0x121D1F20);
  static const text14 = Color(0x241D1F20);
  static const text45 = Color(0x731D1F20);
  static const text55 = Color(0x8C1D1F20);
  static const text70 = Color(0xB31D1F20);

  /// Accent @ 10% / 18% — ghost hover and press.
  static const accent10 = Color(0x1A5980A6);
  static const accent18 = Color(0x2E5980A6);

  /// Neutral-900 @ 45% — sheet scrim.
  static const scrim = Color(0x732B2B2D);

  static const neutral100 = Color(0xFFF5F5F8);
  static const neutral200 = Color(0xFFE7E7EA);
  static const neutral300 = Color(0xFFD4D4D7);
  static const neutral400 = Color(0xFFB7B7BA);
  static const neutral500 = Color(0xFF98989B);
  static const neutral600 = Color(0xFF7A7A7D);
  static const neutral700 = Color(0xFF5D5D60);
  static const neutral800 = Color(0xFF424244);
  static const neutral900 = Color(0xFF2B2B2D);

  static const accent100 = Color(0xFFEEF6FF);
  static const accent200 = Color(0xFFD6EBFF);
  static const accent300 = Color(0xFFB5D9FD);
  static const accent400 = Color(0xFF94BCE3);
  static const accent500 = Color(0xFF749DC4);
  static const accent600 = Color(0xFF597EA3);
  static const accent700 = Color(0xFF416180);
  static const accent800 = Color(0xFF2C455D);
  static const accent900 = Color(0xFF1D2D3D);

  static const neutral = <int, Color>{
    100: neutral100,
    200: neutral200,
    300: neutral300,
    400: neutral400,
    500: neutral500,
    600: neutral600,
    700: neutral700,
    800: neutral800,
    900: neutral900,
  };

  static const accentRamp = <int, Color>{
    100: accent100,
    200: accent200,
    300: accent300,
    400: accent400,
    500: accent500,
    600: accent600,
    700: accent700,
    800: accent800,
    900: accent900,
  };

  /// Registration-mark color: text @ 55%.
  static const mark = text55;
}

class RelayShadows {
  const RelayShadows._();

  static const sm = <BoxShadow>[
    BoxShadow(color: Color(0x242B2B2D), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const md = <BoxShadow>[
    BoxShadow(color: Color(0x292B2B2D), blurRadius: 10, offset: Offset(0, 3)),
  ];
  static const lg = <BoxShadow>[
    BoxShadow(color: Color(0x382B2B2D), blurRadius: 32, offset: Offset(0, 12)),
  ];
}

/// `--space-1..8`. The scale skips 5 and 7; those steps are not in the CSS.
class RelaySpace {
  const RelaySpace._();

  static const s1 = 3.4;
  static const s2 = 6.8;
  static const s3 = 10.2;
  static const s4 = 13.6;
  static const s6 = 20.4;
  static const s8 = 27.2;
}

class RelayFonts {
  const RelayFonts._();

  static const body = 'Barlow';
  static const heading = 'Barlow Condensed';
}
