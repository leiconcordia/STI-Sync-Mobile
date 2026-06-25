import 'package:flutter/material.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';

class AnnouncementsSection extends StatelessWidget {
  const AnnouncementsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Announcements',
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
        _buildAnnouncementCard(
          orgInitial: 'IC',
          orgName: 'ICTSO',
          timeAgo: '2h ago',
          title: 'New scholarship applications open',
          body: 'Applications for the 2026 ICT scholarship are now open. Deadline is June 30...',
          isUrgent: false,
        ),
        const SizedBox(height: 16),
        _buildAnnouncementCard(
          orgInitial: 'SG',
          orgName: 'SSG',
          timeAgo: '1d ago', // Assuming some value
          title: 'Enrollment reminder for 2nd sem',
          body: 'Please confirm your enrollment for the upcoming semester before June 20...',
          isUrgent: true,
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard({
    required String orgInitial,
    required String orgName,
    required String timeAgo,
    required String title,
    required String body,
    required bool isUrgent,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primaryDark,
                              child: Text(
                                orgInitial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              orgName,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (isUrgent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Urgent',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Text(
                            timeAgo,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      body,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Read more',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
