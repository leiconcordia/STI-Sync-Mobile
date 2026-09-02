import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/core/utils/date_formatter.dart';
import 'package:sti_sync/features/events/models/event_model.dart';
import 'package:sti_sync/shared/providers/providers.dart';

class UpcomingEventsSection extends ConsumerWidget {
  const UpcomingEventsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsStreamProvider);

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
            GestureDetector(
              onTap: () {
                context.go('/events');
              },
              child: Text(
                'See All',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        eventsAsync.when(
          data: (events) {
            final upcomingEvents = events.where((e) => e.isUpcomingOrOngoing()).toList()
              ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

            if (upcomingEvents.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: Text(
                    'No upcoming events at this time.',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: upcomingEvents.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return _DashboardEventCard(event: upcomingEvents[index]);
                },
              ),
            );
          },
          loading: () => const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Failed to load events.',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardEventCard extends ConsumerWidget {
  final EventModel event;

  const _DashboardEventCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String dateDisplay = 'TBA';
    if (event.sessions.isNotEmpty && event.sessions.first.date.isNotEmpty) {
      dateDisplay = formatAppDate(event.sessions.first.date, fallback: event.sessions.first.date);
    } else {
      dateDisplay = formatAppDate(event.createdAt, fallback: 'TBA');
    }

    final venueName = ref.watch(venueNameProvider(event.venueId));
    final orgName = ref.watch(orgNameProvider(event.hostingOrgId));

    final String displayOrg = event.isCampusWide
        ? 'STI College / SAO'
        : (orgName.valueOrNull ?? 'Student Organization');
    final String displayVenue = event.customVenueName ?? venueName.valueOrNull ?? (event.venueId.isNotEmpty ? event.venueId : 'Campus Venue');

    return GestureDetector(
      onTap: () {
        context.pushNamed('eventDetail', pathParameters: {'eventId': event.id});
      },
      child: Container(
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
              decoration: BoxDecoration(
                color: event.isCampusWide ? AppColors.primary : Colors.indigo.shade600,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              event.isCampusWide ? Icons.school_rounded : Icons.groups_outlined,
                              size: 13,
                              color: event.isCampusWide ? AppColors.primary : Colors.indigo.shade700,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                displayOrg,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: event.isCampusWide ? AppColors.primary : Colors.indigo.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                dateDisplay,
                                style: AppTextStyles.labelSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                displayVenue,
                                style: AppTextStyles.labelSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: event.isCampusWide
                                ? AppColors.primary.withOpacity(0.1)
                                : Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            event.isCampusWide ? 'SAO / School' : 'Club Org',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: event.isCampusWide ? AppColors.primary : Colors.indigo.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            context.pushNamed('eventDetail', pathParameters: {'eventId': event.id});
                          },
                          child: Row(
                            children: [
                              Text(
                                'View',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.chevron_right, size: 14, color: AppColors.primaryDark),
                            ],
                          ),
                        ),
                      ],
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
