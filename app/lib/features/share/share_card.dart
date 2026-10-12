import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/buttons.dart';
import '../../domain/diagnosis.dart';
import '../../domain/estimate.dart';
import '../../domain/session.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import '../history/session_labels.dart';
import '../session/estimate_card.dart';

/// Carte à partager : portrait 4:5, rendue ×3 → PNG 1080 × 1350 (format des réseaux sociaux).
const kShareCardSize = Size(360, 450);
const kShareCardPixelRatio = 3.0;

typedef ShareCardRenderer = Future<Uint8List> Function(Widget card, ui.FlutterView view);

/// Rendu hors écran d'une carte en PNG. Surchargé en test (le vrai rendu exige un moteur graphique).
final shareCardRendererProvider = Provider<ShareCardRenderer>((ref) => renderShareCardPng);

/// Construit [card] dans un arbre isolé (jamais affiché), puis RepaintBoundary.toImage.
/// La carte ne lit ni thème ni traductions : tous ses textes lui sont donnés déjà résolus.
Future<Uint8List> renderShareCardPng(
  Widget card,
  ui.FlutterView view, {
  Size size = kShareCardSize,
  double pixelRatio = kShareCardPixelRatio,
}) async {
  final boundary = RenderRepaintBoundary();
  final renderView = RenderView(
    view: view,
    configuration: ViewConfiguration(logicalConstraints: BoxConstraints.tight(size)),
    child: RenderPositionedBox(child: boundary),
  );
  final pipeline = PipelineOwner()..rootNode = renderView;
  renderView.prepareInitialFrame();
  final focus = FocusManager();
  final build = BuildOwner(focusManager: focus);
  final root = RenderObjectToWidgetAdapter<RenderBox>(
    container: boundary,
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.fromSize(size: size, child: card),
      ),
    ),
  ).attachToRenderTree(build);
  build
    ..buildScope(root)
    ..finalizeTree();
  pipeline
    ..flushLayout()
    ..flushCompositingBits()
    ..flushPaint();
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
    focus.dispose();
  }
}

