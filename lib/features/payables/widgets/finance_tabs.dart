import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/shared/providers/providers.dart';

class FinanceTabs extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const FinanceTabs({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payablesAsync = ref.watch(payablesStreamProvider);

    int pendingDuesCount = 0;
    int pendingFinesCount = 0;

    payablesAsync.whenData((list) {
      for (final p in list) {
        if (p.isPending) {
          if (p.type == 'org_fine' || p.type == 'admin_fine') {
            pendingFinesCount++;
          } else {
            pendingDuesCount++;
          }
        }
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTab(0, 'Active Dues', pendingDuesCount),
          _buildTab(1, 'History', 0),
          _buildTab(2, 'Fines', pendingFinesCount, isDanger: pendingFinesCount > 0),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String title, int count, {bool isDanger = false}) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryDark : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected ? AppColors.secondary : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDanger ? Colors.red.shade400 : AppColors.secondary.withValues(alpha: 0.3))
                        : (isDanger ? AppColors.error : AppColors.primaryDark.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected
                          ? (isDanger ? Colors.white : AppColors.secondary)
                          : (isDanger ? Colors.white : AppColors.primaryDark),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

