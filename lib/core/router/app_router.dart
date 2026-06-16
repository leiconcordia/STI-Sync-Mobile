import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/features/auth/views/login_screen.dart';
import 'package:sti_sync/features/auth/views/registration/registration_flow_screen.dart';
import 'package:sti_sync/features/auth/views/splash_screen.dart';
import 'package:sti_sync/features/auth/views/welcome_screen.dart';
import 'package:sti_sync/shared/providers/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authViewModelProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      
      // Paths that don't require authentication
      final isAuthPath = state.matchedLocation == '/login' ||
                         state.matchedLocation == '/register' ||
                         state.matchedLocation == '/welcome';
      
      // If at splash screen, don't redirect yet; let splash handle navigation
      if (state.matchedLocation == '/') {
        return null;
      }

      if (isAuth) {
        // If authenticated and on an auth-related path, go to dashboard
        if (isAuthPath) return '/dashboard';
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
        name: 'dashboard',
        path: '/dashboard',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Dashboard (Coming Soon)')),
        ),
      ),
    ],
  );
});
