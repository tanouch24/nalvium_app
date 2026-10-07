import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_info.dart';
import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/buttons.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import 'legal_texts.dart';

AppBar _bar(BuildContext context, String title) => AppBar(
  automaticallyImplyLeading: false,
  leading: BackButton(onPressed: () => context.pop()),
  title: Text(
    title,
    style: NalviumText.title,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  ),
  toolbarHeight: 72,
);

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Space.gutter,
      Space.x6,
      Space.gutter,
      Space.x2,
    ),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: NalviumText.title.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: NalviumColors.textSecondary,
        ),
      ),
    ),
  );
}

/// Un groupe de lignes sur une surface légère, séparées par de fins traits.
class _Group extends StatelessWidget {
  const _Group(this.children);
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
    child: Container(
      decoration: BoxDecoration(
        color: NalviumColors.surface,
        borderRadius: BorderRadius.circular(Corner.small + 4),
        border: Border.all(color: NalviumColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                indent: Space.x4,
                color: NalviumColors.borderSubtle,
              ),
            children[i],
          ],
        ],
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.label,
    this.value,
    this.onTap,
    this.icon,
    this.destructive = false,
  });
  final String label;
  final IconData? icon;
  final String? value;
  final VoidCallback? onTap;
  final bool destructive;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Space.tap),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.x4,
          vertical: Space.x3,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 22,
                color: destructive
                    ? NalviumColors.dangerText
                    : NalviumColors.primary,
              ),
              const SizedBox(width: Space.x3),
            ],
            Expanded(
              child: Text(
                label,
                style: NalviumText.bodyLarge.copyWith(
                  color: destructive
                      ? NalviumColors.dangerText
                      : NalviumColors.textPrimary,
                ),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: NalviumText.body.copyWith(
                  color: NalviumColors.textMuted,
                ),
              ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: NalviumColors.textMuted,
              ),
          ],
        ),
      ),
    ),
  );
}

