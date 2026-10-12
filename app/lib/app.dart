import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/nalvium_colors.dart';
import 'core/theme/nalvium_spacing.dart';
import 'core/theme/nalvium_theme.dart';
import 'l10n/app_localizations.dart';
import 'services/providers.dart';
import 'core/analytics/analytics.dart';
import 'features/house/maintenance_reminders.dart';

class NalviumApp extends ConsumerStatefulWidget {
  const NalviumApp({super.key, this.router});
  final GoRouter? router;

  @override
  ConsumerState<NalviumApp> createState() => _NalviumAppState();
}

class _NalviumAppState extends ConsumerState<NalviumApp> {
  late final GoRouter _router =
      widget.router ??
      buildRouter(
        redirect: (_, state) => appGuard(
          onboarded: ref.read(localStoreProvider).onboarded,
          aiConsent: ref.read(aiConsentProvider),
          location: state.matchedLocation,
        ),
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        ref.read(analyticsProvider).log(AnalyticsEvent.appOpened);
        ref.read(tipsServiceProvider); // écoute des achats en attente dès l'ouverture
        _recoverLostPhoto();
        // Rappels d'entretien (seulement s'ils sont déjà activés : aucune autorisation demandée ici).
        // Toucher un rappel ouvre Ma maison.
        ref.read(maintenanceRemindersProvider.notifier).start(onOpen: () => _router.go('/house'));
      },
    );
    // Un entretien noté ou un profil complété : les rappels sont reprogrammés.
    ref.listenManual(homeProfileProvider, (_, _) => ref.read(maintenanceRemindersProvider.notifier).sync());
  }

  /// Photo prise juste avant qu'Android ne ferme l'app : on rouvre son aperçu au lieu de la perdre.
  /// Seulement si l'utilisateur a terminé le démarrage et donné son accord IA.
  Future<void> _recoverLostPhoto() async {
    final photo = await ref.read(photoCaptureServiceProvider).recoverLostPhoto();
    if (photo == null || !mounted) return;
    if (!ref.read(localStoreProvider).onboarded || !ref.read(aiConsentProvider)) return;
    _router.push('/capture/preview', extra: photo.path);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Nalvium',
      debugShowCheckedModeBanner: false,
      theme: buildNalviumTheme(),
      routerConfig: _router,
      builder: (context, child) => ContentWidthLimit(child: child ?? const SizedBox.shrink()),
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

/// Tablettes et grands écrans (Android ignore le verrouillage portrait au-delà de 600 dp) : le contenu garde
/// une largeur de téléphone, centré, et le fond remplit l'écran. Sur téléphone, rien ne change.
class ContentWidthLimit extends StatelessWidget {
  const ContentWidthLimit({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width <= Space.maxContentWidth) return child;
    return ColoredBox(
      color: NalviumColors.background,
      child: Center(
        child: SizedBox(
          width: Space.maxContentWidth,
          // Les écrans qui lisent la taille de l'écran voient la colonne, pas la tablette entière.
          child: MediaQuery(data: media.copyWith(size: Size(Space.maxContentWidth, media.size.height)), child: child),
        ),
      ),
    );
  }
}
