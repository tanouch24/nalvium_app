import 'package:flutter/material.dart';

/// Tokens de couleur Nalvium (direction premium, octobre 2026).
/// Blanc cassé + encre = calme et lisible ; cuivre = UNE seule couleur d'accent ; rouge = danger réel uniquement.
abstract final class NalviumColors {
  static const background = Color(0xFFF6F4EF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFECE8DF);

  /// Action principale : encre (boutons pleins, bouton Scanner).
  static const primary = Color(0xFF15140F);
  static const primaryPressed = Color(0xFF34322B);
  static const primarySoft = Color(0xFFECE8DF);

  /// Texte d'action sur fond clair ou doux (liens, « Continuer ») : cuivre foncé (contraste ≥ 4.5:1).
  static const primaryText = Color(0xFF9A3F14);

  /// Accent cuivre : un geste fort par écran au plus. Texte blanc lisible dessus (≥ 4.5:1).
  static const accent = Color(0xFFB0561F);
  static const accentSoft = Color(0xFFFBE9DF);

  static const textPrimary = Color(0xFF15140F);
  static const textSecondary = Color(0xFF5B574E);
  static const textMuted = Color(0xFF6B675E);
  static const borderSubtle = Color(0xFFE4DFD4);

  /// Eau (points vitaux, urgence fuite).
  static const water = Color(0xFF2A5B85);
  static const waterSoft = Color(0xFFE4EEF6);

  static const success = Color(0xFF2F6B3A);
  static const successSoft = Color(0xFFE3EFE3);
  static const warning = Color(0xFF8A5A00);
  static const warningSoft = Color(0xFFF6EED8);
  static const danger = Color(0xFFC8372D);

  /// Texte rouge sur fonds clairs (contraste ≥ 4.5:1) ; `danger` reste pour les aplats/icônes.
  static const dangerText = Color(0xFFA82A21);
  static const dangerPressed = Color(0xFFA82D24);
  static const dangerSoft = Color(0xFFFBE8E5);
  static const dangerBackground = Color(0xFFFDF5F3);
}
