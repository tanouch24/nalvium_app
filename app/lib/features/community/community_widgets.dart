import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exceptions.dart';
import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/choice_tile.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';

String categoryName(AppLocalizations l10n, String? c) => switch (c) {
  'plumbing' => l10n.cmCatPlumbing,
  'appliance' => l10n.cmCatAppliance,
  'handyman' => l10n.cmCatHandyman,
  'other' => l10n.cmCatOther,
  _ => '',
};

/// Image publique de la Communauté (liste ou détail). Placeholder sobre si indisponible.
class CommunityImage extends ConsumerWidget {
  const CommunityImage({super.key, required this.mediaId, required this.variant, this.fit = BoxFit.cover, this.semanticLabel});
  final String mediaId;
  final String variant; // thumb | large
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(communityImageProvider((mediaId, variant))).value;
    const placeholder = ColoredBox(color: NalviumColors.surfaceSubtle, child: Center(child: Icon(Icons.image_outlined, color: NalviumColors.textMuted)));
    if (source == null) return placeholder;
    return Image.network(
      source.url,
      headers: source.headers,
      fit: fit,
      semanticLabel: semanticLabel,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (_, child, p) => p == null ? child : placeholder,
    );
  }
}

/// Petite pastille d'action (Utile / Enregistrer) : icône + texte, jamais la couleur seule.
class CommunityAction extends StatelessWidget {
  const CommunityAction({super.key, required this.icon, required this.label, required this.onTap, this.active = false, this.activeIcon});
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? NalviumColors.primaryText : NalviumColors.textSecondary;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(Corner.small),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.x2),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(active ? (activeIcon ?? icon) : icon, size: 22, color: color),
              const SizedBox(width: 6),
              Flexible(child: Text(label, style: NalviumText.caption.copyWith(color: color, fontWeight: active ? FontWeight.w700 : FontWeight.w600))),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Feuille de signalement : une raison, une confirmation calme. Un membre ne peut signaler qu'une fois la même cible.
Future<void> showReportSheet(BuildContext context, WidgetRef ref, {required Future<bool> Function(String reason) send}) async {
  final l10n = AppLocalizations.of(context);
  final reasons = {
    'dangerous': l10n.cmReasonDangerous,
    'spam': l10n.cmReasonSpam,
    'inappropriate': l10n.cmReasonInappropriate,
    'personal_info': l10n.cmReasonPersonal,
    'other': l10n.cmReasonOther,
  };
  final reason = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: NalviumColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Corner.large))),
    builder: (sheet) => Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.x6, Space.gutter, Space.x6),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l10n.cmReportTitle, key: const Key('report-title'), style: NalviumText.titleLarge),
          const SizedBox(height: Space.x4),
          for (final e in reasons.entries) ...[
            ChoiceTile(key: Key('report-${e.key}'), label: e.value, onTap: () => Navigator.of(sheet).pop(e.key)),
            const SizedBox(height: Space.x2),
          ],
        ]),
      ),
    ),
  );
  if (reason == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final created = await send(reason);
    messenger.showSnackBar(SnackBar(content: Text(created ? l10n.cmReported : l10n.cmReportedAlready)));
  } on ApiException {
    messenger.showSnackBar(SnackBar(content: Text(l10n.cmActionFail)));
  }
}
