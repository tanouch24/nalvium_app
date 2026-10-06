import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../core/network/api_exceptions.dart';
import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/authed_image.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/error_panel.dart';
import '../../domain/equipment.dart';
import '../../domain/service_request.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import '../capture/capture_flow.dart';
import '../house/add_equipment_screen.dart' show EquipmentNotice;
import 'out_of_zone_screen.dart';

/// « Votre demande d'intervention » : un écran simple, sections claires, une action principale.
/// Depuis un diagnostic, le contexte est déjà prêt (rien à réexpliquer). Aucun média n'est joint sans choix explicite ;
/// le consentement n'est jamais précoché. Créer une demande n'est PAS un diagnostic : aucune publicité.
class HelpRequestScreen extends ConsumerStatefulWidget {
  const HelpRequestScreen({super.key, this.sessionId});
  final String? sessionId;

  @override
  ConsumerState<HelpRequestScreen> createState() => _HelpRequestScreenState();
}

class _HelpRequestScreenState extends ConsumerState<HelpRequestScreen> {
  ServiceRequest? _req;
  Object? _loadError;
  final _summary = TextEditingController();
  final _first = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _postal = TextEditingController();
  final _email = TextEditingController();
  String? _category;
  String? _equipmentId;
  AvailabilityType? _availability;
  DateTime? _date;
  String? _window;
  bool _consent = false;
  bool _sending = false;
  bool _photoBusy = false;
  bool _submitted = false; // tentative d'envoi faite : les erreurs s'affichent
  String? _sendError;
  final _cityFocus = FocusNode();
  final _postalFocus = FocusNode();
  final _areaErrors = <String, String>{}; // incohérence ville / code postal détectée par le serveur
  String? _checkedKey;
  String? _areaErrorKey;
  final _selected = <String>{};
  final _extraMedia = <String>[]; // photos ajoutées hors diagnostic

  bool get _fromSession => widget.sessionId != null;

