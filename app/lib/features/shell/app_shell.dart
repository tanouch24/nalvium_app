import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../l10n/app_localizations.dart';
import '../capture/capture_flow.dart';

/// Accueil | Maison | [CAMÉRA] | Dépannage | Communauté
/// Le bouton central est une ACTION : il n'a pas de page, il ouvre la caméra.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = navigationShell.currentIndex;

    Widget item(int index, IconData icon, IconData activeIcon, String label, Key key) => Expanded(
          child: _NavItem(
            key: key,
            icon: index == current ? activeIcon : icon,
            label: label,
            selected: index == current,
            onTap: () => navigationShell.goBranch(index, initialLocation: index == current),
          ),
        );

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: NalviumColors.surface,
          border: Border(top: BorderSide(color: NalviumColors.greyLight)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                item(0, Icons.home_outlined, Icons.home_rounded, l10n.navHome, const Key('nav-home')),
                item(1, Icons.house_outlined, Icons.house_rounded, l10n.navHouse, const Key('nav-house')),
                Expanded(child: _CameraButton(label: l10n.navCamera, onTap: () => startPhotoCapture(context, ref))),
                item(2, Icons.build_circle_outlined, Icons.build_circle_rounded, l10n.navRepair, const Key('nav-repair')),
                item(3, Icons.groups_outlined, Icons.groups_rounded, l10n.navCommunity, const Key('nav-community')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({super.key, required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? NalviumColors.blue : NalviumColors.grey;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraButton extends StatelessWidget {
  const _CameraButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: NalviumColors.blue,
          shape: const CircleBorder(),
          elevation: 4,
          shadowColor: NalviumColors.blue.withValues(alpha: 0.5),
          child: InkWell(
            key: const Key('nav-camera'),
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const SizedBox(
              width: 58,
              height: 58,
              child: Icon(Icons.photo_camera_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
