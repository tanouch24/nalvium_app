import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exceptions.dart';
import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/authed_image.dart';
import '../../core/widgets/buttons.dart';
import '../../domain/equipment.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import '../capture/capture_flow.dart';
import 'house_widgets.dart';
import 'reference_help.dart';

/// Point de départ du flux d'ajout. Tout est facultatif sauf le type ; marque et modèle ne sont jamais requis.
class AddEquipmentArgs {
  const AddEquipmentArgs({
    this.type,
    this.brand,
    this.model,
    this.photoMediaId,
    this.linkSessionId,
    this.startAtRoom = false,
  });

  /// Type déjà connu (identification confirmée, ou type détecté dans un diagnostic).
  final String? type;
  final String? brand;
  final String? model;
  final String? photoMediaId;

  /// Si défini, le diagnostic est rattaché à l'équipement créé (l'utilisateur l'a demandé).
  final String? linkSessionId;
  final bool startAtRoom;
}

enum _Step { type, room, details }

/// 1. Quel équipement ?  2. Où se trouve-t-il ?  3. Précisions facultatives.
class AddEquipmentScreen extends ConsumerStatefulWidget {
  const AddEquipmentScreen({super.key, this.args = const AddEquipmentArgs()});
  final AddEquipmentArgs args;

  @override
  ConsumerState<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends ConsumerState<AddEquipmentScreen> {
  late _Step _step = (widget.args.type != null && widget.args.startAtRoom) ? _Step.room : _Step.type;
  late String? _type = widget.args.type;
  String? _room;
  late final _name = TextEditingController();
  late final _brand = TextEditingController(text: widget.args.brand ?? '');
  late final _model = TextEditingController(text: widget.args.model ?? '');
  final _search = TextEditingController();
  late String? _photoId = widget.args.photoMediaId;
  bool _saving = false;
  bool _photoBusy = false;
  String? _message;

  @override
  void dispose() {
    for (final c in [_name, _brand, _model, _search]) {
      c.dispose();
    }
    super.dispose();
  }

  void _go(_Step s) => setState(() {
    _step = s;
    _message = null;
  });

  void _back() {
    switch (_step) {
      case _Step.type:
        // Abandon explicite : une photo temporaire non enregistrée est supprimée tout de suite.
        if (_photoId != null) ref.read(homeRepositoryProvider).discardEquipmentPhoto(_photoId!);
        context.pop();
      case _Step.room:
        _go(_Step.type);
      case _Step.details:
        _go(_Step.room);
    }
  }

  bool get _isOther => _type == 'other';
  bool get _canSave => _type != null && (!_isOther || _name.text.trim().isNotEmpty);

  Future<void> _addPhoto() async {
    final l10n = AppLocalizations.of(context);
    final photo = await capturePhoto(context, ref);
    if (photo == null || !mounted) return;
    setState(() {
      _photoBusy = true;
      _message = null;
    });
    try {
      final id = await ref.read(homeRepositoryProvider).uploadEquipmentPhoto(photo.path);
      if (mounted) setState(() => _photoId = id);
    } on ApiException {
      if (mounted) setState(() => _message = l10n.eqPhotoFail);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final home = ref.read(homeRepositoryProvider);
      final created = await home.createEquipment(
        EquipmentDraft(
          equipmentType: _type!,
          displayName: _name.text,
          roomType: _room,
          brand: _brand.text,
          model: _model.text,
          photoMediaId: _photoId,
        ),
      );
      final link = widget.args.linkSessionId;
      if (link != null) {
        await home.linkSession(link, created.summary.id);
        ref.read(sessionsRevisionProvider.notifier).bump();
      }
      ref.read(homeRevisionProvider.notifier).bump();
      if (!mounted) return;
      context.pop(created.summary.id);
    } on ApiException {
      // La saisie n'est jamais perdue : on reste sur l'écran, tout est conservé.
      if (mounted) setState(() => _message = l10n.eqSaveFail);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = switch (_step) {
      _Step.type => l10n.eqStepType,
      _Step.room => l10n.eqStepRoom,
      _Step.details => l10n.eqStepDetails,
    };
    return PopScope(
      canPop: _step == _Step.type,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            key: const Key('add-back'),
            icon: Icon(_step == _Step.type ? Icons.close_rounded : Icons.arrow_back_rounded),
            tooltip: _step == _Step.type ? l10n.close : MaterialLocalizations.of(context).backButtonTooltip,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: _back,
          ),
          title: Text(l10n.eqAddTitle, style: NalviumText.title),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.x2, Space.gutter, Space.x8),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, key: const Key('add-step-title'), style: NalviumText.titleLarge.copyWith(fontSize: 28)),
                ),
                const SizedBox(height: Space.x5),
                switch (_step) {
                  _Step.type => _typeStep(l10n),
                  _Step.room => _roomStep(l10n),
                  _Step.details => _detailsStep(l10n),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Étape 1 : type ─────────────────────────────────────────────────────
  Widget _typeStep(AppLocalizations l10n) {
    final results = EquipmentCatalog.search(_search.text);
    final noMatch = results.isEmpty;
    final shown = noMatch ? const [EquipmentCatalog.other] : results;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.args.linkSessionId == null && widget.args.photoMediaId == null) ...[
          _QuickPath(
            key: const Key('add-identify'),
            label: l10n.eqIdentifyPhoto,
            onTap: () => context.pushReplacement('/equipment/identify'),
          ),
          const SizedBox(height: Space.x4),
        ],
        TextField(
          key: const Key('add-search'),
          controller: _search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.eqSearchHint,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.close,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(_search.clear),
                  ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Space.x4),
        if (noMatch) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: Space.x3),
            child: Text(l10n.eqSearchEmpty, key: const Key('add-search-empty'), style: NalviumText.body),
          ),
        ],
        TwoColumnWrap(
          children: [
            for (final k in shown)
              KindTile(
                kind: k,
                selected: _type == k.slug,
                onTap: () {
                  _type = k.slug;
                  _go(_Step.room);
                },
              ),
          ],
        ),
      ],
    );
  }

  // ── Étape 2 : pièce ────────────────────────────────────────────────────
  Widget _roomStep(AppLocalizations l10n) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TwoColumnWrap(
        children: [
          for (final r in RoomCatalog.kinds)
            RoomTile(
              room: r,
              onTap: () {
                _room = r.slug;
                _go(_Step.details);
              },
            ),
        ],
      ),
      const SizedBox(height: Space.x3),
      TertiaryButton(
        key: const Key('room-skip'),
        label: l10n.eqRoomSkip,
        color: NalviumColors.textSecondary,
        onPressed: () {
          _room = null;
          _go(_Step.details);
        },
      ),
    ],
  );

  // ── Étape 3 : précisions facultatives ──────────────────────────────────
  Widget _detailsStep(AppLocalizations l10n) {
    final kind = EquipmentCatalog.of(_type ?? 'other');
    final room = RoomCatalog.of(_room);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            EquipmentAvatar(kind: kind, mediaId: _photoId, size: 48, radius: 14),
            const SizedBox(width: Space.x3),
            Expanded(
              child: Text(
                [kind.label, ?room?.label].join(' — '),
                key: const Key('add-summary'),
                style: NalviumText.title.copyWith(fontSize: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.x2),
        Text(l10n.eqDetailsHint, style: NalviumText.body),
        const SizedBox(height: Space.x5),
        if (_isOther) ...[
          _Field(fieldKey: const Key('field-name'), label: l10n.eqName, hint: l10n.eqNameHint, controller: _name, onChanged: () => setState(() {})),
          const SizedBox(height: Space.x4),
        ],
        _Field(fieldKey: const Key('field-brand'), label: l10n.eqBrand, hint: l10n.eqBrandHint, controller: _brand),
        const SizedBox(height: Space.x4),
        _Field(fieldKey: const Key('field-model'), label: l10n.eqModel, hint: l10n.eqModelHint, controller: _model),
        const ReferenceHelpLink(),
        const SizedBox(height: Space.x5),
        _PhotoBlock(
          photoId: _photoId,
          busy: _photoBusy,
          onAdd: _addPhoto,
          onRemove: () => setState(() => _photoId = null),
        ),
        if (_message != null) ...[
          const SizedBox(height: Space.x4),
          EquipmentNotice(key: const Key('add-error'), text: _message!),
        ],
        const SizedBox(height: Space.x6),
        PrimaryButton(
          key: const Key('add-save'),
          label: l10n.eqSave,
          loading: _saving,
          onPressed: _canSave ? _save : null,
        ),
      ],
    );
  }
}

