import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/viewfinder.dart';
import '../../l10n/app_localizations.dart';

/// L'attente (≈10 s) : Nalvium observe CET objet. Les coins du viseur respirent très lentement.
/// Les phrases tournent pour rassurer ; elles ne prétendent JAMAIS qu'une étape précise a eu lieu,
/// et il n'y a ni pourcentage ni barre de progression.
class AnalysisWait extends StatefulWidget {
  const AnalysisWait({
    super.key,
    this.photo,
    this.title,
    this.subject,
    this.video = false,
    required this.onCancel,
  });

  /// Photo observée. Null : variante compacte, sans zone d'image.
  final Widget? photo;

  /// Titre (par défaut « J'analyse le problème… »).
  final String? title;

  /// Description écrite par l'utilisateur, rappelée telle quelle (variante sans photo).
  final String? subject;
  final VoidCallback onCancel;

  /// Variante vidéo : même cadre que la photo, première phrase d'attente adaptée.
  final bool video;

  @override
  State<AnalysisWait> createState() => _AnalysisWaitState();
}

class _AnalysisWaitState extends State<AnalysisWait>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  Timer? _timer;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() => _tick++);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breath.dispose();
    super.dispose();
  }

  String _phrase(AppLocalizations l10n) {
    if (_tick >= 5) return l10n.analyzingSlow; // ≈ 25 s
    final first = widget.video ? l10n.waitVideo : l10n.waitLooking;
    return [
      first,
      l10n.waitObserving,
      l10n.waitChecking,
      first,
      l10n.waitObserving,
    ][_tick];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasPhoto = widget.photo != null;
    final frame = AnimatedBuilder(
      animation: _breath,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_breath.value);
        return SizedBox(
          width: hasPhoto ? 276 : 124,
          height: hasPhoto ? 336 : 124,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: EdgeInsets.all(hasPhoto ? 14 : 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(hasPhoto ? 22 : 20),
                  child:
                      widget.photo ??
                      const ColoredBox(
                        color: NalviumColors.primarySoft,
                        child: Center(
                          child: Icon(
                            Icons.visibility_outlined,
                            size: 40,
                            color: NalviumColors.primary,
                          ),
                        ),
                      ),
                ),
              ),
              // Seuls les coins bougent (4 dp) : la photo, elle, reste immobile.
              ViewfinderCorners(
                color: NalviumColors.primary,
                length: hasPhoto ? 36 : 24,
                stroke: hasPhoto ? 4 : 3.5,
                radius: hasPhoto ? 16 : 12,
                inset: 5 * t,
              ),
            ],
          ),
        );
      },
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.gutter,
          vertical: Space.x6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            frame,
            SizedBox(height: hasPhoto ? Space.x8 : Space.x6),
            Text(
              widget.title ?? l10n.analyzingTitle,
              key: const Key('analyzing-title'),
              style: NalviumText.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (widget.subject != null &&
                widget.subject!.trim().isNotEmpty) ...[
              const SizedBox(height: Space.x3),
              Text(
                '« ${widget.subject!.trim()} »',
                key: const Key('analysis-subject'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: NalviumText.body.copyWith(
                  color: NalviumColors.textPrimary,
                  fontSize: 16,
                ),
              ),
            ],
            const SizedBox(height: Space.x3),
            SizedBox(
              height: 48,
              child: AnimatedSwitcher(
                duration: motionDuration(
                  context,
                  const Duration(milliseconds: 500),
                ),
                child: Text(
                  _phrase(l10n),
                  key: ValueKey(_phrase(l10n)),
                  style: NalviumText.body,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: Space.x2),
            TertiaryButton(
              key: const Key('cancel-analysis'),
              label: l10n.cancel,
              onPressed: widget.onCancel,
              color: NalviumColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
