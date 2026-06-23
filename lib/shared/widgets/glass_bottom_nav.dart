import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:sti_sync/core/theme/app_colors.dart';

enum NavTab { home, events, scanner, finance, profile }

class NavItem {
  final NavTab tab;
  final IconData icon;
  final String label;

  const NavItem({
    required this.tab,
    required this.icon,
    required this.label,
  });
}

class GlassBottomNav extends StatelessWidget {
  final NavTab selectedTab;
  final Function(NavTab) onTabSelected;
  final bool isScanner;

  const GlassBottomNav({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    this.isScanner = false,
  });

  List<NavItem> get _items {
    final items = [
      const NavItem(tab: NavTab.home, icon: Icons.home_outlined, label: 'Home'),
      const NavItem(tab: NavTab.events, icon: Icons.calendar_month_outlined, label: 'Events'),
    ];

    if (isScanner) {
      items.add(const NavItem(tab: NavTab.scanner, icon: Icons.qr_code_scanner, label: 'My QR'));
    }

    items.addAll([
      const NavItem(tab: NavTab.finance, icon: Icons.account_balance_wallet_outlined, label: 'Finance'),
      const NavItem(tab: NavTab.profile, icon: Icons.person_outline, label: 'Profile'),
    ]);

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Assuming some margin around the nav bar
    final navWidth = screenWidth - 32;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, left: 16.0, right: 16.0),
      child: GlassmorphicContainer(
        width: navWidth,
        height: 72,
        borderRadius: 36,
        blur: 15,
        alignment: Alignment.center,
        border: 1.5,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.8),
            Colors.white.withValues(alpha: 0.5),
          ],
          stops: const [0.1, 1],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.4),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _items.map((item) {
              final isActive = selectedTab == item.tab;
              final isQrTab = item.tab == NavTab.scanner;

              // active colors based on requirements
              final activeFillColor = isQrTab ? AppColors.secondary : AppColors.primaryDark;
              final activeTextColor = isQrTab ? AppColors.primaryDark : AppColors.secondary;

              // inactive colors
              final inactiveColor = AppColors.primaryDark.withValues(alpha: 0.45);

              return GestureDetector(
                onTap: () => onTabSelected(item.tab),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: isActive
                      ? const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                      : const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: isActive ? activeFillColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: isActive ? activeTextColor : inactiveColor,
                        size: 24,
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: activeTextColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
