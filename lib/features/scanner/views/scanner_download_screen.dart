import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/utils/date_formatter.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/shared/providers/providers.dart';
import 'package:sti_sync/features/scanner/models/scanner_assignment_model.dart';
import 'package:sti_sync/features/sync/models/sync_status_model.dart';

class ScannerDownloadScreen extends ConsumerWidget {
  const ScannerDownloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scannerViewModelProvider);
    final activeAssignments = ref.watch(activeScannerAssignmentsProvider).valueOrNull ?? [];
    final assignments = state.assignments.isNotEmpty ? state.assignments : activeAssignments;
    final isOnline = ref.watch(connectivityStatusProvider).valueOrNull ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Scanner Assignments',
          style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark, fontSize: 22),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!isOnline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.amber.shade100,
                child: Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, color: Colors.amber.shade900, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Offline Mode — Internet connection is required to download or re-sync rosters.',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await ref.read(connectivityServiceProvider).checkConnectivity();
                  final student = ref.read(authViewModelProvider).student;
                  if (student != null) {
                    ref.read(scannerViewModelProvider.notifier).loadAssignments(student.id);
                  }
                  ref.invalidate(activeScannerAssignmentsProvider);
                },
                child: assignments.isEmpty
                    ? LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(28),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.qr_code_scanner_rounded,
                                        size: 64,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'No Active Gate Duty',
                                      style: AppTextStyles.h1.copyWith(
                                        color: AppColors.primaryDark,
                                        fontSize: 22,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'You are currently not assigned as an event scanner. Duty assignments will appear here automatically when created by SAO admins. Swipe down to refresh.',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: assignments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return _AssignmentCard(
                            assignment: assignments[index],
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );

  }
}

