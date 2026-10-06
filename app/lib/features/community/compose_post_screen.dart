import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exceptions.dart';
import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/authed_image.dart';
import '../../core/widgets/buttons.dart';
import '../../domain/community.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import '../capture/capture_flow.dart';
import '../house/add_equipment_screen.dart' show EquipmentNotice;
import 'community_widgets.dart';

class ComposeArgs {
  const ComposeArgs({this.draft = const CommunityDraft(), this.editing});
  final CommunityDraft draft;
  final CommunityPost? editing;
}

enum _Step { form, preview }

/// Partager une solution : formulaire court → aperçu exact → consentement explicite (non précoché) → publier.
/// Une photo n'est JAMAIS publique sans choix + confirmation : copie nettoyée distincte, original privé.
class ComposePostScreen extends ConsumerStatefulWidget {
  const ComposePostScreen({super.key, this.args = const ComposeArgs()});
  final ComposeArgs args;

  @override
  ConsumerState<ComposePostScreen> createState() => _ComposePostScreenState();
}

class _ComposePostScreenState extends ConsumerState<ComposePostScreen> {
  late final _title = TextEditingController(text: widget.args.editing?.title ?? widget.args.draft.title);
  late final _solution = TextEditingController(text: widget.args.editing?.solution ?? widget.args.draft.solution);
  late final _materials = TextEditingController(text: widget.args.editing?.materials ?? widget.args.draft.materials);
  late String? _category = widget.args.editing?.category ?? widget.args.draft.category;
  late String? _photoId = widget.args.editing?.photoId;
  late final String? _originalPhotoId = widget.args.editing?.photoId;
  _Step _step = _Step.form;
  bool _consent = false;
  bool _busy = false;
  bool _photoBusy = false;
  bool _tried = false;
  String? _error;
  bool _published = false;
  final _newDrafts = <String>{}; // photos publiques créées dans CE formulaire (à supprimer si abandon)

  bool get _editing => widget.args.editing != null;

