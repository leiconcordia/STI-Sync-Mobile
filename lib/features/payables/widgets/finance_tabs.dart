import 'package:flutter/material.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';

class FinanceTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const FinanceTabs({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          _buildTab(0, 'Dues'),
          Container(width: 1, height: 24, color: Colors.grey.shade300),
          _buildTab(1, 'History'),
          Container(width: 1, height: 24, color: Colors.grey.shade300),
          _buildTab(2, 'Fines'),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String title) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryDark : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: AppTextStyles.labelSmall.copyWith(
              color: isSelected ? AppColors.secondary : Colors.grey.shade500,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
