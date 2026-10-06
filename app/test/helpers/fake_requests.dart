import 'package:nalvium/core/network/api_exceptions.dart';
import 'package:nalvium/data/service_requests_repository.dart';
import 'package:nalvium/domain/service_request.dart';

Map<String, dynamic> requestJson({
  String id = 'r1',
  String status = 'SUBMITTED',
  String summary = 'Fuite sous mon évier',
  String? city = 'Lyon',
  List<String> media = const [],
  Map<String, dynamic>? context,
  String? sessionId,
  String? equipmentLabel,
  String availability = 'asap',
}) => {
  'id': id, 'status': status, 'diagnostic_session_id': sessionId, 'equipment_id': null, 'problem_category': 'plumbing',
  'problem_summary': summary, 'first_name': 'Camille', 'phone': '+33612345678', 'email': null, 'city': city,
  'postal_code': '69003', 'availability_type': availability, 'preferred_date': null, 'preferred_time_window': null,
  'media_ids': media, 'consent_version': kConsentVersion, 'consented_at': '2026-10-06T08:00:00+00:00',
  'submitted_at': '2026-10-06T08:00:00+00:00', 'created_at': '2026-10-06T08:00:00+00:00',
  'updated_at': '2026-10-06T08:00:00+00:00', 'context': context ?? {'source': 'direct'}, 'equipment_label': equipmentLabel,
};

ServiceRequest request({String id = 'r1', String status = 'SUBMITTED', String summary = 'Fuite sous mon évier', Map<String, dynamic>? context, List<String> media = const [], String? equipmentLabel}) =>
    ServiceRequest.fromJson(requestJson(id: id, status: status, summary: summary, context: context, media: media, equipmentLabel: equipmentLabel));

/// Faux dépôt de TEST (en mémoire). Enregistre ce qui est réellement envoyé.
class FakeServiceRequestsRepository implements ServiceRequestsRepository {
  FakeServiceRequestsRepository({List<ServiceRequest> items = const [], this.draftContext, this.draftSummary})
    : items = List.of(items);

  final List<ServiceRequest> items;
  Map<String, dynamic>? draftContext;
  String? draftSummary;
  final calls = <String>[];
  final updates = <Map<String, dynamic>>[];
  final mediaSelections = <List<String>>[];
  Object? listError;
  Object? prepareError;
  Object? submitError;
  Object? cancelError;
  String? lastSessionId;
  Map<String, dynamic>? created;
  final areaChecks = <(String, String)>[];
  final Map<String, AreaCheck> areaByPostal = {};
  Object? areaError;
  AreaCheck defaultArea = const AreaCheck(status: 'in_zone');
  Object? submitCode; // ApiHttpException à lever à l'envoi (ex. out_of_zone)

  @override
  Future<ServiceAreaInfo> serviceArea() async => const ServiceAreaInfo(name: 'Lyon', radiusKm: 50);

  @override
  Future<AreaCheck> checkArea(String city, String postalCode) async {
    calls.add('area');
    areaChecks.add((city, postalCode));
    if (areaError case final ApiException e) throw e;
    return areaByPostal[postalCode] ?? defaultArea;
  }

  @override
  Future<ServiceRequest> createDraft({String? equipmentId, String? summary, String? category}) async {
    calls.add('create');
    if (prepareError case final ApiException e) throw e;
    created = {'equipment_id': equipmentId, 'summary': summary, 'category': category};
    return ServiceRequest.fromJson(requestJson(id: 'draft1', status: 'DRAFT', summary: '')..['problem_summary'] = null);
  }

  @override
  Future<ServiceRequest> fromSession(String sessionId) async {
    calls.add('from-session');
    lastSessionId = sessionId;
    if (prepareError case final ApiException e) throw e;
    return ServiceRequest.fromJson(requestJson(id: 'draft1', status: 'DRAFT', summary: draftSummary ?? 'Lave-vaisselle qui ne vidange plus', context: draftContext, sessionId: sessionId));
  }

  @override
  Future<ServiceRequest> update(String id, Map<String, dynamic> fields) async {
    calls.add('update');
    updates.add(fields);
    return request(id: id, status: 'DRAFT');
  }

  @override
  Future<ServiceRequest> selectMedia(String id, List<String> mediaIds) async {
    calls.add('media');
    mediaSelections.add(mediaIds);
    return request(id: id, status: 'DRAFT', media: mediaIds);
  }

  @override
  Future<ServiceRequest> submit(String id) async {
    calls.add('submit');
    if (submitError case final ApiException e) throw e;
    if (submitCode case final ApiException e) throw e;
    final u = updates.isEmpty ? <String, dynamic>{} : updates.last;
    final r = ServiceRequest.fromJson(requestJson(
      id: id, summary: (u['problem_summary'] as String?) ?? 'x', media: mediaSelections.isEmpty ? const [] : mediaSelections.last,
      context: draftContext, availability: (u['availability_type'] as String?) ?? 'asap',
    ));
    items.insert(0, r);
    return r;
  }

  @override
  Future<ServiceRequest> cancel(String id) async {
    calls.add('cancel');
    if (cancelError case final ApiException e) throw e;
    final i = items.indexWhere((r) => r.id == id);
    final old = items[i];
    items[i] = ServiceRequest.fromJson(requestJson(id: id, status: 'CANCELLED', summary: old.summary ?? '', media: old.mediaIds));
    return items[i];
  }

  @override
  Future<ServiceRequest> get(String id) async {
    calls.add('get:$id');
    return items.firstWhere((r) => r.id == id, orElse: () => throw const ApiHttpException(404, 'request_not_found'));
  }

  @override
  Future<List<ServiceRequest>> list() async {
    calls.add('list');
    if (listError case final ApiException e) throw e;
    return List.of(items);
  }
}
