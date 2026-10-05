import 'package:flutter/material.dart';

import 'nalvium_colors.dart';
import 'nalvium_spacing.dart';

ThemeData buildNalviumTheme() {
  const scheme = ColorScheme.light(
    primary: NalviumColors.blue,
    onPrimary: Colors.white,
    surface: NalviumColors.surface,
    onSurface: NalviumColors.navy,
    error: NalviumColors.danger,
    secondary: NalviumColors.blue,
  );

  const text = TextTheme(
    headlineLarge: TextStyle(fontSize: 32, height: 1.15, fontWeight: FontWeight.w700, color: NalviumColors.navy, letterSpacing: -0.5),
    headlineMedium: TextStyle(fontSize: 26, height: 1.2, fontWeight: FontWeight.w700, color: NalviumColors.navy, letterSpacing: -0.3),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: NalviumColors.navy),
    titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: NalviumColors.navy),
    bodyLarge: TextStyle(fontSize: 17, height: 1.45, color: NalviumColors.navy),
    bodyMedium: TextStyle(fontSize: 15, height: 1.45, color: NalviumColors.grey),
    labelLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: NalviumColors.background,
    textTheme: text,
    appBarTheme: const AppBarTheme(
      backgroundColor: NalviumColors.background,
      foregroundColor: NalviumColors.navy,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: NalviumColors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(60),
        textStyle: text.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NalviumSpacing.radius)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: NalviumColors.navy,
        minimumSize: const Size.fromHeight(56),
        textStyle: text.labelLarge,
        side: const BorderSide(color: NalviumColors.greyLight, width: 1.5),
        backgroundColor: NalviumColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NalviumSpacing.radius)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: NalviumColors.blue,
        textStyle: text.titleMedium,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: NalviumColors.navy,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NalviumSpacing.radiusSmall)),
    ),
  );
}
