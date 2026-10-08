import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/buttons.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import '../../services/tips_service.dart';

/// « Soutenir Nalvium » : trois pourboires au prix du store, paiement Apple / Google, aucune contrepartie.
/// L'app ne renvoie jamais vers un paiement externe.
Future<void> showSupportSheet(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final service = ref.read(tipsServiceProvider);
  final outcome = await showModalBottomSheet<TipOutcome>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: NalviumColors.surface,
    builder: (_) => _SupportSheet(service: service),
  );
  final message = switch (outcome) {
    TipOutcome.thanks => l10n.supportThanks,
    TipOutcome.pending => l10n.supportPending,
    TipOutcome.failed => l10n.supportFailed,
    TipOutcome.cancelled || null => null,
  };
  if (message != null) {
    if (outcome == TipOutcome.thanks) HapticFeedback.mediumImpact();
    messenger.showSnackBar(SnackBar(key: Key('support-${outcome!.name}'), content: Text(message)));
  }
}

class _SupportSheet extends StatefulWidget {
  const _SupportSheet({required this.service});
  final TipsService service;
  @override
  State<_SupportSheet> createState() => _SupportSheetState();
}

class _SupportSheetState extends State<_SupportSheet> {
  late final Future<List<TipProduct>> _products = widget.service.products();
  String? _selected;
  bool _paying = false;

  Future<void> _pay() async {
    final id = _selected;
    if (id == null) return;
    setState(() => _paying = true);
    final outcome = await widget.service.tip(id);
    if (mounted) Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final names = {
      'nalvium.tip.coffee': l10n.supportCoffee,
      'nalvium.tip.two_coffees': l10n.supportTwoCoffees,
      'nalvium.tip.meal': l10n.supportMeal,
    };
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.x5),
        child: FutureBuilder<List<TipProduct>>(
          future: _products,
          builder: (context, snap) {
            final products = snap.data ?? const <TipProduct>[];
            _selected ??= products.length > 1 ? products[1].id : (products.isEmpty ? null : products.first.id);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.supportTitle, key: const Key('support-title'), style: NalviumText.titleLarge.copyWith(fontSize: 24)),
                const SizedBox(height: Space.x2),
                Text(l10n.supportBody, style: NalviumText.body),
                const SizedBox(height: Space.x5),
                if (snap.connectionState != ConnectionState.done)
                  const Padding(padding: EdgeInsets.all(Space.x6), child: Center(child: CircularProgressIndicator()))
                else if (products.isEmpty)
                  Text(l10n.supportUnavailable, key: const Key('support-unavailable'), style: NalviumText.body.copyWith(color: NalviumColors.textPrimary))
                else ...[
                  Row(
                    children: [
                      for (var i = 0; i < products.length; i++) ...[
                        if (i > 0) const SizedBox(width: Space.x2),
                        Expanded(
                          child: _Amount(
                            key: Key('tip-${products[i].id}'),
                            price: products[i].price,
                            label: names[products[i].id] ?? '',
                            selected: _selected == products[i].id,
                            onTap: () => setState(() => _selected = products[i].id),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: Space.x3),
                  Text(l10n.supportNoReward, style: NalviumText.caption),
                  const SizedBox(height: Space.x4),
                  PrimaryButton(key: const Key('support-pay'), label: l10n.supportCta, loading: _paying, onPressed: _pay),
                ],
                const SizedBox(height: Space.x1),
                TertiaryButton(
                  key: const Key('support-later'),
                  label: l10n.supportLater,
                  color: NalviumColors.textSecondary,
                  onPressed: _paying ? null : () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({super.key, required this.price, required this.label, required this.selected, required this.onTap});
  final String price;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? NalviumColors.accentSoft : NalviumColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corner.medium - 2),
        side: BorderSide(color: selected ? NalviumColors.accent : NalviumColors.borderSubtle, width: selected ? 2 : 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 68),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.x2, horizontal: Space.x1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(price, textAlign: TextAlign.center, style: NalviumText.title.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: NalviumText.caption.copyWith(fontSize: 12, color: selected ? NalviumColors.primaryText : NalviumColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Carte discrète après une réparation réussie : le meilleur moment pour proposer un soutien.
class SupportCard extends ConsumerWidget {
  const SupportCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Container(
      key: const Key('support-card'),
      padding: const EdgeInsets.all(Space.x4),
      decoration: BoxDecoration(color: NalviumColors.surface, borderRadius: BorderRadius.circular(Corner.medium)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.supportTitle, style: NalviumText.title.copyWith(fontSize: 17)),
          const SizedBox(height: Space.x1),
          Text(l10n.supportBody, style: NalviumText.caption.copyWith(fontSize: 14)),
          const SizedBox(height: Space.x3),
          SecondaryButton(
            key: const Key('support-open'),
            label: l10n.supportCta,
            icon: Icons.favorite_border_rounded,
            onPressed: () => showSupportSheet(context, ref),
          ),
        ],
      ),
    );
  }
}
