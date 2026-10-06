import 'dart:async';

import 'package:nalvium/core/network/api_exceptions.dart';
import 'package:nalvium/data/home_repository.dart';
import 'package:nalvium/domain/equipment.dart';
import 'package:nalvium/domain/session.dart';

import 'fakes.dart';

EquipmentSummary equipment({
  String id = 'e1',
  String type = 'dishwasher',
  String name = 'Lave-vaisselle',
  String? brand,
  String? model,
  String? room = 'kitchen',
  String? photo,
  int diagnostics = 0,
}) => EquipmentSummary(
  id: id,
  equipmentType: type,
  displayName: name,
  brand: brand,
  model: model,
  roomType: room,
  roomName: RoomCatalog.of(room)?.label,
  photoMediaId: photo,
  diagnosticsCount: diagnostics,
);

/// Faux dépôt « Maison » de TEST : en mémoire, erreurs pilotées par le test. Jamais utilisé dans l'app.
class FakeHomeRepository implements HomeRepository {
  FakeHomeRepository({List<EquipmentSummary> items = const [], Map<String, List<EquipmentDiagnostic>>? diagnostics})
    : items = List.of(items),
      diagnostics = diagnostics ?? {};

  final List<EquipmentSummary> items;
  final Map<String, List<EquipmentDiagnostic>> diagnostics;
  final calls = <String>[];
  final created = <EquipmentDraft>[];
  final updates = <Map<String, dynamic>>[];
  final links = <(String, String?)>[];

  Object? homeError;
  Object? createError;
  Object? uploadError;
  Object? identifyError;
  Object? deleteError;
  Object? linkError;
  Object? updateError;
  EquipmentIdentification identification = const EquipmentIdentification(
    equipmentType: 'dishwasher',
    brand: 'Bosch',
    confidence: 0.6,
  );
  EquipmentSuggestions suggested = const EquipmentSuggestions();

  /// Notice par équipement (état « serveur ») et issue de la prochaine recherche.
  final manuals = <String, ManualInfo>{};
  Object? manualError;
  ManualSearchResult? nextSearch;
  Completer<void>? searchGate;
  final manualPages = <int, String>{1: 'Texte de la page 1', 2: 'Texte de la page 2'};
  int _n = 0;

  @override
  Future<HomeData> getHome() async {
    calls.add('home');
    if (homeError case final ApiException e) throw e;
    return HomeData(equipment: List.of(items));
  }

  @override
  Future<EquipmentDetail> getEquipment(String id) async {
    calls.add('get:$id');
    final found = items.where((e) => e.id == id);
    if (found.isEmpty) throw const ApiHttpException(404, 'equipment_not_found');
    return EquipmentDetail(summary: found.first, diagnostics: diagnostics[id] ?? const [], manual: manuals[id]);
  }

  @override
  Future<EquipmentDetail> createEquipment(EquipmentDraft d) async {
    calls.add('create');
    if (createError case final ApiException e) throw e;
    created.add(d);
    final item = EquipmentSummary(
      id: 'new${++_n}',
      equipmentType: d.equipmentType,
      displayName: (d.displayName ?? '').trim().isEmpty ? EquipmentCatalog.of(d.equipmentType).label : d.displayName!.trim(),
      brand: (d.brand ?? '').trim().isEmpty ? null : d.brand!.trim(),
      model: (d.model ?? '').trim().isEmpty ? null : d.model!.trim(),
      roomType: d.roomType,
      roomName: RoomCatalog.of(d.roomType)?.label,
      photoMediaId: d.photoMediaId,
    );
    items.add(item);
    return EquipmentDetail(summary: item, diagnostics: const []);
  }

  @override
  Future<EquipmentDetail> updateEquipment(String id, Map<String, dynamic> fields) async {
    calls.add('update:$id');
    if (updateError case final ApiException e) throw e;
    updates.add(fields);
    final i = items.indexWhere((e) => e.id == id);
    if (i < 0) throw const ApiHttpException(404, 'equipment_not_found');
    final old = items[i];
    String? opt(String key, String? current) => fields.containsKey(key) ? ((fields[key] as String?)?.isEmpty ?? true ? null : fields[key] as String) : current;
    final room = fields.containsKey('room_type') ? fields['room_type'] as String? : old.roomType;
    items[i] = EquipmentSummary(
      id: id,
      equipmentType: (fields['equipment_type'] as String?) ?? old.equipmentType,
      displayName: (fields['display_name'] as String?) ?? old.displayName,
      brand: opt('brand', old.brand),
      model: opt('model', old.model),
      roomType: room,
      roomName: RoomCatalog.of(room)?.label,
      photoMediaId: fields.containsKey('primary_media_id') ? fields['primary_media_id'] as String? : old.photoMediaId,
      diagnosticsCount: old.diagnosticsCount,
    );
    return EquipmentDetail(summary: items[i], diagnostics: diagnostics[id] ?? const []);
  }

  @override
  Future<void> deleteEquipment(String id) async {
    calls.add('delete:$id');
    if (deleteError case final ApiException e) throw e;
    items.removeWhere((e) => e.id == id);
  }

  @override
  Future<String> uploadEquipmentPhoto(String filePath) async {
    calls.add('upload');
    if (uploadError case final ApiException e) throw e;
    return 'photo${calls.where((c) => c == 'upload').length}';
  }

  final discarded = <String>[];

  @override
  Future<void> discardEquipmentPhoto(String mediaId) async {
    discarded.add(mediaId);
  }

  @override
  Future<EquipmentIdentification> identify(String mediaId) async {
    calls.add('identify:$mediaId');
    if (identifyError case final ApiException e) throw e;
    return identification;
  }

  @override
  Future<SessionState> linkSession(String sessionId, String? equipmentId) async {
    calls.add('link');
    if (linkError case final ApiException e) throw e;
    links.add((sessionId, equipmentId));
    return sessionState(id: sessionId);
  }

  @override
  Future<ManualSearchResult> searchManual(String equipmentId) async {
    calls.add('manual-search:$equipmentId');
    if (searchGate != null) await searchGate!.future;
    if (manualError case final ApiException e) throw e;
    final r = nextSearch ?? const ManualSearchResult(outcome: 'not_found', manual: ManualInfo(status: 'not_found'));
    manuals[equipmentId] = r.manual;
    return r;
  }

  @override
  Future<ManualSearchResult> confirmManual(String equipmentId) async {
    calls.add('manual-confirm:$equipmentId');
    if (manualError case final ApiException e) throw e;
    final old = manuals[equipmentId]!;
    final done = ManualInfo(
      status: 'available', manufacturer: old.manufacturer, modelReference: old.modelReference, title: old.title,
      sourceDomain: old.sourceDomain, official: true, pageCount: old.pageCount, matchLevel: old.matchLevel,
    );
    manuals[equipmentId] = done;
    return ManualSearchResult(outcome: 'found', manual: done);
  }

  @override
  Future<void> deleteManual(String equipmentId) async {
    calls.add('manual-delete:$equipmentId');
    manuals.remove(equipmentId);
  }

  @override
  Future<ManualPage> manualPage(String equipmentId, int page) async {
    calls.add('manual-page:$page');
    if (manualError case final ApiException e) throw e;
    return ManualPage(page: page, pageCount: manuals[equipmentId]?.pageCount ?? 2, text: manualPages[page] ?? '');
  }

  @override
  Future<EquipmentSuggestions> suggestions(String sessionId) async {
    calls.add('suggestions');
    return suggested;
  }
}
