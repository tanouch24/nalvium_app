import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Identité anonyme persistante par installation : un UUID aléatoire propre à Nalvium.
/// Ce n'est ni l'IMEI, ni l'Android ID, ni un identifiant publicitaire, ni une empreinte matérielle.
/// Réservé pour rattacher plus tard cet utilisateur anonyme à un compte.
class InstallIdStore {
  InstallIdStore({SharedPreferences? prefs, String Function()? generator})
      : _prefsFuture = prefs != null ? Future.value(prefs) : SharedPreferences.getInstance(),
        _generate = generator ?? (() => const Uuid().v4());

  static const key = 'nalvium.install_id';
  final Future<SharedPreferences> _prefsFuture;
  final String Function() _generate;
  Future<String>? _cached;

  Future<String> getOrCreate() => _cached ??= _load();

  /// Oublie l'identité actuelle (après suppression des données) : la prochaine lecture en crée une NOUVELLE.
  Future<void> reset() async {
    _cached = null;
    final prefs = await _prefsFuture;
    await prefs.remove(key);
  }

  Future<String> _load() async {
    final prefs = await _prefsFuture;
    final existing = prefs.getString(key);
    if (existing != null && Uuid.isValidUUID(fromString: existing)) return existing;
    final id = _generate();
    await prefs.setString(key, id);
    return id;
  }
}
