import 'package:flutter/material.dart';

import '../theme/nalvium_colors.dart';
import '../theme/nalvium_spacing.dart';
import '../theme/nalvium_typography.dart';

/// État vide sobre : une icône, un titre, une phrase. Aucun faux contenu.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.x10,
        vertical: Space.x8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: NalviumColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 42, color: NalviumColors.primary),
          ),
          const SizedBox(height: Space.x6),
          Text(
            title,
            style: NalviumText.title.copyWith(fontSize: 22),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.x2),
          Text(body, style: NalviumText.body, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
