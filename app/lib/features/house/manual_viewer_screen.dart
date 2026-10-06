import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/error_panel.dart';
import '../../domain/equipment.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';

final _manualPageProvider = FutureProvider.autoDispose.family<ManualPage, (String, int)>(
  (ref, key) => ref.watch(homeRepositoryProvider).manualPage(key.$1, key.$2),
);

/// Consulter la notice : le texte de chaque page, depuis la copie privée du serveur. Aucune publicité plein écran.
/// [initialPage] permet d'ouvrir directement la page citée par Nalvium.
class ManualViewerScreen extends ConsumerStatefulWidget {
  const ManualViewerScreen({super.key, required this.equipmentId, this.initialPage = 1});
  final String equipmentId;
  final int initialPage;

  @override
  ConsumerState<ManualViewerScreen> createState() => _ManualViewerScreenState();
}

class _ManualViewerScreenState extends ConsumerState<ManualViewerScreen> {
  late int _page = widget.initialPage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final page = ref.watch(_manualPageProvider((widget.equipmentId, _page)));
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(key: const Key('manual-back'), onPressed: () => context.pop()),
        title: Text(l10n.manualTitle, style: NalviumText.title),
      ),
      body: SafeArea(
        child: page.when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Space.gutter),
              child: ErrorPanel(error: e, onRetry: () => ref.invalidate(_manualPageProvider((widget.equipmentId, _page)))),
            ),
          ),
          data: (p) => Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(Space.gutter, Space.x2, Space.gutter, Space.x4),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(l10n.manualPageOf(p.page, p.pageCount), key: const Key('manual-page-title'), style: NalviumText.title.copyWith(fontSize: 19)),
                        ),
                        const SizedBox(height: Space.x1),
                        Text(l10n.manualPrivate, style: NalviumText.caption.copyWith(color: NalviumColors.textMuted)),
                        const SizedBox(height: Space.x4),
                        SelectableText(
                          p.text.trim().isEmpty ? l10n.manualPageEmpty : p.text,
                          key: const Key('manual-page-text'),
                          style: NalviumText.body.copyWith(color: NalviumColors.textPrimary, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.x2, Space.gutter, Space.x3),
                child: Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        key: const Key('manual-prev'),
                        label: l10n.manualPagePrev,
                        onPressed: _page > 1 ? () => setState(() => _page--) : null,
                      ),
                    ),
                    const SizedBox(width: Space.x3),
                    Expanded(
                      child: SecondaryButton(
                        key: const Key('manual-next'),
                        label: l10n.manualPageNext,
                        onPressed: _page < p.pageCount ? () => setState(() => _page++) : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
