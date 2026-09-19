import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/core/utils/currency_formatter.dart';
import 'package:sti_sync/core/utils/date_formatter.dart';
import 'package:go_router/go_router.dart';
import 'package:sti_sync/shared/providers/providers.dart';
import 'package:sti_sync/features/events/models/event_model.dart';
import 'package:sti_sync/features/payables/models/payable_model.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsyncValue = ref.watch(eventDetailProvider(eventId));
    final payablesAsync = ref.watch(payablesStreamProvider);

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
          final orgDataAsync = event.isOrgEvent ? ref.watch(orgProvider(event.hostingOrgId)) : null;
          final resolvedOrgName = ref.watch(orgNameProvider(event.hostingOrgId));
          final categoryName =
              ref.watch(categoryNameProvider(event.eventCategoryId));

          String orgName = event.isCampusWide ? 'STI College / SAO' : (resolvedOrgName.valueOrNull ?? 'Student Organization');
          String? logoUrl;
          if (orgDataAsync != null) {
            orgDataAsync.whenData((orgMap) {
              if (orgMap != null) {
                orgName = orgMap['name'] as String? ??
                    orgMap['acronym'] as String? ??
                    'Student Organization';
                logoUrl = orgMap['logoUrl'] as String?;
              }
            });
          }

          final actualParticipantCount =
              ref.watch(actualParticipantCountProvider(event.id));
          final eventPayable = payablesAsync.valueOrNull
              ?.where((p) => p.eventId == event.id)
              .firstOrNull;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (event.isEffectivelyCancelled) ...[
                      _buildCancelledAlertBanner(event),
                      const SizedBox(height: 16),
                    ],
                    _buildBannerImage(event),
                    const SizedBox(height: 16),
                    if (event.isEffectivelyCancelled && eventPayable != null) ...[
                      _buildStudentPaymentAndRefundCard(event, eventPayable),
                      const SizedBox(height: 16),
                    ],
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (event.eventCategoryId.isNotEmpty)
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: event.isCampusWide
                                    ? AppColors.primaryDark
                                    : AppColors.primary,
                                child: event.isCampusWide
                                    ? const Icon(Icons.school_rounded,
                                        size: 12, color: Colors.white)
                                    : (logoUrl != null && logoUrl!.isNotEmpty
                                        ? ClipOval(
                                            child: CachedNetworkImage(
                                              imageUrl: logoUrl!,
                                              width: 20,
                                              height: 20,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) =>
                                                  Text(
                                                orgName.isNotEmpty
                                                    ? orgName.substring(0, 1).toUpperCase()
                                                    : 'C',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          )
                                        : Text(
                                            orgName.isNotEmpty
                                                ? orgName.substring(0, 1).toUpperCase()
                                                : 'C',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold),
                                          )),
                              ),
                              const SizedBox(width: 8),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 160),
                                child: Text(
                                  orgName,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: event.isCampusWide
                                        ? AppColors.primaryDark
                                        : AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: event.isCampusWide
                                      ? AppColors.primary.withValues(alpha: 0.1)
                                      : Colors.indigo.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  event.isCampusWide ? 'SAO / School' : 'Club',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: event.isCampusWide
                                        ? AppColors.primary
                                        : Colors.indigo.shade800,
                                  ),
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
                          _buildInfoRow(Icons.calendar_today_outlined, 'Date', event.displayDate),
                          Divider(color: Colors.grey.shade200, height: 1),
                          _buildInfoRow(Icons.location_on_outlined, 'Venue',
                              event.customVenueName ?? venueName.valueOrNull ?? (event.venueId.isNotEmpty ? event.venueId : 'Campus Venue')),
                          Divider(color: Colors.grey.shade200, height: 1),
                          _buildInfoRow(Icons.people_outline, 'Attendees',
                              event.expectedParticipantCount > 0
                                  ? '${event.expectedParticipantCount} expected'
                                  : '${actualParticipantCount.valueOrNull ?? '...'} registered'),
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
                    if (event.totalApprovedBudget > 0 ||
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
                            if (event.totalApprovedBudget > 0)
                              _buildInfoRow(
                                Icons.account_balance_wallet_outlined,
                                'Total Budget',
                                _formatCurrency(event.totalApprovedBudget),
                              ),
                            if ((event.adminFeeOverride ?? 0) > 0) ...[
                              if (event.totalApprovedBudget > 0)
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
                  padding: const EdgeInsets.all(16),
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
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.pushNamed(
                            'qrTicket',
                            pathParameters: {'eventId': eventId},
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: event.isEffectivelyCancelled
                              ? Colors.grey.shade800
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: Icon(
                          event.isEffectivelyCancelled
                              ? Icons.block_rounded
                              : Icons.qr_code_rounded,
                          size: 20,
                          color: event.isEffectivelyCancelled
                              ? Colors.redAccent
                              : Colors.white,
                        ),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            event.isEffectivelyCancelled
                                ? 'Ticket Revoked (Event Cancelled)'
                                : 'View Digital QR Ticket',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
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

  Widget _buildBannerImage(EventModel event) {
    Widget banner;
    if (event.bannerImageUrl != null && event.bannerImageUrl!.isNotEmpty) {
      banner = ClipRRect(
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                event.title,
                style: AppTextStyles.h1.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    } else {
      banner = Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: event.isEffectivelyCancelled
              ? Colors.grey.shade700
              : AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            event.title,
            style: AppTextStyles.h1.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (event.isEffectivelyCancelled) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]),
        child: banner,
      );
    }
    return banner;
  }

  Widget _buildSessionInfo(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
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
        if (onTimeUntil != null)
          _buildGuideRow('On-Time Check-In Until', _formatTime(onTimeUntil)),
        _buildGuideRow('Time-In Closes (Late Cutoff)', _formatTime(lateUntil)),
        if (event.gracePeriodMinutes == null && onTimeUntil != null)
          _buildGuideNotice(
              'Check in promptly once time-in opens to be marked on time.'),
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
    return formatAppDate(value, fallback: value.isEmpty ? 'Date to be announced' : value);
  }

  String _formatSessionTime(EventSessionModel session, String value) {
    return _formatTime(_parseSessionDateTime(session, value));
  }

  String _formatTime(DateTime? value) =>
      value == null ? 'Not set' : formatAppTime(value);

  String _formatCurrency(double value) => formatCurrency(value);

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

  Widget _buildCancelledAlertBanner(EventModel event) {
    final reason = event.cancellationReason?.trim().isNotEmpty == true
        ? event.cancellationReason!
        : 'Official cancellation recorded by event organizers.';
    final dateStr = event.cancelledAt != null ? formatAppDateTime(event.cancelledAt) : 'Recently';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade300, width: 1.2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cancel_rounded, color: Colors.red.shade800, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EVENT CANCELLED',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'This event has been officially cancelled.',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reason for Cancellation:',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                'Date Cancelled: $dateStr',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 11,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Text(
                  _formatRefundPolicy(event.refundPolicy),
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentPaymentAndRefundCard(EventModel event, PayableModel payable) {
    final status = payable.payableStatus;
    final isPendingRefund = status == PayableStatus.refundPending || payable.isRefundPending;
    final isRefunded = status == PayableStatus.refunded || payable.isRefunded;
    final isWaived = status == PayableStatus.waived || payable.isWaived;

    Color badgeBg;
    Color badgeText;
    String badgeLabel;
    String amountLine;
    String helperNote;

    if (isPendingRefund) {
      badgeBg = Colors.amber.shade50;
      badgeText = Colors.amber.shade900;
      badgeLabel = 'REFUND PENDING';
      amountLine = '${formatCurrency(payable.refundDue ?? payable.paidAmount)} Due Back';
      helperNote = 'Disbursement at SAO / Org Booth. Please present your Student ID to claim.';
    } else if (isRefunded) {
      badgeBg = Colors.blue.shade50;
      badgeText = Colors.blue.shade800;
      badgeLabel = 'REFUND DISBURSED';
      amountLine = '${formatCurrency(payable.paidAmount)} Refunded';
      helperNote = payable.refundReceiptNumber != null
          ? 'Receipt / Ref: ${payable.refundReceiptNumber}'
          : 'Disbursement recorded and settled.';
    } else if (isWaived) {
      badgeBg = const Color(0xFFECFDF5);
      badgeText = const Color(0xFF047857);
      badgeLabel = 'AUTO-WAIVED';
      amountLine = '₱0.00 Balance';
      helperNote = 'Event cancelled. Payment is no longer required.';
    } else {
      badgeBg = Colors.grey.shade100;
      badgeText = Colors.grey.shade800;
      badgeLabel = payable.status.toUpperCase();
      amountLine = formatCurrency(payable.amountDue);
      helperNote = 'Event cancelled. Financial adjustments in progress.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.payment_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your Payment & Fee Status',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    color: badgeText,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            amountLine,
            style: AppTextStyles.h2.copyWith(
              color: AppColors.primaryDark,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            helperNote,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRefundPolicy(String? policy) {
    switch (policy) {
      case 'refund_cash':
        return 'Full Cash Refund';
      case 'credit_next_event':
        return 'Credited to Next Event';
      case 'no_fees_collected':
        return 'Free Event / No Fees';
      default:
        return 'Refund Policy Active';
    }
  }
}
