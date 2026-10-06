import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exceptions.dart';
import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/buttons.dart';
import '../../domain/equipment.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';

/// Zone « Notice constructeur » de la fiche équipement. Discrète : un état, une phrase, une action.
/// Chercher une notice n'est PAS un diagnostic (aucun compteur, aucune publicité).
class ManualSection extends ConsumerStatefulWidget {
  const ManualSection({super.key, required this.equipment, required this.manual});
  final EquipmentSummary equipment;
  final ManualInfo? manual;

  @override
  ConsumerState<ManualSection> createState() => _ManualSectionState();
}

class _ManualSectionState extends ConsumerState<ManualSection> {
  bool _searching = false;
  Object? _error;
  String? _notice;

  bool get _hasReference => (widget.equipment.brand ?? '').isNotEmpty && (widget.equipment.model ?? '').isNotEmpty;

  Future<void> _search() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _searching = true;
      _error = null;
      _notice = null;
    });
    try {
      final r = await ref.read(homeRepositoryProvider).searchManual(widget.equipment.id);
      if (!mounted) return;
      _notice = switch (r.outcome) {
        'up_to_date' => l10n.manualUpToDate,
        'kept' => l10n.manualKept,
        _ => null,
      };
      ref.read(homeRevisionProvider.notifier).bump();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _confirm({required bool accept}) async {
    final repo = ref.read(homeRepositoryProvider);
    final l10n = AppLocalizations.of(context);
    try {
      accept ? await repo.confirmManual(widget.equipment.id) : await repo.deleteManual(widget.equipment.id);
      ref.read(homeRevisionProvider.notifier).bump();
    } on ApiException {
      if (mounted) setState(() => _notice = l10n.manualConfirmFail);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final m = widget.manual;
    final (IconData icon, Color color, String title, String? body, List<Widget> actions) = _state(l10n, m);
    return Container(
      key: const Key('manual-section'),
      width: double.infinity,
      padding: const EdgeInsets.all(Space.x4),
      decoration: BoxDecoration(
        color: NalviumColors.surface,
        borderRadius: BorderRadius.circular(Corner.medium),
        border: Border.all(color: NalviumColors.borderSubtle, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.manualZone, style: NalviumText.caption.copyWith(fontWeight: FontWeight.w700, color: NalviumColors.textMuted)),
          ),
          const SizedBox(height: Space.x2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_searching)
                const Padding(padding: EdgeInsets.only(top: 2), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)))
              else
                Icon(icon, size: 22, color: color),
              const SizedBox(width: Space.x3),
              Expanded(child: Text(title, key: const Key('manual-state'), style: NalviumText.title.copyWith(fontSize: 18))),
            ],
          ),
          if (body != null) ...[
            const SizedBox(height: Space.x1),
            Text(body, key: const Key('manual-body'), style: NalviumText.body.copyWith(fontSize: 15)),
          ],
          if (_notice != null) ...[
            const SizedBox(height: Space.x2),
            Text(_notice!, key: const Key('manual-notice'), style: NalviumText.caption.copyWith(color: NalviumColors.textPrimary)),
          ],
          if (actions.isNotEmpty && !_searching) ...[
            const SizedBox(height: Space.x3),
            ...actions,
          ],
        ],
      ),
    );
  }

  (IconData, Color, String, String?, List<Widget>) _state(AppLocalizations l10n, ManualInfo? m) {
    if (_searching) {
      return (Icons.hourglass_empty_rounded, NalviumColors.primaryText, l10n.manualSearching, l10n.manualSearchingBody, const []);
    }
    if (_error != null) {
      return (
        Icons.error_outline_rounded,
        NalviumColors.warning,
        l10n.manualError,
        l10n.manualErrorBody,
        [SecondaryButton(key: const Key('manual-retry'), label: l10n.manualRetry, onPressed: _search)],
      );
    }
    if (!_hasReference) {
      return (
        Icons.edit_note_rounded,
        NalviumColors.textSecondary,
        l10n.manualNeedRef,
        l10n.manualNeedRefBody,
        const [],
      );
    }
    switch (m?.status) {
      case 'available':
        final pages = m!.pageCount;
        return (
          Icons.menu_book_rounded,
          NalviumColors.success,
          l10n.manualAvailable,
          [
            if (m.official) l10n.manualOfficial,
            if (pages != null) l10n.manualPages(pages),
            if (m.sourceDomain != null) l10n.manualSource(m.sourceDomain!),
          ].join(' · '),
          [
            PrimaryButton(
              key: const Key('manual-consult'),
              label: l10n.manualConsult,
              onPressed: () => context.push('/equipment/${widget.equipment.id}/manual'),
            ),
            TertiaryButton(key: const Key('manual-update'), label: l10n.manualUpdate, color: NalviumColors.textSecondary, onPressed: _search),
          ],
        );
      case 'needs_confirmation':
        return (
          Icons.help_outline_rounded,
          NalviumColors.warning,
          l10n.manualApprox,
          l10n.manualApproxBody,
          [
            PrimaryButton(key: const Key('manual-approx-yes'), label: l10n.manualApproxYes, onPressed: () => _confirm(accept: true)),
            const SizedBox(height: Space.x2),
            SecondaryButton(key: const Key('manual-approx-no'), label: l10n.manualApproxNo, onPressed: () => _confirm(accept: false)),
          ],
        );
      case 'not_found':
        return (
          Icons.search_off_rounded,
          NalviumColors.textSecondary,
          l10n.manualNotFound,
          l10n.manualNotFoundBody,
          [SecondaryButton(key: const Key('manual-retry'), label: l10n.manualRetry, onPressed: _search)],
        );
      case 'error':
        return (
          Icons.error_outline_rounded,
          NalviumColors.warning,
          l10n.manualError,
          l10n.manualErrorBody,
          [SecondaryButton(key: const Key('manual-retry'), label: l10n.manualRetry, onPressed: _search)],
        );
      default:
        return (
          Icons.menu_book_outlined,
          NalviumColors.textSecondary,
          l10n.manualIdle,
          l10n.manualIdleBody,
          [SecondaryButton(key: const Key('manual-search'), label: l10n.manualSearch, icon: Icons.search_rounded, onPressed: _search)],
        );
    }
  }
}
