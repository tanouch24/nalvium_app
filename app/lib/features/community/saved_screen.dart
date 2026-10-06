import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_typography.dart';
import '../../l10n/app_localizations.dart';
import 'community_screen.dart';

/// Enregistrés : sauvegardes PRIVÉES (personne d'autre ne les voit).
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(key: const Key('saved-back'), onPressed: () => context.pop()),
        title: Text(l10n.cmSaved, style: NalviumText.titleLarge),
        toolbarHeight: 72,
      ),
      body: const SafeArea(child: PostList(saved: true)),
    );
  }
}
