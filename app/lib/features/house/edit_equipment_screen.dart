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
import 'add_equipment_screen.dart';
import 'reference_help.dart';

/// Modifier : nom, type, pièce, marque, modèle, photo. Les erreurs ne font jamais perdre la saisie.
class EditEquipmentScreen extends ConsumerStatefulWidget {
  const EditEquipmentScreen({super.key, required this.equipment});
  final EquipmentSummary equipment;

  @override
  ConsumerState<EditEquipmentScreen> createState() => _EditEquipmentScreenState();
}

class _EditEquipmentScreenState extends ConsumerState<EditEquipmentScreen> {
  late final _name = TextEditingController(text: widget.equipment.displayName);
  late final _brand = TextEditingController(text: widget.equipment.brand ?? '');
  late final _model = TextEditingController(text: widget.equipment.model ?? '');
  late String _type = widget.equipment.equipmentType;
  late String? _room = widget.equipment.roomType;
  late String? _photo = widget.equipment.photoMediaId;
  bool _saving = false;
  bool _photoBusy = false;
  String? _message;

  @override
  void dispose() {
    for (final c in [_name, _brand, _model]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final l10n = AppLocalizations.of(context);
    final photo = await capturePhoto(context, ref);
    if (photo == null || !mounted) return;
    setState(() {
      _photoBusy = true;
      _message = null;
    });
    try {
      final id = await ref.read(homeRepositoryProvider).uploadEquipmentPhoto(photo.path);
      if (mounted) setState(() => _photo = id);
    } on ApiException {
      if (mounted) setState(() => _message = l10n.eqPhotoFail);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_name.text.trim().isEmpty || _saving) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final e = widget.equipment;
      await ref.read(homeRepositoryProvider).updateEquipment(e.id, {
        'equipment_type': _type,
        'display_name': _name.text.trim(),
        'room_type': _room,
        'brand': _brand.text.trim(),
        'model': _model.text.trim(),
        if (_photo != e.photoMediaId) 'primary_media_id': _photo,
      });
      ref.read(homeRevisionProvider.notifier).bump();
      if (mounted) context.pop();
    } on ApiHttpException catch (err) {
      if (mounted) setState(() => _message = err.status == 404 ? l10n.eqGone : l10n.eqSaveFail);
    } on ApiException {
      if (mounted) setState(() => _message = l10n.eqSaveFail);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickType() async {
    final l10n = AppLocalizations.of(context);
    final picked = await _pickFrom<String>(
      title: l10n.eqType,
      options: [for (final k in EquipmentCatalog.kinds) (k.slug, k.label, k.icon)],
      current: _type,
    );
    if (picked != null) setState(() => _type = picked);
  }

  Future<void> _pickRoom() async {
    final l10n = AppLocalizations.of(context);
    final picked = await _pickFrom<String>(
      title: l10n.eqRoomLabel,
      options: [for (final r in RoomCatalog.kinds) (r.slug, r.label, r.icon)],
      current: _room,
      clearLabel: l10n.eqRoomSkip,
    );
    if (picked != null) setState(() => _room = picked == '' ? null : picked);
  }

  Future<T?> _pickFrom<T>({
    required String title,
    required List<(String, String, IconData)> options,
    String? current,
    String? clearLabel,
  }) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: NalviumColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Corner.large))),
    builder: (sheet) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.x4, Space.x6, Space.x4, Space.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.x2),
            child: Text(title, style: NalviumText.titleLarge),
          ),
          const SizedBox(height: Space.x2),
          for (final (slug, label, icon) in options)
            ListTile(
              key: Key('pick-$slug'),
              minVerticalPadding: Space.x3,
              leading: Icon(icon, color: NalviumColors.primary),
              title: Text(label, style: NalviumText.button.copyWith(color: NalviumColors.textPrimary)),
              trailing: slug == current ? const Icon(Icons.check_rounded, color: NalviumColors.primary) : null,
              onTap: () => Navigator.of(sheet).pop(slug as T),
            ),
          if (clearLabel != null)
            ListTile(
              key: const Key('pick-none'),
              minVerticalPadding: Space.x3,
              title: Text(clearLabel, style: NalviumText.button.copyWith(color: NalviumColors.textSecondary)),
              onTap: () => Navigator.of(sheet).pop('' as T),
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final kind = EquipmentCatalog.of(_type);
    final room = RoomCatalog.of(_room);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          key: const Key('edit-close'),
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.close,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.eqEditTitle, style: NalviumText.title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.x2, Space.gutter, Space.x8),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label(l10n.eqName),
              TextField(
                key: const Key('edit-name'),
                controller: _name,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(counterText: ''),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Space.x4),
              _label(l10n.eqType),
              _PickerRow(key: const Key('edit-type'), icon: kind.icon, label: kind.label, onTap: _pickType),
              const SizedBox(height: Space.x4),
              _label(l10n.eqRoomLabel),
              _PickerRow(
                key: const Key('edit-room'),
                icon: room?.icon ?? Icons.meeting_room_outlined,
                label: room?.label ?? l10n.houseNoRoom,
                onTap: _pickRoom,
              ),
              const SizedBox(height: Space.x4),
              _label(l10n.eqBrand),
              TextField(
                key: const Key('edit-brand'),
                controller: _brand,
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: l10n.eqBrandHint, counterText: ''),
              ),
              const SizedBox(height: Space.x4),
              _label(l10n.eqModel),
              TextField(
                key: const Key('edit-model'),
                controller: _model,
                maxLength: 80,
                decoration: InputDecoration(hintText: l10n.eqModelHint, counterText: ''),
              ),
              const ReferenceHelpLink(),
              const SizedBox(height: Space.x5),
              _label(l10n.eqPhoto),
              if (_photo != null) ...[
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Corner.medium),
                    child: AuthedImage(key: const Key('edit-photo'), mediaId: _photo!, semanticLabel: l10n.photoSemantics),
                  ),
                ),
                const SizedBox(height: Space.x2),
              ],
              SecondaryButton(
                key: const Key('edit-photo-button'),
                label: _photo == null ? l10n.eqPhotoAdd : l10n.eqPhotoChange,
                icon: _photoBusy ? null : Icons.photo_camera_outlined,
                onPressed: _photoBusy ? null : _pickPhoto,
              ),
              if (_photo != null)
                TertiaryButton(
                  key: const Key('edit-photo-remove'),
                  label: l10n.eqPhotoRemove,
                  color: NalviumColors.textSecondary,
                  onPressed: () => setState(() => _photo = null),
                ),
              if (_message != null) ...[
                const SizedBox(height: Space.x4),
                EquipmentNotice(key: const Key('edit-error'), text: _message!),
              ],
              const SizedBox(height: Space.x6),
              PrimaryButton(
                key: const Key('edit-save'),
                label: l10n.eqSave,
                loading: _saving,
                onPressed: _name.text.trim().isEmpty ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: Space.x1 + 2),
    child: Text(text, style: NalviumText.caption.copyWith(fontWeight: FontWeight.w700, color: NalviumColors.textPrimary)),
  );
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({super.key, required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: Material(
      color: NalviumColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corner.medium),
        side: const BorderSide(color: NalviumColors.borderSubtle, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.x5, vertical: Space.x3),
            child: Row(
              children: [
                Icon(icon, color: NalviumColors.primary),
                const SizedBox(width: Space.x3),
                Expanded(child: Text(label, style: NalviumText.bodyLarge.copyWith(fontWeight: FontWeight.w500))),
                const Icon(Icons.expand_more_rounded, color: NalviumColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
