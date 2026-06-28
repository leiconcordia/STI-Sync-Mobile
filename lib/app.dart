import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/providers.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class StiSyncApp extends ConsumerWidget {
  const StiSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    ref.listen<AsyncValue<bool>>(connectivityStatusProvider, (previous, next) {
      if (previous != null && next.hasValue && previous.value != next.value) {
        final isOnline = next.value!;
        
        final contextForSize = scaffoldMessengerKey.currentContext;
        final screenHeight = contextForSize != null ? MediaQuery.of(contextForSize).size.height : 800.0;

        scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isOnline ? Icons.wifi : Icons.wifi_off,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isOnline ? 'Back online' : 'You are offline. Some features may be unavailable.',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: isOnline ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: screenHeight - 120, // Push to top
              left: 20,
              right: 20,
            ),
            dismissDirection: DismissDirection.up,
          ),
        );
      }
    });

    return MaterialApp.router(
      title: 'STI Sync',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
    );
  }
}
