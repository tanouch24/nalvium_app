import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/buttons.dart';
import '../../domain/home_profile.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';

/// Appel téléphonique (surchargé en test). Ne lance jamais l'appel seul : il ouvre le composeur du téléphone.
final phoneDialerProvider = Provider<Future<void> Function(String number)>(
  (ref) => (number) async {
    await launchUrl(Uri(scheme: 'tel', path: number.replaceAll(' ', '')));
  },
);

/// Urgence : consignes de mise en sécurité FIXES (aucune IA), numéros officiels, et les points vitaux de
/// l'utilisateur s'il les a photographiés. Disponible même sans réseau.
class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vitals = ref.watch(homeProfileProvider).vitals;
    final call = ref.read(phoneDialerProvider);
    return Scaffold(
      backgroundColor: NalviumColors.dangerBackground,
      appBar: AppBar(
        backgroundColor: NalviumColors.dangerBackground,
        title: Text(l10n.emergency, style: NalviumText.title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.x10),
          children: [
            Semantics(header: true, child: Text(l10n.emTitle, key: const Key('em-title'), style: NalviumText.titleLarge)),
            const SizedBox(height: Space.x2),
            Text(l10n.emIntro, style: NalviumText.body.copyWith(color: NalviumColors.dangerText, fontWeight: FontWeight.w600)),
            const SizedBox(height: Space.x5),
            _Situation(
              key: const Key('em-leak'),
              icon: Icons.water_drop_outlined,
              title: l10n.emLeakTitle,
              steps: [l10n.emLeak1, l10n.emLeak2, l10n.emLeak3, l10n.emLeak4],
              vital: vitals[VitalPoint.waterValve],
              vitalLabel: l10n.emYourValve,
            ),
            _Situation(
              key: const Key('em-gas'),
              icon: Icons.local_fire_department_outlined,
              title: l10n.emGasTitle,
              steps: [l10n.emGas1, l10n.emGas2, l10n.emGas3, l10n.emGas4],
              vital: vitals[VitalPoint.gasMeter],
              vitalLabel: l10n.emYourGas,
              action: _CallButton(
                key: const Key('em-call-gas'),
                label: l10n.emGasCall,
                hint: l10n.emGasCallHint,
                onTap: () => call('0800473333'),
              ),
            ),
            _Situation(
              key: const Key('em-power'),
              icon: Icons.bolt_rounded,
              title: l10n.emPowerTitle,
              steps: [l10n.emPower1, l10n.emPower2, l10n.emPower3, l10n.emPower4],
              vital: vitals[VitalPoint.electricalPanel],
              vitalLabel: l10n.emYourPanel,
            ),
            const SizedBox(height: Space.x2),
            Semantics(header: true, child: Text(l10n.emNumbers, style: NalviumText.title.copyWith(fontSize: 19))),
            const SizedBox(height: Space.x3),
            _CallButton(key: const Key('em-call-18'), label: l10n.emCall18, onTap: () => call('18')),
            const SizedBox(height: Space.x2),
            _CallButton(key: const Key('em-call-15'), label: l10n.emCall15, onTap: () => call('15')),
            const SizedBox(height: Space.x2),
            _CallButton(key: const Key('em-call-112'), label: l10n.emCall112, onTap: () => call('112')),
            const SizedBox(height: Space.x6),
            SecondaryButton(
              key: const Key('em-diagnose'),
              label: l10n.emDiagnose,
              icon: Icons.photo_camera_outlined,
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Situation extends StatelessWidget {
  const _Situation({
    super.key,
    required this.icon,
    required this.title,
    required this.steps,
    required this.vital,
    required this.vitalLabel,
    this.action,
  });
  final IconData icon;
  final String title;
  final List<String> steps;
  final VitalInfo? vital;
  final String vitalLabel;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final photo = vital?.photoPath;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x4),
      child: Container(
        padding: const EdgeInsets.all(Space.x4),
        decoration: BoxDecoration(color: NalviumColors.surface, borderRadius: BorderRadius.circular(Corner.medium)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: NalviumColors.dangerText),
                const SizedBox(width: Space.x2),
                Expanded(child: Semantics(header: true, child: Text(title, style: NalviumText.title.copyWith(fontSize: 18)))),
              ],
            ),
            const SizedBox(height: Space.x3),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.x2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 26,
                      child: Text('${i + 1}.', style: NalviumText.body.copyWith(fontWeight: FontWeight.w800, color: NalviumColors.textPrimary)),
                    ),
                    Expanded(child: Text(steps[i], style: NalviumText.body.copyWith(color: NalviumColors.textPrimary))),
                  ],
                ),
              ),
            if (photo != null && File(photo).existsSync()) ...[
              const SizedBox(height: Space.x2),
              Text(vitalLabel, style: NalviumText.caption.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: Space.x1),
              ClipRRect(
                borderRadius: BorderRadius.circular(Corner.small),
                child: Image.file(File(photo), height: 160, fit: BoxFit.cover, cacheWidth: 900, semanticLabel: vitalLabel),
              ),
            ],
            if (action != null) ...[const SizedBox(height: Space.x3), action!],
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({super.key, required this.label, required this.onTap, this.hint});
  final String label;
  final String? hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: Material(
      color: NalviumColors.danger,
      borderRadius: BorderRadius.circular(Corner.medium),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Space.tap),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.x4, vertical: Space.x3),
            child: Row(
              children: [
                const Icon(Icons.call_rounded, color: Colors.white),
                const SizedBox(width: Space.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: NalviumText.button.copyWith(color: Colors.white)),
                      if (hint != null)
                        Text(hint!, style: NalviumText.caption.copyWith(color: Colors.white.withValues(alpha: 0.9))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
