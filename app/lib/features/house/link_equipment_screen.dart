import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exceptions.dart';
import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/error_panel.dart';
import '../../domain/equipment.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import 'add_equipment_screen.dart';
import 'house_widgets.dart';

final _suggestionsProvider = FutureProvider.autoDispose.family<EquipmentSuggestions, String>(
  (ref, sessionId) => ref.watch(homeRepositoryProvider).suggestions(sessionId),
);

/// Rattacher un diagnostic existant à la Maison. Rien n'est lié sans le geste de l'utilisateur :
/// Nalvium PROPOSE (« Est-ce votre lave-vaisselle ? »), l'utilisateur confirme.
class LinkEquipmentScreen extends ConsumerStatefulWidget {
  const LinkEquipmentScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<LinkEquipmentScreen> createState() => _LinkEquipmentScreenState();
}

class _LinkEquipmentScreenState extends ConsumerState<LinkEquipmentScreen> {
  bool _dismissedSuggestion = false;
  bool _busy = false;
  String? _message;

  Future<void> _link(EquipmentSummary e) async {
    final l10n = AppLocalizations.of(context);
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref.read(homeRepositoryProvider).linkSession(widget.sessionId, e.id);
      ref.read(sessionsRevisionProvider.notifier).bump();
      ref.read(homeRevisionProvider.notifier).bump();
      ref.invalidate(sessionProvider(widget.sessionId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.eqLinkDone)));
      context.pop(true);
    } on ApiException {
      if (mounted) setState(() => _message = l10n.eqLinkFail);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createNew(String? detectedType) async {
    final id = await context.push<String>(
      '/equipment/add',
      extra: AddEquipmentArgs(type: detectedType, linkSessionId: widget.sessionId, startAtRoom: detectedType != null),
    );
    if (id == null || !mounted) return;
    ref.invalidate(sessionProvider(widget.sessionId));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).eqLinkDone)));
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final home = ref.watch(homeProvider);
    final suggestions = ref.watch(_suggestionsProvider(widget.sessionId));
    final detected = suggestions.value?.detectedType;
    final match = _dismissedSuggestion ? null : suggestions.value?.matches.firstOrNull;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          key: const Key('link-close'),
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.close,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () => context.pop(false),
        ),
        title: Text(l10n.eqLinkTitle, style: NalviumText.title),
      ),
      body: SafeArea(
        child: home.when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Space.gutter),
              child: ErrorPanel(error: e, onRetry: () => ref.invalidate(homeProvider)),
            ),
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.x2, Space.gutter, Space.x10),
            children: [
              if (match != null) _SuggestionCard(match: match, busy: _busy, onYes: () => _link(match), onNo: () => setState(() => _dismissedSuggestion = true)),
              if (_message != null) ...[
                const SizedBox(height: Space.x3),
                EquipmentNotice(key: const Key('link-error'), text: _message!),
              ],
              const SizedBox(height: Space.x5),
              if (data.equipment.isEmpty)
                Text(l10n.eqLinkNothing, key: const Key('link-nothing'), style: NalviumText.body)
              else ...[
                Semantics(header: true, child: Text(l10n.eqLinkChoose, style: NalviumText.title.copyWith(fontSize: 19))),
                const SizedBox(height: Space.x3),
                for (final e in _sorted(data.equipment, detected))
                  _Pickable(equipment: e, onTap: _busy ? null : () => _link(e)),
              ],
              const SizedBox(height: Space.x5),
              SecondaryButton(
                key: const Key('link-new'),
                label: l10n.eqLinkNew,
                icon: Icons.add_rounded,
                onPressed: _busy ? null : () => _createNew(detected),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Les équipements du type probable d'abord.
  List<EquipmentSummary> _sorted(List<EquipmentSummary> all, String? detected) => [
    ...all.where((e) => e.equipmentType == detected),
    ...all.where((e) => e.equipmentType != detected),
  ];
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.match, required this.busy, required this.onYes, required this.onNo});
  final EquipmentSummary match;
  final bool busy;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = [
      match.displayName.isEmpty ? '' : match.displayName[0].toLowerCase() + match.displayName.substring(1),
      ?match.brand,
      if (match.roomName != null) '(${match.roomName})',
    ].join(' ');
    return Container(
      padding: const EdgeInsets.all(Space.x5),
      decoration: BoxDecoration(color: NalviumColors.primarySoft, borderRadius: BorderRadius.circular(Corner.medium)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              EquipmentAvatar(kind: match.kind, mediaId: match.photoMediaId, size: 48, radius: 14),
              const SizedBox(width: Space.x3),
              Expanded(child: Text(l10n.eqLinkAsk(name), key: const Key('link-ask'), style: NalviumText.title.copyWith(fontSize: 18))),
            ],
          ),
          const SizedBox(height: Space.x4),
          PrimaryButton(key: const Key('link-yes'), label: l10n.eqLinkYes, loading: busy, onPressed: onYes),
          const SizedBox(height: Space.x2),
          SecondaryButton(key: const Key('link-no'), label: l10n.eqLinkNo, onPressed: busy ? null : onNo),
        ],
      ),
    );
  }
}

class _Pickable extends StatelessWidget {
  const _Pickable({required this.equipment, required this.onTap});
  final EquipmentSummary equipment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final e = equipment;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x2),
      child: Material(
        color: NalviumColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corner.medium),
          side: const BorderSide(color: NalviumColors.borderSubtle, width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('link-pick-${e.id}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Space.x3),
            child: Row(
              children: [
                EquipmentAvatar(kind: e.kind, mediaId: e.photoMediaId, size: 48, radius: 14),
                const SizedBox(width: Space.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.displayName, maxLines: 2, overflow: TextOverflow.ellipsis, style: NalviumText.title.copyWith(fontSize: 17)),
                      Text(
                        [?brandModel(e.brand, e.model), ?e.roomName].join(' — '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: NalviumText.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
