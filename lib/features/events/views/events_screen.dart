import 'package:flutter/material.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/features/events/widgets/event_search_bar.dart';
import 'package:sti_sync/features/events/widgets/event_filter_chips.dart';
import 'package:sti_sync/features/events/widgets/featured_event_card.dart';
import 'package:sti_sync/features/events/widgets/event_list_card.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 24),
              const FeaturedEventCard(),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('All Events', style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark)),
                  const Icon(Icons.tune, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 16),
              const EventListCard(),
              const SizedBox(height: 100), // padding for bottom nav
            ],
          ),
        ),
      ),
    );
  }
}
