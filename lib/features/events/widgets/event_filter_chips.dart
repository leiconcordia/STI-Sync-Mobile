import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/shared/providers/providers.dart';

class EventFilterChips extends ConsumerWidget {
  const EventFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(eventFilterCategoryProvider);

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildChip(
            context: context,
            ref: ref,
            label: 'All Events',
            category: EventFilterCategory.all,
            isSelected: selectedFilter == EventFilterCategory.all,
            icon: Icons.grid_view_rounded,
          ),
          const SizedBox(width: 8),
          _buildChip(
            context: context,
            ref: ref,
            label: 'School / SAO',
            category: EventFilterCategory.schoolSao,
            isSelected: selectedFilter == EventFilterCategory.schoolSao,
            icon: Icons.school_rounded,
          ),
          const SizedBox(width: 8),
          _buildChip(
            context: context,
            ref: ref,
            label: 'Club Events',
            category: EventFilterCategory.clubs,
            isSelected: selectedFilter == EventFilterCategory.clubs,
            icon: Icons.groups_rounded,
          ),
          const SizedBox(width: 8),
          _buildChip(
            context: context,
            ref: ref,
            label: 'My Orgs',
            category: EventFilterCategory.myOrgs,
            isSelected: selectedFilter == EventFilterCategory.myOrgs,
            icon: Icons.star_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required EventFilterCategory category,
    required bool isSelected,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        ref.read(eventFilterCategoryProvider.notifier).state = category;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryDark : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryDark.withOpacity(0.18),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.secondary : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
