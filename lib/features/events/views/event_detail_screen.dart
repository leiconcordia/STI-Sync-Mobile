import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import 'package:sti_sync/shared/providers/providers.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsyncValue = ref.watch(eventDetailProvider(eventId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Event Details',
          style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.primaryDark),
            onPressed: () {},
          ),
        ],
      ),
      body: eventAsyncValue.when(
        data: (event) {
          if (event == null) {
            return const Center(child: Text('Event not found.'));
          }

          final venueName = ref.watch(venueNameProvider(event.venueId));
          final orgDataAsync = ref.watch(orgProvider(event.hostingOrgId));
          final categoryName = ref.watch(categoryNameProvider(event.eventCategoryId));

          String orgName = 'Loading...';
          String? logoUrl;
          orgDataAsync.whenData((orgMap) {
            if (orgMap != null) {
              orgName = orgMap['name'] as String? ?? orgMap['acronym'] as String? ?? 'Unknown Org';
              logoUrl = orgMap['logoUrl'] as String?;
            } else {
              orgName = 'Unknown Org';
            }
          });

          final actualParticipantCount = ref.watch(actualParticipantCountProvider(event));

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (event.bannerImageUrl != null && event.bannerImageUrl!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: NetworkImage(event.bannerImageUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          event.title,
                          style: AppTextStyles.h1.copyWith(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (event.eventCategoryId.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              categoryName.valueOrNull ?? 'Loading...',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: AppColors.primary,
                                backgroundImage: logoUrl != null ? NetworkImage(logoUrl!) : null,
                                child: logoUrl == null
                                    ? Text(
                                        orgName.isNotEmpty ? orgName.substring(0, 1) : 'O',
                                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                orgName,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      event.title,
                      style: AppTextStyles.h1.copyWith(color: AppColors.primaryDark, fontSize: 26),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.location_on_outlined, 'Venue', venueName.valueOrNull ?? 'Loading...'),
                          Divider(color: Colors.grey.shade200, height: 1),
                          _buildInfoRow(Icons.people_outline, 'Attendees', '${actualParticipantCount.valueOrNull ?? '...'} expected'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (event.sessions.isNotEmpty) ...[
                      Text(
                        'Sessions',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...event.sessions.map((session) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.title.isNotEmpty ? session.title : 'Session',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                                    const SizedBox(width: 8),
                                    Text(
                                      session.date,
                                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${session.startTime} to ${session.endTime}',
                                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Divider(color: Colors.grey.shade200, height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Time In', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                                          Text(
                                            '${session.timeInOpen}',
                                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                                          ),
                                          if (_calculateTimeWithOffset(session.timeInClose, event.lateThresholdMinutes) != null)
                                            Text(
                                              'Late after ${_calculateTimeWithOffset(session.timeInClose, event.lateThresholdMinutes)}',
                                              style: AppTextStyles.labelSmall.copyWith(color: Colors.orange.shade700),
                                            ),
                                          if (_calculateTimeWithOffset(session.timeInClose, event.gracePeriodMinutes) != null)
                                            Text(
                                              'Absent after ${_calculateTimeWithOffset(session.timeInClose, event.gracePeriodMinutes)}',
                                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (session.hasTimeOut)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Time Out', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                                            Text(
                                              '${session.timeOutOpen ?? '?'} - ${session.timeOutClose ?? '?'}',
                                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 12),
                    ],
                    if (event.studentPayablesEnabled) ...[
                      Text(
                        'Budget & Payables',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(Icons.payments_outlined, 'Expected', '₱${(event.suggestedFeePerStudent ?? 0).toStringAsFixed(2)}'),
                            if (event.adminFeeOverride != null && event.adminFeeOverride! > 0) ...[
                              Divider(color: Colors.grey.shade200, height: 1),
                              _buildInfoRow(Icons.admin_panel_settings_outlined, 'Admin Fee', '₱${event.adminFeeOverride!.toStringAsFixed(2)}'),
                            ],
                            Divider(color: Colors.grey.shade200, height: 1),
                            _buildInfoRow(Icons.account_balance_wallet_outlined, 'Total Budget', '₱${(event.totalExpectedCollection ?? 0).toStringAsFixed(2)}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About This Event',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            event.description.isNotEmpty ? event.description : 'No description provided.',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100), // Padding for sticky bottom button
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success, width: 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "You're Eligible ✓",
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'View Ticket',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.orange.shade700, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  String? _calculateTimeWithOffset(String timeString, int? minutesToAdd) {
    if (minutesToAdd == null || minutesToAdd == 0 || timeString.isEmpty) return null;
    try {
      final format = DateFormat('h:mm a'); 
      final parsed = format.parse(timeString);
      final added = parsed.add(Duration(minutes: minutesToAdd));
      return format.format(added);
    } catch (_) {
      try {
        final format2 = DateFormat('HH:mm'); 
        final parsed2 = format2.parse(timeString);
        final added2 = parsed2.add(Duration(minutes: minutesToAdd));
        return DateFormat('h:mm a').format(added2);
      } catch (_) {
         return null;
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
