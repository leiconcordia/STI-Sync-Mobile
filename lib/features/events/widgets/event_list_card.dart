import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    String dateStr = 'No schedule yet';
    if (event.sessions.isNotEmpty) {
      dateStr = event.sessions.first.date;
    }

    final venueName = ref.watch(venueNameProvider(event.venueId));
    final orgName = ref.watch(orgNameProvider(event.hostingOrgId));

    final categoryName = ref.watch(categoryNameProvider(event.eventCategoryId));
    final actualParticipantCount = ref.watch(actualParticipantCountProvider(event.id));


    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              event.title,
              style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                    color: event.isCampusWide ? AppColors.primary.withOpacity(0.1) : Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: event.isCampusWide ? AppColors.primary.withOpacity(0.2) : Colors.indigo.shade200,
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
                    venueName.valueOrNull ?? 'Loading...', 
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
