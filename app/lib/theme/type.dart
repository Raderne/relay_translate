import 'package:flutter/painting.dart';

import 'tokens.dart';

/// Type scale from `styles.css` h1–h6 and body.
class RelayType {
  const RelayType._();

  static final h1 = _heading(42);
  static final h2 = _heading(32);
  static final h3 = _heading(25);
  static final h4 = _heading(20);
  static final h5 = _heading(16);

  /// Uppercase is the caller's job: [TextStyle] cannot transform case. Pass `text.toUpperCase()`.
  static final h6 = TextStyle(
    fontFamily: RelayFonts.heading,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    height: 1.12,
    letterSpacing: 0.08 * 13,
    color: RelayColors.text,
  );

  static const body = TextStyle(
    fontFamily: RelayFonts.body,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 1.55,
    color: RelayColors.text,
  );

  /// 11 px, Barlow 600, tracked uppercase. Accent-700 because accent-on-bg is ~3:1.
  static final kicker = TextStyle(
    fontFamily: RelayFonts.body,
    fontWeight: FontWeight.w600,
    fontSize: 11,
    letterSpacing: 0.1 * 11,
    color: RelayColors.accent700,
  );

  static const button = TextStyle(
    fontFamily: RelayFonts.heading,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 1.2,
    letterSpacing: -0.21,
  );

  static TextStyle _heading(double size) => TextStyle(
    fontFamily: RelayFonts.heading,
    fontWeight: FontWeight.w600,
    fontSize: size,
    height: 1.12,
    letterSpacing: -0.015 * size,
    color: RelayColors.text,
  );
}
