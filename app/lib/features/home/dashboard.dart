import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/motion.dart';
import '../../domain/home_profile.dart';
import '../../domain/session.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import '../house/maintenance_section.dart';

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
    final saved = savingsOf(ref.watch(allSessionsProvider).value ?? const []);

    final band = score >= 75 ? l10n.dashFollowUpGood : (score >= 40 ? l10n.dashFollowUpMid : l10n.dashFollowUpLow);
    final hint = vitalsKnown == 0 ? l10n.dashAddVitals : l10n.dashTasksDue(due);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                      Text(l10n.dashSaved, style: NalviumText.caption.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                      const SizedBox(height: Space.x1),
                      if (saved.repairs > 0) ...[
                        Text('${saved.total} €', style: NalviumText.display.copyWith(color: Colors.white, fontSize: 30)),
                        Text(
                          l10n.dashSavedRepairs(saved.repairs),
                          style: NalviumText.caption.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                        ),
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
