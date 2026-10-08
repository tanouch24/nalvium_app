import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/motion.dart';
import '../../l10n/app_localizations.dart';
import '../capture/capture_flow.dart';

/// Accueil | Ma maison | Historique, et le bouton Scanner (noir, à droite, en relief).
/// Scanner est une ACTION (pas un onglet) : il ouvre directement la caméra.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _barHeight = 64.0;
  static const _lift = 22.0;
  static const _scanSize = 64.0;

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
        maxScaleFactor: 1.0, // libellés de navigation à taille fixe
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
                        item(
                          2,
                          Icons.history_rounded,
                          Icons.history_rounded,
                          l10n.navHistory,
                          const Key('nav-history'),
                        ),
                        const SizedBox(width: _scanSize + 2 * Space.x4),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: Space.x4,
                  child: _ScanButton(
                    label: l10n.navCamera,
                    size: _scanSize,
                    onTap: () => startPhotoCapture(context, ref),
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
  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? NalviumColors.textPrimary
        : NalviumColors.textMuted;
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
              duration: motionDuration(
                context,
                const Duration(milliseconds: 180),
              ),
              width: 52,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? NalviumColors.primarySoft
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: NalviumText.caption.copyWith(
                fontSize: 11,
                letterSpacing: -0.1,
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({
    required this.label,
    required this.size,
    required this.onTap,
  });
  final String label;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: NalviumColors.primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
          child: SizedBox(
            width: size,
            height: size,
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    ),
  );
}
