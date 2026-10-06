import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import 'package:sti_sync/shared/providers/providers.dart';
import '../models/event_model.dart';

class EventListCard extends ConsumerWidget {
  final EventModel event;

  const EventListCard({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String dateStr = event.displayDate;

    final venueName = ref.watch(venueNameProvider(event.venueId));
    final orgName = ref.watch(orgNameProvider(event.hostingOrgId));

    final categoryName = ref.watch(categoryNameProvider(event.eventCategoryId));
    final actualParticipantCount = ref.watch(actualParticipantCountProvider(event.id));

    final hasBanner = event.bannerImageUrl != null && event.bannerImageUrl!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasBanner) ...[
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: event.bannerImageUrl!.trim(),
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 140,
                  color: Colors.grey.shade100,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              ),
            ),
          ],
          Container(
            height: 4,
            margin: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: hasBanner ? 8 : 14,
            ),
            decoration: BoxDecoration(
              color: event.isEffectivelyCancelled
                  ? Colors.red.shade600
                  : (event.isArchived
                      ? const Color(0xFF64748B)
                      : (event.isCompleted
                          ? const Color(0xFF10B981)
                          : AppColors.primary)),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: AppTextStyles.h2.copyWith(
                      color: event.isEffectivelyCancelled ? Colors.grey.shade800 : AppColors.primaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (event.isEffectivelyCancelled) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Text(
                      'CANCELLED',
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ] else if (event.isArchived) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.archive_outlined, size: 10, color: Color(0xFF475569)),
                        SizedBox(width: 3),
                        Text(
                          'ARCHIVED',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (event.isCompleted) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, size: 10, color: Color(0xFF047857)),
                        SizedBox(width: 3),
                        Text(
                          'COMPLETED',
                          style: TextStyle(
                            color: Color(0xFF047857),
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: event.isCampusWide ? AppColors.primaryDark : Colors.indigo.shade700,
                  child: event.isCampusWide
                      ? const Icon(Icons.school_rounded, size: 14, color: Colors.white)
                      : Text(
                          (orgName.valueOrNull?.isNotEmpty == true)
                              ? orgName.valueOrNull!.substring(0, 1).toUpperCase()
                              : 'C',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.isCampusWide
                        ? 'STI College / SAO'
                        : (orgName.valueOrNull ?? 'Student Organization'),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: event.isCampusWide ? AppColors.primaryDark : Colors.indigo.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: event.isCampusWide ? AppColors.primary.withValues(alpha: 0.1) : Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: event.isCampusWide ? AppColors.primary.withValues(alpha: 0.2) : Colors.indigo.shade200,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    event.isCampusWide ? 'SAO / Admin' : 'Club Org',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: event.isCampusWide ? AppColors.primary : Colors.indigo.shade800,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (categoryName.valueOrNull != null && categoryName.valueOrNull!.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text('• ${categoryName.valueOrNull}', style: AppTextStyles.labelSmall.copyWith(fontSize: 11)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(dateStr, style: AppTextStyles.labelSmall),
                const SizedBox(width: 16),
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.customVenueName ?? venueName.valueOrNull ?? (event.venueId.isNotEmpty ? event.venueId : 'Campus Venue'), 
                    style: AppTextStyles.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.people_outline, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${actualParticipantCount.valueOrNull ?? '...'} targeted', style: AppTextStyles.labelSmall),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200, height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (event.requiresAttendance) ...[
                  GestureDetector(
                    onTap: () {
                      context.pushNamed('eventDetail', pathParameters: {'eventId': event.id});
                    },
                    child: Text(
                      'View Details',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.pushNamed('qrTicket', pathParameters: {'eventId': event.id});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'View Ticket',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'No Scanners Required',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      context.pushNamed('eventDetail', pathParameters: {'eventId': event.id});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        'View Details',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
