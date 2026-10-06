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
import 'community_widgets.dart';

/// Communauté : le fil national des solutions partagées. Simple, lumineux, une action principale.
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: Space.gutter,
        title: Text(
          l10n.cmTitle,
          key: const Key('community-title'),
          style: NalviumText.titleLarge,
        ),
        toolbarHeight: 72,
      ),
      body: SafeArea(
        child: PostList(saved: false, header: _Header(l10n: l10n)),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fil vide : un seul CTA principal (celui de l'état vide). Avec des publications : accès normal ici.
    final hasPosts = ref.watch(communityFeedProvider(false)).items.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.cmIntro,
            key: const Key('community-intro'),
            style: NalviumText.body,
          ),
          const SizedBox(height: Space.x3),
          Wrap(
            spacing: Space.x2,
            runSpacing: Space.x1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (hasPosts)
                SecondaryButton(
                  key: const Key('community-share'),
                  label: l10n.cmShare,
                  icon: Icons.add_rounded,
                  onPressed: () => context.push('/community/new'),
                ),
              TertiaryButton(
                key: const Key('community-saved'),
                label: l10n.cmSaved,
                color: NalviumColors.primaryText,
                onPressed: () => context.push('/community/saved'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Liste paginée (fil ou enregistrés) : chargement progressif, rafraîchissement, états vide / erreur.
class PostList extends ConsumerStatefulWidget {
  const PostList({super.key, required this.saved, this.header});
  final bool saved;
  final Widget? header;

  @override
  ConsumerState<PostList> createState() => _PostListState();
}

class _PostListState extends ConsumerState<PostList> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) {
        ref.read(communityFeedProvider(widget.saved).notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final feed = ref.watch(communityFeedProvider(widget.saved));
    final notifier = ref.read(communityFeedProvider(widget.saved).notifier);
    Widget body;
    if (feed.loading && feed.items.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (feed.error != null && feed.items.isEmpty) {
      body = Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.gutter),
          child: ErrorPanel(error: feed.error!, onRetry: notifier.refresh),
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: notifier.refresh,
        child: ListView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            Space.x2,
            Space.gutter,
            Space.x10,
          ),
          children: [
            ?widget.header,
            if (feed.items.isEmpty)
              _Empty(saved: widget.saved)
            else ...[
              for (final p in feed.items)
                PostCard(post: p, saved: widget.saved),
              if (feed.loadingMore)
                const Padding(
                  padding: EdgeInsets.all(Space.x4),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (feed.moreError != null)
                TertiaryButton(
                  key: const Key('community-more-retry'),
                  label: l10n.retry,
                  onPressed: notifier.loadMore,
                ),
              if (!feed.hasMore && !feed.loadingMore && feed.moreError == null)
                Padding(
                  padding: const EdgeInsets.all(Space.x4),
                  child: Center(
                    child: Text(
                      l10n.cmEnd,
                      key: const Key('community-end'),
                      style: NalviumText.caption,
                    ),
                  ),
                ),
            ],
          ],
        ),
      );
    }
    return body;
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.saved});
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.x8),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: NalviumColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              saved ? Icons.bookmark_border_rounded : Icons.groups_outlined,
              size: 38,
              color: NalviumColors.primary,
            ),
          ),
          const SizedBox(height: Space.x5),
          Text(
            saved ? l10n.cmSavedEmpty : l10n.cmEmptyTitle,
            key: const Key('community-empty'),
            textAlign: TextAlign.center,
            style: NalviumText.title.copyWith(fontSize: 20),
          ),
          if (!saved) ...[
            const SizedBox(height: Space.x2),
            Text(
              l10n.cmEmptyBody,
              textAlign: TextAlign.center,
              style: NalviumText.body,
            ),
            const SizedBox(height: Space.x5),
            PrimaryButton(
              key: const Key('community-empty-share'),
              label: l10n.cmShare,
              onPressed: () => context.push('/community/new'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Carte compacte : photo, catégorie, titre, solution courte, matériel, date, compteurs, 3 actions.
class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.post, required this.saved});
  final CommunityPost post;
  final bool saved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = post;
    final cat = categoryName(l10n, p.category);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x3),
      child: Material(
        color: NalviumColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corner.medium),
          side: const BorderSide(color: NalviumColors.borderSubtle, width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              key: Key('post-${p.id}'),
              onTap: () => context.push('/community/post/${p.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (p.photoId != null)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CommunityImage(
                        key: Key('post-photo-${p.id}'),
                        mediaId: p.photoId!,
                        variant: 'thumb',
                        semanticLabel: l10n.photoSemantics,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.x4,
                      Space.x3,
                      Space.x4,
                      Space.x1,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            if (cat.isNotEmpty) cat,
                            relativeDate(l10n, p.createdAt),
                          ].join(' · '),
                          style: NalviumText.caption.copyWith(
                            color: NalviumColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: NalviumText.title.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.solution,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: NalviumText.body.copyWith(fontSize: 15),
                        ),
                        if (p.materials != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.cmMaterials} : ${p.materials}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: NalviumText.caption,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.x2),
              child: Wrap(
                children: [
                  CommunityAction(
                    key: Key('helpful-${p.id}'),
                    icon: Icons.thumb_up_outlined,
                    activeIcon: Icons.thumb_up_alt_rounded,
                    label: p.helpfulCount > 0
                        ? '${l10n.cmHelpful} · ${p.helpfulCount}'
                        : l10n.cmHelpful,
                    active: p.helpful,
                    onTap: () => toggleHelpful(context, ref, p),
                  ),
                  CommunityAction(
                    key: Key('comment-${p.id}'),
                    icon: Icons.chat_bubble_outline_rounded,
                    label: p.commentCount > 0
                        ? '${l10n.cmComment} · ${p.commentCount}'
                        : l10n.cmComment,
                    onTap: () => context.push('/community/post/${p.id}'),
                  ),
                  CommunityAction(
                    key: Key('save-${p.id}'),
                    icon: Icons.bookmark_border_rounded,
                    activeIcon: Icons.bookmark_rounded,
                    label: p.saved ? l10n.cmSaved : l10n.cmSave,
                    active: p.saved,
                    onTap: () => toggleSaved(context, ref, p),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Utile / retirer : met à jour le fil et les enregistrés avec la réponse du serveur (compteur réel).
Future<CommunityPost?> toggleHelpful(
  BuildContext context,
  WidgetRef ref,
  CommunityPost p,
) async {
  final l10n = AppLocalizations.of(context);
  try {
    final updated = await ref
        .read(communityRepositoryProvider)
        .setHelpful(p.id, !p.helpful);
    _sync(ref, updated);
    return updated;
  } on ApiException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cmActionFail)));
    }
    return null;
  }
}

Future<CommunityPost?> toggleSaved(
  BuildContext context,
  WidgetRef ref,
  CommunityPost p,
) async {
  final l10n = AppLocalizations.of(context);
  try {
    final updated = await ref
        .read(communityRepositoryProvider)
        .setSaved(p.id, !p.saved);
    _sync(ref, updated);
    ref.read(communityFeedProvider(true).notifier).refresh();
    return updated;
  } on ApiException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cmActionFail)));
    }
    return null;
  }
}

void _sync(WidgetRef ref, CommunityPost updated) {
  ref.read(communityFeedProvider(false).notifier).replace(updated);
  ref.read(communityFeedProvider(true).notifier).replace(updated);
  ref.invalidate(communityPostProvider(updated.id));
}