class _AssignmentCard extends ConsumerWidget {
  final ScannerAssignmentModel assignment;

  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scannerViewModelProvider);
    final isOnline = ref.watch(connectivityStatusProvider).valueOrNull ?? false;
    final isDownloading = state.downloadingEventId == assignment.eventId;
    final progress = state.downloadProgress;
    final hasData = assignment.dataDownloaded;


    final venueNameAsync = ref.watch(venueNameProvider(assignment.venueId));
    final String venue = (assignment.customVenueName != null && assignment.customVenueName!.isNotEmpty)
        ? assignment.customVenueName!
        : (venueNameAsync.valueOrNull != null && venueNameAsync.valueOrNull != 'Campus Venue' && venueNameAsync.valueOrNull != 'TBA'
            ? venueNameAsync.valueOrNull!
            : (assignment.venue.isNotEmpty && assignment.venue != 'STI Campus' && assignment.venue != 'Campus Venue'
                ? assignment.venue
                : (venueNameAsync.valueOrNull ?? 'Campus Venue')));
    final int sessionCount = assignment.sessions.length;
    final liveEvent = ref.watch(eventDetailProvider(assignment.eventId)).valueOrNull;
    final isCancelled = assignment.isEffectivelyCancelled || (liveEvent?.isEffectivelyCancelled ?? false);

    // If live event is cancelled in cloud, immediately sync cancellation state to local Drift
    if (liveEvent != null && liveEvent.isEffectivelyCancelled && !assignment.isEffectivelyCancelled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(scannerRepositoryProvider).saveAssignmentLocally(
          assignment.copyWith(
            isCancelled: true,
            status: 'cancelled',
            proposalStatus: 'cancelled',
            cancellationReason: liveEvent.cancellationReason,
          ),
        );
      });
    }

    final reason = (assignment.cancellationReason != null && assignment.cancellationReason!.trim().isNotEmpty)
        ? assignment.cancellationReason!
        : (liveEvent?.cancellationReason != null && liveEvent!.cancellationReason!.trim().isNotEmpty
            ? liveEvent.cancellationReason!
            : 'Gate duty assignments and QR check-ins are revoked for this event.');

    final bool needsUpload = assignment.requiresAttendanceUploadNotice;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCancelled
              ? Colors.red.shade200
              : needsUpload
                  ? Colors.amber.shade400
                  : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar Accent
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCancelled
                    ? [const Color(0xFF991B1B), const Color(0xFF7F1D1D)]
                    : needsUpload
                        ? [const Color(0xFF78350F), const Color(0xFF92400E)]
                        : hasData 
                            ? [AppColors.primaryDark, const Color(0xFF1E3A8A)]
                            : [const Color(0xFF1E293B), const Color(0xFF334155)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isCancelled
                          ? Icons.cancel_outlined
                          : (needsUpload ? Icons.cloud_upload_outlined : Icons.shield_outlined),
                      color: isCancelled ? Colors.white : (needsUpload ? Colors.amber.shade300 : AppColors.secondary),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCancelled
                          ? 'CANCELLED EVENT'
                          : (needsUpload ? 'EVENT CONCLUDED' : 'GATE DUTY ASSIGNMENT'),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isCancelled ? Colors.white : (needsUpload ? Colors.amber.shade300 : AppColors.secondary),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? Colors.red.shade800
                        : needsUpload
                            ? Colors.amber.shade700
                            : hasData 
                                ? AppColors.success
                                : AppColors.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCancelled
                            ? Icons.block
                            : (needsUpload ? Icons.cloud_upload_rounded : (hasData ? Icons.check_circle : Icons.downloading_rounded)),
                        size: 11,
                        color: isCancelled || hasData || needsUpload ? Colors.white : AppColors.primaryDark,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCancelled
                            ? 'DUTY VOIDED'
                            : (needsUpload ? 'UPLOAD REQUIRED' : (hasData ? 'ROSTER READY' : 'DOWNLOAD NEEDED')),
                        style: TextStyle(
                          color: isCancelled || hasData || needsUpload ? Colors.white : AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Title and CANCELLED badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        assignment.eventTitle,
                        style: AppTextStyles.h2.copyWith(
                          color: isCancelled ? Colors.grey.shade800 : AppColors.primaryDark,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isCancelled) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cancel, size: 12, color: Colors.red.shade800),
                            const SizedBox(width: 4),
                            Text(
                              'CANCELLED',
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),

                // Date, Venue & Sessions Metadata Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (isCancelled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cancel, size: 12, color: Colors.red.shade800),
                            const SizedBox(width: 4),
                            Text(
                              'CANCELLED',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Start Date Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.primaryDark),
                          const SizedBox(width: 4),
                          Text(
                            assignment.formattedStartDate,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Venue Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            venue,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Sessions Count Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event_seat_outlined, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '$sessionCount Session(s)',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Permission Badges (3 Checkboxes)
                    if (assignment.canCheckIn)
                      _buildPermChip(Icons.login, 'Time-In', AppColors.success),
                    if (assignment.canCheckOut)
                      _buildPermChip(Icons.logout, 'Time-Out', const Color(0xFF0284C7)),
                    if (assignment.allowManualAttendance)
                      _buildPermChip(Icons.edit_note, 'Manual/Flagged', Colors.amber.shade800),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                if (isCancelled)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.red.shade800, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Event Cancelled — Duty Voided',
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                reason,
                                style: TextStyle(
                                  color: Colors.red.shade800,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                if (needsUpload)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.shade400, width: 1.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.cloud_upload_rounded, color: Colors.amber.shade900, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upload your attendance: Event has been concluded',
                                style: TextStyle(
                                  color: const Color(0xFF451A03),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${assignment.pendingSyncCount} attendance log(s) recorded offline. Scanning is closed. Upload your records now to finalize and clean up scanner duty.',
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                if (isDownloading) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Syncing participant roster...',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ] else if (isCancelled) ...[
                  // Event Cancelled: Action buttons Re-sync & Launch Gate Scanner are explicitly disabled / not clickable
                  Row(
                    children: [
                      Icon(Icons.block, color: Colors.red.shade700, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Duty Revoked — Event has been cancelled',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: null, // Disabled / not clickable
                        style: OutlinedButton.styleFrom(
                          disabledForegroundColor: Colors.grey.shade400,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        icon: Icon(Icons.refresh, size: 16, color: Colors.grey.shade400),
                        label: Text(
                          'Re-sync',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: null, // Disabled / not clickable
                          style: ElevatedButton.styleFrom(
                            disabledBackgroundColor: Colors.grey.shade200,
                            disabledForegroundColor: Colors.grey.shade500,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: Icon(
                            Icons.qr_code_scanner,
                            size: 18,
                            color: Colors.grey.shade500,
                          ),
                          label: Text(
                            'Launch Gate Scanner',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (needsUpload) ...[
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          context.push('/scanner/${assignment.eventId}/logs');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryDark,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        icon: const Icon(Icons.list_alt_rounded, size: 16),
                        label: const Text('View Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isOnline
                              ? () async {
                                  final result = await ref
                                      .read(scannerViewModelProvider.notifier)
                                      .uploadAttendanceAndCleanup(assignment.eventId);
                                  if (context.mounted) {
                                    if (result.type == SyncResultType.success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Uploaded ${result.uploadedCount} record(s)! Scanner cache cleaned up.'),
                                          backgroundColor: AppColors.success,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    } else if (result.type == SyncResultType.hasConflicts) {
                                      context.push('/scanner/sync-conflicts', extra: result.conflicts);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(result.errorMessage ?? 'Upload failed'),
                                          backgroundColor: AppColors.error,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isOnline ? Colors.amber.shade700 : Colors.grey.shade300,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                          label: Text(
                            isOnline ? 'Upload Attendance Now' : 'Connect to Sync',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (!hasData) ...[
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          context.pushNamed(
                            'eventDetail',
                            pathParameters: {'eventId': assignment.eventId},
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryDark,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: const Text('Event Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (isOnline && state.downloadingEventId == null)
                              ? () {
                                  ref
                                      .read(scannerViewModelProvider.notifier)
                                      .downloadParticipantData(assignment.eventId);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isOnline ? AppColors.primary : Colors.grey.shade300,
                            foregroundColor: isOnline ? Colors.white : Colors.grey.shade600,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.cloud_download_rounded, size: 16),
                          label: Text(
                            isOnline ? 'Download Roster' : 'Offline Mode',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          assignment.downloadedAt != null
                              ? 'Synced: ${formatAppDateTime(assignment.downloadedAt!)}'
                              : 'Student Roster Offline Ready',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: isOnline
                            ? () {
                                ref
                                    .read(scannerViewModelProvider.notifier)
                                    .downloadParticipantData(assignment.eventId);
                              }
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isOnline ? AppColors.primary : Colors.grey.shade400,
                          side: BorderSide(color: isOnline ? AppColors.primary : Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        icon: Icon(Icons.refresh, size: 16, color: isOnline ? AppColors.primary : Colors.grey.shade400),
                        label: Text(
                          isOnline ? 'Re-sync' : 'Re-sync (Offline)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isOnline ? AppColors.primary : Colors.grey.shade400,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ref
                                .read(scannerViewModelProvider.notifier)
                                .selectEvent(assignment.eventId);
                            context.push('/scanner/mode');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: AppColors.primaryDark,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(
                            Icons.qr_code_scanner,
                            size: 18,
                            color: AppColors.primaryDark,
                          ),
                          label: const Text(
                            'Launch Gate Scanner',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (state.downloadError != null && isDownloading == false && state.downloadingEventId == null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.downloadError!,
                    style: const TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
