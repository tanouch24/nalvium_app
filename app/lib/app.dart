import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/nalvium_theme.dart';
import 'l10n/app_localizations.dart';

class NalviumApp extends StatefulWidget {
  const NalviumApp({super.key, this.router});
  final GoRouter? router;

  @override
  State<NalviumApp> createState() => _NalviumAppState();
}

class _NalviumAppState extends State<NalviumApp> {
  late final GoRouter _router = widget.router ?? buildRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Nalvium',
      debugShowCheckedModeBanner: false,
      theme: buildNalviumTheme(),
      routerConfig: _router,
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
