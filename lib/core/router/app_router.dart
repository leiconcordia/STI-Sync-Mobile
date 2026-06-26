import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/features/auth/views/login_screen.dart';
import 'package:sti_sync/features/auth/views/pending_status_screen.dart';
import 'package:sti_sync/features/auth/views/registration/registration_flow_screen.dart';
import 'package:sti_sync/features/auth/views/splash_screen.dart';
import 'package:sti_sync/features/auth/views/welcome_screen.dart';
import 'package:sti_sync/features/dashboard/views/main_shell_screen.dart';
import 'package:sti_sync/features/dashboard/views/dashboard_screen.dart';
import 'package:sti_sync/features/events/views/events_screen.dart';
import 'package:sti_sync/features/events/views/event_detail_screen.dart';
import 'package:sti_sync/features/payables/views/payables_screen.dart';
import 'package:sti_sync/features/profile/views/profile_screen.dart';
import 'package:sti_sync/shared/providers/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authViewModelProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final isPending = authState.pendingStudent != null;
      
      // Paths that don't require authentication
      final isAuthPath = state.matchedLocation == '/login' ||
                         state.matchedLocation == '/register' ||
                         state.matchedLocation == '/welcome';
      
      // If at splash screen, don't redirect yet; let splash handle navigation
      if (state.matchedLocation == '/') {
        return null;
      }

      if (isAuth) {
        if (isPending) {
           if (state.matchedLocation != '/pending-status' && state.matchedLocation != '/register') {
              // Allow them to go to register if they hit "Register Again"
              return '/pending-status';
           }
        } else {
           // Fully authenticated, ACTIVE student
           if (isAuthPath || state.matchedLocation == '/pending-status') {
             return '/dashboard';
           }
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
        name: 'register',
        path: '/register',
        builder: (context, state) => const RegistrationFlowScreen(),
      ),
      GoRoute(
        name: 'pendingStatus',
        path: '/pending-status',
        builder: (context, state) => const PendingStatusScreen(),
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
                routes: [
                  GoRoute(
                    name: 'eventDetail',
                    path: ':eventId',
                    builder: (context, state) => EventDetailScreen(
                      eventId: state.pathParameters['eventId']!,
                    ),
                  ),
                ],
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
