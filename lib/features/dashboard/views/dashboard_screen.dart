import 'package:flutter/material.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/features/dashboard/widgets/dashboard_header.dart';
import 'package:sti_sync/features/dashboard/widgets/digital_id_card.dart';
import 'package:sti_sync/features/dashboard/widgets/quick_actions_grid.dart';
import 'package:sti_sync/features/dashboard/widgets/scanner_assignment_banner.dart';
import 'package:sti_sync/features/dashboard/widgets/upcoming_events_section.dart';
import 'package:sti_sync/features/dashboard/widgets/announcements_section.dart';
import 'package:sti_sync/features/dashboard/widgets/my_organizations_section.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              DashboardHeader(),
              SizedBox(height: 24),
              DigitalIdCard(),
              SizedBox(height: 24),
              QuickActionsGrid(),
              SizedBox(height: 24),
              ScannerAssignmentBanner(),
              SizedBox(height: 32),
              UpcomingEventsSection(),
              SizedBox(height: 32),
              AnnouncementsSection(),
              SizedBox(height: 32),
              MyOrganizationsSection(),
              SizedBox(height: 100), // Bottom padding for navigation bar
            ],
          ),
        ),
      ),
    );
  }
}
