import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/nalvium_spacing.dart';
import '../theme/nalvium_typography.dart';
import 'empty_state.dart';

/// Écran secondaire non construit : titre + état vide.
class EmptyScreen extends StatelessWidget {
  const EmptyScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.emptyTitle,
    required this.emptyBody,
    this.showBack = false,
  });
  final String title;
  final IconData icon;
  final String emptyTitle;
  final String emptyBody;
  final bool showBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      leading: showBack ? BackButton(onPressed: () => context.pop()) : null,
      titleSpacing: showBack ? 0 : Space.gutter,
      title: Text(title, style: NalviumText.titleLarge),
      toolbarHeight: 72,
    ),
    body: SafeArea(
      child: EmptyState(icon: icon, title: emptyTitle, body: emptyBody),
    ),
  );
}
