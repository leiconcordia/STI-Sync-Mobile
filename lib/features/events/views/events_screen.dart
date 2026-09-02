import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/features/events/widgets/event_search_bar.dart';
import 'package:sti_sync/features/events/widgets/event_filter_chips.dart';
import 'package:sti_sync/features/events/widgets/featured_event_card.dart';
import 'package:sti_sync/features/events/widgets/event_list_card.dart';
import 'package:sti_sync/shared/providers/providers.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Events', style: AppTextStyles.h1.copyWith(fontSize: 28, color: AppColors.primaryDark)),
                  IconButton(
                    icon: const Icon(Icons.search, size: 28, color: AppColors.primaryDark),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const EventSearchBar(),
              const SizedBox(height: 14),
              const EventFilterChips(),
              const SizedBox(height: 16),
              ref.watch(eventsStreamProvider).when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                    data: (allEvents) {
                      final filter = ref.watch(eventFilterCategoryProvider);
                      final searchQuery = ref.watch(eventSearchQueryProvider).trim().toLowerCase();
                      final myOrgs = ref.watch(myOrganizationsProvider).valueOrNull ?? [];
                      final myOrgIds = myOrgs.map((o) => o.organizationId).toSet();

                      final filteredEvents = allEvents.where((e) {
                        // 1. Search Query Filter
                        if (searchQuery.isNotEmpty) {
                          final matchesTitle = e.title.toLowerCase().contains(searchQuery);
                          final matchesTagline = (e.tagline ?? '').toLowerCase().contains(searchQuery);
                          final matchesDesc = e.description.toLowerCase().contains(searchQuery);
                          if (!matchesTitle && !matchesTagline && !matchesDesc) {
                            return false;
                          }
                        }

                        // 2. Category / Scope Filter
                        switch (filter) {
                          case EventFilterCategory.all:
                            return e.isUpcomingOrOngoing();
                          case EventFilterCategory.schoolSao:
                            return e.isCampusWide && e.isUpcomingOrOngoing();
                          case EventFilterCategory.myOrgs:
                            return e.isOrgEvent && myOrgIds.contains(e.hostingOrgId) && e.isUpcomingOrOngoing();
                          case EventFilterCategory.completed:
                            return e.isPast();
                        }
                      }).toList();

                      // 3. Sorting
                      if (filter == EventFilterCategory.completed) {
                        filteredEvents.sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
                      } else {
                        filteredEvents.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
                      }

                      if (filteredEvents.isEmpty) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 20),
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                filter == EventFilterCategory.schoolSao
                                    ? Icons.school_outlined
                                    : (filter == EventFilterCategory.myOrgs
                                        ? Icons.star_rounded
                                        : (filter == EventFilterCategory.completed
                                            ? Icons.history_rounded
                                            : Icons.event_busy)),
                                size: 44,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No Events Found',
                                style: AppTextStyles.h2.copyWith(
                                  color: AppColors.primaryDark,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                searchQuery.isNotEmpty
                                    ? 'No events match "$searchQuery".'
                                    : (filter == EventFilterCategory.schoolSao
                                        ? 'No institutional SAO / School events available.'
                                        : (filter == EventFilterCategory.myOrgs
                                            ? 'No events from your joined clubs.'
                                            : (filter == EventFilterCategory.completed
                                                ? 'No completed events found.'
                                                : 'No upcoming events available right now.'))),
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600),
                              ),
                              if (filter != EventFilterCategory.all || searchQuery.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    ref.read(eventFilterCategoryProvider.notifier).state = EventFilterCategory.all;
                                    ref.read(eventSearchQueryProvider.notifier).state = '';
                                  },
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Reset Filters'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryDark,
                                    side: const BorderSide(color: AppColors.primaryDark),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }

                      final isDefaultAllView = searchQuery.isEmpty && filter == EventFilterCategory.all;
                      final featuredEvent = (isDefaultAllView && filteredEvents.isNotEmpty) ? filteredEvents.first : null;
                      final listEvents = (isDefaultAllView && filteredEvents.isNotEmpty)
                          ? filteredEvents.skip(1).toList()
                          : filteredEvents;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (featuredEvent != null) ...[
                            FeaturedEventCard(event: featuredEvent),
                            const SizedBox(height: 28),
                          ],
                          if (listEvents.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  filter == EventFilterCategory.schoolSao
                                      ? 'School & SAO Events (${listEvents.length})'
                                      : (filter == EventFilterCategory.myOrgs
                                          ? 'My Clubs Events (${listEvents.length})'
                                          : (filter == EventFilterCategory.completed
                                              ? 'Completed Events (${listEvents.length})'
                                              : 'All Events (${listEvents.length})')),
                                  style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: listEvents.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                return EventListCard(event: listEvents[index]);
                              },
                            ),
                          ],
                        ],
                      );
                    },
                  ),
              const SizedBox(height: 24),

            ],
          ),
        ),
      ),
    );
  }
}

