import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/capture/analysis_screen.dart';
import '../../features/capture/photo_preview_screen.dart';
import '../../features/describe/describe_screen.dart';
import '../../features/help/help_done_screen.dart';
import '../../features/help/help_request_screen.dart';
import '../../features/help/repair_screen.dart';
import '../../features/help/request_detail_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/house/add_equipment_screen.dart';
import '../../features/house/edit_equipment_screen.dart';
import '../../features/house/equipment_detail_screen.dart';
import '../../features/house/house_screen.dart';
import '../../features/house/identify_equipment_screen.dart';
import '../../features/house/link_equipment_screen.dart';
import '../../features/house/manual_viewer_screen.dart';
import '../../domain/equipment.dart';
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
            GoRoute(path: '/house', builder: (_, _) => const HouseScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/repair', builder: (_, _) => const RepairScreen()),
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
        PhotoPreviewScreen(
          photoPath: state.extra! as String,
          equipmentId: state.uri.queryParameters['equipment'],
        ),
      ),
    ),
    GoRoute(
      path: '/video/capture',
      pageBuilder: (_, state) => nalviumPage(
        state,
        VideoCaptureScreen(equipmentId: state.uri.queryParameters['equipment']),
      ),
    ),
    GoRoute(
      path: '/video/preview',
      pageBuilder: (_, state) => nalviumPage(
        state,
        VideoPreviewScreen(
          clip: state.extra! as VideoClip,
          equipmentId: state.uri.queryParameters['equipment'],
        ),
      ),
    ),
    GoRoute(
      path: '/describe',
      pageBuilder: (_, state) => nalviumPage(
        state,
        DescribeScreen(equipmentId: state.uri.queryParameters['equipment']),
      ),
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
          path: 'house',
          pageBuilder: (_, state) => nalviumPage(
            state,
            LinkEquipmentScreen(sessionId: state.pathParameters['id']!),
          ),
        ),
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
      path: '/equipment/add',
      pageBuilder: (_, state) => nalviumPage(
        state,
        AddEquipmentScreen(
          args: state.extra is AddEquipmentArgs ? state.extra! as AddEquipmentArgs : const AddEquipmentArgs(),
        ),
      ),
    ),
    GoRoute(
      path: '/equipment/identify',
      pageBuilder: (_, state) => nalviumPage(state, const IdentifyEquipmentScreen()),
    ),
    GoRoute(
      path: '/equipment/:id',
      pageBuilder: (_, state) => nalviumPage(
        state,
        EquipmentDetailScreen(equipmentId: state.pathParameters['id']!),
      ),
      routes: [
        GoRoute(
          path: 'manual',
          pageBuilder: (_, state) => nalviumPage(
            state,
            ManualViewerScreen(
              equipmentId: state.pathParameters['id']!,
              initialPage: int.tryParse(state.uri.queryParameters['page'] ?? '') ?? 1,
            ),
          ),
        ),
        GoRoute(
          path: 'edit',
          pageBuilder: (_, state) => nalviumPage(state, EditEquipmentScreen(equipment: state.extra! as EquipmentSummary)),
        ),
      ],
    ),
    GoRoute(
      path: '/help/new',
      pageBuilder: (_, state) => nalviumPage(
        state,
        HelpRequestScreen(sessionId: state.uri.queryParameters['session']),
      ),
    ),
    GoRoute(
      path: '/help/:id/done',
      pageBuilder: (_, state) => nalviumPage(state, HelpDoneScreen(requestId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/requests/:id',
      pageBuilder: (_, state) => nalviumPage(state, RequestDetailScreen(requestId: state.pathParameters['id']!)),
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
