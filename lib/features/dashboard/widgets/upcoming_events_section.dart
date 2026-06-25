import 'package:flutter/material.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';

class UpcomingEventsSection extends StatelessWidget {
  const UpcomingEventsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Events',
              style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark),
            ),
            Text(
              'See All',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildEventCard(
                title: 'Tech Summit 2026',
                org: 'ICTSO',
                date: 'Jun 15',
                location: 'Auditorium',
                status: 'Registered',
                statusColor: AppColors.primary.withOpacity(0.1),
                statusTextColor: AppColors.primary,
                statusIcon: Icons.check,
              ),
              const SizedBox(width: 16),
              _buildEventCard(
                title: 'Leadership Training',
                org: 'SSG',
                date: 'Jun 20',
                location: 'Campus Ground',
                status: 'Open',
                statusColor: AppColors.success.withOpacity(0.1),
                statusTextColor: AppColors.success,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard({
    required String title,
    required String org,
    required String date,
    required String location,
    required String status,
    required Color statusColor,
    required Color statusTextColor,
    IconData? statusIcon,
  }) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  org,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(date, style: AppTextStyles.labelSmall),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(location, style: AppTextStyles.labelSmall),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            status,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: statusTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (statusIcon != null) ...[
                            const SizedBox(width: 2),
                            Icon(statusIcon, size: 12, color: statusTextColor),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      'View',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
