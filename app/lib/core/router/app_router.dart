import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/capture/analysis_screen.dart';
import '../../features/capture/photo_preview_screen.dart';
import '../../features/describe/describe_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/session/session_screen.dart';
import '../../features/video/video_capture_screen.dart';
import '../../features/video/video_preview_screen.dart';
import '../../domain/video.dart';
import '../../features/session/session_summary_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/empty_screen.dart';
import '../widgets/page_transitions.dart';

GoRouter buildRouter({
  String initialLocation = '/home',
  Object? initialExtra,
}) => GoRouter(
  initialLocation: initialLocation,
  initialExtra: initialExtra,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/house',
              builder: (context, _) {
                final l = AppLocalizations.of(context);
                return EmptyScreen(
                  title: l.houseTitle,
                  icon: Icons.house_outlined,
                  emptyTitle: l.houseEmptyTitle,
                  emptyBody: l.houseEmptyBody,
                );
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/repair',
              builder: (context, _) {
                final l = AppLocalizations.of(context);
                return EmptyScreen(
                  title: l.repairTitle,
                  icon: Icons.build_circle_outlined,
                  emptyTitle: l.repairEmptyTitle,
                  emptyBody: l.repairEmptyBody,
                );
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/community',
              builder: (context, _) {
                final l = AppLocalizations.of(context);
                return EmptyScreen(
                  title: l.communityTitle,
                  icon: Icons.groups_outlined,
                  emptyTitle: l.communityEmptyTitle,
                  emptyBody: l.communityEmptyBody,
                );
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/capture/preview',
      pageBuilder: (_, state) => nalviumPage(
        state,
        PhotoPreviewScreen(photoPath: state.extra! as String),
      ),
    ),
    GoRoute(
      path: '/video/capture',
      pageBuilder: (_, state) => nalviumPage(state, const VideoCaptureScreen()),
    ),
    GoRoute(
      path: '/video/preview',
      pageBuilder: (_, state) => nalviumPage(
        state,
        VideoPreviewScreen(clip: state.extra! as VideoClip),
      ),
    ),
    GoRoute(
      path: '/describe',
      pageBuilder: (_, state) => nalviumPage(state, const DescribeScreen()),
    ),
    GoRoute(
      path: '/analyze',
      pageBuilder: (_, state) => nalviumPage(
        state,
        AnalysisScreen(start: state.extra! as SessionStart),
      ),
    ),
    GoRoute(
      path: '/session/:id',
      pageBuilder: (_, state) => nalviumPage(
        state,
        SessionScreen(sessionId: state.pathParameters['id']!),
      ),
      routes: [
        GoRoute(
          path: 'summary',
          pageBuilder: (_, state) => nalviumPage(
            state,
            SessionSummaryScreen(sessionId: state.pathParameters['id']!),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/history',
      pageBuilder: (_, state) => nalviumPage(state, const HistoryScreen()),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) {
        final l = AppLocalizations.of(context);
        return nalviumPage(
          state,
          EmptyScreen(
            title: l.settings,
            icon: Icons.settings_outlined,
            emptyTitle: l.settingsEmptyTitle,
            emptyBody: l.settingsEmptyBody,
            showBack: true,
          ),
        );
      },
    ),
  ],
);
