import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/ads/banner_slot.dart';
import 'core/ads/route_path.dart';
import 'core/router/app_router.dart';
import 'core/theme/nalvium_theme.dart';
import 'l10n/app_localizations.dart';
import 'services/providers.dart';

class NalviumApp extends ConsumerStatefulWidget {
  const NalviumApp({super.key, this.router});
  final GoRouter? router;

  @override
  ConsumerState<NalviumApp> createState() => _NalviumAppState();
}

class _NalviumAppState extends ConsumerState<NalviumApp>
    with WidgetsBindingObserver {
  late final GoRouter _router = widget.router ?? buildRouter();
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Consentement (UMP) puis SDK publicitaire, après le premier affichage.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(adsServiceProvider).initialize(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed && _pausedAt != null) {
      final away = DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      final route = _router.routeInformationProvider.value.uri.path;
      ref
          .read(adsServiceProvider)
          .onAppResumed(route: route, backgroundFor: away);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Nalvium',
      debugShowCheckedModeBanner: false,
      theme: buildNalviumTheme(),
      routerConfig: _router,
      // Bannière des écrans empilés autorisés (historique, fiche équipement…), au même endroit pour tous.
      builder: (context, child) => ValueListenableBuilder<String>(
        valueListenable: RoutePath.of(_router),
        builder: (context, path, _) {
          final show = BannerSlot.visibleFor(path, inTabs: false);
          return Column(
            children: [
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeBottom: show,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
              BannerSlot(router: _router, inTabs: false),
            ],
          );
        },
      ),
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
