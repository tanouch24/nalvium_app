import 'package:flutter/material.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../domain/estimate.dart';
import '../../l10n/app_localizations.dart';

/// Carte résultat chiffrée : faisabilité, durée, niveau ; vous-même contre artisan ; pièces à acheter.
/// Toujours présentée comme une ESTIMATION indicative, jamais comme un devis.
class EstimateCard extends StatelessWidget {
  const EstimateCard({super.key, required this.estimate});
  final RepairEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final e = estimate;
    final level = switch (e.difficulty) {
      'easy' => l10n.estEasy,
      'hard' => l10n.estHard,
      _ => l10n.estMedium,
    };
    final notDiy = e.diyFeasibility <= 3;
    final hasCosts = e.diyMid != null || e.proMid != null;

    return Semantics(
      container: true,
      label: l10n.estTitle,
      child: Column(
        key: const Key('estimate-card'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(l10n.estTitle, style: NalviumText.title.copyWith(fontSize: 19))),
          const SizedBox(height: Space.x3),
          _Tiles(children: [
            _Tile(
              label: l10n.estFeasible,
              value: '${e.diyFeasibility}',
              suffix: '/10',
              key: const Key('estimate-feasibility'),
            ),
            if (e.durationMinutes != null)
              _Tile(label: l10n.estDuration, value: formatDuration(e.durationMinutes!)),
            _Tile(label: l10n.estLevel, value: notDiy ? l10n.estHard : level),
          ]),
          if (hasCosts) ...[
            const SizedBox(height: Space.x2),
            Container(
              key: const Key('estimate-costs'),
              padding: const EdgeInsets.all(Space.x4),
              decoration: BoxDecoration(color: NalviumColors.primary, borderRadius: BorderRadius.circular(Corner.medium)),
              child: Row(
                children: [
                  Expanded(
                    child: _Cost(
                      label: notDiy ? l10n.estNotDiy : l10n.estYourself,
                      value: notDiy ? '—' : formatEuros(e.diyCostMin, e.diyCostMax),
                      strong: !notDiy,
                    ),
                  ),
                  Container(width: 1, height: 44, color: Colors.white.withValues(alpha: 0.2), margin: const EdgeInsets.symmetric(horizontal: Space.x4)),
                  Expanded(
                    child: _Cost(
                      label: l10n.estPro,
                      value: formatEuros(e.proCostMin, e.proCostMax),
                      strong: notDiy,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: Space.x2),
          Text(l10n.estDisclaimer, style: NalviumText.caption.copyWith(fontSize: 12.5, color: NalviumColors.textMuted)),
          if (e.parts.isNotEmpty && !notDiy) ...[
            const SizedBox(height: Space.x3),
            Container(
              padding: const EdgeInsets.fromLTRB(Space.x4, Space.x3 + 2, Space.x4, Space.x3),
              decoration: BoxDecoration(color: NalviumColors.surface, borderRadius: BorderRadius.circular(Corner.medium)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.estParts, style: NalviumText.caption.copyWith(fontWeight: FontWeight.w700, color: NalviumColors.textPrimary)),
                  const SizedBox(height: Space.x1),
                  for (final p in e.parts)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text(p.name, style: NalviumText.body.copyWith(fontSize: 15, color: NalviumColors.textPrimary))),
                          if (p.approxEur != null)
                            Text('~${p.approxEur} €', style: NalviumText.body.copyWith(fontSize: 15)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Trois tuiles côte à côte ; à très grande taille de texte, elles passent sur deux lignes.
class _Tiles extends StatelessWidget {
  const _Tiles({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final perRow = MediaQuery.textScalerOf(context).scale(1) >= 1.5 ? 2 : children.length;
      final w = (c.maxWidth - Space.x2 * (perRow - 1)) / perRow;
      return Wrap(
        spacing: Space.x2,
        runSpacing: Space.x2,
        children: [for (final t in children) SizedBox(width: w, child: t)],
      );
    },
  );
}

class _Tile extends StatelessWidget {
  const _Tile({super.key, required this.label, required this.value, this.suffix});
  final String label;
  final String value;
  final String? suffix;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Space.x3),
    decoration: BoxDecoration(color: NalviumColors.surface, borderRadius: BorderRadius.circular(Corner.medium - 2)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: NalviumText.caption.copyWith(fontSize: 12.5)),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: value, style: NalviumText.title.copyWith(fontSize: 20, fontWeight: FontWeight.w800)),
            if (suffix != null)
              TextSpan(text: suffix, style: NalviumText.caption.copyWith(fontWeight: FontWeight.w600)),
          ]),
        ),
      ],
    ),
  );
}

class _Cost extends StatelessWidget {
  const _Cost({required this.label, required this.value, required this.strong});
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: NalviumText.caption.copyWith(color: Colors.white.withValues(alpha: 0.8), fontSize: 12.5)),
      const SizedBox(height: 2),
      Text(
        value,
        style: NalviumText.titleLarge.copyWith(
          color: strong ? Colors.white : Colors.white.withValues(alpha: 0.75),
          fontSize: 24,
        ),
      ),
    ],
  );
}
