import 'package:flutter/material.dart';

import '../theme/nalvium_colors.dart';
import '../theme/nalvium_spacing.dart';

/// État vide honnête : jamais de fausses données.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NalviumSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(color: NalviumColors.blueSoft, shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: NalviumColors.blue),
            ),
            const SizedBox(height: NalviumSpacing.lg),
            Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: NalviumSpacing.sm),
            Text(body, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
