import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/shared/providers/providers.dart';
import 'package:sti_sync/features/scanner/models/scanner_assignment_model.dart';

class ScannerDownloadScreen extends ConsumerWidget {
  const ScannerDownloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scannerViewModelProvider);
    final assignments = state.assignments;
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
              child: assignments.isEmpty
                  ? Center(
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
                              'You are currently not assigned as an event scanner. Duty assignments will appear here automatically when created by SAO admins.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
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


    final String format = assignment.eventFormat.isNotEmpty ? assignment.eventFormat : 'On-Campus';
    final int sessionCount = assignment.sessions.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
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
                colors: hasData 
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
                    const Icon(Icons.shield_outlined, color: AppColors.secondary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'GATE DUTY ASSIGNMENT',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.secondary,
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
                    color: hasData 
                        ? AppColors.success
                        : AppColors.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasData ? Icons.check_circle : Icons.downloading_rounded,
                        size: 11,
                        color: hasData ? Colors.white : AppColors.primaryDark,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasData ? 'ROSTER READY' : 'DOWNLOAD NEEDED',
                        style: TextStyle(
                          color: hasData ? Colors.white : AppColors.primaryDark,
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
                // Event Title
                Text(
                  assignment.eventTitle,
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.primaryDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // Format & Sessions Metadata Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
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
                            format,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Status & Action buttons
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
                              ? 'Synced: ${DateFormat("MMM dd, hh:mm a").format(assignment.downloadedAt!)}'
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
                          icon: const Icon(Icons.qr_code_scanner, size: 18, color: AppColors.primaryDark),
                          label: const Text(
                            'Launch Gate Scanner',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
}
