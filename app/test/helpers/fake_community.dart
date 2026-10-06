import 'package:nalvium/core/network/api_exceptions.dart';
import 'package:nalvium/data/community_repository.dart';
import 'package:nalvium/domain/community.dart';

CommunityPost makePost({
  String id = 'p1',
  String title = 'Mon lave-vaisselle ne vidangeait plus',
  String solution = "J'ai nettoyé le filtre et retiré un morceau de verre.",
  String? category = 'appliance',
  String? materials,
  String? photo,
  int helpful = 0,
  int comments = 0,
  bool mine = false,
  bool isHelpful = false,
  bool saved = false,
  DateTime? at,
}) => CommunityPost(
  id: id, title: title, solution: solution, category: category, materials: materials, photoId: photo,
  helpfulCount: helpful, commentCount: comments, mine: mine, helpful: isHelpful, saved: saved,
  createdAt: at ?? DateTime(2020, 3, 12),
);

/// Faux dépôt Communauté de TEST (en mémoire, pagination par curseur simulée). Jamais utilisé dans l'app.
class FakeCommunityRepository implements CommunityRepository {
  FakeCommunityRepository({List<CommunityPost> posts = const [], this.pageSize = 20}) : posts = List.of(posts);

  final List<CommunityPost> posts;
  final int pageSize;
  final calls = <String>[];
  final created = <Map<String, dynamic>>[];
  final updates = <Map<String, dynamic>>[];
  final reports = <String>[];
  final commentsByPost = <String, List<CommunityComment>>{};
  final discarded = <String>[];
  Object? feedError;
  Object? moreError;
  Object? createError;
  Object? actionError;
  Object? commentError;
  Object? postError;
  bool alreadyReported = false;
  int _n = 0;

  CommunityPage _page(List<CommunityPost> src, String? cursor) {
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + pageSize).clamp(0, src.length);
    return CommunityPage(items: src.sublist(start, end), nextCursor: end < src.length ? '$end' : null);
  }

  @override
  Future<CommunityPage> feed({String? cursor}) async {
    calls.add('feed:${cursor ?? 0}');
    if (cursor != null) {
      if (moreError case final ApiException e) throw e;
    }
    if (feedError case final ApiException e) throw e;
    return _page(posts, cursor);
  }

  @override
  Future<CommunityPage> saved({String? cursor}) async {
    calls.add('saved');
    return _page([for (final p in posts) if (p.saved) p], cursor);
  }

  @override
  Future<CommunityPost> post(String id) async {
    calls.add('post:$id');
    if (postError case final ApiException e) throw e;
    return posts.firstWhere((p) => p.id == id, orElse: () => throw const ApiHttpException(404, 'not_found'));
  }

  @override
  Future<CommunityPost> create({required String title, required String solution, String? category, String? materials, String? mediaId}) async {
    calls.add('create');
    if (createError case final ApiException e) throw e;
    created.add({'title': title, 'solution': solution, 'category': category, 'materials': materials, 'media_id': mediaId});
    final p = makePost(id: 'new${++_n}', title: title, solution: solution, category: category, materials: materials, photo: mediaId, mine: true, at: DateTime.now());
    posts.insert(0, p);
    return p;
  }

  @override
  Future<CommunityPost> update(String id, Map<String, dynamic> fields) async {
    calls.add('update');
    updates.add(fields);
    final i = posts.indexWhere((p) => p.id == id);
    final o = posts[i];
    posts[i] = makePost(id: id, title: fields['title'] as String? ?? o.title, solution: fields['solution'] as String? ?? o.solution, category: fields['category'] as String?, materials: fields['materials'] as String?, photo: fields.containsKey('media_id') ? fields['media_id'] as String? : o.photoId, mine: true, helpful: o.helpfulCount, comments: o.commentCount, saved: o.saved, isHelpful: o.helpful, at: o.createdAt);
    return posts[i];
  }

  @override
  Future<void> delete(String id) async {
    calls.add('delete');
    if (actionError case final ApiException e) throw e;
    posts.removeWhere((p) => p.id == id);
  }

  CommunityPost _mutate(String id, CommunityPost Function(CommunityPost) f) {
    final i = posts.indexWhere((p) => p.id == id);
    if (i < 0) throw const ApiHttpException(404, 'not_found');
    return posts[i] = f(posts[i]);
  }

  @override
  Future<CommunityPost> setHelpful(String id, bool on) async {
    calls.add('helpful:$on');
    if (actionError case final ApiException e) throw e;
    return _mutate(id, (p) => makePost(id: p.id, title: p.title, solution: p.solution, category: p.category, materials: p.materials, photo: p.photoId, helpful: p.helpfulCount + (on == p.helpful ? 0 : (on ? 1 : -1)), comments: p.commentCount, mine: p.mine, isHelpful: on, saved: p.saved, at: p.createdAt));
  }

  @override
  Future<CommunityPost> setSaved(String id, bool on) async {
    calls.add('save:$on');
    if (actionError case final ApiException e) throw e;
    return _mutate(id, (p) => makePost(id: p.id, title: p.title, solution: p.solution, category: p.category, materials: p.materials, photo: p.photoId, helpful: p.helpfulCount, comments: p.commentCount, mine: p.mine, isHelpful: p.helpful, saved: on, at: p.createdAt));
  }

  @override
  Future<CommentPage> comments(String postId, {String? cursor}) async {
    calls.add('comments:$postId');
    return CommentPage(items: List.of(commentsByPost[postId] ?? const []));
  }

  @override
  Future<CommunityComment> addComment(String postId, String body) async {
    calls.add('comment');
    if (commentError case final ApiException e) throw e;
    final c = CommunityComment(id: 'c${++_n}', body: body, createdAt: DateTime.now(), mine: true);
    commentsByPost.putIfAbsent(postId, () => []).add(c);
    return c;
  }

  @override
  Future<void> deleteComment(String commentId) async {
    calls.add('comment-delete');
    for (final l in commentsByPost.values) {
      l.removeWhere((c) => c.id == commentId);
    }
  }

  @override
  Future<String> uploadPhoto(String filePath) async {
    calls.add('upload');
    return 'pub${++_n}';
  }

  @override
  Future<String> derivePrivatePhoto(String privateMediaId) async {
    calls.add('derive:$privateMediaId');
    return 'pub${++_n}';
  }

  @override
  Future<void> discardDraftPhoto(String mediaId) async {
    discarded.add(mediaId);
  }

  @override
  Future<bool> reportPost(String postId, String reason, {String? details}) async {
    calls.add('report-post:$reason');
    reports.add('post:$postId:$reason');
    return !alreadyReported;
  }

  @override
  Future<bool> reportComment(String commentId, String reason, {String? details}) async {
    calls.add('report-comment:$reason');
    reports.add('comment:$commentId:$reason');
    return !alreadyReported;
  }
}