/// Réglages : seulement ce qui sert vraiment (données, publicité, aide, légal, version).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: _bar(context, l.stTitle),
      body: SafeArea(
        child: ListView(
          key: const Key('settings-list'),
          children: [
            _Header(l.stSecData),
            _Group([
              _Row(
                key: const Key('st-data'),
                icon: Icons.folder_open_rounded,
                label: l.stDataRow,
                onTap: () => context.push('/settings/data'),
              ),
            ]),
            _Header(l.stSecPrivacy),
            _Group([
              _Row(
                key: const Key('st-privacy'),
                icon: Icons.lock_outline_rounded,
                label: l.stPrivacy,
                onTap: () => context.push('/settings/legal/privacy'),
              ),
              _Row(
                key: const Key('st-ads'),
                icon: Icons.tune_rounded,
                label: l.stAdChoices,
                onTap: () => context.push('/settings/ads'),
              ),
            ]),
            _Header(l.stSecHelp),
            _Group([
              _Row(
                key: const Key('st-about'),
                icon: Icons.info_outline_rounded,
                label: l.stAbout,
                onTap: () => context.push('/settings/legal/about'),
              ),
              _Row(
                key: const Key('st-contact'),
                icon: Icons.mail_outline_rounded,
                label: l.stContact,
                onTap: () => context.push('/settings/contact'),
              ),
            ]),
            _Header(l.stSecLegal),
            _Group([
              _Row(
                key: const Key('st-terms'),
                icon: Icons.description_outlined,
                label: l.stTerms,
                onTap: () => context.push('/settings/legal/terms'),
              ),
              _Row(
                key: const Key('st-notice'),
                icon: Icons.gavel_rounded,
                label: l.stLegalNotice,
                onTap: () => context.push('/settings/legal/legal'),
              ),
              _Row(
                key: const Key('st-ai'),
                icon: Icons.auto_awesome_outlined,
                label: l.stAiInfo,
                onTap: () => context.push('/settings/legal/ai'),
              ),
            ]),
            _Header(l.stSecApp),
            _Group([
              _Row(
                key: const Key('st-version'),
                label: l.stVersion,
                value: '$kAppVersionName ($kAppBuildNumber)',
              ),
            ]),
            const SizedBox(height: Space.x8),
          ],
        ),
      ),
    );
  }
}

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.documentId});
  final String documentId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final doc = legalById(documentId);
    if (doc == null) {
      return Scaffold(
        appBar: _bar(context, l.stTitle),
        body: const SizedBox.shrink(),
      );
    }
    return Scaffold(
      appBar: _bar(context, doc.title),
      body: SafeArea(
        child: ListView(
          key: Key('legal-${doc.id}'),
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            0,
            Space.gutter,
            Space.x8,
          ),
          children: [
            for (final s in doc.sections) ...[
              const SizedBox(height: Space.x6),
              Semantics(
                header: true,
                child: Text(
                  s.heading,
                  style: NalviumText.title.copyWith(fontSize: 18.5),
                ),
              ),
              for (final p in s.paragraphs)
                Padding(
                  padding: const EdgeInsets.only(top: Space.x2 + 2),
                  child: Text(
                    p,
                    style: NalviumText.body.copyWith(
                      color: NalviumColors.textPrimary,
                      height: 1.55,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: Space.x4),
            Text(
              'v$kLegalVersion',
              style: NalviumText.caption.copyWith(
                color: NalviumColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: _bar(context, l.stContact),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Space.gutter),
          children: [
            Text(l.stContactBody, style: NalviumText.bodyLarge),
            const SizedBox(height: Space.x4),
            SelectableText(
              kContactEmail,
              key: const Key('contact-email'),
              style: NalviumText.title.copyWith(
                color: NalviumColors.primaryText,
              ),
            ),
            const SizedBox(height: Space.x6),
            SecondaryButton(
              label: l.stContactCopy,
              icon: Icons.copy_rounded,
              onPressed: () async {
                await Clipboard.setData(
                  const ClipboardData(text: kContactEmail),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(l.stContactCopied)));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// « Gérer mes choix publicitaires » : n'ouvre le formulaire UMP que s'il est réellement requis.
class AdChoicesScreen extends ConsumerStatefulWidget {
  const AdChoicesScreen({super.key});
  @override
  ConsumerState<AdChoicesScreen> createState() => _AdChoicesScreenState();
}

class _AdChoicesScreenState extends ConsumerState<AdChoicesScreen> {
  late final Future<bool> _required = ref
      .read(adsServiceProvider)
      .privacyOptionsRequired();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: _bar(context, l.stAdsTitle),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Space.gutter),
          children: [
            Text(l.stAdsBody, style: NalviumText.bodyLarge),
            const SizedBox(height: Space.x6),
            FutureBuilder<bool>(
              future: _required,
              builder: (context, snap) {
                if (snap.data == true) {
                  return PrimaryButton(
                    key: const Key('ads-manage'),
                    label: l.stAdsManage,
                    onPressed: () =>
                        ref.read(adsServiceProvider).showPrivacyOptions(),
                  );
                }
                if (!snap.hasData) return const SizedBox.shrink();
                return Text(
                  l.stAdsNone,
                  key: const Key('ads-none'),
                  style: NalviumText.body.copyWith(
                    color: NalviumColors.textSecondary,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DataScreen extends StatelessWidget {
  const DataScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: _bar(context, l.stDataTitle),
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(Space.gutter),
              child: Text(l.stDataBody, style: NalviumText.bodyLarge),
            ),
            _Group([
              _Row(
                key: const Key('st-history'),
                icon: Icons.history_rounded,
                label: l.stHistory,
                onTap: () => context.push('/history'),
              ),
              _Row(
                key: const Key('st-requests'),
                icon: Icons.support_agent_rounded,
                label: l.stRequests,
                onTap: () => context.go('/repair'),
              ),
            ]),
            const SizedBox(height: Space.x6),
            _Group([
              _Row(
                key: const Key('st-delete'),
                icon: Icons.delete_outline_rounded,
                label: l.stDeleteData,
                destructive: true,
                onTap: () => context.push('/settings/data/delete'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

/// Suppression définitive : liste explicite de ce qui disparaît, case à cocher, puis action.
class DeleteDataScreen extends ConsumerStatefulWidget {
  const DeleteDataScreen({super.key});
  @override
  ConsumerState<DeleteDataScreen> createState() => _DeleteDataScreenState();
}

class _DeleteDataScreenState extends ConsumerState<DeleteDataScreen> {
  bool _checked = false;
  bool _busy = false;
  bool _done = false;
  Object? _error;

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await deleteAllMyData(ref);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _done = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_done) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(l.stDelDoneTitle, style: NalviumText.titleLarge),
          toolbarHeight: 72,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Space.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.stDelDoneBody,
                  key: const Key('delete-done'),
                  style: NalviumText.bodyLarge,
                ),
                const Spacer(),
                PrimaryButton(
                  key: const Key('delete-home'),
                  label: l.stDelHome,
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final items = [
      l.stDelItem1,
      l.stDelItem2,
      l.stDelItem3,
      l.stDelItem4,
      l.stDelItem5,
      l.stDelItem6,
    ];
    return Scaffold(
      appBar: _bar(context, l.stDelTitle),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Space.gutter),
          children: [
            Text(l.stDelIntro, style: NalviumText.bodyLarge),
            const SizedBox(height: Space.x2),
            for (final i in items)
              Padding(
                padding: const EdgeInsets.only(top: Space.x1),
                child: Text('• $i', style: NalviumText.body),
              ),
            const SizedBox(height: Space.x4),
            Text(
              l.stDelStays,
              style: NalviumText.body.copyWith(
                color: NalviumColors.textSecondary,
              ),
            ),
            const SizedBox(height: Space.x2),
            Text(l.stDelAfter, style: NalviumText.body),
            const SizedBox(height: Space.x4),
            CheckboxListTile(
              key: const Key('delete-check'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _checked,
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _checked = v ?? false),
              title: Text(l.stDelCheck, style: NalviumText.body),
            ),
            if (_error != null) ...[
              const SizedBox(height: Space.x2),
              Text(
                l.stDelFail,
                key: const Key('delete-error'),
                style: NalviumText.body.copyWith(
                  color: NalviumColors.dangerText,
                ),
              ),
            ],
            const SizedBox(height: Space.x4),
            Semantics(
              label: _busy ? l.stDelWorking : null,
              child: DangerButton(
                key: const Key('delete-confirm'),
                label: l.stDelConfirm,
                onPressed: (_checked && !_busy) ? _delete : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
