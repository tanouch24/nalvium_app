import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

/// Chemin de la route AFFICHÉE (y compris après un `push`, où `uri` reste celui de la page précédente), exposé comme un ValueListenable sûr :
/// le routeur notifie pendant sa construction, on diffère donc la mise à jour à la fin de l'image.
class RoutePath extends ValueNotifier<String> {
  RoutePath._(this._router) : super(_read(_router)) {
    _router.routerDelegate.addListener(_onChange);
  }

  static final _cache = Expando<RoutePath>('RoutePath');
  static RoutePath of(GoRouter router) => _cache[router] ??= RoutePath._(router);

  final GoRouter _router;

  static String _read(GoRouter r) {
    final matches = r.routerDelegate.currentConfiguration;
    return matches.isEmpty ? '' : matches.last.matchedLocation; // vide avant la première résolution
  }

  void _onChange() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final next = _read(_router);
      if (next != value) value = next;
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }
}