/// Chemin le plus simple : identifier l'équipement avec une photo. Fond bleu très clair, une seule zone tactile.
class _QuickPath extends StatelessWidget {
  const _QuickPath({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: Material(
      color: NalviumColors.primarySoft,
      borderRadius: BorderRadius.circular(Corner.small + 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.x4, vertical: Space.x3),
            child: Row(
              children: [
                const Icon(Icons.photo_camera_outlined, color: NalviumColors.primary),
                const SizedBox(width: Space.x3),
                Expanded(child: Text(label, style: NalviumText.button.copyWith(color: NalviumColors.primaryText))),
                const Icon(Icons.chevron_right_rounded, color: NalviumColors.primaryText),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({required this.fieldKey, required this.label, required this.hint, required this.controller, this.onChanged});
  final Key fieldKey;
  final String label;
  final String hint;
  final TextEditingController controller;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: NalviumText.caption.copyWith(fontWeight: FontWeight.w600, color: NalviumColors.textSecondary)),
      const SizedBox(height: Space.x1 + 2),
      TextField(
        key: fieldKey,
        controller: controller,
        maxLength: 80,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: hint, counterText: ''),
        onChanged: (_) => onChanged?.call(),
      ),
    ],
  );
}

class _PhotoBlock extends StatelessWidget {
  const _PhotoBlock({required this.photoId, required this.busy, required this.onAdd, required this.onRemove});
  final String? photoId;
  final bool busy;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.eqPhoto, style: NalviumText.caption.copyWith(fontWeight: FontWeight.w600, color: NalviumColors.textSecondary)),
        const SizedBox(height: Space.x1 + 2),
        if (photoId != null) ...[
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Corner.medium),
              child: AuthedImage(key: const Key('add-photo'), mediaId: photoId!, semanticLabel: l10n.photoSemantics),
            ),
          ),
          const SizedBox(height: Space.x2),
        ],
        SecondaryButton(
          key: const Key('add-photo-button'),
          label: photoId == null ? l10n.eqPhotoAdd : l10n.eqPhotoChange,
          icon: busy ? null : Icons.photo_camera_outlined,
          onPressed: busy ? null : onAdd,
        ),
        if (photoId != null)
          TertiaryButton(
            key: const Key('add-photo-remove'),
            label: l10n.eqPhotoRemove,
            color: NalviumColors.textSecondary,
            onPressed: onRemove,
          ),
        Padding(
          padding: const EdgeInsets.only(top: Space.x1),
          child: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 15, color: NalviumColors.textMuted),
              const SizedBox(width: 6),
              Flexible(child: Text(l10n.eqPhotoPrivate, style: NalviumText.caption.copyWith(color: NalviumColors.textMuted, fontSize: 13))),
            ],
          ),
        ),
      ],
    );
  }
}

/// Message d'erreur sobre, jamais seulement coloré : icône + texte.
class EquipmentNotice extends StatelessWidget {
  const EquipmentNotice({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Space.x4),
    decoration: BoxDecoration(color: NalviumColors.warningSoft, borderRadius: BorderRadius.circular(Corner.medium)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, color: NalviumColors.warning, size: 22),
        const SizedBox(width: Space.x3),
        Expanded(child: Text(text, style: NalviumText.body.copyWith(color: NalviumColors.textPrimary, fontSize: 15))),
      ],
    ),
  );
}

