import 'package:flutter/material.dart';

import 'tokens.dart';
import 'type.dart';

export 'icons.dart';
export 'tokens.dart';
export 'type.dart';
export 'widgets.dart';

/// Material shell seeded from the tokens. Not [ColorScheme.fromSeed] — that would re-tone the accent.
class RelayTheme {
  const RelayTheme._();

  static ThemeData get data {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: RelayColors.accent,
      onPrimary: RelayColors.bg,
      secondary: RelayColors.accent700,
      onSecondary: RelayColors.bg,
      error: RelayColors.accent900,
      onError: RelayColors.bg,
      surface: RelayColors.bg,
      onSurface: RelayColors.text,
    );
    const square = RoundedRectangleBorder();
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: RelayColors.bg,
      canvasColor: RelayColors.bg,
      dividerColor: RelayColors.divider,
      focusColor: RelayColors.accent,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      fontFamily: RelayFonts.body,
      textTheme: TextTheme(
        displayLarge: RelayType.h1,
        displayMedium: RelayType.h2,
        displaySmall: RelayType.h3,
        headlineMedium: RelayType.h4,
        headlineSmall: RelayType.h5,
        titleMedium: RelayType.h6,
        bodyLarge: RelayType.body,
        bodyMedium: RelayType.body,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: RelayColors.bg,
        foregroundColor: RelayColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: RelayColors.bg,
        titleTextStyle: RelayType.h4,
      ),
      dividerTheme: const DividerThemeData(color: RelayColors.divider, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: square,
          backgroundColor: RelayColors.accent,
          foregroundColor: RelayColors.bg,
          disabledBackgroundColor: RelayColors.accent,
          disabledForegroundColor: RelayColors.bg,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: square,
          side: const BorderSide(color: RelayColors.divider),
          foregroundColor: RelayColors.text,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: square, foregroundColor: RelayColors.accent),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: RelayColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: RelayColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: RelayColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: RelayColors.accent),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: RelayColors.bg,
        surfaceTintColor: RelayColors.bg,
        shape: square,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: RelayColors.bg,
        surfaceTintColor: RelayColors.bg,
        shape: square,
        dragHandleColor: RelayColors.divider,
      ),
    );
  }
}
