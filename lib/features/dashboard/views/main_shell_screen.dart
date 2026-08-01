import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/shared/widgets/glass_bottom_nav.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/shared/providers/providers.dart';

/// The root shell for all authenticated screens.
///
/// Renders the [GlassBottomNav] over the active branch of the
/// [StatefulNavigationShell]. When the current user has no active scanner
/// assignments the Scanner tab (branch index 2) is hidden and visual tab
/// indices are remapped so Finance and Profile still navigate to their
/// correct branches.
///
/// Branch index layout (fixed in app_router.dart):
///   0 → dashboard
///   1 → events
///   2 → scanner   ← may be hidden
///   3 → payables
///   4 → profile
class MainShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  // ─── Index mapping ─────────────────────────────────────────────────────

  /// Converts the current branch index to the visible [NavTab].
  NavTab _branchToTab(int branchIndex) {
    switch (branchIndex) {
      case 0:
        return NavTab.home;
      case 1:
        return NavTab.events;
      case 2:
        return NavTab.scanner;
      case 3:
        return NavTab.finance;
      case 4:
        return NavTab.profile;
      default:
        return NavTab.home;
    }
  }

  /// Converts a tapped [NavTab] to the correct branch index.
  int _tabToBranch(NavTab tab) {
    switch (tab) {
      case NavTab.home:
        return 0;
      case NavTab.events:
        return 1;
      case NavTab.scanner:
        return 2;
      case NavTab.finance:
        return 3;
      case NavTab.profile:
        return 4;
    }
  }

  void _onTabSelected(NavTab tab) {
    final branchIndex = _tabToBranch(tab);
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read live scanner state to decide whether to show the scanner tab
    final scannerState = ref.watch(scannerViewModelProvider);
    final showScanner = scannerState.hasActiveAssignments;

    final selectedTab = _branchToTab(navigationShell.currentIndex);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Active screen from the navigation shell with bottom inset padding
          // so content on all tabs never overlaps with the floating glass nav bar
          Padding(
            padding: const EdgeInsets.only(bottom: 60.0),
            child: navigationShell,
          ),


          // Floating glass nav bar pinned to the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassBottomNav(
              selectedTab: selectedTab,
              onTabSelected: _onTabSelected,
              showScannerTab: showScanner,
              hasActiveScannerAssignment: showScanner,
            ),
          ),
        ],
      ),
    );

  }
}
