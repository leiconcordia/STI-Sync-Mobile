import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/shared/providers/providers.dart';
import 'package:sti_sync/features/organizations/models/organization_member_model.dart';

class MyOrganizationsSection extends ConsumerWidget {
  const MyOrganizationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgsAsync = ref.watch(myOrganizationsProvider);

    return orgsAsync.when(
      data: (orgs) {
        if (orgs.isEmpty) return const SizedBox.shrink();

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
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: orgs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final org = orgs[index];
                  return _buildOrgCard(org);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildOrgCard(OrganizationMemberModel org) {
    Color badgeBgColor;
    Color badgeTextColor;
    String badgeText;

    if (org.isPending) {
      badgeBgColor = const Color(0xFFFFF3E0);
      badgeTextColor = Colors.amber.shade900;
      badgeText = 'Pending Approval';
    } else if (org.isOfficer) {
      badgeBgColor = AppColors.accentPurple;
      badgeTextColor = Colors.white;
      badgeText = org.role.isNotEmpty && org.role != 'Member'
          ? 'Officer: ${org.role}'
          : 'Officer';
    } else {
      badgeBgColor = AppColors.primaryDark;
      badgeTextColor = AppColors.secondary;
      badgeText = 'Member';
    }

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
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
            backgroundColor: org.isOfficer ? AppColors.accentPurple : AppColors.primary,
            child: Text(
              org.initials,
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
                  org.organizationName,
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
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: badgeTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
