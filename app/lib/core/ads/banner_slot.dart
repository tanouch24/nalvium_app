import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/providers.dart';
import 'banner_policy.dart';
import 'route_path.dart';

/// L'unique emplacement de bannière Nalvium. Il se montre ou se retire selon la route (BannerPolicy).
/// [inTabs] : hébergé par la barre de navigation (onglets) ; sinon hébergé sous les écrans empilés.
class BannerSlot extends ConsumerWidget {
  const BannerSlot({super.key, required this.router, required this.inTabs});
  final GoRouter router;
  final bool inTabs;

  static bool visibleFor(String path, {required bool inTabs}) =>
      BannerPolicy.allowedFor(path) && BannerPolicy.isTab(path) == inTabs;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ValueListenableBuilder<String>(
    valueListenable: RoutePath.of(router),
    builder: (context, path, _) {
      if (!visibleFor(path, inTabs: inTabs)) return const SizedBox.shrink();
      final banner = ref.watch(adsServiceProvider).buildBanner();
      // Hors onglets, la bannière est tout en bas : elle respecte la zone de sécurité du système.
      return inTabs ? banner : SafeArea(top: false, child: banner);
    },
  );
}
