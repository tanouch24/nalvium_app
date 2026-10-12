import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/motion.dart';
import '../../domain/estimate.dart';
import '../../domain/home_profile.dart';
import '../../domain/session.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import '../house/maintenance_section.dart';
import '../share/share_card.dart';

/// Économies estimées : diagnostics RÉSOLUS que l'utilisateur pouvait faire lui-même (faisabilité > 3).
({int total, int repairs}) savingsOf(List<SessionSummary> sessions) {
  var total = 0, repairs = 0;
  for (final s in sessions) {
    final e = s.estimate;
    if (s.status != 'resolved' || e == null || e.diyFeasibility <= 3) continue;
    final saved = e.savings;
    if (saved == null) continue;
    total += saved;
    repairs++;
  }
  return (total: total, repairs: repairs);
}

/// Paliers d'économies célébrés sur l'accueil.
const kSavingsMilestones = [50, 100, 250, 500, 1000];

/// Plus haut palier atteint (null en dessous de 50 €).
int? savingsMilestone(int total) {
  int? reached;
  for (final m in kSavingsMilestones) {
    if (total >= m) reached = m;
  }
  return reached;
}

/// Tableau de bord de l'accueil : suivi de la maison, économies, prochain entretien, urgence.
/// Uniquement des données réelles (profil local, diagnostics du serveur) : aucun chiffre inventé.
class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = ref.watch(homeProfileProvider);
    final now = ref.watch(clockProvider)();
    final score = homeFollowUpScore(p, now);
    final tasks = MaintenanceTask.forProfile(p);
    final due = tasks.where((t) => !t.isUpToDate(p, now)).length;
    final vitalsKnown = VitalPoint.values.where((v) => p.vitals[v]?.known ?? false).length;
    final next = nextMaintenance(p, now);
    final sessions = ref.watch(allSessionsProvider);
    final saved = savingsOf(sessions.value ?? const []);
    final milestone = savingsMilestone(saved.total);

    final band = score >= 75 ? l10n.dashFollowUpGood : (score >= 40 ? l10n.dashFollowUpMid : l10n.dashFollowUpLow);
    final hint = vitalsKnown == 0 ? l10n.dashAddVitals : l10n.dashTasksDue(due);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CompleteProfileCard(),
        _Card(
          key: const Key('dash-follow-up'),
          onTap: () => context.go('/house'),
          child: Row(
            children: [
              _Ring(value: score / 100, label: '$score'),
              const SizedBox(width: Space.x5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.dashFollowUp, style: NalviumText.caption),
                    const SizedBox(height: 2),
                    Text(band, style: NalviumText.title.copyWith(fontSize: 19)),
                    const SizedBox(height: 2),
                    Text(hint, style: NalviumText.caption.copyWith(color: NalviumColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.x3),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Card(
                  key: const Key('dash-savings'),
                  dark: true,
                  onTap: () => context.go('/history'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(l10n.dashSaved, style: NalviumText.caption.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                          ),
                          if (saved.total > 0) _ShareSavings(total: saved.total, milestone: milestone),
                        ],
                      ),
                      const SizedBox(height: Space.x1),
                      if (saved.repairs > 0) ...[
                        _SavingsAmount(total: saved.total),
                        Text(
                          l10n.dashSavedRepairs(saved.repairs),
                          style: NalviumText.caption.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                        ),
                        if (milestone != null) ...[
                          const SizedBox(height: Space.x2),
                          Row(
                            key: const Key('dash-milestone'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1),
                                child: Icon(Icons.workspace_premium_rounded, size: 16, color: NalviumColors.accentSoft),
                              ),
                              const SizedBox(width: Space.x1),
                              Expanded(
                                child: Text(
                                  // Insécable : « 250 € » ne se coupe jamais en fin de ligne.
                                  l10n.dashMilestone(formatEurosInt(milestone).replaceAll(' €', '\u00a0€')),
                                  style: NalviumText.caption.copyWith(color: NalviumColors.accentSoft, fontWeight: FontWeight.w700, fontSize: 12.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ] else
                        Text(
                          l10n.dashSavedEmpty,
                          style: NalviumText.caption.copyWith(color: Colors.white.withValues(alpha: 0.9), fontSize: 13.5),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: Space.x3),
              Expanded(
                child: _Card(
                  key: const Key('dash-next-task'),
                  onTap: () => context.go('/house'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.dashNextTask, style: NalviumText.caption),
                      const SizedBox(height: Space.x1),
                      if (next != null) ...[
                        Text(next.labels(l10n).$1, style: NalviumText.title.copyWith(fontSize: 16.5, height: 1.25)),
                        const SizedBox(height: 2),
                        Text(
                          maintenanceStatus(l10n, next, p, now),
                          style: NalviumText.caption.copyWith(color: NalviumColors.primaryText, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.x3),
        Semantics(
          button: true,
          child: Material(
            color: NalviumColors.dangerSoft,
            borderRadius: BorderRadius.circular(Corner.medium),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const Key('open-emergency'),
              onTap: () => context.push('/emergency'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.x4, vertical: Space.x3 + 2),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(color: NalviumColors.danger, shape: BoxShape.circle),
                      child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: Space.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.emergency, style: NalviumText.title.copyWith(fontSize: 16.5, color: NalviumColors.dangerText)),
                          Text(l10n.emergencyHint, style: NalviumText.caption.copyWith(color: NalviumColors.dangerText)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: NalviumColors.dangerText),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Total économisé : compte de l'ancien total vu vers le nouveau, seulement s'il a augmenté depuis la
/// dernière visite (mémorisé sur le téléphone). Réduire les animations : le chiffre s'affiche directement.
class _SavingsAmount extends ConsumerStatefulWidget {
  const _SavingsAmount({required this.total});
  final int total;

  @override
  ConsumerState<_SavingsAmount> createState() => _SavingsAmountState();
}

class _SavingsAmountState extends ConsumerState<_SavingsAmount> {
  late int _from;

  @override
  void initState() {
    super.initState();
    final seen = ref.read(localStoreProvider).savingsSeen ?? 0;
    _from = seen < widget.total ? seen : widget.total;
    _remember();
  }

  @override
  void didUpdateWidget(_SavingsAmount old) {
    super.didUpdateWidget(old);
    if (old.total != widget.total) _remember();
  }

  void _remember() => ref.read(localStoreProvider).setSavingsSeen(widget.total);

  @override
  Widget build(BuildContext context) {
    final style = NalviumText.display.copyWith(color: Colors.white, fontSize: 30);
    return Semantics(
      label: formatEurosInt(widget.total),
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        key: const Key('dash-savings-amount'),
        tween: Tween(begin: _from.toDouble(), end: widget.total.toDouble()),
        duration: motionDuration(context, const Duration(milliseconds: 800)),
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => Text(formatEurosInt(v.round()), style: style),
      ),
    );
  }
}

/// Partager ses économies (carte « économies » rendue hors écran). Discret, dans le coin de la carte.
class _ShareSavings extends ConsumerStatefulWidget {
  const _ShareSavings({required this.total, this.milestone});
  final int total;
  final int? milestone;

  @override
  ConsumerState<_ShareSavings> createState() => _ShareSavingsState();
}

class _ShareSavingsState extends ConsumerState<_ShareSavings> {
  bool _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final amount = formatEurosInt(widget.total);
    setState(() => _busy = true);
    await shareCard(
      context,
      ref,
      card: SavingsShareCard(
        lead: l10n.shareSavingsLead,
        amount: amount,
        tail: l10n.shareSavingsTail,
        disclaimer: l10n.shareSavingsDisclaimer,
        milestone: widget.milestone == null ? null : l10n.dashMilestone(formatEurosInt(widget.milestone!)),
      ),
      text: l10n.shareSavingsText(amount),
      fileName: 'nalvium-economies.png',
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => Transform.translate(
    // Rentré dans le coin : la zone tactile reste de 48 dp sans agrandir la carte.
    offset: const Offset(Space.x3, -Space.x3),
    child: IconButton(
      key: const Key('dash-share-savings'),
      tooltip: AppLocalizations.of(context).shareSavingsTooltip,
      onPressed: _busy ? null : _share,
      icon: const Icon(Icons.ios_share_rounded, size: 20),
      color: Colors.white,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      padding: EdgeInsets.zero,
    ),
  );
}

/// « Complétez votre carnet maison (1 min) » : seulement si le premier diagnostic a été lancé avant le profil.
/// Discrète, masquable ; disparaît en douceur (immédiatement si les animations sont réduites).
class _CompleteProfileCard extends ConsumerWidget {
  const _CompleteProfileCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pending = ref.watch(profileSetupPendingProvider);
    return AnimatedSize(
      duration: motionDuration(context, const Duration(milliseconds: 280)),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: !pending
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(bottom: Space.x3),
              child: _Card(
                key: const Key('dash-complete-profile'),
                onTap: () => context.push('/profile-setup'),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: NalviumColors.accentSoft, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.house_outlined, color: NalviumColors.primaryText, size: 22),
                    ),
                    const SizedBox(width: Space.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.dashCompleteProfileTitle, style: NalviumText.title.copyWith(fontSize: 16.5, height: 1.25)),
                          const SizedBox(height: 2),
                          Text(l10n.dashCompleteProfileBody, style: NalviumText.caption),
                        ],
                      ),
                    ),
                    Transform.translate(
                      // Rentré dans le coin : zone tactile de 48 dp sans agrandir la carte.
                      offset: const Offset(Space.x3, -Space.x3),
                      child: IconButton(
                        key: const Key('dash-complete-profile-dismiss'),
                        tooltip: l10n.dashCompleteProfileDismiss,
                        onPressed: () => ref.read(profileSetupPendingProvider.notifier).set(false),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: NalviumColors.textMuted,
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({super.key, required this.child, this.onTap, this.dark = false});
  final Widget child;
  final VoidCallback? onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    child: Material(
      color: dark ? NalviumColors.primary : NalviumColors.surface,
      borderRadius: BorderRadius.circular(Corner.large - 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(Space.x4), child: child),
      ),
    ),
  );
}

/// Anneau de suivi (style « calories ») : le chiffre au centre, l'accent cuivre sur le pourtour.
class _Ring extends StatelessWidget {
  const _Ring({required this.value, required this.label});
  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final big = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final size = big ? 76.0 : 96.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: motionDuration(context, const Duration(milliseconds: 900)),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(v),
          child: Center(
            child: Text(label, style: NalviumText.display.copyWith(fontSize: big ? 22 : 28), textScaler: TextScaler.noScaling),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value);
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = NalviumColors.surfaceSubtle;
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = NalviumColors.accent;
    canvas.drawArc(arc, 0, 2 * math.pi, false, base);
    if (value > 0) canvas.drawArc(arc, -math.pi / 2, 2 * math.pi * value.clamp(0, 1), false, fg);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}
