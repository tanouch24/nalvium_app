import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../domain/session.dart';
import '../../l10n/app_localizations.dart';

/// Provenance discrète : « D'après la notice Bosch de votre appareil · Notice · page 31 ».
/// N'existe QUE si le serveur confirme qu'au moins une page de la notice a réellement servi à la réponse.
class ManualCitationLine extends StatelessWidget {
  const ManualCitationLine({super.key, required this.citation, this.equipmentId});
  final ManualCitation citation;
  final String? equipmentId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = citation.manufacturer;
    final pages = citation.pages.join(', ');
    final head = brand == null || brand.isEmpty ? l10n.manualCiteGeneric : l10n.manualCite(brand);
    final tail = citation.pages.length == 1 ? l10n.manualCitePage(pages) : l10n.manualCitePages(pages);
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.only(top: 1), child: Icon(Icons.menu_book_outlined, size: 18, color: NalviumColors.textSecondary)),
        const SizedBox(width: Space.x2),
        Expanded(
          child: Text(
            '$head · $tail',
            key: const Key('manual-citation'),
            style: NalviumText.caption.copyWith(color: NalviumColors.textSecondary),
          ),
        ),
      ],
    );
    if (equipmentId == null) return content;
    return Semantics(
      button: true,
      child: InkWell(
        key: const Key('manual-citation-open'),
        borderRadius: BorderRadius.circular(Corner.small),
        onTap: () => context.push('/equipment/$equipmentId/manual?page=${citation.pages.first}'),
        child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 48), child: Align(alignment: Alignment.centerLeft, child: content)),
      ),
    );
  }
}
