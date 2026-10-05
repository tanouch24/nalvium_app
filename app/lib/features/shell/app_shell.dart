import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/motion.dart';
import '../../l10n/app_localizations.dart';
import '../capture/capture_flow.dart';

/// Accueil | Maison | [CAMÉRA] | Dépannage | Communauté
/// Le bouton central est une ACTION (pas un onglet) : il ouvre directement la caméra.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _barHeight = 64.0;
  static const _lift = 20.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = navigationShell.currentIndex;

    Widget item(
      int index,
      IconData icon,
      IconData activeIcon,
      String label,
      Key key,
    ) => Expanded(
      child: _NavItem(
        key: key,
        icon: index == current ? activeIcon : icon,
        label: label,
        selected: index == current,
        onTap: () =>
            navigationShell.goBranch(index, initialLocation: index == current),
      ),
    );

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.0, // libellés de navigation à taille fixe (5 destinations sur 360 dp)
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: _barHeight + _lift,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _barHeight,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: NalviumColors.surface,
                      border: Border(
                        top: BorderSide(color: NalviumColors.borderSubtle),
                      ),
                    ),
                    child: Row(
                      children: [
                        item(
                          0,
                          Icons.home_outlined,
                          Icons.home_rounded,
                          l10n.navHome,
                          const Key('nav-home'),
                        ),
                        item(
                          1,
                          Icons.house_outlined,
                          Icons.house_rounded,
                          l10n.navHouse,
                          const Key('nav-house'),
                        ),
                        const Expanded(child: SizedBox.shrink()),
                        item(
                          2,
                          Icons.build_circle_outlined,
                          Icons.build_circle_rounded,
                          l10n.navRepair,
                          const Key('nav-repair'),
                        ),
                        item(
                          3,
                          Icons.groups_outlined,
                          Icons.groups_rounded,
                          l10n.navCommunity,
                          const Key('nav-community'),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _CameraButton(
                      label: l10n.navCamera,
                      onTap: () => startPhotoCapture(context, ref),
                    ),
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

class _NavItem extends StatelessWidget {
  const _NavItem({super.key, required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? NalviumColors.primaryText : NalviumColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: () {
          if (!selected) HapticFeedback.selectionClick();
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: motionDuration(context, const Duration(milliseconds: 180)),
              width: 52,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: selected ? NalviumColors.primarySoft : Colors.transparent, borderRadius: BorderRadius.circular(15)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: NalviumText.caption.copyWith(fontSize: 11, letterSpacing: -0.1, color: color, fontWeight: selected ? FontWeight.w700 : FontWeight.w600),
            ),
          ],
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
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: NalviumColors.surface, width: 4),
        boxShadow: [
          BoxShadow(
            color: NalviumColors.primary.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: NalviumColors.primary,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('nav-camera'),
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          overlayColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.pressed)
                ? NalviumColors.primaryPressed
                : null,
          ),
          child: const SizedBox(
            width: 62,
            height: 62,
            child: Icon(
              Icons.photo_camera_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
        ),
      ),
    ),
  );
}
