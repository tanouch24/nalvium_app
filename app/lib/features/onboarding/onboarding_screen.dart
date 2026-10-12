import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/choice_tile.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/viewfinder.dart';
import '../../domain/home_profile.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import '../capture/capture_flow.dart';
import 'consent_view.dart';
import 'vitals_editor.dart';

/// Premier lancement : bienvenue → accord IA → « Montrez-nous un problème maintenant » (moment wow : un premier
/// résultat en moins d'une minute) → profil de la maison (facultatif) → points vitaux (facultatifs) → « Votre
/// carnet maison est prêt ». L'accord IA vient TOUJOURS avant tout envoi ; sans accord, l'étape wow est sautée.
/// Si l'utilisateur lance un diagnostic tout de suite, le carnet maison lui est reproposé sur l'accueil
/// ([profileOnly] : seulement les questions du profil et les points vitaux).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.profileOnly = false});
  final bool profileOnly;
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Step { welcome, consent, wow, housing, tenure, heating, hotWater, diy, vitals, ready }

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final List<_Step> _steps = widget.profileOnly ? _Step.values.sublist(_Step.housing.index) : _Step.values;
  int _i = 0;
  _Step get _step => _steps[_i];

  void _go(_Step step) {
    HapticFeedback.selectionClick();
    setState(() => _i = _steps.indexOf(step));
  }

  void _next() {
    HapticFeedback.selectionClick();
    setState(() => _i++);
  }

  void _back() {
    if (_i == 0) {
      if (widget.profileOnly && context.canPop()) context.pop();
      return;
    }
    // Sans accord IA, l'étape wow n'a pas été proposée : on revient directement à l'accord.
    final previous = _steps[_i - 1];
    setState(() => _i = previous == _Step.wow && !ref.read(aiConsentProvider) ? _i - 2 : _i - 1);
  }

  /// Moment wow : le diagnostic part tout de suite ; le carnet maison sera reproposé sur l'accueil.
  Future<void> _scanNow(_ScanKind kind) async {
    final router = GoRouter.of(context);
    String? photoPath;
    if (kind == _ScanKind.photo) {
      final photo = await capturePhoto(context, ref);
      if (photo == null || !mounted) return; // annulé : on reste sur l'étape, « Plus tard » reste possible
      photoPath = photo.path;
    }
    await ref.read(localStoreProvider).setOnboarded();
    await ref.read(profileSetupPendingProvider.notifier).set(true);
    switch (kind) {
      case _ScanKind.photo:
        router.push('/capture/preview', extra: photoPath);
      case _ScanKind.describe:
        router.push('/describe');
      case _ScanKind.film:
        router.push('/video/capture');
    }
  }

  Future<void> _answer(HomeProfile Function(HomeProfile) change) async {
    await ref.read(homeProfileProvider.notifier).update(change);
    _next();
  }

  Future<void> _finish() async {
    await ref.read(localStoreProvider).setOnboarded();
    await ref.read(profileSetupPendingProvider.notifier).set(false);
    if (!mounted) return;
    if (widget.profileOnly && context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = ref.watch(homeProfileProvider);
    final showBar = _step != _Step.welcome && _step != _Step.ready;
    final progress = (_i + (widget.profileOnly ? 1 : 0)) / (_steps.length - (widget.profileOnly ? 0 : 1));

    final Widget body = switch (_step) {
      _Step.welcome => _Welcome(onStart: _next),
      _Step.consent => ConsentView(onDone: (accepted) => accepted ? _next() : _go(_Step.housing)),
      _Step.wow => _Wow(onScan: _scanNow, onLater: _next),
      _Step.housing => _Choice(
        title: l10n.obHousingTitle,
        selected: p.housing,
        options: {'apartment': l10n.obHousingApartment, 'house': l10n.obHousingHouse},
        onPick: (v) => _answer((p) => p.copyWith(housing: v)),
        onSkip: _next,
      ),
      _Step.tenure => _Choice(
        title: l10n.obTenureTitle,
        selected: p.tenure,
        options: {'tenant': l10n.obTenureTenant, 'owner': l10n.obTenureOwner},
        onPick: (v) => _answer((p) => p.copyWith(tenure: v)),
        onSkip: _next,
      ),
      _Step.heating => _Choice(
        title: l10n.obHeatingTitle,
        selected: p.heating,
        options: {
          'gas': l10n.obHeatingGas,
          'electric': l10n.obHeatingElectric,
          'heat_pump': l10n.obHeatingHeatPump,
          'oil_wood': l10n.obHeatingOilWood,
          'unknown': l10n.obUnknown,
        },
        onPick: (v) => _answer((p) => p.copyWith(heating: v)),
        onSkip: _next,
      ),
      _Step.hotWater => _Choice(
        title: l10n.obHotWaterTitle,
        selected: p.hotWater,
        options: {'boiler': l10n.obHotWaterBoiler, 'electric_tank': l10n.obHotWaterTank, 'unknown': l10n.obUnknown},
        onPick: (v) => _answer((p) => p.copyWith(hotWater: v)),
        onSkip: _next,
      ),
      _Step.diy => _Choice(
        title: l10n.obDiyTitle,
        selected: p.diyLevel,
        options: {'beginner': l10n.obDiyBeginner, 'handy': l10n.obDiyHandy, 'confident': l10n.obDiyConfident},
        onPick: (v) => _answer((p) => p.copyWith(diyLevel: v)),
        onSkip: _next,
      ),
      _Step.vitals => _Vitals(onContinue: _next),
      _Step.ready => _Ready(onGo: _finish),
    };

    // Bienvenue : le retour système quitte l'app (Android) ; ensuite, il revient à l'étape précédente.
    return PopScope(
      canPop: _i == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showBar)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.x4, Space.x2, Space.gutter, 0),
                  child: Row(
                    children: [
                      IconButton(
                        key: const Key('ob-back'),
                        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: _back,
                      ),
                      const SizedBox(width: Space.x2),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(end: progress),
                            duration: motionDuration(context, const Duration(milliseconds: 260)),
                            builder: (_, v, _) => LinearProgressIndicator(
                              value: v,
                              minHeight: 6,
                              color: NalviumColors.primary,
                              backgroundColor: NalviumColors.surfaceSubtle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: motionDuration(context, const Duration(milliseconds: 240)),
                  child: SingleChildScrollView(
                    key: ValueKey(_step),
                    padding: const EdgeInsets.fromLTRB(Space.gutter, Space.x6, Space.gutter, Space.x8),
                    child: body,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget bullet(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: Space.x3),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: NalviumColors.surface, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: NalviumColors.textPrimary, size: 22),
          ),
          const SizedBox(width: Space.x4),
          Expanded(child: Text(text, style: NalviumText.body.copyWith(color: NalviumColors.textPrimary, fontSize: 16.5))),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.appName.toLowerCase(), style: NalviumText.wordmark, textScaler: TextScaler.noScaling),
        const SizedBox(height: Space.x8),
        ClipRRect(
          borderRadius: BorderRadius.circular(Corner.large),
          child: Image.asset(
            'assets/images/home_hero.jpg',
            height: 200,
            fit: BoxFit.cover,
            alignment: const Alignment(0, 0.15),
            cacheWidth: 1080,
            excludeFromSemantics: true,
          ),
        ),
        const SizedBox(height: Space.x6),
        Semantics(header: true, child: Text(l10n.obWelcomeTitle, key: const Key('ob-welcome'), style: NalviumText.display)),
        const SizedBox(height: Space.x3),
        Text(l10n.obWelcomeBody, style: NalviumText.body.copyWith(fontSize: 17)),
        const SizedBox(height: Space.x6),
        bullet(Icons.photo_camera_outlined, l10n.obWelcomeBullet1),
        bullet(Icons.euro_rounded, l10n.obWelcomeBullet2),
        bullet(Icons.house_outlined, l10n.obWelcomeBullet3),
        const SizedBox(height: Space.x4),
        PrimaryButton(key: const Key('ob-start'), label: l10n.obStart, onPressed: onStart),
      ],
    );
  }
}