/// Rend [card] puis ouvre la feuille de partage. Un échec n'est jamais bloquant : simple message.
Future<void> shareCard(
  BuildContext context,
  WidgetRef ref, {
  required Widget card,
  required String text,
  required String fileName,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final box = context.findRenderObject();
  final origin = box is RenderBox && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : null;
  try {
    final png = await ref.read(shareCardRendererProvider)(card, View.of(context));
    await ref.read(shareServiceProvider).shareImage(png, fileName: fileName, text: text, origin: origin);
  } catch (_) {
    messenger.showSnackBar(SnackBar(key: const Key('share-failed'), content: Text(l10n.shareFailed)));
  }
}

/// Carte résultat prête à partager (titre, catégorie, niveau, coûts). Aucune photo, aucune donnée personnelle.
ResultShareCard resultShareCardFor(AppLocalizations l10n, SessionState state) {
  final e = state.estimate!;
  final verdict = e.verdict(diyAllowed: state.diyAllowed);
  final notDiy = verdict == DiyVerdict.pro;
  final level = notDiy
      ? l10n.estHard
      : switch (e.difficulty) {
          'easy' => l10n.estEasy,
          'hard' => l10n.estHard,
          _ => l10n.estMedium,
        };
  final saved = notDiy ? null : e.savings;
  return ResultShareCard(
    title: (state.title ?? '').trim().isEmpty ? l10n.untitledProblem : state.title!.trim(),
    category: categoryLabel(l10n, state.category),
    verdict: verdict,
    verdictLabel: trustBadgeLabel(l10n, verdict),
    level: l10n.shareLevel(level),
    yourselfLabel: notDiy ? l10n.estNotDiy : l10n.estYourself,
    yourself: notDiy ? '—' : formatEuros(e.diyCostMin, e.diyCostMax),
    proLabel: l10n.estPro,
    pro: formatEuros(e.proCostMin, e.proCostMax),
    savings: saved == null ? null : l10n.shareSavingsPossible(formatEurosInt(saved)),
    disclaimer: l10n.shareDisclaimer,
  );
}

/// « Partager » sous la carte résultat. Rien du tout sur un arrêt de sécurité ou sans estimation.
class ShareResultButton extends ConsumerStatefulWidget {
  const ShareResultButton({super.key, required this.state});
  final SessionState state;

  @override
  ConsumerState<ShareResultButton> createState() => _ShareResultButtonState();
}

class _ShareResultButtonState extends ConsumerState<ShareResultButton> {
  bool _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    await shareCard(
      context,
      ref,
      card: resultShareCardFor(l10n, widget.state),
      text: l10n.shareResultText,
      fileName: 'nalvium-diagnostic.png',
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final isStop = s.next?.actionType == NextActionType.safetyStop || s.status == 'stopped';
    if (s.estimate == null || isStop) return const SizedBox.shrink();
    return SecondaryButton(
      key: const Key('share-result'),
      label: AppLocalizations.of(context).shareAction,
      icon: Icons.ios_share_rounded,
      onPressed: _busy ? null : _share,
    );
  }
}

/// Cadre commun : fond Nalvium, logotype en haut, adresse du site en bas.
class _Frame extends StatelessWidget {
  const _Frame({required this.child, required this.footer});
  final Widget child;
  final String footer;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: NalviumColors.background,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(Space.x8 - 4, Space.x8 - 4, Space.x8 - 4, Space.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('nalvium', style: NalviumText.wordmark),
              const SizedBox(width: 6),
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(color: NalviumColors.accent, shape: BoxShape.circle),
              ),
              Expanded(
                child: Text('nalvium.com', maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: NalviumText.caption.copyWith(color: NalviumColors.textMuted, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          Expanded(child: child),
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, size: 13, color: NalviumColors.textMuted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(footer, style: NalviumText.caption.copyWith(fontSize: 11.5, color: NalviumColors.textMuted)),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class ResultShareCard extends StatelessWidget {
  const ResultShareCard({
    super.key,
    required this.title,
    required this.category,
    required this.verdict,
    required this.verdictLabel,
    required this.level,
    required this.yourselfLabel,
    required this.yourself,
    required this.proLabel,
    required this.pro,
    required this.disclaimer,
    this.savings,
  });
  final String title;
  final String category;
  final DiyVerdict verdict;
  final String verdictLabel;
  final String level;
  final String yourselfLabel;
  final String yourself;
  final String proLabel;
  final String pro;
  final String? savings;
  final String disclaimer;

  @override
  Widget build(BuildContext context) => _Frame(
    footer: disclaimer,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Space.x8),
        if (category.isNotEmpty) ...[
          Text(
            category.toUpperCase(),
            style: NalviumText.caption.copyWith(color: NalviumColors.primaryText, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 12),
          ),
          const SizedBox(height: Space.x1 + 2),
        ],
        // Seul bloc élastique : un titre très long se coupe proprement, la carte ne déborde jamais.
        Flexible(
          child: Text(title, maxLines: 3, overflow: TextOverflow.ellipsis, style: NalviumText.titleLarge.copyWith(fontSize: 28)),
        ),
        const SizedBox(height: Space.x4),
        Wrap(
          spacing: Space.x2,
          runSpacing: Space.x2,
          children: [
            TrustBadge(verdict: verdict, label: verdictLabel),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Space.x3, vertical: Space.x1 + 2),
              decoration: const ShapeDecoration(color: NalviumColors.surface, shape: StadiumBorder()),
              child: Text(level, style: NalviumText.caption.copyWith(color: NalviumColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(Space.x4),
          decoration: BoxDecoration(color: NalviumColors.primary, borderRadius: BorderRadius.circular(Corner.medium)),
          child: Row(
            children: [
              Expanded(child: _Cost(label: yourselfLabel, value: yourself)),
              Container(width: 1, height: 44, color: Colors.white.withValues(alpha: 0.2), margin: const EdgeInsets.symmetric(horizontal: Space.x4)),
              Expanded(child: _Cost(label: proLabel, value: pro)),
            ],
          ),
        ),
        if (savings != null) ...[
          const SizedBox(height: Space.x3),
          Text(savings!, style: NalviumText.title.copyWith(fontSize: 19, fontWeight: FontWeight.w800, color: NalviumColors.primaryText)),
        ],
        const SizedBox(height: Space.x4),
      ],
    ),
  );
}

class _Cost extends StatelessWidget {
  const _Cost({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, maxLines: 2, style: NalviumText.caption.copyWith(color: Colors.white.withValues(alpha: 0.8), fontSize: 12.5)),
      const SizedBox(height: 2),
      Text(value, style: NalviumText.titleLarge.copyWith(color: Colors.white, fontSize: 24)),
    ],
  );
}

/// Variante « économies » (accueil) : un seul chiffre, très grand.
class SavingsShareCard extends StatelessWidget {
  const SavingsShareCard({
    super.key,
    required this.lead,
    required this.amount,
    required this.tail,
    required this.disclaimer,
    this.milestone,
  });
  final String lead;
  final String amount;
  final String tail;
  final String disclaimer;
  final String? milestone;

  @override
  Widget build(BuildContext context) => _Frame(
    footer: disclaimer,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(lead, style: NalviumText.title.copyWith(fontSize: 22)),
        const SizedBox(height: Space.x1),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(amount, style: NalviumText.display.copyWith(fontSize: 84, letterSpacing: -3, color: NalviumColors.accent)),
        ),
        const SizedBox(height: Space.x1),
        Text(tail, style: NalviumText.title.copyWith(fontSize: 22)),
        if (milestone != null) ...[
          const SizedBox(height: Space.x5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Space.x3, vertical: Space.x1 + 2),
            decoration: const ShapeDecoration(color: NalviumColors.accentSoft, shape: StadiumBorder()),
            child: Text(milestone!, style: NalviumText.caption.copyWith(color: NalviumColors.primaryText, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ],
      ],
    ),
  );
}

/// Variante « Avant / après » : les DEUX photos de l'utilisateur, seulement quand il touche lui-même
/// « Partager l'avant / après ». Images déjà décodées (le rendu hors écran ne peut pas attendre un chargement).
class BeforeAfterShareCard extends StatelessWidget {
  const BeforeAfterShareCard({
    super.key,
    required this.lead,
    required this.title,
    required this.beforeLabel,
    required this.afterLabel,
    required this.disclaimer,
    this.before,
    this.after,
  });
  final String lead;
  final String title;
  final String beforeLabel;
  final String afterLabel;
  final String disclaimer;
  final ui.Image? before;
  final ui.Image? after;

  @override
  Widget build(BuildContext context) {
    Widget photo(ui.Image? image, String label, {bool accent = false}) => Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Corner.medium),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image == null)
              const ColoredBox(color: NalviumColors.surfaceSubtle)
            else
              RawImage(image: image, fit: BoxFit.cover),
            Positioned(
              left: Space.x2,
              bottom: Space.x2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: Space.x3, vertical: Space.x1),
                decoration: ShapeDecoration(color: accent ? NalviumColors.accent : NalviumColors.primary, shape: const StadiumBorder()),
                child: Text(label, style: NalviumText.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
              ),
            ),
          ],
        ),
      ),
    );
    return _Frame(
      footer: disclaimer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Space.x5),
          Text(
            lead.toUpperCase(),
            style: NalviumText.caption.copyWith(color: NalviumColors.primaryText, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 12),
          ),
          const SizedBox(height: Space.x1),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: NalviumText.titleLarge.copyWith(fontSize: 24)),
          const SizedBox(height: Space.x4),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                photo(before, beforeLabel),
                const SizedBox(width: Space.x2),
                photo(after, afterLabel, accent: true),
              ],
            ),
          ),
          const SizedBox(height: Space.x4),
        ],
      ),
    );
  }
}
