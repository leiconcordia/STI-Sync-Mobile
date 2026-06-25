import 'package:flutter/material.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';

class MyOrganizationsSection extends StatelessWidget {
  const MyOrganizationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Organizations',
          style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 72,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildOrgCard('SG', 'Student Gov\'t', 'Rep'),
              const SizedBox(width: 16),
              _buildOrgCard('LA', 'Lit-Arts Club', 'Member'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrgCard(String initial, String name, String role) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    role,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.secondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
