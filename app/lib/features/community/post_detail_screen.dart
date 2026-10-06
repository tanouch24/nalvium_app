import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exceptions.dart';
import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/error_panel.dart';
import '../../domain/community.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import '../history/session_labels.dart';
import 'community_screen.dart';
import 'community_widgets.dart';

/// Détail d'une publication : la solution, « Utile », enregistrer, signaler, commentaires.
/// Une solution communautaire n'est PAS une instruction officielle Nalvium : c'est dit, discrètement.
class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({super.key, required this.postId});
  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final post = ref.watch(communityPostProvider(postId));
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(key: const Key('post-back'), onPressed: () => context.pop()),
        title: Text(l10n.cmTitle, style: NalviumText.title),
      ),
      body: SafeArea(
        child: post.when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Space.gutter),
              child: e is ApiHttpException && e.status == 404
                  ? Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text(l10n.cmGone, key: const Key('post-gone'), textAlign: TextAlign.center, style: NalviumText.titleLarge),
                      const SizedBox(height: Space.x6),
                      PrimaryButton(key: const Key('post-gone-back'), label: l10n.cmBack, onPressed: () => context.pop()),
                    ])
                  : ErrorPanel(error: e, onRetry: () => ref.invalidate(communityPostProvider(postId))),
            ),
          ),
          data: (p) => _Body(post: p),
        ),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.post});
  final CommunityPost post;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  final _comments = <CommunityComment>[];
  String? _cursor;
  bool _loaded = false;
  Object? _commentsError;
  bool _sending = false;
  String? _sendError;
  final _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    try {
      final page = await ref.read(communityRepositoryProvider).comments(widget.post.id, cursor: reset ? null : _cursor);
      if (!mounted) return;
      setState(() {
        if (reset) _comments.clear();
        final known = {for (final c in _comments) c.id};
        _comments.addAll(page.items.where((c) => !known.contains(c.id)));
        _cursor = page.nextCursor;
        _loaded = true;
        _commentsError = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _commentsError = e);
    }
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    if (text.length > 500) {
      setState(() => _sendError = l10n.cmCommentTooLong);
      return;
    }
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      final c = await ref.read(communityRepositoryProvider).addComment(widget.post.id, text);
      if (!mounted) return;
      setState(() {
        _comments.add(c);
        _input.clear();
      });
      ref.invalidate(communityPostProvider(widget.post.id));
      ref.read(communityFeedProvider(false).notifier).refresh();
    } on ApiHttpException catch (e) {
      if (mounted) setState(() => _sendError = e.code == 'unsafe_content' ? l10n.cmCommentUnsafe : l10n.cmCommentFail);
    } on ApiException {
      if (mounted) setState(() => _sendError = l10n.cmCommentFail);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteComment(CommunityComment c) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(communityRepositoryProvider).deleteComment(c.id);
      if (mounted) setState(() => _comments.removeWhere((x) => x.id == c.id));
      ref.invalidate(communityPostProvider(widget.post.id));
    } on ApiException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cmActionFail)));
    }
  }

  Future<void> _deletePost() async {
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
            Text(l10n.cmDeleteTitle, style: NalviumText.titleLarge),
            const SizedBox(height: Space.x3),
            Text(l10n.cmDeleteBody, style: NalviumText.body),
            const SizedBox(height: Space.x6),
            DangerButton(key: const Key('post-delete-confirm'), label: l10n.cmDeleteConfirm, onPressed: () => Navigator.of(sheet).pop(true)),
            const SizedBox(height: Space.x2),
            SecondaryButton(key: const Key('post-delete-cancel'), label: l10n.cancel, onPressed: () => Navigator.of(sheet).pop(false)),
          ]),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(communityRepositoryProvider).delete(widget.post.id);
      ref.read(communityFeedProvider(false).notifier).remove(widget.post.id);
      ref.read(communityFeedProvider(true).notifier).remove(widget.post.id);
      if (mounted) context.pop();
    } on ApiHttpException catch (e) {
      if (e.status == 404 && mounted) {
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cmDeleteFail)));
      }
    } on ApiException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cmDeleteFail)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = widget.post;
    final cat = categoryName(l10n, p.category);
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(Space.gutter, Space.x2, Space.gutter, Space.x10 + MediaQuery.viewInsetsOf(context).bottom),
      children: [
        if (p.photoId != null) ...[
          AspectRatio(
            aspectRatio: (p.photoWidth != null && p.photoHeight != null && p.photoHeight! > 0) ? (p.photoWidth! / p.photoHeight!).clamp(0.75, 1.8) : 16 / 9,
            child: ClipRRect(borderRadius: BorderRadius.circular(Corner.large), child: CommunityImage(key: const Key('post-photo'), mediaId: p.photoId!, variant: 'large', semanticLabel: l10n.photoSemantics)),
          ),
          const SizedBox(height: Space.x4),
        ],
        Text([if (cat.isNotEmpty) cat, '${l10n.cmMember} · ${relativeDate(l10n, p.createdAt)}'].join(' · '), key: const Key('post-meta'), style: NalviumText.caption.copyWith(color: NalviumColors.textMuted)),
        const SizedBox(height: Space.x1),
        Semantics(header: true, child: Text(p.title, key: const Key('post-title'), style: NalviumText.titleLarge.copyWith(fontSize: 26))),
        const SizedBox(height: Space.x3),
        Text(p.solution, key: const Key('post-solution'), style: NalviumText.bodyLarge.copyWith(fontWeight: FontWeight.w400, fontSize: 17.5)),
        if (p.materials != null) ...[
          const SizedBox(height: Space.x3),
          Text('${l10n.cmMaterials} : ${p.materials}', key: const Key('post-materials'), style: NalviumText.body.copyWith(color: NalviumColors.textPrimary)),
        ],
        const SizedBox(height: Space.x3),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.info_outline_rounded, size: 16, color: NalviumColors.textMuted)),
          const SizedBox(width: 6),
          Expanded(child: Text(l10n.cmNotOfficial, key: const Key('post-not-official'), style: NalviumText.caption.copyWith(color: NalviumColors.textMuted, fontSize: 13))),
        ]),
        const SizedBox(height: Space.x3),
        Wrap(children: [
          CommunityAction(
            key: const Key('detail-helpful'),
            icon: Icons.thumb_up_outlined,
            activeIcon: Icons.thumb_up_alt_rounded,
            label: p.helpfulCount > 0 ? '${l10n.cmHelpful} · ${p.helpfulCount}' : l10n.cmHelpful,
            active: p.helpful,
            onTap: () => toggleHelpful(context, ref, p),
          ),
          CommunityAction(
            key: const Key('detail-save'),
            icon: Icons.bookmark_border_rounded,
            activeIcon: Icons.bookmark_rounded,
            label: p.saved ? l10n.cmSaved : l10n.cmSave,
            active: p.saved,
            onTap: () => toggleSaved(context, ref, p),
          ),
          CommunityAction(
            key: const Key('detail-report'),
            icon: Icons.flag_outlined,
            label: l10n.cmReport,
            onTap: () => showReportSheet(context, ref, send: (r) => ref.read(communityRepositoryProvider).reportPost(p.id, r)),
          ),
        ]),
        if (p.mine) ...[
          const SizedBox(height: Space.x2),
          Wrap(spacing: Space.x2, runSpacing: Space.x1, crossAxisAlignment: WrapCrossAlignment.center, children: [
            SecondaryButton(key: const Key('post-edit'), label: l10n.cmEdit, icon: Icons.edit_outlined, onPressed: () async {
              await context.push('/community/post/${p.id}/edit', extra: p);
              ref.invalidate(communityPostProvider(p.id));
            }),
            TertiaryButton(key: const Key('post-delete'), label: l10n.cmDelete, color: NalviumColors.dangerText, onPressed: _deletePost),
          ]),
        ],
        const SizedBox(height: Space.x6),
        Semantics(header: true, child: Text('${l10n.cmComments}${p.commentCount > 0 ? ' · ${p.commentCount}' : ''}', style: NalviumText.title.copyWith(fontSize: 19))),
        const SizedBox(height: Space.x3),
        if (_commentsError != null && !_loaded)
          Column(children: [
            Text(l10n.cmLoadFail, style: NalviumText.body),
            TertiaryButton(key: const Key('comments-retry'), label: l10n.retry, onPressed: () => _load(reset: true)),
          ])
        else if (!_loaded)
          const Padding(padding: EdgeInsets.all(Space.x4), child: Center(child: CircularProgressIndicator()))
        else if (_comments.isEmpty)
          Text(l10n.cmNoComments, key: const Key('no-comments'), style: NalviumText.body.copyWith(fontSize: 15))
        else
          for (final c in _comments) _CommentRow(comment: c, onDelete: () => _deleteComment(c), onReport: () => showReportSheet(context, ref, send: (r) => ref.read(communityRepositoryProvider).reportComment(c.id, r))),
        if (_cursor != null) TertiaryButton(key: const Key('comments-more'), label: l10n.cmLoadMore, onPressed: () => _load()),
        const SizedBox(height: Space.x3),
        TextField(
          key: const Key('comment-field'),
          controller: _input,
          minLines: 1,
          maxLines: 4,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: l10n.cmCommentHint, counterText: ''),
          onChanged: (_) => setState(() {}),
        ),
        if (_sendError != null)
          Padding(
            padding: const EdgeInsets.only(top: Space.x2),
            child: Text(_sendError!, key: const Key('comment-error'), style: NalviumText.caption.copyWith(color: NalviumColors.dangerText, fontWeight: FontWeight.w600)),
          ),
        const SizedBox(height: Space.x2),
        PrimaryButton(key: const Key('comment-send'), label: l10n.cmCommentSend, loading: _sending, onPressed: _input.text.trim().isEmpty ? null : _send),
      ],
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.comment, required this.onDelete, required this.onReport});
  final CommunityComment comment;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      key: Key('comment-${comment.id}'),
      margin: const EdgeInsets.only(bottom: Space.x2),
      padding: const EdgeInsets.fromLTRB(Space.x4, Space.x3, Space.x2, Space.x1),
      decoration: BoxDecoration(color: NalviumColors.surface, borderRadius: BorderRadius.circular(Corner.medium), border: Border.all(color: NalviumColors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${l10n.cmMember} · ${relativeDate(l10n, comment.createdAt)}', style: NalviumText.caption.copyWith(color: NalviumColors.textMuted, fontSize: 13)),
        const SizedBox(height: 2),
        Text(comment.body, style: NalviumText.body.copyWith(color: NalviumColors.textPrimary, fontSize: 15.5)),
        Align(
          alignment: Alignment.centerRight,
          child: comment.mine
              ? CommunityAction(key: Key('comment-delete-${comment.id}'), icon: Icons.delete_outline_rounded, label: l10n.cmCommentDelete, onTap: onDelete)
              : CommunityAction(key: Key('comment-report-${comment.id}'), icon: Icons.flag_outlined, label: l10n.cmReport, onTap: onReport),
        ),
      ]),
    );
  }
}