  @override
  void dispose() {
    for (final c in [_title, _solution, _materials]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> _errors(AppLocalizations l10n) => {
    if (_title.text.trim().length < 3) 'title': l10n.cmErrTitle,
    if (_solution.text.trim().length < 10) 'solution': l10n.cmErrSolution,
  };

  void _toPreview() {
    setState(() => _tried = true);
    if (_errors(AppLocalizations.of(context)).isNotEmpty) return;
    if (_editing) {
      _save();
    } else {
      setState(() {
        _step = _Step.preview;
        _error = null;
        _tried = false; // l'erreur de consentement n'apparaît qu'après une tentative de publication
      });
    }
  }

  /// Abandon explicite : les copies publiques de brouillon non publiées sont supprimées tout de suite.
  void _close() {
    if (!_published) {
      for (final id in _newDrafts) {
        ref.read(communityRepositoryProvider).discardDraftPhoto(id);
      }
    }
    context.pop();
  }

  Future<void> _takePhoto() async {
    final photo = await capturePhoto(context, ref);
    if (photo == null || !mounted) return;
    await _prepare(() => ref.read(communityRepositoryProvider).uploadPhoto(photo.path));
  }

  Future<void> _fromDiagnostic(String privateId) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: NalviumColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Corner.large))),
      builder: (sheet) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.gutter, Space.x6, Space.gutter, Space.x6),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l10n.cmPhotoConfirmTitle, key: const Key('photo-confirm-title'), style: NalviumText.titleLarge),
            const SizedBox(height: Space.x3),
            AspectRatio(aspectRatio: 16 / 10, child: ClipRRect(borderRadius: BorderRadius.circular(Corner.medium), child: AuthedImage(mediaId: privateId))),
            const SizedBox(height: Space.x3),
            Text(l10n.cmPhotoConfirmBody, key: const Key('photo-confirm-body'), style: NalviumText.body),
            const SizedBox(height: Space.x5),
            PrimaryButton(key: const Key('photo-confirm-yes'), label: l10n.cmPhotoConfirmYes, onPressed: () => Navigator.of(sheet).pop(true)),
            const SizedBox(height: Space.x2),
            SecondaryButton(key: const Key('photo-confirm-no'), label: l10n.cancel, onPressed: () => Navigator.of(sheet).pop(false)),
          ]),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    await _prepare(() => ref.read(communityRepositoryProvider).derivePrivatePhoto(privateId));
  }

  Future<void> _prepare(Future<String> Function() make) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _photoBusy = true;
      _error = null;
    });
    try {
      final id = await make();
      if (_photoId != null && _newDrafts.remove(_photoId)) ref.read(communityRepositoryProvider).discardDraftPhoto(_photoId!);
      if (mounted) {
        setState(() {
          _photoId = id;
          _newDrafts.add(id);
        });
      }
    } on ApiException {
      if (mounted) setState(() => _error = l10n.cmPhotoFail);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  void _removePhoto() {
    final id = _photoId;
    if (id != null && _newDrafts.remove(id)) ref.read(communityRepositoryProvider).discardDraftPhoto(id);
    setState(() => _photoId = null);
  }

  Future<void> _publish() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _tried = true);
    if (!_consent || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final post = await ref.read(communityRepositoryProvider).create(
        title: _title.text.trim(),
        solution: _solution.text.trim(),
        category: _category,
        materials: _materials.text.trim().isEmpty ? null : _materials.text.trim(),
        mediaId: _photoId,
      );
      _published = true;
      ref.read(communityFeedProvider(false).notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cmPublished)));
      context.pushReplacement('/community/post/${post.id}');
    } on ApiHttpException catch (e) {
      if (mounted) setState(() => _error = e.code == 'unsafe_content' ? l10n.cmErrUnsafe : l10n.cmErrPublish);
    } on ApiException {
      if (mounted) setState(() => _error = l10n.cmErrPublish);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(communityRepositoryProvider).update(widget.args.editing!.id, {
        'title': _title.text.trim(),
        'solution': _solution.text.trim(),
        'category': _category,
        'materials': _materials.text.trim().isEmpty ? null : _materials.text.trim(),
        if (_photoId != _originalPhotoId) 'media_id': _photoId,
      });
      _published = true;
      ref.read(communityFeedProvider(false).notifier).refresh();
      ref.read(communityFeedProvider(true).notifier).refresh();
      if (mounted) context.pop();
    } on ApiHttpException catch (e) {
      if (mounted) setState(() => _error = e.code == 'unsafe_content' ? l10n.cmErrUnsafe : l10n.cmErrPublish);
    } on ApiException {
      if (mounted) setState(() => _error = l10n.cmErrPublish);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_step == _Step.preview) {
          setState(() => _step = _Step.form);
        } else {
          _close();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            key: const Key('compose-close'),
            icon: Icon(_step == _Step.preview ? Icons.arrow_back_rounded : Icons.close_rounded),
            tooltip: l10n.close,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => _step == _Step.preview ? setState(() => _step = _Step.form) : _close(),
          ),
          title: Text(_editing ? l10n.cmEditTitle : l10n.cmNewTitle, style: NalviumText.title),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(Space.gutter, Space.x2, Space.gutter, Space.x10 + MediaQuery.viewInsetsOf(context).bottom),
            child: _step == _Step.form ? _form(l10n) : _preview(l10n),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(top: Space.x5, bottom: Space.x1 + 2),
    child: Text(t, style: NalviumText.caption.copyWith(fontWeight: FontWeight.w700, color: NalviumColors.textPrimary)),
  );

  Widget _form(AppLocalizations l10n) {
    final errors = _tried ? _errors(l10n) : const <String, String>{};
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l10n.cmReview, key: const Key('compose-review'), style: NalviumText.caption),
      _label(l10n.cmPhoto),
      Text(l10n.cmPhotoRecommended, style: NalviumText.caption.copyWith(color: NalviumColors.textMuted)),
      const SizedBox(height: Space.x2),
      if (_photoId != null) ...[
        AspectRatio(aspectRatio: 16 / 9, child: ClipRRect(borderRadius: BorderRadius.circular(Corner.medium), child: CommunityImage(key: const Key('compose-photo'), mediaId: _photoId!, variant: 'thumb', semanticLabel: l10n.photoSemantics))),
        const SizedBox(height: Space.x2),
        Row(children: [
          const Icon(Icons.public_rounded, size: 16, color: NalviumColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(child: Text(l10n.cmPhotoPublicNotice, key: const Key('compose-public-notice'), style: NalviumText.caption.copyWith(fontWeight: FontWeight.w600))),
        ]),
        TertiaryButton(key: const Key('compose-photo-remove'), label: l10n.cmPhotoRemove, color: NalviumColors.textSecondary, onPressed: _removePhoto),
      ] else ...[
        SecondaryButton(key: const Key('compose-take-photo'), label: l10n.cmPhotoTake, icon: _photoBusy ? null : Icons.photo_camera_outlined, onPressed: _photoBusy ? null : _takePhoto),
        if (widget.args.draft.privatePhotoIds.isNotEmpty) ...[
          const SizedBox(height: Space.x2),
          Text(l10n.cmPhotoFromDiagnostic, style: NalviumText.caption.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: Space.x2),
          Wrap(spacing: Space.x2, runSpacing: Space.x2, children: [
            for (final id in widget.args.draft.privatePhotoIds)
              InkWell(
                key: Key('compose-private-$id'),
                borderRadius: BorderRadius.circular(Corner.small),
                onTap: _photoBusy ? null : () => _fromDiagnostic(id),
                child: ClipRRect(borderRadius: BorderRadius.circular(Corner.small), child: SizedBox(width: 88, height: 88, child: AuthedImage(mediaId: id))),
              ),
          ]),
        ],
      ],
      _label(l10n.cmFieldTitle),
      TextField(
        key: const Key('compose-title'),
        controller: _title,
        maxLength: 120,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: l10n.cmFieldTitleHint, counterText: '', errorText: errors['title']),
        onChanged: (_) => setState(() {}),
      ),
      _label(l10n.cmFieldSolution),
      TextField(
        key: const Key('compose-solution'),
        controller: _solution,
        minLines: 4,
        maxLines: 10,
        maxLength: 2000,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: l10n.cmFieldSolutionHint, errorText: errors['solution']),
        onChanged: (_) => setState(() {}),
      ),
      _label(l10n.cmFieldCategory),
      Wrap(spacing: Space.x2, runSpacing: Space.x2, children: [
        for (final c in kCommunityCategories)
          _CategoryChip(key: Key('compose-cat-$c'), label: categoryName(l10n, c), selected: _category == c, onTap: () => setState(() => _category = _category == c ? null : c)),
      ]),
      _label(l10n.cmFieldMaterials),
      TextField(
        key: const Key('compose-materials'),
        controller: _materials,
        maxLength: 200,
        decoration: InputDecoration(hintText: l10n.cmFieldMaterialsHint, counterText: ''),
      ),
      if (_error != null) ...[const SizedBox(height: Space.x4), EquipmentNotice(key: const Key('compose-error'), text: _error!)],
      const SizedBox(height: Space.x6),
      PrimaryButton(key: const Key('compose-continue'), label: _editing ? l10n.cmEditTitle : l10n.cmContinue, loading: _busy, onPressed: _toPreview),
    ]);
  }

  Widget _preview(AppLocalizations l10n) {
    final cat = categoryName(l10n, _category);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Semantics(header: true, child: Text(l10n.cmPreviewTitle, key: const Key('preview-title'), style: NalviumText.titleLarge)),
      const SizedBox(height: Space.x4),
      Container(
        key: const Key('preview-card'),
        decoration: BoxDecoration(color: NalviumColors.surface, borderRadius: BorderRadius.circular(Corner.medium), border: Border.all(color: NalviumColors.borderSubtle, width: 1.2)),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_photoId != null) AspectRatio(aspectRatio: 16 / 9, child: CommunityImage(mediaId: _photoId!, variant: 'thumb')),
          Padding(
            padding: const EdgeInsets.all(Space.x4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text([if (cat.isNotEmpty) cat, l10n.cmMember].join(' · '), style: NalviumText.caption.copyWith(color: NalviumColors.textMuted)),
              const SizedBox(height: 2),
              Text(_title.text.trim(), key: const Key('preview-post-title'), style: NalviumText.title.copyWith(fontSize: 19)),
              const SizedBox(height: 4),
              Text(_solution.text.trim(), key: const Key('preview-post-solution'), style: NalviumText.body.copyWith(color: NalviumColors.textPrimary)),
              if (_materials.text.trim().isNotEmpty) ...[const SizedBox(height: 4), Text('${l10n.cmMaterials} : ${_materials.text.trim()}', style: NalviumText.caption)],
            ]),
          ),
        ]),
      ),
      if (_photoId != null) ...[
        const SizedBox(height: Space.x3),
        Row(children: [
          const Icon(Icons.public_rounded, size: 16, color: NalviumColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(child: Text(l10n.cmPhotoPublicNotice, key: const Key('preview-public-notice'), style: NalviumText.caption.copyWith(fontWeight: FontWeight.w600))),
        ]),
      ],
      const SizedBox(height: Space.x5),
      InkWell(
        key: const Key('compose-consent'),
        borderRadius: BorderRadius.circular(Corner.small),
        onTap: () => setState(() => _consent = !_consent),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Checkbox(value: _consent, onChanged: (v) => setState(() => _consent = v ?? false), activeColor: NalviumColors.primary),
            Expanded(child: Padding(padding: const EdgeInsets.only(top: 12), child: Text(l10n.cmConsent, style: NalviumText.body.copyWith(color: NalviumColors.textPrimary, fontSize: 15)))),
          ]),
        ),
      ),
      if (_tried && !_consent)
        Padding(
          padding: const EdgeInsets.only(top: Space.x2),
          child: Row(key: const Key('compose-consent-error'), children: [
            const Icon(Icons.error_outline_rounded, size: 18, color: NalviumColors.dangerText),
            const SizedBox(width: 6),
            Expanded(child: Text(l10n.cmErrConsent, style: NalviumText.caption.copyWith(color: NalviumColors.dangerText, fontWeight: FontWeight.w600))),
          ]),
        ),
      if (_error != null) ...[const SizedBox(height: Space.x4), EquipmentNotice(key: const Key('compose-error'), text: _error!)],
      const SizedBox(height: Space.x5),
      PrimaryButton(key: const Key('compose-publish'), label: l10n.cmPublish, loading: _busy, onPressed: _publish),
      TertiaryButton(key: const Key('compose-back-edit'), label: l10n.cmBackEdit, color: NalviumColors.textSecondary, onPressed: () => setState(() => _step = _Step.form)),
    ]);
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({super.key, required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? NalviumColors.primarySoft : NalviumColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Corner.medium), side: BorderSide(color: selected ? NalviumColors.primary : NalviumColors.borderSubtle, width: 1.5)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.x4, vertical: Space.x2),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (selected) ...[const Icon(Icons.check_rounded, size: 18, color: NalviumColors.primaryText), const SizedBox(width: 6)],
              Flexible(child: Text(label, style: NalviumText.button.copyWith(fontSize: 15.5, color: selected ? NalviumColors.primaryText : NalviumColors.textPrimary))),
            ]),
          ),
        ),
      ),
    ),
  );
}
