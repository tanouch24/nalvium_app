import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/capture/analysis_screen.dart';
import '../../features/capture/photo_preview_screen.dart';
import '../../features/describe/describe_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/session/session_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/empty_screen.dart';

GoRouter buildRouter({String initialLocation = '/home'}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/house',
                builder: (context, _) {
                  final l = AppLocalizations.of(context);
                  return EmptyScreen(title: l.houseTitle, icon: Icons.house_outlined, emptyTitle: l.houseEmptyTitle, emptyBody: l.houseEmptyBody);
                },
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/repair',
                builder: (context, _) {
                  final l = AppLocalizations.of(context);
                  return EmptyScreen(title: l.repairTitle, icon: Icons.build_circle_outlined, emptyTitle: l.repairEmptyTitle, emptyBody: l.repairEmptyBody);
                },
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/community',
                builder: (context, _) {
                  final l = AppLocalizations.of(context);
                  return EmptyScreen(title: l.communityTitle, icon: Icons.groups_outlined, emptyTitle: l.communityEmptyTitle, emptyBody: l.communityEmptyBody);
                },
              ),
            ]),
          ],
        ),
        GoRoute(
          path: '/capture/preview',
          builder: (_, state) => PhotoPreviewScreen(photoPath: state.extra! as String),
        ),
        GoRoute(path: '/describe', builder: (_, _) => const DescribeScreen()),
        GoRoute(path: '/analyze', builder: (_, state) => AnalysisScreen(start: state.extra! as SessionStart)),
        GoRoute(path: '/session/:id', builder: (_, state) => SessionScreen(sessionId: state.pathParameters['id']!)),
        GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
        GoRoute(
          path: '/settings',
          builder: (context, _) {
            final l = AppLocalizations.of(context);
            return EmptyScreen(title: l.settings, icon: Icons.settings_outlined, emptyTitle: l.settingsEmptyTitle, emptyBody: l.settingsEmptyBody, showBack: true);
          },
        ),
      ],
    );
