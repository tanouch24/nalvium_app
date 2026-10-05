import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/core/theme/nalvium_colors.dart';
import 'package:nalvium/core/theme/nalvium_theme.dart';
import 'package:nalvium/core/widgets/buttons.dart';
import 'package:nalvium/core/widgets/choice_tile.dart';
import 'package:nalvium/core/widgets/status_chip.dart';
import 'package:nalvium/domain/session.dart';
import 'package:nalvium/features/history/session_labels.dart';
import 'package:nalvium/l10n/app_localizations.dart';

Widget host(Widget child) => MaterialApp(
      theme: buildNalviumTheme(),
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: Center(child: child)),
    );

double _lum(Color c) => c.computeLuminance();
double contrast(Color a, Color b) {
  final l1 = _lum(a), l2 = _lum(b);
  final hi = l1 > l2 ? l1 : l2, lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('boutons : états', () {
    testWidgets('PrimaryButton : actif, appuyé, désactivé, chargement', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(PrimaryButton(label: 'Valider', onPressed: () => taps++, haptic: false)));
      expect(tester.getSize(find.byType(PrimaryButton)).height, greaterThanOrEqualTo(56)); // zone tactile
      await tester.tap(find.text('Valider'));
      expect(taps, 1);

      await tester.pumpWidget(host(const PrimaryButton(label: 'Valider', onPressed: null)));
      await tester.tap(find.text('Valider'));
      expect(taps, 1); // désactivé

      await tester.pumpWidget(host(PrimaryButton(label: 'Valider', onPressed: () => taps++, loading: true)));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Valider'), findsNothing);
      await tester.tap(find.byType(PrimaryButton));
      expect(taps, 1); // pas de double envoi pendant le chargement
    });

    testWidgets('Secondary / Tertiary / Danger / ChoiceTile : libellé + tap + sémantique', (tester) async {
      final log = <String>[];
      await tester.pumpWidget(host(Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SecondaryButton(label: 'Reprendre', onPressed: () => log.add('s')),
          TertiaryButton(label: 'Plus tard', onPressed: () => log.add('t')),
          DangerButton(label: 'Compris', onPressed: () => log.add('d')),
          ChoiceTile(label: 'Oui', onTap: () => log.add('c')),
        ],
      )));
      for (final t in ['Reprendre', 'Plus tard', 'Compris', 'Oui']) {
        await tester.tap(find.text(t));
      }
      expect(log, ['s', 't', 'd', 'c']);
      final handle = tester.ensureSemantics();
      for (final t in ['Reprendre', 'Plus tard', 'Compris', 'Oui']) {
        final data = tester.getSemantics(find.text(t).first).getSemanticsData();
        expect(data.label, t, reason: t);
        expect(data.hasAction(SemanticsAction.tap), isTrue, reason: '$t doit être activable par un lecteur d\'écran');
      }
      handle.dispose();
    });

    testWidgets('statut = icône + texte (jamais la couleur seule)', (tester) async {
      await tester.pumpWidget(host(const StatusChip(label: 'Arrêt de sécurité', tone: StatusTone.danger)));
      expect(find.text('Arrêt de sécurité'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });
  });

  group('contrastes (WCAG AA 4.5:1 pour le texte)', () {
    test('texte principal / secondaire sur fonds clairs', () {
      for (final bg in [NalviumColors.background, NalviumColors.surface, NalviumColors.surfaceSubtle]) {
        expect(contrast(NalviumColors.textPrimary, bg), greaterThan(7));
        expect(contrast(NalviumColors.textSecondary, bg), greaterThan(4.5));
      }
    });
    test('texte blanc sur bleu Nalvium et sur rouge sécurité', () {
      expect(contrast(Colors.white, NalviumColors.primary), greaterThanOrEqualTo(4.5));
      expect(contrast(Colors.white, NalviumColors.primaryPressed), greaterThanOrEqualTo(4.5));
      expect(contrast(Colors.white, NalviumColors.danger), greaterThanOrEqualTo(4.5));
    });
    test('couleurs de statut sur leur fond doux', () {
      expect(contrast(NalviumColors.primaryText, NalviumColors.primarySoft), greaterThanOrEqualTo(4.5));
      expect(contrast(NalviumColors.primaryText, NalviumColors.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(NalviumColors.success, NalviumColors.successSoft), greaterThanOrEqualTo(4.5));
      expect(contrast(NalviumColors.dangerText, NalviumColors.dangerSoft), greaterThanOrEqualTo(4.5));
      expect(contrast(NalviumColors.dangerText, NalviumColors.dangerBackground), greaterThanOrEqualTo(4.5));
      expect(contrast(NalviumColors.warning, NalviumColors.surface), greaterThanOrEqualTo(4.5));
    });
    test('texte discret (légendes, dates) lisible sur blanc et sur fond clair', () {
      expect(contrast(NalviumColors.textMuted, NalviumColors.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(NalviumColors.textMuted, NalviumColors.background), greaterThanOrEqualTo(4.5));
    });
  });

  group('libellés et dates relatives', () {
    late AppLocalizations l10n;
    setUp(() async => l10n = await AppLocalizations.delegate.load(const Locale('fr')));

    test('relativeDate', () {
      final now = DateTime(2026, 10, 5, 18, 0);
      expect(relativeDate(l10n, DateTime(2026, 10, 5, 9, 5), now: now), 'Aujourd\'hui, 09:05');
      expect(relativeDate(l10n, DateTime(2026, 10, 4, 23, 0), now: now), 'Hier');
      expect(relativeDate(l10n, DateTime(2026, 9, 12), now: now), '12 sept.');
      expect(relativeDate(l10n, DateTime(2025, 3, 12), now: now), '12 mars 2025');
    });

    test('catégories et statuts', () {
      expect(categoryLabel(l10n, 'plumbing'), 'Plomberie');
      expect(categoryLabel(l10n, 'electrical'), 'Électricité');
      expect(categoryLabel(l10n, null), '');
      expect(categoryLabel(l10n, 'other'), '');
      expect(sessionTone('resolved'), StatusTone.success);
      expect(sessionTone('stopped'), StatusTone.danger);
      final s = SessionSummary(id: 'x', status: 'referred', currentState: 'RECOMMEND_PROFESSIONAL', updatedAt: DateTime.now());
      expect(sessionStatusLabel(l10n, s), 'Professionnel recommandé');
    });
  });
}
