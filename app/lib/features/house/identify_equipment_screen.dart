import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exceptions.dart';
import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/error_panel.dart';
import '../../domain/equipment.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import '../capture/capture_flow.dart';
import 'add_equipment_screen.dart';

enum _Phase { intro, working, result, uploadFailed, identifyFailed }

/// « Identifier avec une photo ». Ce n'est PAS un diagnostic : aucune session n'est créée, aucune publicité,
/// aucun compteur. Une identification est toujours une proposition que l'utilisateur confirme ou corrige.
class IdentifyEquipmentScreen extends ConsumerStatefulWidget {
  const IdentifyEquipmentScreen({super.key});

  @override
  ConsumerState<IdentifyEquipmentScreen> createState() => _IdentifyEquipmentScreenState();
}

class _IdentifyEquipmentScreenState extends ConsumerState<IdentifyEquipmentScreen> {
  _Phase _phase = _Phase.intro;
  String? _path;
  String? _mediaId;
  EquipmentIdentification? _result;
  Object? _error;

  Future<void> _take() async {
    final photo = await capturePhoto(context, ref);
    if (photo == null || !mounted) return;
    _path = photo.path;
    _mediaId = null;
    await _run();
  }

  /// Envoie la photo (une seule fois) puis demande l'identification. Une erreur ne perd jamais la photo.
  Future<void> _run() async {
    setState(() {
      _phase = _Phase.working;
      _error = null;
    });
    final repo = ref.read(homeRepositoryProvider);
    try {
      _mediaId ??= await repo.uploadEquipmentPhoto(_path!);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.uploadFailed;
          _error = e;
        });
      }
      return;
    }
    try {
      final result = await repo.identify(_mediaId!);
      if (mounted) {
        setState(() {
          _phase = _Phase.result;
          _result = result;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.identifyFailed;
          _error = e;
        });
      }
    }
  }

  bool _handedOver = false;

  /// Fermeture explicite : la photo temporaire envoyée n'a plus d'usage, on la supprime tout de suite.
  void _close() {
    final id = _mediaId;
    if (id != null && !_handedOver) ref.read(homeRepositoryProvider).discardEquipmentPhoto(id);
    context.pop();
  }

  void _continue({String? type, String? brand, String? model, bool atRoom = false}) {
    _handedOver = true; // la photo est transmise au flux d'ajout
    context.pushReplacement(
      '/equipment/add',
      extra: AddEquipmentArgs(type: type, brand: brand, model: model, photoMediaId: _mediaId, startAtRoom: atRoom),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          key: const Key('identify-close'),
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.close,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: _close,
        ),
        title: Text(l10n.eqIdentifyTitle, style: NalviumText.title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.x2, Space.gutter, Space.x8),
          child: switch (_phase) {
            _Phase.intro => _intro(l10n),
            _Phase.working => _working(l10n),
            _Phase.result => _resultView(l10n),
            _Phase.uploadFailed => ErrorPanel(
              error: _error!,
              onRetry: _run,
              secondary: TertiaryButton(
                key: const Key('identify-manual'),
                label: l10n.eqIdentifyChoose,
                color: NalviumColors.textSecondary,
                onPressed: () => _continue(),
              ),
            ),
            _Phase.identifyFailed => _failed(l10n),
          },
        ),
      ),
    );
  }

  Widget _intro(AppLocalizations l10n) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: Space.x8),
      Center(
        child: Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(color: NalviumColors.primarySoft, shape: BoxShape.circle),
          child: const Icon(Icons.photo_camera_outlined, size: 42, color: NalviumColors.primary),
        ),
      ),
      const SizedBox(height: Space.x6),
      Text(l10n.eqIdentifyTip, style: NalviumText.bodyLarge, textAlign: TextAlign.center),
      const SizedBox(height: Space.x3),
      Text(l10n.eqPhotoPrivate, style: NalviumText.caption, textAlign: TextAlign.center),
      const SizedBox(height: Space.x8),
      PrimaryButton(key: const Key('identify-take'), label: l10n.eqIdentifyTake, icon: Icons.photo_camera_rounded, onPressed: _take),
      TertiaryButton(
        key: const Key('identify-manual'),
        label: l10n.eqIdentifyChoose,
        color: NalviumColors.textSecondary,
        onPressed: () => _continue(),
      ),
    ],
  );

  Widget _photo() => AspectRatio(
    aspectRatio: 16 / 10,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(Corner.large),
      child: Image.file(
        File(_path!),
        key: const Key('identify-photo'),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const ColoredBox(color: NalviumColors.surfaceSubtle),
      ),
    ),
  );

  Widget _working(AppLocalizations l10n) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _photo(),
      const SizedBox(height: Space.x6),
      const Center(child: CircularProgressIndicator()),
      const SizedBox(height: Space.x4),
      Text(l10n.eqIdentifyWorking, key: const Key('identify-working'), style: NalviumText.bodyLarge, textAlign: TextAlign.center),
    ],
  );

  Widget _resultView(AppLocalizations l10n) {
    final r = _result!;
    if (r.isUnknown) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _photo(),
          const SizedBox(height: Space.x6),
          Text(l10n.eqIdentifyUnknownTitle, key: const Key('identify-unknown'), style: NalviumText.titleLarge),
          const SizedBox(height: Space.x2),
          Text(l10n.eqIdentifyUnknownBody, style: NalviumText.body),
          const SizedBox(height: Space.x6),
          PrimaryButton(key: const Key('identify-choose'), label: l10n.eqIdentifyChoose, onPressed: () => _continue()),
        ],
      );
    }
    final kind = EquipmentCatalog.of(r.equipmentType);
    // Formulation prudente : « Cela ressemble à un lave-vaisselle Bosch. » — jamais « C'est ».
    final what = [kind.withArticle, ?r.brand].join(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _photo(),
        const SizedBox(height: Space.x6),
        Text(l10n.eqIdentifyResult(what), key: const Key('identify-result'), style: NalviumText.titleLarge),
        if (r.model != null) ...[
          const SizedBox(height: Space.x2),
          Text('${l10n.eqModel} : ${r.model}', key: const Key('identify-model'), style: NalviumText.bodyLarge),
        ],
        const SizedBox(height: Space.x2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.info_outline_rounded, size: 18, color: NalviumColors.textMuted),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.eqIdentifyNotSure, key: const Key('identify-not-sure'), style: NalviumText.body.copyWith(fontSize: 15))),
          ],
        ),
        if (r.model == null) ...[
          // Référence illisible : on ne l'invente jamais, on propose une photo plus proche de la plaque.
          const SizedBox(height: Space.x2),
          Text(l10n.eqIdentifyCloser, key: const Key('identify-closer'), style: NalviumText.caption),
        ],
        if (r.visibleText.isNotEmpty) ...[
          const SizedBox(height: Space.x3),
          Text('${l10n.eqIdentifyReadable} : ${r.visibleText.join(', ')}', style: NalviumText.caption),
        ],
        const SizedBox(height: Space.x6),
        PrimaryButton(
          key: const Key('identify-confirm'),
          label: l10n.eqIdentifyConfirm,
          onPressed: () => _continue(type: r.equipmentType, brand: r.brand, model: r.model, atRoom: true),
        ),
        const SizedBox(height: Space.x2),
        SecondaryButton(
          key: const Key('identify-correct'),
          label: l10n.eqIdentifyCorrect,
          onPressed: () => _continue(type: r.equipmentType, brand: r.brand, model: r.model),
        ),
      ],
    );
  }

  Widget _failed(AppLocalizations l10n) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _photo(),
      const SizedBox(height: Space.x6),
      Text(l10n.eqIdentifyFailTitle, key: const Key('identify-failed'), style: NalviumText.titleLarge),
      const SizedBox(height: Space.x2),
      Text(l10n.eqIdentifyFailBody, style: NalviumText.body),
      const SizedBox(height: Space.x6),
      PrimaryButton(key: const Key('identify-continue'), label: l10n.eqIdentifyContinue, onPressed: () => _continue()),
      const SizedBox(height: Space.x2),
      SecondaryButton(key: const Key('retry'), label: l10n.retry, onPressed: _run),
    ],
  );
}
