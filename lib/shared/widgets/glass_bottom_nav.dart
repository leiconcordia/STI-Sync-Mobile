import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:sti_sync/core/theme/app_colors.dart';

enum NavTab { home, events, scanner, finance, profile }

class NavItem {
  final NavTab tab;
  final IconData icon;
  final String label;
  final bool hasDot;

  const NavItem({
    required this.tab,
    required this.icon,
    required this.label,
    this.hasDot = false,
  });
}

/// Floating glassmorphic bottom navigation bar.
///
/// When [showScannerTab] is false (default), the Scanner tab is hidden and
/// only 4 items are rendered — preventing horizontal overflow when the active
/// item expands to show its label.
///
/// When [showScannerTab] is true, all 5 tabs are rendered. The scanner tab
/// shows a golden dot indicator to signal an active assignment.
class GlassBottomNav extends StatelessWidget {
  final NavTab selectedTab;
  final Function(NavTab) onTabSelected;

  /// Whether to include the Scanner tab (only true when officer has active assignment).
  final bool showScannerTab;

  /// Whether the scanner assignment indicator dot should be shown.
  final bool hasActiveScannerAssignment;

  const GlassBottomNav({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    this.showScannerTab = false,
    this.hasActiveScannerAssignment = false,
  });

  List<NavItem> get _items {
    const allItems = [
      NavItem(tab: NavTab.home, icon: Icons.home_outlined, label: 'Home'),
      NavItem(tab: NavTab.events, icon: Icons.calendar_month_outlined, label: 'Events'),
      NavItem(tab: NavTab.scanner, icon: Icons.qr_code_scanner, label: 'Scanner'),
      NavItem(tab: NavTab.finance, icon: Icons.account_balance_wallet_outlined, label: 'Finance'),
      NavItem(tab: NavTab.profile, icon: Icons.person_outline, label: 'Profile'),
    ];

    if (!showScannerTab) {
      return allItems
          .where((item) => item.tab != NavTab.scanner)
          .toList();
    }

    // When scanner is visible, add the dot indicator
    return allItems.map((item) {
      if (item.tab == NavTab.scanner) {
        return NavItem(
          tab: item.tab,
          icon: item.icon,
          label: item.label,
          hasDot: hasActiveScannerAssignment,
        );
      }
      return item;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final navWidth = screenWidth - 32;
    final items = _items;
    final itemCount = items.length;

    // Tighter active padding when 5 tabs are showing so they all fit
    final activePaddingH = itemCount >= 5 ? 14.0 : 20.0;

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
            children: items.map((item) {
              final isActive = selectedTab == item.tab;
              final isQrTab = item.tab == NavTab.scanner;

              final activeFillColor = isQrTab
                  ? const Color(0xFFFFCC00) // golden yellow for scanner
                  : AppColors.primaryDark;
              final activeTextColor = isQrTab
                  ? AppColors.primaryDark
                  : AppColors.secondary;

              final inactiveColor =
                  AppColors.primaryDark.withValues(alpha: 0.45);

              return GestureDetector(
                onTap: () => onTabSelected(item.tab),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: isActive
                      ? EdgeInsets.symmetric(
                          horizontal: activePaddingH, vertical: 12)
                      : const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: isActive ? activeFillColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            color: isActive ? activeTextColor : inactiveColor,
                            size: 24,
                          ),
                          // Show label only for non-scanner active tabs,
                          // and only when there's room (4-item layout)
                          if (isActive && !isQrTab && itemCount < 5) ...[
                            const SizedBox(width: 8),
                            Text(
                              item.label,
                              style: TextStyle(
                                color: activeTextColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Active assignment dot indicator on scanner tab
                      if (item.hasDot && !isActive)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFCC00),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
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
