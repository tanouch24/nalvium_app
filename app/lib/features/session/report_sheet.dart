import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/choice_tile.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';

/// Lien discret « Signaler ce résultat », présent sur chaque réponse de Nalvium (exigence des stores pour l'IA).
class ReportResultLink extends ConsumerWidget {
  const ReportResultLink({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    child: TertiaryButton(
      key: const Key('report-result'),
      label: AppLocalizations.of(context).reportResult,
      color: NalviumColors.textMuted,
      onPressed: () => showReportSheet(context, ref, sessionId),
    ),
  );
}

Future<void> showReportSheet(BuildContext context, WidgetRef ref, String sessionId) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final picked = await showModalBottomSheet<(String, String?)>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: NalviumColors.background,
    builder: (_) => const _ReportSheet(),
  );
  if (picked == null) return;
  try {
    await ref.read(sessionsRepositoryProvider).reportResult(sessionId, picked.$1, details: picked.$2);
    messenger.showSnackBar(SnackBar(content: Text(l10n.reportThanks), key: const Key('report-thanks')));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.reportFailed), key: const Key('report-failed')));
  }
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet();
  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String? _reason;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reasons = {
      'wrong': l10n.reportWrong,
      'dangerous': l10n.reportDangerous,
      'offensive': l10n.reportOffensive,
      'other': l10n.reportOther,
    };
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.x5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.reportTitle, key: const Key('report-sheet-title'), style: NalviumText.titleLarge),
              const SizedBox(height: Space.x4),
              for (final r in reasons.entries) ...[
                ChoiceTile(
                  key: Key('report-${r.key}'),
                  label: r.value,
                  icon: _reason == r.key ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  onTap: () => setState(() => _reason = r.key),
                ),
                const SizedBox(height: Space.x2),
              ],
              const SizedBox(height: Space.x2),
              TextField(
                key: const Key('report-details'),
                controller: _details,
                maxLength: 500,
                maxLines: 3,
                minLines: 2,
                decoration: InputDecoration(hintText: l10n.reportDetailsHint),
              ),
              const SizedBox(height: Space.x3),
              PrimaryButton(
                key: const Key('report-send'),
                label: l10n.reportSend,
                onPressed: _reason == null ? null : () => Navigator.of(context).pop((_reason!, _details.text)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
