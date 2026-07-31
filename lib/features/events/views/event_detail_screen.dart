import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import 'package:sti_sync/shared/providers/providers.dart';
import 'package:sti_sync/features/events/models/event_model.dart';

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
            icon:
                const Icon(Icons.share_outlined, color: AppColors.primaryDark),
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
          final categoryName =
              ref.watch(categoryNameProvider(event.eventCategoryId));

          String orgName = 'Loading...';
          String? logoUrl;
          orgDataAsync.whenData((orgMap) {
            if (orgMap != null) {
              orgName = orgMap['name'] as String? ??
                  orgMap['acronym'] as String? ??
                  'Unknown Org';
              logoUrl = orgMap['logoUrl'] as String?;
            } else {
              orgName = 'Unknown Org';
            }
          });

          final actualParticipantCount =
              ref.watch(actualParticipantCountProvider(event));

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (event.bannerImageUrl != null &&
                        event.bannerImageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CachedNetworkImage(
                          imageUrl: event.bannerImageUrl!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade200,
                            height: 200,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: double.infinity,
                            height: 200,
                            color: AppColors.primary,
                            alignment: Alignment.center,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                event.title,
                                style: AppTextStyles.h1
                                    .copyWith(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            event.title,
                            style:
                                AppTextStyles.h1.copyWith(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (event.eventCategoryId.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              ClipOval(
                                child: logoUrl != null && logoUrl!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: logoUrl!,
                                        width: 20,
                                        height: 20,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                          width: 20,
                                          height: 20,
                                          color: Colors.grey.shade300,
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                          width: 20,
                                          height: 20,
                                          color: AppColors.primary,
                                          alignment: Alignment.center,
                                          child: Text(
                                            orgName.isNotEmpty
                                                ? orgName.substring(0, 1)
                                                : 'O',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 20,
                                        height: 20,
                                        color: AppColors.primary,
                                        alignment: Alignment.center,
                                        child: Text(
                                          orgName.isNotEmpty
                                              ? orgName.substring(0, 1)
                                              : 'O',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
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
                      style: AppTextStyles.h1
                          .copyWith(color: AppColors.primaryDark, fontSize: 26),
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
                          _buildInfoRow(Icons.location_on_outlined, 'Venue',
                              venueName.valueOrNull ?? 'Loading...'),
                          Divider(color: Colors.grey.shade200, height: 1),
                          _buildInfoRow(Icons.people_outline, 'Attendees',
                              '${actualParticipantCount.valueOrNull ?? '...'} expected'),
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
                                  session.title.isNotEmpty
                                      ? session.title
                                      : 'Session',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildSessionInfo(
                                  Icons.calendar_today,
                                  _formatSessionDate(session.date),
                                ),
                                const SizedBox(height: 4),
                                _buildSessionInfo(
                                  Icons.schedule,
                                  '${_formatSessionTime(session, session.startTime)} to '
                                  '${_formatSessionTime(session, session.endTime)}',
                                ),
                                const SizedBox(height: 12),
                                Divider(color: Colors.grey.shade200, height: 1),
                                const SizedBox(height: 12),
                                _buildAttendanceGuide(event, session),
                              ],
                            ),
                          )),
                      const SizedBox(height: 12),
                    ],
                    if (event.budgetItems.isNotEmpty ||
                        event.totalApprovedBudget > 0 ||
                        (event.adminFeeOverride ?? 0) > 0) ...[
                      Text(
                        'Budget & Event Fee',
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
                            ExpansionTile(
                              tilePadding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              childrenPadding: const EdgeInsets.only(bottom: 8),
                              title: Row(
                                children: [
                                  const Icon(
                                      Icons.account_balance_wallet_outlined,
                                      color: AppColors.primary,
                                      size: 20),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      'Total Budget',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(event.totalApprovedBudget),
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                'View budget breakdown',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              children: event.budgetItems.isEmpty
                                  ? [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 0, 16, 12),
                                        child: Text(
                                          'No budget items were provided.',
                                          style:
                                              AppTextStyles.bodyMedium.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ]
                                  : event.budgetItems
                                      .map(_buildBudgetItem)
                                      .toList(),
                            ),
                            if ((event.adminFeeOverride ?? 0) > 0) ...[
                              Divider(color: Colors.grey.shade200, height: 1),
                              _buildInfoRow(
                                Icons.confirmation_number_outlined,
                                'Event Fee',
                                _formatCurrency(event.adminFeeOverride!),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Text(
                                  'Payment of the event fee is required to unlock your QR ticket.',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
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
                            event.description.isNotEmpty
                                ? event.description
                                : 'No description provided.',
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                        height: 100), // Padding for sticky bottom button
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
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
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
                          GestureDetector(
                            onTap: () {
                              context.goNamed('qrTicket',
                                  pathParameters: {'eventId': eventId});
                            },
                            child: Text(
                              'View Ticket',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                              ),
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
        error: (err, stack) => Center(
            child:
                Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildSessionInfo(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceGuide(EventModel event, EventSessionModel session) {
    final start = _parseSessionDateTime(session, session.startTime);
    final opens = _parseSessionDateTime(session, session.timeInOpen) ?? start;
    final graceMinutes =
        (event.gracePeriodMinutes ?? 0).clamp(0, 24 * 60).toInt();
    final onTimeUntil = start?.add(Duration(minutes: graceMinutes));
    final configuredClose = _parseSessionDateTime(session, session.timeInClose);
    final fallbackClose = configuredClose ??
        _parseSessionDateTime(session, session.endTime) ??
        onTimeUntil ??
        start;
    final thresholdClose = event.lateThresholdMinutes == null || start == null
        ? fallbackClose
        : start.add(
            Duration(
              minutes: event.lateThresholdMinutes!.clamp(0, 24 * 60).toInt(),
            ),
          );
    final lateUntil = thresholdClose != null &&
            onTimeUntil != null &&
            thresholdClose.isBefore(onTimeUntil)
        ? onTimeUntil
        : thresholdClose;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance Guide',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildGuideRow('Time-In Opens', _formatTime(opens)),
        _buildGuideRow('Session Starts', _formatTime(start)),
        _buildGuideRow('On-Time Until', _formatTime(onTimeUntil)),
        _buildGuideRow('Late Until / Time-In Closes', _formatTime(lateUntil)),
        if (event.gracePeriodMinutes == null)
          _buildGuideNotice(
              'No grace period is set. Check in by the session start time to be on time.'),
        if (event.lateThresholdMinutes == null)
          _buildGuideNotice(
              'The configured time-in closing time is used as the late cutoff.'),
        if (session.hasTimeOut) ...[
          const SizedBox(height: 8),
          _buildGuideRow(
            'Time-Out Window',
            '${_formatSessionTime(session, session.timeOutOpen ?? '')} to '
                '${_formatSessionTime(session, session.timeOutClose ?? '')}',
          ),
        ],
      ],
    );
  }

  Widget _buildGuideRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideNotice(String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        value,
        style:
            AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildBudgetItem(BudgetItemModel item) {
    final status = item.status.isEmpty ? 'pending' : item.status;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.item.isEmpty ? 'Budget item' : item.item,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                _formatCurrency(item.approvedAmount),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              item.description,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 2),
          Text(
            '${_formatNumber(item.quantity)} × ${_formatCurrency(item.unitCost)} · ${_capitalize(status)}',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _parseSessionDateTime(EventSessionModel session, String time) {
    if (session.date.isEmpty || time.isEmpty) return null;
    try {
      return DateFormat('yyyy-MM-dd HH:mm')
          .parseStrict('${session.date} $time');
    } catch (_) {
      try {
        return DateFormat('yyyy-MM-dd h:mm a')
            .parseStrict('${session.date} $time');
      } catch (_) {
        return null;
      }
    }
  }

  String _formatSessionDate(String value) {
    try {
      return DateFormat('MMM d, y').format(DateTime.parse(value));
    } catch (_) {
      return value.isEmpty ? 'Date to be announced' : value;
    }
  }

  String _formatSessionTime(EventSessionModel session, String value) {
    return _formatTime(_parseSessionDateTime(session, value));
  }

  String _formatTime(DateTime? value) =>
      value == null ? 'Not set' : DateFormat('h:mm a').format(value);

  String _formatCurrency(double value) => '₱${value.toStringAsFixed(2)}';

  String _formatNumber(double value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);

  String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

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
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
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
