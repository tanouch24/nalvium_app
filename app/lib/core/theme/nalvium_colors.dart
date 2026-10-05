import 'package:flutter/material.dart';

/// Tokens de couleur Nalvium. Bleu = action, marine = texte, rouge = danger réel uniquement.
abstract final class NalviumColors {
  static const background = Color(0xFFF7F9FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFEEF2F8);

  static const primary = Color(0xFF1E6BFF);
  static const primaryPressed = Color(0xFF1657D6);
  static const primarySoft = Color(0xFFE8F0FF);

  /// Texte bleu sur fond doux (contraste ≥ 4.5:1).
  static const primaryText = Color(0xFF1553CC);

  static const textPrimary = Color(0xFF0B1F44);
  static const textSecondary = Color(0xFF4F5E78);
  static const textMuted = Color(0xFF5E6B85);
  static const borderSubtle = Color(0xFFE3E9F2);

  static const success = Color(0xFF0F7048);
  static const successSoft = Color(0xFFE6F5EE);
  static const warning = Color(0xFF8F5200);
  static const warningSoft = Color(0xFFFFF1DB);
  static const danger = Color(0xFFD6342C);

  /// Texte rouge sur fonds clairs (contraste ≥ 4.5:1) ; `danger` reste pour les aplats/icônes.
  static const dangerText = Color(0xFFB8261F);
  static const dangerPressed = Color(0xFFB92A23);
  static const dangerSoft = Color(0xFFFDECEA);
  static const dangerBackground = Color(0xFFFFF7F6);
}
