import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/authed_image.dart';
import '../../services/providers.dart';
import '../capture/capture_flow.dart';
import '../history/session_labels.dart';

/// Accueil : explique l'app immédiatement. « À reprendre » et « Votre maison »
/// n'apparaîtront que lorsqu'il existera de vraies données (aucun faux contenu).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    void soon() => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.comingSoon)));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(NalviumSpacing.lg, NalviumSpacing.sm, NalviumSpacing.lg, NalviumSpacing.xl),
          children: [
            Row(
              children: [
                Text(
                  l10n.appName,
                  style: theme.textTheme.titleLarge?.copyWith(color: NalviumColors.blue, letterSpacing: 2.5, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                IconButton(
                  key: const Key('open-history'),
                  tooltip: l10n.history,
                  icon: const Icon(Icons.history_rounded),
                  onPressed: () => context.push('/history'),
                ),
                IconButton(
                  key: const Key('open-settings'),
                  tooltip: l10n.settings,
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
            const SizedBox(height: NalviumSpacing.xl),
            Text(l10n.homeGreeting, style: theme.textTheme.bodyLarge?.copyWith(color: NalviumColors.grey)),
            const SizedBox(height: NalviumSpacing.xs),
            Text(l10n.homeTitle, style: theme.textTheme.headlineLarge),
            const SizedBox(height: NalviumSpacing.md),
            Text(l10n.homeSubtitle, style: theme.textTheme.bodyLarge?.copyWith(color: NalviumColors.grey)),
            const SizedBox(height: NalviumSpacing.xl),
            _PrimaryCameraCta(label: l10n.takePhoto, onPressed: () => startPhotoCapture(context, ref)),
            const SizedBox(height: NalviumSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('describe-problem'),
                    onPressed: () => context.push('/describe'),
                    icon: const Icon(Icons.edit_note_rounded),
                    label: Text(l10n.describeProblem),
                  ),
                ),
                const SizedBox(width: NalviumSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('film-problem'),
                    onPressed: soon,
                    icon: const Icon(Icons.videocam_outlined),
                    label: Text(l10n.film),
                  ),
                ),
              ],
            ),
            const _ResumeSection(),
          ],
        ),
      ),
    );
  }
}

/// « À reprendre » : UNIQUEMENT s'il existe une vraie session active côté backend.
class _ResumeSection extends ConsumerWidget {
  const _ResumeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeSessionsProvider).value;
    if (active == null || active.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = active.first;
    return Padding(
      padding: const EdgeInsets.only(top: NalviumSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.resumeSection, style: theme.textTheme.titleLarge),
          const SizedBox(height: NalviumSpacing.md),
          Material(
            color: NalviumColors.surface,
            borderRadius: BorderRadius.circular(NalviumSpacing.radius),
            child: InkWell(
              key: const Key('resume-session'),
              borderRadius: BorderRadius.circular(NalviumSpacing.radius),
              onTap: () => context.push('/session/${s.id}'),
              child: Padding(
                padding: const EdgeInsets.all(NalviumSpacing.md),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: s.firstMediaId == null
                            ? const ColoredBox(color: NalviumColors.blueSoft, child: Icon(Icons.chat_bubble_outline_rounded, color: NalviumColors.blue))
                            : AuthedImage(mediaId: s.firstMediaId!),
                      ),
                    ),
                    const SizedBox(width: NalviumSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sessionTitle(l10n, s), maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(sessionStateLabel(l10n, s), style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    Text(l10n.resumeButton, style: theme.textTheme.titleMedium?.copyWith(color: NalviumColors.blue)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryCameraCta extends StatelessWidget {
  const _PrimaryCameraCta({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NalviumColors.blue,
      borderRadius: BorderRadius.circular(NalviumSpacing.radius + 4),
      child: InkWell(
        key: const Key('take-photo'),
        borderRadius: BorderRadius.circular(NalviumSpacing.radius + 4),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: NalviumSpacing.xl),
          child: Column(
            children: [
              const Icon(Icons.photo_camera_rounded, size: 44, color: Colors.white),
              const SizedBox(height: NalviumSpacing.sm),
              Text(label, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
