import 'package:flutter/material.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';

class HistoryListView extends StatelessWidget {
  const HistoryListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Today', style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark)),
        const SizedBox(height: 16),
        _buildHistoryCard(
          title: 'Paid ICTSO T-shirt fee',
          org: 'ICTSO',
          amount: '+₱150',
          date: 'Jun 5',
          isPositive: true,
          icon: Icons.arrow_downward,
        ),
        const SizedBox(height: 16),
        _buildHistoryCard(
          title: 'Paid ICTSO Organization Fee',
          org: 'ICTSO',
          amount: '+₱200',
          date: 'Jun 3',
          isPositive: true,
          icon: Icons.arrow_downward,
        ),
        const SizedBox(height: 16),
        _buildHistoryCard(
          title: 'Fine issued: Absence',
          org: 'ICTSO',
          amount: '-₱50',
          date: 'Jun 10',
          isPositive: false,
          icon: Icons.error_outline,
        ),
      ],
    );
  }

  Widget _buildHistoryCard({
    required String title,
    required String org,
    required String amount,
    required String date,
    required bool isPositive,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isPositive ? AppColors.success : AppColors.error,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  org,
                  style: AppTextStyles.labelSmall.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isPositive ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                date,
                style: AppTextStyles.labelSmall.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
