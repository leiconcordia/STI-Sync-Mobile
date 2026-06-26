import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/features/events/widgets/event_search_bar.dart';
import 'package:sti_sync/features/events/widgets/event_filter_chips.dart';
import 'package:sti_sync/features/events/widgets/featured_event_card.dart';
import 'package:sti_sync/features/events/widgets/event_list_card.dart';
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
              const SizedBox(height: 16),
              const EventFilterChips(),
              if (user != null)
                StreamBuilder(
                  stream: ref.read(eventViewModelProvider.notifier).watchEligibleEvents(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                    }
                    
                    final events = snapshot.data ?? [];
                    if (events.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('No events available right now.'),
                        ),
                      );
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FeaturedEventCard(event: events.first),
                        if (events.length > 1) ...[
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('All Events', style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark)),
                              const Icon(Icons.tune, color: Colors.grey),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: events.length - 1,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              return EventListCard(event: events[index + 1]);
                            },
                          ),
                        ]
                      ],
                    );
                  },
                ),
              const SizedBox(height: 100), // padding for bottom nav
            ],
          ),
        ),
      ),
    );
  }
}

