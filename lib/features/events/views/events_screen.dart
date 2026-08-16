import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/features/events/widgets/event_search_bar.dart';
import 'package:sti_sync/features/events/widgets/event_filter_chips.dart';
import 'package:sti_sync/features/events/widgets/featured_event_card.dart';
import 'package:sti_sync/features/events/widgets/event_list_card.dart';
import 'package:sti_sync/features/events/models/event_model.dart';
import 'package:sti_sync/shared/providers/providers.dart';
import 'package:sti_sync/core/firebase/firebase_service.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;
    
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
              if (user != null)
                StreamBuilder<List<EventModel>>(
                  stream: ref.read(eventViewModelProvider.notifier).watchEligibleEvents(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                        ),
                      );
                    }

                    final allEvents = snapshot.data ?? [];
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
                        case EventFilterCategory.schoolSao:
                          return e.isCampusWide;
                        case EventFilterCategory.clubs:
                          return e.isOrgEvent;
                        case EventFilterCategory.myOrgs:
                          return e.isOrgEvent && myOrgIds.contains(e.hostingOrgId);
                        case EventFilterCategory.all:
                          return true;
                      }
                    }).toList();

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
                                  : (filter == EventFilterCategory.clubs
                                      ? Icons.groups_outlined
                                      : Icons.event_busy),
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
                                      : (filter == EventFilterCategory.clubs
                                          ? 'No club organization events available.'
                                          : (filter == EventFilterCategory.myOrgs
                                              ? 'No events from your joined clubs.'
                                              : 'No events available right now.'))),
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

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (searchQuery.isEmpty && filter == EventFilterCategory.all && filteredEvents.isNotEmpty) ...[
                          FeaturedEventCard(event: filteredEvents.first),
                          const SizedBox(height: 28),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              filter == EventFilterCategory.schoolSao
                                  ? 'School & SAO Events (${filteredEvents.length})'
                                  : (filter == EventFilterCategory.clubs
                                      ? 'Club Organization Events (${filteredEvents.length})'
                                      : (filter == EventFilterCategory.myOrgs
                                          ? 'My Clubs Events (${filteredEvents.length})'
                                          : 'All Events (${filteredEvents.length})')),
                              style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredEvents.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return EventListCard(event: filteredEvents[index]);
                          },
                        ),
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

