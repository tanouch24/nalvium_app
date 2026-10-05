import 'package:flutter/material.dart';

import 'nalvium_colors.dart';

/// Styles typographiques explicites (famille Figtree embarquée).
abstract final class NalviumText {
  static const family = 'Figtree';

  static const display = TextStyle(
    fontFamily: family,
    fontSize: 34,
    height: 1.12,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    color: NalviumColors.textPrimary,
  );
  static const titleLarge = TextStyle(
    fontFamily: family,
    fontSize: 27,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: NalviumColors.textPrimary,
  );
  static const title = TextStyle(
    fontFamily: family,
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: NalviumColors.textPrimary,
  );
  static const bodyLarge = TextStyle(
    fontFamily: family,
    fontSize: 19,
    height: 1.45,
    fontWeight: FontWeight.w500,
    color: NalviumColors.textPrimary,
  );
  static const body = TextStyle(
    fontFamily: family,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: NalviumColors.textSecondary,
  );
  static const caption = TextStyle(
    fontFamily: family,
    fontSize: 13.5,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: NalviumColors.textSecondary,
  );
  static const button = TextStyle(
    fontFamily: family,
    fontSize: 17,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );
  static const wordmark = TextStyle(
    fontFamily: family,
    fontSize: 17,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 3,
    color: NalviumColors.primary,
  );
}
