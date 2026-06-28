import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sti_sync/shared/widgets/glass_bottom_nav.dart';
import 'package:sti_sync/core/theme/app_colors.dart';

class MainShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  NavTab _getNavTabFromIndex(int index) {
    switch (index) {
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

  void _onTabSelected(NavTab tab) {
    int index;
    switch (tab) {
      case NavTab.home:
        index = 0;
        break;
      case NavTab.events:
        index = 1;
        break;
      case NavTab.scanner:
        index = 2;
        break;
      case NavTab.finance:
        index = 3;
        break;
      case NavTab.profile:
        index = 4;
        break;
    }
    
    // Navigate to the correct branch
    navigationShell.goBranch(
      index,
      // A common pattern when using bottom navigation bars is to support
      // navigating to the initial location when tapping the item that is
      // already active.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // The current active screen from the shell
          navigationShell,
          
          // The glass bottom nav pinned to the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassBottomNav(
              selectedTab: _getNavTabFromIndex(navigationShell.currentIndex),
              onTabSelected: _onTabSelected,
            ),
          ),
        ],
      ),
    );
  }
}
