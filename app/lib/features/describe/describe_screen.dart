import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/buttons.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import '../capture/analysis_screen.dart';

class DescribeScreen extends ConsumerStatefulWidget {
  const DescribeScreen({super.key});

  @override
  ConsumerState<DescribeScreen> createState() => _DescribeScreenState();
}

class _DescribeScreenState extends ConsumerState<DescribeScreen> {
  bool _starting = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Nouveau diagnostic : interstitiel éventuel (à partir du n°2), puis l'analyse démarre.
  Future<void> _continue() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _starting) return;
    setState(() => _starting = true);
    await ref.read(adsServiceProvider).beforeNewDiagnostic();
    if (!mounted) return;
    context.pushReplacement('/analyze', extra: DescriptionStart(text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.close,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            Space.x2,
            Space.gutter,
            Space.x6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.describeTitle, style: NalviumText.display),
              const SizedBox(height: Space.x6),
              TextField(
                key: const Key('describe-field'),
                controller: _controller,
                autofocus: true,
                minLines: 4,
                maxLines: 8,
                maxLength: 2000,
                style: NalviumText.bodyLarge.copyWith(
                  fontWeight: FontWeight.w400,
                ),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: l10n.describeHint),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Space.x4),
              PrimaryButton(
                key: const Key('describe-continue'),
                label: l10n.continueLabel,
                loading: _starting,
                onPressed: _controller.text.trim().isEmpty ? null : _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