enum _ScanKind { photo, describe, film }

/// « Montrez-nous un problème maintenant » : photo (le plus rapide), décrire ou filmer ; « Plus tard » mène au
/// profil de la maison.
class _Wow extends StatelessWidget {
  const _Wow({required this.onScan, required this.onLater});
  final ValueChanged<_ScanKind> onScan;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stack = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final describe = SecondaryButton(
      key: const Key('ob-wow-describe'),
      label: l10n.describeShort,
      icon: Icons.edit_note_rounded,
      onPressed: () => onScan(_ScanKind.describe),
    );
    final film = SecondaryButton(
      key: const Key('ob-wow-film'),
      label: l10n.filmShort,
      icon: Icons.videocam_outlined,
      onPressed: () => onScan(_ScanKind.film),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Viseur qui « se pose » : discret, et immédiat si les animations sont réduites.
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: motionDuration(context, const Duration(milliseconds: 700)),
          curve: Curves.easeOutCubic,
          builder: (_, v, child) => Opacity(
            opacity: v,
            child: Transform.scale(scale: 0.94 + 0.06 * v, child: child),
          ),
          child: Container(
            height: stack ? 120 : 168,
            decoration: BoxDecoration(color: NalviumColors.surface, borderRadius: BorderRadius.circular(Corner.large)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const Padding(
                  padding: EdgeInsets.all(Space.x5),
                  child: ViewfinderCorners(color: NalviumColors.accent, length: 26, stroke: 3.5, radius: 12),
                ),
                Center(child: Icon(Icons.photo_camera_outlined, size: stack ? 36 : 48, color: NalviumColors.textPrimary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.x6),
        Semantics(
          header: true,
          child: Text(l10n.obWowTitle, key: const Key('ob-wow'), style: NalviumText.titleLarge.copyWith(fontSize: 29)),
        ),
        const SizedBox(height: Space.x3),
        Text(l10n.obWowBody, style: NalviumText.body.copyWith(fontSize: 17)),
        const SizedBox(height: Space.x6),
        PrimaryButton(
          key: const Key('ob-wow-photo'),
          label: l10n.takePhoto,
          icon: Icons.photo_camera_outlined,
          onPressed: () => onScan(_ScanKind.photo),
        ),
        const SizedBox(height: Space.x3),
        if (stack) ...[describe, const SizedBox(height: Space.x3), film]
        else
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [Expanded(child: describe), const SizedBox(width: Space.x3), Expanded(child: film)],
            ),
          ),
        const SizedBox(height: Space.x3),
        TertiaryButton(key: const Key('ob-wow-later'), label: l10n.obWowLater, color: NalviumColors.textSecondary, onPressed: onLater),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.title,
    required this.options,
    required this.selected,
    required this.onPick,
    required this.onSkip,
  });
  final String title;
  final Map<String, String> options;
  final String? selected;
  final ValueChanged<String> onPick;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(title, style: NalviumText.titleLarge.copyWith(fontSize: 29))),
        const SizedBox(height: Space.x2),
        Text(l10n.obProfileHint, style: NalviumText.body),
        const SizedBox(height: Space.x6),
        for (final o in options.entries) ...[
          ChoiceTile(
            key: Key('ob-${o.key}'),
            label: o.value,
            icon: selected == o.key ? Icons.check_circle_rounded : null,
            onTap: () => onPick(o.key),
          ),
          const SizedBox(height: Space.x2 + 2),
        ],
        const SizedBox(height: Space.x2),
        TertiaryButton(key: const Key('ob-skip'), label: l10n.obSkip, color: NalviumColors.textSecondary, onPressed: onSkip),
      ],
    );
  }
}

