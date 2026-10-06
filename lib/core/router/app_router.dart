import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/features/auth/views/login_screen.dart';
import 'package:sti_sync/features/auth/views/reenrollment_expired_screen.dart';
import 'package:sti_sync/features/auth/views/profile_completion/profile_completion_flow_screen.dart';
import 'package:sti_sync/features/auth/views/splash_screen.dart';
import 'package:sti_sync/features/auth/views/welcome_screen.dart';
import 'package:sti_sync/features/dashboard/views/main_shell_screen.dart';
import 'package:sti_sync/features/dashboard/views/dashboard_screen.dart';
import 'package:sti_sync/features/events/views/events_screen.dart';
import 'package:sti_sync/features/events/views/event_detail_screen.dart';
import 'package:sti_sync/features/qr_ticket/views/qr_ticket_screen.dart';
import 'package:sti_sync/features/scanner/views/scanner_download_screen.dart';
import 'package:sti_sync/features/scanner/views/scanner_mode_screen.dart';
import 'package:sti_sync/features/scanner/views/scanner_camera_screen.dart';
import 'package:sti_sync/features/scanner/views/manual_attendance_screen.dart';
import 'package:sti_sync/features/scanner/views/scanner_logs_screen.dart';
import 'package:sti_sync/features/scanner/views/sync_conflicts_screen.dart';
import 'package:sti_sync/features/payables/views/payables_screen.dart';
import 'package:sti_sync/features/profile/views/profile_screen.dart';
import 'package:sti_sync/features/certificates/views/certificates_screen.dart';
import 'package:sti_sync/features/certificates/views/certificate_detail_screen.dart';
import 'package:sti_sync/features/certificates/models/issued_certificate_model.dart';
import 'package:sti_sync/features/profile/views/student_attendance_history_screen.dart';
import 'package:sti_sync/shared/providers/providers.dart';
import 'package:sti_sync/features/sync/models/sync_status_model.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authViewModelProvider, (previous, next) {
      notifyListeners();
    });
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authViewModelProvider);
      final isAuth = authState.isAuthenticated;
      final currentStudent = authState.student;

      final isProfileIncomplete = currentStudent != null &&
          (!currentStudent.isProfileComplete || currentStudent.requiresPasswordChange);

      // Paths that don't require authentication
      final isAuthPath = state.matchedLocation == '/login' ||
                         state.matchedLocation == '/welcome';
      
      // If at splash screen:
      if (state.matchedLocation == '/') {
        if (isAuth) {
          return isProfileIncomplete ? '/complete-profile' : '/dashboard';
        }
        return null;
      }

      if (isAuth) {
        if (isProfileIncomplete) {
          if (state.matchedLocation != '/complete-profile') {
            return '/complete-profile';
          }
          return null;
        }

        // Fully authenticated, ACTIVE student with complete profile
        if (isAuthPath || state.matchedLocation == '/complete-profile') {
          return '/dashboard';
        }
      } else {
        // If not authenticated and not on an auth path, go to welcome
        if (!isAuthPath && state.matchedLocation != '/') {
          return '/welcome';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        name: 'splash',
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        name: 'welcome',
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: 'completeProfile',
        path: '/complete-profile',
        builder: (context, state) => const ProfileCompletionFlowScreen(),
      ),
      GoRoute(
        name: 'reenrollmentExpired',
        path: '/reenrollment-expired',
        builder: (context, state) => const ReEnrollmentExpiredScreen(),
      ),
      GoRoute(
        name: 'eventDetail',
        path: '/events/detail/:eventId',
        builder: (context, state) => EventDetailScreen(
          eventId: state.pathParameters['eventId']!,
        ),
      ),
      GoRoute(
        name: 'qrTicket',
        path: '/events/:eventId/ticket',
        builder: (context, state) => QrTicketScreen(
          eventId: state.pathParameters['eventId']!,
        ),
      ),
      GoRoute(
        name: 'certificates',
        path: '/certificates',
        builder: (context, state) => const CertificatesScreen(),
      ),
      GoRoute(
        name: 'certificateDetail',
        path: '/certificates/:certificateId',
        builder: (context, state) => CertificateDetailScreen(
          certificateId: state.pathParameters['certificateId']!,
          certificate: state.extra as IssuedCertificateModel?,
        ),
      ),
      GoRoute(
        name: 'attendanceHistory',
        path: '/attendance-history',
        builder: (context, state) => const StudentAttendanceHistoryScreen(),
      ),

      GoRoute(
        name: 'scannerMode',
        path: '/scanner/mode',
        builder: (context, state) => const ScannerModeScreen(),
      ),
      GoRoute(
        name: 'scannerCamera',
        path: '/scanner/camera/:eventId/:sessionId/:gateType',
        builder: (context, state) => ScannerCameraScreen(
          eventId: state.pathParameters['eventId']!,
          sessionId: state.pathParameters['sessionId']!,
          gateType: state.pathParameters['gateType']!,
        ),
      ),
      GoRoute(
        name: 'manualAttendance',
        path: '/scanner/:eventId/manual',
        builder: (context, state) => ManualAttendanceScreen(
          eventId: state.pathParameters['eventId']!,
        ),
      ),
      GoRoute(
        name: 'scannerLogs',
        path: '/scanner/:eventId/logs',
        builder: (context, state) => ScannerLogsScreen(
          eventId: state.pathParameters['eventId']!,
        ),
      ),
      GoRoute(
        name: 'syncConflicts',
        path: '/scanner/sync-conflicts',
        builder: (context, state) => SyncConflictsScreen(
          conflicts: state.extra as List<SyncConflict>? ?? [],
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'dashboard',
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'events',
                path: '/events',
                builder: (context, state) => const EventsScreen(),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'scanner',
                path: '/scanner',
                builder: (context, state) => const ScannerDownloadScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'payables',
                path: '/payables',
                builder: (context, state) => const PayablesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'profile',
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
