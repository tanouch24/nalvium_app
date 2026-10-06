import 'session.dart';
import 'text.dart';

/// Version du consentement de publication publique (doit correspondre au backend).
const kCommunityConsentVersion = '2026-10-community';

const kCommunityCategories = ['plumbing', 'appliance', 'handyman', 'other'];
const kReportReasons = ['dangerous', 'spam', 'inappropriate', 'personal_info', 'other'];

/// Publication PUBLIQUE : aucun identifiant d'auteur, aucune donnée privée.
class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.title,
    required this.solution,
    required this.createdAt,
    this.category,
    this.materials,
    this.helpfulCount = 0,
    this.commentCount = 0,
    this.photoId,
    this.photoWidth,
    this.photoHeight,
    this.mine = false,
    this.helpful = false,
    this.saved = false,
  });

  final String id;
  final String title;
  final String solution;
  final String? category;
  final String? materials;
  final DateTime createdAt;
  final int helpfulCount;
  final int commentCount;
  final String? photoId;
  final int? photoWidth;
  final int? photoHeight;
  final bool mine;
  final bool helpful;
  final bool saved;

  factory CommunityPost.fromJson(Map<String, dynamic> j) => CommunityPost(
    id: j['id'] as String,
    title: cleanText(j['title'] as String),
    solution: (j['solution'] as String).trim(),
    category: j['category'] as String?,
    materials: j['materials'] == null ? null : cleanText(j['materials'] as String),
    createdAt: DateTime.parse(j['created_at'] as String),
    helpfulCount: j['helpful_count'] as int? ?? 0,
    commentCount: j['comment_count'] as int? ?? 0,
    photoId: j['photo_id'] as String?,
    photoWidth: j['photo_width'] as int?,
    photoHeight: j['photo_height'] as int?,
    mine: j['mine'] as bool? ?? false,
    helpful: j['helpful'] as bool? ?? false,
    saved: j['saved'] as bool? ?? false,
  );
}

class CommunityPage {
  const CommunityPage({required this.items, this.nextCursor});
  final List<CommunityPost> items;
  final String? nextCursor;

  factory CommunityPage.fromJson(Map<String, dynamic> j) => CommunityPage(
    items: [for (final e in j['items'] as List) CommunityPost.fromJson(e as Map<String, dynamic>)],
    nextCursor: j['next_cursor'] as String?,
  );
}

class CommunityComment {
  const CommunityComment({required this.id, required this.body, required this.createdAt, required this.mine});
  final String id;
  final String body;
  final DateTime createdAt;
  final bool mine;

  factory CommunityComment.fromJson(Map<String, dynamic> j) => CommunityComment(
    id: j['id'] as String,
    body: cleanText(j['body'] as String),
    createdAt: DateTime.parse(j['created_at'] as String),
    mine: j['mine'] as bool? ?? false,
  );
}

class CommentPage {
  const CommentPage({required this.items, this.nextCursor});
  final List<CommunityComment> items;
  final String? nextCursor;

  factory CommentPage.fromJson(Map<String, dynamic> j) => CommentPage(
    items: [for (final e in j['items'] as List) CommunityComment.fromJson(e as Map<String, dynamic>)],
    nextCursor: j['next_cursor'] as String?,
  );
}

/// Brouillon de publication (formulaire). Les médias privés d'un diagnostic ne sont JAMAIS joints d'office.
class CommunityDraft {
  const CommunityDraft({this.title = '', this.solution = '', this.category, this.materials = '', this.privatePhotoIds = const []});
  final String title;
  final String solution;
  final String? category;
  final String materials;

  /// Photos PRIVÉES du diagnostic proposées au choix (jamais publiées sans choix + consentement explicites).
  final List<String> privatePhotoIds;

  /// Brouillon dérivé d'un diagnostic RÉSOLU : uniquement titre, catégorie et étapes confirmées « faites ».
  /// Jamais : conversation, hypothèses, pièce, marque/modèle, notice, Safety Stop, coordonnées, médias privés.
  factory CommunityDraft.fromSession(SessionState s) {
    final steps = [for (final a in s.actions) if (a.status == 'done') a.instruction.trim()];
    return CommunityDraft(
      title: (s.title ?? '').trim(),
      solution: steps.isEmpty ? '' : steps.map((e) => '• $e').join('\n'),
      category: switch (s.category) {
        'plumbing' => 'plumbing',
        'appliance' => 'appliance',
        'handyman' => 'handyman',
        _ => 'other',
      },
      materials: (s.next?.requiredItems ?? const <String>[]).join(', '),
      privatePhotoIds: [for (final m in s.mediaItems) if (!m.video) m.id],
    );
  }
}