class _Vitals extends StatelessWidget {
  const _Vitals({required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.vitalsOptional,
          style: NalviumText.caption.copyWith(color: NalviumColors.primaryText, fontWeight: FontWeight.w800, letterSpacing: 0.6),
        ),
        const SizedBox(height: Space.x2),
        Semantics(header: true, child: Text(l10n.vitalsTitle, key: const Key('ob-vitals'), style: NalviumText.titleLarge.copyWith(fontSize: 29))),
        const SizedBox(height: Space.x3),
        Text(l10n.vitalsBody, style: NalviumText.body),
        const SizedBox(height: Space.x6),
        const VitalsEditor(),
        const SizedBox(height: Space.x4),
        PrimaryButton(key: const Key('ob-vitals-continue'), label: l10n.obContinue, onPressed: onContinue),
        const SizedBox(height: Space.x1),
        TertiaryButton(key: const Key('ob-vitals-later'), label: l10n.obLater, color: NalviumColors.textSecondary, onPressed: onContinue),
      ],
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.onGo});
  final VoidCallback onGo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Space.x10),
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: motionDuration(context, const Duration(milliseconds: 900)),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => SizedBox(
              width: 132,
              height: 132,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: v,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      color: NalviumColors.accent,
                      backgroundColor: NalviumColors.surfaceSubtle,
                    ),
                  ),
                  Icon(Icons.house_rounded, size: 48, color: NalviumColors.textPrimary.withValues(alpha: v)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: Space.x8),
        Semantics(
          header: true,
          child: Text(l10n.obReadyTitle, key: const Key('ob-ready'), textAlign: TextAlign.center, style: NalviumText.titleLarge.copyWith(fontSize: 29)),
        ),
        const SizedBox(height: Space.x3),
        Text(l10n.obReadyBody, textAlign: TextAlign.center, style: NalviumText.body.copyWith(fontSize: 17)),
        const SizedBox(height: Space.x8),
        PrimaryButton(key: const Key('ob-go'), label: l10n.obReadyGo, onPressed: onGo),
      ],
    );
  }
}
