import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../domain/home_profile.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import '../capture/capture_flow.dart';

extension VitalPointLabels on VitalPoint {
  String label(AppLocalizations l10n) => switch (this) {
    VitalPoint.waterValve => l10n.vitalWaterValve,
    VitalPoint.electricalPanel => l10n.vitalElectricalPanel,
    VitalPoint.gasMeter => l10n.vitalGasMeter,
  };

  IconData get icon => switch (this) {
    VitalPoint.waterValve => Icons.water_drop_outlined,
    VitalPoint.electricalPanel => Icons.bolt_rounded,
    VitalPoint.gasMeter => Icons.local_fire_department_outlined,
  };

  (Color bg, Color fg) get tone => switch (this) {
    VitalPoint.waterValve => (NalviumColors.waterSoft, NalviumColors.water),
    VitalPoint.electricalPanel => (NalviumColors.warningSoft, NalviumColors.warning),
    VitalPoint.gasMeter => (NalviumColors.accentSoft, NalviumColors.primaryText),
  };
}

/// Les trois points vitaux : une photo chacun (facultative), « pas de gaz » possible. Utilisé au démarrage
/// et dans Ma maison.
class VitalsEditor extends ConsumerWidget {
  const VitalsEditor({super.key});

  Future<void> _capture(BuildContext context, WidgetRef ref, VitalPoint point) async {
    final photo = await capturePhoto(context, ref);
    if (photo == null) return;
    final saved = await ref.read(vitalPhotoSaverProvider)(photo.path, point);
    await ref.read(homeProfileProvider.notifier).update(
      (p) => p.copyWith(vitals: {...p.vitals, point: VitalInfo(photoPath: saved)}),
    );
  }

  Future<void> _set(WidgetRef ref, VitalPoint point, VitalInfo? info) =>
      ref.read(homeProfileProvider.notifier).update((p) {
        final next = {...p.vitals};
        if (info == null) {
          next.remove(point);
        } else {
          next[point] = info;
        }
        return p.copyWith(vitals: next);
      });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vitals = ref.watch(homeProfileProvider).vitals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final point in VitalPoint.values) ...[
          _VitalTile(
            point: point,
            info: vitals[point],
            onCapture: () => _capture(context, ref, point),
            onAbsent: point == VitalPoint.gasMeter ? () => _set(ref, point, const VitalInfo(absent: true)) : null,
            onRemove: () => _set(ref, point, null),
            l10n: l10n,
          ),
          const SizedBox(height: Space.x2 + 2),
        ],
      ],
    );
  }
}

class _VitalTile extends StatelessWidget {
  const _VitalTile({
    required this.point,
    required this.info,
    required this.onCapture,
    required this.onAbsent,
    required this.onRemove,
    required this.l10n,
  });
  final VitalPoint point;
  final VitalInfo? info;
  final VoidCallback onCapture;
  final VoidCallback? onAbsent;
  final VoidCallback onRemove;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = point.tone;
    final photo = info?.photoPath;
    final absent = info?.absent ?? false;
    final status = photo != null ? l10n.vitalAdded : (absent ? l10n.vitalAbsent : l10n.vitalTakePhoto);
    return Material(
      color: NalviumColors.surface,
      borderRadius: BorderRadius.circular(Corner.medium),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('vital-${point.name}'),
        onTap: onCapture,
        child: Padding(
          padding: const EdgeInsets.all(Space.x3 + 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: photo != null && File(photo).existsSync()
                          ? Image.file(File(photo), fit: BoxFit.cover, cacheWidth: 160, excludeFromSemantics: true)
                          : ColoredBox(color: bg, child: Icon(point.icon, color: fg, size: 24)),
                    ),
                  ),
                  const SizedBox(width: Space.x3 + 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(point.label(l10n), style: NalviumText.title.copyWith(fontSize: 16.5)),
                        const SizedBox(height: 2),
                        Text(
                          status,
                          style: NalviumText.caption.copyWith(
                            color: info?.known ?? false ? NalviumColors.success : NalviumColors.textSecondary,
                            fontWeight: info?.known ?? false ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    info?.known ?? false ? Icons.check_circle_rounded : Icons.photo_camera_outlined,
                    color: info?.known ?? false ? NalviumColors.success : NalviumColors.textPrimary,
                  ),
                ],
              ),
              if (onAbsent != null && !(info?.known ?? false))
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: Key('vital-${point.name}-absent'),
                    onPressed: onAbsent,
                    style: TextButton.styleFrom(minimumSize: const Size(48, 44), foregroundColor: NalviumColors.primaryText),
                    child: Text(l10n.vitalNoGas),
                  ),
                ),
              if (info?.known ?? false)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: Key('vital-${point.name}-remove'),
                    onPressed: onRemove,
                    style: TextButton.styleFrom(minimumSize: const Size(48, 44), foregroundColor: NalviumColors.textSecondary),
                    child: Text(l10n.vitalRemove),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
