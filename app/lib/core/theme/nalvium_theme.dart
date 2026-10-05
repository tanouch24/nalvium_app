import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'nalvium_colors.dart';
import 'nalvium_spacing.dart';
import 'nalvium_typography.dart';

const _overlay = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: NalviumColors.surface,
  systemNavigationBarIconBrightness: Brightness.dark,
);

ThemeData buildNalviumTheme() {
  const scheme = ColorScheme.light(
    primary: NalviumColors.primary,
    onPrimary: Colors.white,
    surface: NalviumColors.surface,
    onSurface: NalviumColors.textPrimary,
    error: NalviumColors.danger,
    secondary: NalviumColors.primary,
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: NalviumText.family,
    colorScheme: scheme,
    scaffoldBackgroundColor: NalviumColors.background,
    splashFactory: InkRipple.splashFactory,
    textTheme: const TextTheme(
      headlineLarge: NalviumText.display,
      headlineMedium: NalviumText.titleLarge,
      titleLarge: NalviumText.title,
      titleMedium: NalviumText.title,
      bodyLarge: NalviumText.bodyLarge,
      bodyMedium: NalviumText.body,
      bodySmall: NalviumText.caption,
      labelLarge: NalviumText.button,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: NalviumColors.background,
      foregroundColor: NalviumColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: _overlay,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NalviumColors.surface,
      hintStyle: NalviumText.body.copyWith(color: NalviumColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Space.x5,
        vertical: Space.x4,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Corner.medium),
        borderSide: const BorderSide(
          color: NalviumColors.borderSubtle,
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Corner.medium),
        borderSide: const BorderSide(
          color: NalviumColors.borderSubtle,
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Corner.medium),
        borderSide: const BorderSide(color: NalviumColors.primary, width: 2),
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: NalviumColors.primary,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: NalviumColors.primary,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: NalviumColors.textPrimary,
      contentTextStyle: NalviumText.body.copyWith(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corner.small),
      ),
    ),
  );
}

/// Style de la barre système (icônes sombres) pour les écrans clairs.
const nalviumSystemOverlay = _overlay;
