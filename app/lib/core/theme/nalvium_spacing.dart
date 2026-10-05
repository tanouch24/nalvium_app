/// Échelle d'espacement et rayons : peu de valeurs, appliquées partout.
abstract final class Space {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x8 = 32.0;
  static const x10 = 40.0;
  static const x14 = 56.0;

  /// Marge horizontale standard des écrans.
  static const gutter = 24.0;

  /// Hauteur minimale d'une zone tactile principale.
  static const tap = 56.0;
}

/// Trois rayons seulement.
abstract final class Corner {
  static const small = 12.0; // vignettes, champs
  static const medium = 20.0; // boutons, tuiles, cartes
  static const large = 28.0; // grands visuels, feuilles
}
