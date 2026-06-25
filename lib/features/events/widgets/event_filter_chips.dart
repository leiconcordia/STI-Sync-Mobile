import 'package:flutter/material.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';

class EventFilterChips extends StatelessWidget {
  const EventFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildChip('All', true),
          const SizedBox(width: 8),
          _buildChip('Registered', false),
          const SizedBox(width: 8),
          _buildChip('Open', false),
          const SizedBox(width: 8),
          _buildChip('My Orgs', false),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primaryDark : Colors.grey.shade300,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: isSelected ? AppColors.secondary : Colors.grey.shade500,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
