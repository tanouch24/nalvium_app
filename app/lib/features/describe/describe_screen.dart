import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../capture/analysis_screen.dart';

class DescribeScreen extends StatefulWidget {
  const DescribeScreen({super.key});

  @override
  State<DescribeScreen> createState() => _DescribeScreenState();
}

class _DescribeScreenState extends State<DescribeScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.pushReplacement('/analyze', extra: DescriptionStart(text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close_rounded), tooltip: l10n.close, onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(NalviumSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.describeTitle, style: theme.textTheme.headlineLarge),
              const SizedBox(height: NalviumSpacing.lg),
              TextField(
                key: const Key('describe-field'),
                controller: _controller,
                autofocus: true,
                minLines: 4,
                maxLines: 8,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: l10n.describeHint),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: NalviumSpacing.md),
              FilledButton(
                key: const Key('describe-continue'),
                onPressed: _controller.text.trim().isEmpty ? null : _continue,
                child: Text(l10n.continueLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
