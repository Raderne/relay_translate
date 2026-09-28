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

  /// Onboard primary actions: 48 px tall, 17 px condensed.
  static const cta = TextStyle(
    fontFamily: RelayFonts.heading,
    fontWeight: FontWeight.w600,
    fontSize: 17,
    height: 1.2,
    letterSpacing: -0.255,
  );

  /// Onboard permission numbers (01 / 02).
  static final step = TextStyle(
    fontFamily: RelayFonts.heading,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 1.1,
    color: RelayColors.accent700,
  );

  /// Prototype onboard H1 is 40 px; the scale's [h1] stays 42.
  static final onboardTitle = _heading(40);

  /// Home wordmark. The settings screen's nav brand is 24 px.
  static final brand = _heading(24);

  static const bodyMuted = TextStyle(
    fontFamily: RelayFonts.body,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 1.55,
    color: RelayColors.neutral800,
  );

  static const row = TextStyle(
    fontFamily: RelayFonts.body,
    fontSize: 14,
    height: 1.35,
    color: RelayColors.text,
  );

  static const caption = TextStyle(
    fontFamily: RelayFonts.body,
    fontSize: 11,
    height: 1.2,
    color: RelayColors.accent800,
  );

  /// Home translate-into card language name (prototype 36 px).
  static final langDisplay = TextStyle(
    fontFamily: RelayFonts.heading,
    fontWeight: FontWeight.w600,
    fontSize: 36,
    height: 1.1,
    letterSpacing: -0.015 * 36,
    color: RelayColors.text,
  );

  static const cardCaption = TextStyle(
    fontFamily: RelayFonts.body,
    fontSize: 13,
    height: 1.4,
    color: RelayColors.neutral700,
  );

  static const rowLabel = TextStyle(
    fontFamily: RelayFonts.body,
    fontSize: 15,
    height: 1.35,
    color: RelayColors.text,
  );

  static const sheetRow = TextStyle(
    fontFamily: RelayFonts.body,
    fontSize: 16,
    height: 1.35,
    color: RelayColors.text,
  );

  static const sheetNative = TextStyle(
    fontFamily: RelayFonts.body,
    fontSize: 13,
    height: 1.35,
    color: RelayColors.neutral600,
  );

  static final sheetMark = TextStyle(
    fontFamily: RelayFonts.heading,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    height: 1.2,
    color: RelayColors.accent700,
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
