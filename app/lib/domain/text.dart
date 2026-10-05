/// Normalise les caractères typographiques que la police de l'app ne contient pas
/// (ex. trait d'union insécable U+2011 : « au-dessus » s'affichait « au_dessus »).
/// Défense côté client : des messages déjà enregistrés peuvent en contenir.
/// Présentation seulement : le sens du texte n'est jamais modifié.
String cleanText(String s) => s
    .replaceAll(RegExp('[\u2010\u2011\u2012\u2043]'), '-')
    .replaceAll('\u202f', '\u00a0')
    .replaceAll(RegExp('[\u2009\u200a\u2002\u2003]'), ' ')
    .replaceAll(RegExp('[\u200b\u2060\ufeff]'), '')
    .replaceAll(RegExp(r'\*\*|__|`'), '')
    .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
    .trim();