  @override
  void initState() {
    super.initState();
    _prepare();
    // Contrôle d'éligibilité calme : quand l'utilisateur QUITTE le champ, jamais pendant la frappe.
    _postalFocus.addListener(() {
      if (!_postalFocus.hasFocus) _checkArea();
    });
    _cityFocus.addListener(() {
      if (!_cityFocus.hasFocus) _checkArea();
    });
    // Une erreur de zone ne reste affichée que pour la saisie qui l'a produite.
    for (final c in [_city, _postal]) {
      c.addListener(() {
        if (_areaErrors.isNotEmpty && _areaErrorKey != '${_city.text.trim().toLowerCase()}|${_postal.text.trim()}') {
          setState(_areaErrors.clear);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_summary, _first, _phone, _city, _postal, _email]) {
      c.dispose();
    }
    _cityFocus.dispose();
    _postalFocus.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    setState(() => _loadError = null);
    try {
      final repo = ref.read(serviceRequestsRepositoryProvider);
      final req = _fromSession ? await repo.fromSession(widget.sessionId!) : await repo.createDraft();
      if (!mounted) return;
      setState(() {
        _req = req;
        if (_summary.text.isEmpty) _summary.text = req.summary ?? '';
        _category ??= req.category;
        _equipmentId ??= req.equipmentId;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  /// Éligibilité (informative) : le SERVEUR décide ; Flutter affiche. Retourne le résultat ou null si pas évaluable.
  Future<AreaCheck?> _checkArea({bool force = false}) async {
    final city = _city.text.trim();
    final postal = _postal.text.trim();
    if (city.isEmpty || RequestValidation.postalCode(postal) != null) return null;
    final key = '${city.toLowerCase()}|$postal';
    if (!force && key == _checkedKey) return null;
    _checkedKey = key;
    try {
      final r = await ref.read(serviceRequestsRepositoryProvider).checkArea(city, postal);
      if (!mounted) return r;
      setState(() => _applyArea(r));
      if (r.outOfZone) _openOutOfZone();
      return r;
    } on ApiException {
      return null; // le contrôle définitif aura lieu à l'envoi
    }
  }

  void _applyArea(AreaCheck r) {
    final l10n = AppLocalizations.of(context);
    _areaErrors.clear();
    _areaErrorKey = '${_city.text.trim().toLowerCase()}|${_postal.text.trim()}';
    if (r.status != 'invalid') return;
    switch (r.code) {
      case 'unknown_city':
        _areaErrors['city'] = l10n.helpErrCityUnknown;
      case 'unknown_postal_code':
        _areaErrors['postal'] = l10n.helpErrPostalUnknown;
      case 'city_postal_mismatch':
        _areaErrors['postal'] = l10n.helpErrCityPostal;
    }
  }

  void _openOutOfZone() {
    final area = ref.read(serviceAreaProvider).value;
    context.push(
      '/help/out-of-zone',
      extra: OutOfZoneArgs(
        areaName: area?.name ?? '',
        radiusKm: area?.radiusKm ?? 0,
        fromSession: _fromSession,
        safety: _req?.safetyReason != null,
      ),
    );
  }

  // ── validation ─────────────────────────────────────────────────────────
  Map<String, String> _errors(AppLocalizations l10n) {
    final e = <String, String>{};
    if (_summary.text.trim().isEmpty) e['summary'] = l10n.helpErrRequired;
    if (_first.text.trim().isEmpty) e['first'] = l10n.helpErrRequired;
    if (_phone.text.trim().isEmpty) {
      e['phone'] = l10n.helpErrRequired;
    } else if (RequestValidation.phone(_phone.text) != null) {
      e['phone'] = l10n.helpErrPhone;
    }
    if (_city.text.trim().isEmpty) e['city'] = l10n.helpErrRequired;
    if (_postal.text.trim().isEmpty) {
      e['postal'] = l10n.helpErrRequired;
    } else if (RequestValidation.postalCode(_postal.text) != null) {
      e['postal'] = l10n.helpErrPostal;
    }
    if (RequestValidation.email(_email.text) != null) e['email'] = l10n.helpErrEmail;
    if (_availability == null) e['when'] = l10n.helpErrRequired;
    if (_availability == AvailabilityType.custom && (_date == null || _window == null)) e['when'] = l10n.helpErrDate;
    if (!_consent) e['consent'] = l10n.helpErrConsent;
    return e;
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _submitted = true;
      _sendError = null;
    });
    if (_errors(l10n).isNotEmpty || _req == null || _sending) return;
    setState(() => _sending = true);
    try {
      // Éligibilité avant tout enregistrement ; le serveur la REFAIT à l'envoi (source de vérité).
      final area = await _checkArea(force: true);
      if (area != null && !area.inZone) return; // hors zone : écran dédié déjà ouvert ; ou incohérence affichée
      if (!mounted) return;
      final repo = ref.read(serviceRequestsRepositoryProvider);
      final id = _req!.id;
      await repo.update(id, {
        'problem_summary': _summary.text.trim(),
        if (!_fromSession) 'category': _category,
        if (!_fromSession) 'equipment_id': _equipmentId,
        'first_name': _first.text.trim(),
        'phone': _phone.text.trim(),
        'city': _city.text.trim(),
        'postal_code': _postal.text.trim(),
        'email': _email.text.trim(),
        'availability_type': _availability!.wire,
        if (_availability == AvailabilityType.custom) ...{
          'preferred_date': _date!.toIso8601String().substring(0, 10),
          'preferred_time_window': _window,
        },
      });
      await repo.selectMedia(id, _selected.toList()); // exactement la sélection affichée
      await repo.submit(id);
      ref.read(requestsRevisionProvider.notifier).bump();
      if (mounted) context.pushReplacement('/help/$id/done');
    } on ApiHttpException catch (e) {
      if (!mounted) return;
      if (e.code == 'out_of_zone') {
        _openOutOfZone();
      } else if (e.code == 'city_postal_mismatch' || e.code == 'unknown_city' || e.code == 'unknown_postal_code') {
        setState(() => _applyArea(AreaCheck(status: 'invalid', code: e.code)));
      } else {
        setState(() => _sendError = l10n.helpErrSend);
      }
    } on ApiException {
      // Rien n'est perdu : tout reste saisi, on peut réessayer.
      if (mounted) setState(() => _sendError = l10n.helpErrSend);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _addPhoto() async {
    final photo = await capturePhoto(context, ref);
    if (photo == null || !mounted) return;
    setState(() => _photoBusy = true);
    try {
      final id = await ref.read(homeRepositoryProvider).uploadEquipmentPhoto(photo.path);
      if (mounted) {
        setState(() {
          _extraMedia.add(id);
          _selected.add(id); // l'utilisateur vient de l'ajouter à CETTE demande : choix explicite
        });
      }
    } on ApiException {
      if (mounted) setState(() => _sendError = AppLocalizations.of(context).helpErrSend);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (d != null) setState(() => _date = d);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          key: const Key('help-close'),
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.close,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.helpNewTitle, style: NalviumText.title),
      ),
      body: SafeArea(
        child: _loadError != null
            ? Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Space.gutter),
                  child: ErrorPanel(error: _loadError!, onRetry: _prepare),
                ),
              )
            : _req == null
            ? const Center(child: CircularProgressIndicator())
            : _form(l10n),
      ),
    );
  }

  Widget _form(AppLocalizations l10n) {
    final req = _req!;
    final errors = {if (_submitted) ..._errors(l10n), ..._areaErrors};
    final area = ref.watch(serviceAreaProvider).value;
    final session = _fromSession ? ref.watch(sessionProvider(widget.sessionId!)).value : null;
    final sessionMedia = session?.mediaItems ?? const <({String id, bool video})>[];
    final stopReason = req.safetyReason ?? req.professionalReason;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(Space.gutter, Space.x2, Space.gutter, Space.x10 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_fromSession ? l10n.helpIntro : l10n.helpIntroDirect, key: const Key('help-intro'), style: NalviumText.body),
          if (area != null) ...[
            const SizedBox(height: Space.x2),
            Text(l10n.helpAreaNote(area.name, area.radiusKm), key: const Key('help-area-note'), style: NalviumText.caption.copyWith(color: NalviumColors.textMuted)),
          ],
          if (req.safetyReason != null) ...[
            const SizedBox(height: Space.x3),
            Text(l10n.helpEmergency, key: const Key('help-emergency'), style: NalviumText.caption.copyWith(color: NalviumColors.dangerText, fontWeight: FontWeight.w600)),
          ],
          // ── PROBLÈME ──
          _heading(l10n.helpSectionProblem),
          TextField(
            key: const Key('help-summary'),
            controller: _summary,
            minLines: 3,
            maxLines: 6,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: l10n.helpProblemHint, errorText: errors['summary']),
            onChanged: (_) => setState(() {}),
          ),
          if (!_fromSession) ...[
            const SizedBox(height: Space.x2),
            Wrap(
              spacing: Space.x2,
              runSpacing: Space.x2,
              children: [
                for (final (slug, label) in [
                  ('plumbing', l10n.helpCatPlumbing), ('appliance', l10n.helpCatAppliance), ('handyman', l10n.helpCatHandyman),
                  ('electrical', l10n.helpCatElectrical), ('other', l10n.helpCatOther),
                ])
                  _Chip(key: Key('help-cat-$slug'), label: label, selected: _category == slug, onTap: () => setState(() => _category = _category == slug ? null : slug)),
              ],
            ),
          ],
          if (stopReason != null) ...[
            const SizedBox(height: Space.x4),
            Container(
              key: const Key('help-stop-reason'),
              padding: const EdgeInsets.all(Space.x4),
              decoration: BoxDecoration(color: NalviumColors.dangerSoft, borderRadius: BorderRadius.circular(Corner.medium)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.warning_amber_rounded, size: 20, color: NalviumColors.dangerText),
                    const SizedBox(width: 8),
                    Flexible(child: Text(l10n.helpSafetyReason, style: NalviumText.caption.copyWith(color: NalviumColors.dangerText, fontWeight: FontWeight.w700))),
                  ]),
                  const SizedBox(height: 4),
                  Text(stopReason, style: NalviumText.body.copyWith(color: NalviumColors.textPrimary, fontSize: 15)),
                ],
              ),
            ),
          ],
          // ── ÉQUIPEMENT ──
          ..._equipmentSection(l10n, req),
          // ── DÉJÀ ESSAYÉ ──
          if (req.actionsTried.isNotEmpty || req.observations.isNotEmpty || req.hypotheses.isNotEmpty || req.manual != null) ...[
            // Observations, hypothèses et notice = ce que Nalvium a constaté ; seules des actions = « Déjà essayé ».
            _heading(req.observations.isNotEmpty || req.hypotheses.isNotEmpty || req.manual != null ? l10n.helpSectionNoticed : l10n.helpSectionTried),
            for (final a in req.actionsTried)
              _Line(icon: Icons.check_rounded, text: '${a['instruction']} (${_resultLabel(l10n, a['result'] as String)})'),
            for (final o in req.observations.take(4)) _Line(icon: Icons.visibility_outlined, text: o),
            for (final h in req.hypotheses.take(2)) _Line(icon: Icons.help_outline_rounded, text: '${l10n.helpHypothesisNote} ${h['label']}'),
            if (req.manual != null)
              _Line(
                icon: Icons.menu_book_outlined,
                text: [l10n.helpManualUsed, if ((req.manual!['pages'] as List).isNotEmpty) l10n.helpManualPages((req.manual!['pages'] as List).join(', '))].join(' · '),
              ),
          ],
          // ── PHOTOS / VIDÉOS ──
          _heading(l10n.helpSectionMedia),
          Text(l10n.helpMediaPrivacy, key: const Key('help-media-privacy'), style: NalviumText.caption),
          const SizedBox(height: Space.x3),
          if (sessionMedia.isEmpty && _extraMedia.isEmpty)
            Text(l10n.helpMediaNone, key: const Key('help-media-none'), style: NalviumText.body.copyWith(fontSize: 15))
          else
            Wrap(
              spacing: Space.x3,
              runSpacing: Space.x3,
              children: [
                for (final m in sessionMedia) _MediaTile(id: m.id, video: m.video, selected: _selected.contains(m.id), onChanged: (v) => setState(() => v ? _selected.add(m.id) : _selected.remove(m.id))),
                for (final id in _extraMedia) _MediaTile(id: id, video: false, selected: _selected.contains(id), onChanged: (v) => setState(() => v ? _selected.add(id) : _selected.remove(id))),
              ],
            ),
          if (!_fromSession) ...[
            const SizedBox(height: Space.x2),
            SecondaryButton(key: const Key('help-add-photo'), label: l10n.helpMediaAdd, icon: _photoBusy ? null : Icons.photo_camera_outlined, onPressed: _photoBusy ? null : _addPhoto),
          ],
          // ── COORDONNÉES ──
          _heading(l10n.helpSectionContact),
          _field('help-first', l10n.helpFirstName, _first, errors['first'], autofill: const [AutofillHints.givenName], caps: TextCapitalization.words),
          _field('help-phone', l10n.helpPhone, _phone, errors['phone'], keyboard: TextInputType.phone, autofill: const [AutofillHints.telephoneNumber]),
          _field('help-city', l10n.helpCity, _city, errors['city'], caps: TextCapitalization.words, focus: _cityFocus),
          _field('help-postal', l10n.helpPostal, _postal, errors['postal'], keyboard: TextInputType.number, maxLength: 5, focus: _postalFocus),
          _field('help-email', l10n.helpEmail, _email, errors['email'], keyboard: TextInputType.emailAddress, optional: true),
          Row(children: [
            const Icon(Icons.lock_outline_rounded, size: 15, color: NalviumColors.textMuted),
            const SizedBox(width: 6),
            Flexible(child: Text(l10n.helpNoAddress, style: NalviumText.caption.copyWith(color: NalviumColors.textMuted, fontSize: 13))),
          ]),
          // ── DISPONIBILITÉ ──
          _heading(l10n.helpSectionWhen),
          Text(l10n.helpWhenNote, style: NalviumText.caption),
          const SizedBox(height: Space.x2),
          Wrap(
            spacing: Space.x2,
            runSpacing: Space.x2,
            children: [
              for (final (t, label) in [
                (AvailabilityType.asap, l10n.helpAsap), (AvailabilityType.today, l10n.helpToday), (AvailabilityType.tomorrow, l10n.helpTomorrow),
                (AvailabilityType.thisWeek, l10n.helpThisWeek), (AvailabilityType.custom, l10n.helpCustom),
              ])
                _Chip(key: Key('help-when-${t.wire}'), label: label, selected: _availability == t, onTap: () => setState(() => _availability = t)),
            ],
          ),
          if (_availability == AvailabilityType.custom) ...[
            const SizedBox(height: Space.x3),
            SecondaryButton(
              key: const Key('help-pick-date'),
              label: _date == null ? l10n.helpPickDate : '${_date!.day.toString().padLeft(2, '0')}/${_date!.month.toString().padLeft(2, '0')}/${_date!.year}',
              icon: Icons.event_outlined,
              onPressed: _pickDate,
            ),
            const SizedBox(height: Space.x2),
            Wrap(spacing: Space.x2, runSpacing: Space.x2, children: [
              for (final (w, label) in [('morning', l10n.helpMorning), ('afternoon', l10n.helpAfternoon), ('evening', l10n.helpEvening)])
                _Chip(key: Key('help-window-$w'), label: label, selected: _window == w, onTap: () => setState(() => _window = w)),
            ]),
          ],
          if (errors['when'] != null) _error(errors['when']!, const Key('help-when-error')),
          // ── CONSENTEMENT ──
          const SizedBox(height: Space.x6),
          Semantics(
            container: true,
            child: InkWell(
              key: const Key('help-consent'),
              borderRadius: BorderRadius.circular(Corner.small),
              onTap: () => setState(() => _consent = !_consent),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(value: _consent, onChanged: (v) => setState(() => _consent = v ?? false), activeColor: NalviumColors.primary, visualDensity: VisualDensity.standard),
                    const SizedBox(width: Space.x1),
                    Expanded(child: Padding(padding: const EdgeInsets.only(top: 12), child: Text(l10n.helpConsent, style: NalviumText.body.copyWith(color: NalviumColors.textPrimary, fontSize: 15)))),
                  ],
                ),
              ),
            ),
          ),
          if (errors['consent'] != null) _error(errors['consent']!, const Key('help-consent-error')),
          if (_sendError != null) ...[
            const SizedBox(height: Space.x4),
            EquipmentNotice(key: const Key('help-send-error'), text: _sendError!),
          ],
          const SizedBox(height: Space.x5),
          PrimaryButton(key: const Key('help-send'), label: l10n.helpSend, loading: _sending, onPressed: _send),
        ],
      ),
    );
  }

  List<Widget> _equipmentSection(AppLocalizations l10n, ServiceRequest req) {
    if (_fromSession) {
      final eq = req.equipment;
      if (eq == null) return const [];
      final label = [eq['name'], eq['brand'], eq['model'], eq['room']].whereType<String>().join(' · ');
      return [_heading(l10n.helpSectionEquipment), _Line(icon: EquipmentCatalog.of(eq['type'] as String).icon, text: label, key: const Key('help-equipment'))];
    }
    final items = ref.watch(homeProvider).value?.equipment ?? const <EquipmentSummary>[];
    if (items.isEmpty) return const [];
    return [
      _heading(l10n.helpSectionEquipment),
      Wrap(spacing: Space.x2, runSpacing: Space.x2, children: [
        for (final e in items)
          _Chip(key: Key('help-eq-${e.id}'), label: e.displayName, selected: _equipmentId == e.id, onTap: () => setState(() => _equipmentId = _equipmentId == e.id ? null : e.id)),
      ]),
    ];
  }

  String _resultLabel(AppLocalizations l10n, String r) => switch (r) {
    'fait' => l10n.helpTriedDone,
    'impossible' => l10n.helpTriedFailed,
    'ne correspondait pas' => l10n.helpTriedMismatch,
    _ => l10n.helpTriedProposed,
  };

  Widget _heading(String t) => Padding(
    padding: const EdgeInsets.only(top: Space.x6, bottom: Space.x2),
    child: Semantics(header: true, child: Text(t, style: NalviumText.title.copyWith(fontSize: 19))),
  );

  Widget _error(String text, Key key) => Padding(
    padding: const EdgeInsets.only(top: Space.x2),
    child: Row(key: key, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.error_outline_rounded, size: 18, color: NalviumColors.dangerText),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: NalviumText.caption.copyWith(color: NalviumColors.dangerText, fontWeight: FontWeight.w600))),
    ]),
  );

  Widget _field(String key, String label, TextEditingController c, String? error,
      {TextInputType? keyboard, TextCapitalization caps = TextCapitalization.none, int? maxLength, bool optional = false, List<String>? autofill, FocusNode? focus}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: Space.x3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: NalviumText.caption.copyWith(fontWeight: FontWeight.w700, color: NalviumColors.textPrimary)),
        const SizedBox(height: Space.x1 + 2),
        TextField(
          key: Key(key),
          controller: c,
          focusNode: focus,
          keyboardType: keyboard,
          textCapitalization: caps,
          maxLength: maxLength ?? 120,
          autofillHints: autofill,
          decoration: InputDecoration(counterText: '', errorText: error),
          onChanged: (_) => setState(() {}),
        ),
      ]),
    );
}

