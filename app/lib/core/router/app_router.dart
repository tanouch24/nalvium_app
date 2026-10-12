import 'package:go_router/go_router.dart';

import '../../features/capture/analysis_screen.dart';
import '../../features/capture/photo_preview_screen.dart';
import '../../features/describe/describe_screen.dart';
import '../../features/help/help_done_screen.dart';
import '../../features/help/help_request_screen.dart';
import '../../features/help/out_of_zone_screen.dart';
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
import '../../features/settings/settings_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/emergency/emergency_screen.dart';
import '../../features/onboarding/consent_view.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../widgets/page_transitions.dart';

/// Chemins qui envoient des données à l'IA : un accord est exigé avant d'y entrer.
const _aiPaths = ['/capture', '/video', '/describe', '/analyze'];

/// Garde de l'app : démarrage non terminé → `/welcome` (les textes légaux restent lisibles) ;
/// pas d'accord IA → `/consent` avant tout nouveau diagnostic.
String? appGuard({required bool onboarded, required bool aiConsent, required String location}) {
  if (!onboarded) {
    return location.startsWith('/welcome') || location.startsWith('/settings/legal') ? null : '/welcome';
  }
  if (!aiConsent && _aiPaths.any(location.startsWith)) return '/consent';
  return null;
}

GoRouter buildRouter({
  String initialLocation = '/home',
  Object? initialExtra,
  GoRouterRedirect? redirect,
}) => GoRouter(
  initialLocation: initialLocation,
  initialExtra: initialExtra,
  redirect: redirect,
  routes: [
    GoRoute(path: '/welcome', builder: (_, _) => const OnboardingScreen()),
    // Carnet maison à compléter après un premier diagnostic lancé dès le démarrage.
    GoRoute(
      path: '/profile-setup',
      pageBuilder: (_, state) => nalviumPage(state, const OnboardingScreen(profileOnly: true)),
    ),
    GoRoute(
      path: '/emergency',
      pageBuilder: (_, state) => nalviumPage(state, const EmergencyScreen()),
    ),
    GoRoute(
      path: '/consent',
      pageBuilder: (_, state) => nalviumPage(state, const ConsentScreen()),
    ),
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
            GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
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
      path: '/help/out-of-zone',
      pageBuilder: (_, state) => nalviumPage(state, OutOfZoneScreen(args: state.extra! as OutOfZoneArgs)),
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
      path: '/repair',
      pageBuilder: (_, state) => nalviumPage(state, const RepairScreen()),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (_, state) => nalviumPage(state, const SettingsScreen()),
    ),
    GoRoute(
      path: '/settings/data',
      pageBuilder: (_, state) => nalviumPage(state, const DataScreen()),
    ),
    GoRoute(
      path: '/settings/data/delete',
      pageBuilder: (_, state) => nalviumPage(state, const DeleteDataScreen()),
    ),
    GoRoute(
      path: '/settings/contact',
      pageBuilder: (_, state) => nalviumPage(state, const ContactScreen()),
    ),
    GoRoute(
      path: '/settings/legal/:id',
      pageBuilder: (_, state) => nalviumPage(
        state,
        LegalScreen(documentId: state.pathParameters['id']!),
      ),
    ),
  ],
);