class _Chip extends StatelessWidget {
  const _Chip({super.key, required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? NalviumColors.primarySoft : NalviumColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corner.medium),
        side: BorderSide(color: selected ? NalviumColors.primary : NalviumColors.borderSubtle, width: 1.5),
      ),
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

class _Line extends StatelessWidget {
  const _Line({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.x2),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 18, color: NalviumColors.textSecondary)),
      const SizedBox(width: Space.x2),
      Expanded(child: Text(text, style: NalviumText.body.copyWith(fontSize: 15, color: NalviumColors.textPrimary))),
    ]),
  );
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.id, required this.video, required this.selected, required this.onChanged});
  final String id;
  final bool video;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '${video ? l10n.helpMediaVideo : l10n.photoSemantics} — ${l10n.helpMediaJoin}',
      excludeSemantics: true,
      child: InkWell(
        key: Key('help-media-$id'),
        borderRadius: BorderRadius.circular(Corner.small),
        onTap: () => onChanged(!selected),
        child: SizedBox(
          width: 104,
          child: Column(children: [
            Stack(children: [
              ClipRRect(borderRadius: BorderRadius.circular(Corner.small), child: SizedBox(width: 104, height: 104, child: AuthedImage(mediaId: id))),
              if (video) const Positioned(left: 6, bottom: 6, child: Icon(Icons.videocam_rounded, color: Colors.white, size: 20)),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: selected ? NalviumColors.primary : Colors.white, shape: BoxShape.circle, border: Border.all(color: NalviumColors.primary, width: 2)),
                  child: selected ? const Icon(Icons.check_rounded, size: 18, color: Colors.white) : null,
                ),
              ),
            ]),
            const SizedBox(height: 4),
            Text(l10n.helpMediaJoin, textAlign: TextAlign.center, style: NalviumText.caption.copyWith(fontSize: 12.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? NalviumColors.primaryText : NalviumColors.textSecondary)),
          ]),
        ),
      ),
    );
  }
}
