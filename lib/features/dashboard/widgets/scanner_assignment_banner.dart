import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/shared/providers/providers.dart';

class ScannerAssignmentBanner extends ConsumerWidget {
  const ScannerAssignmentBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(activeScannerAssignmentsProvider);

    return assignmentsAsync.when(
      data: (assignments) {
        if (assignments.isEmpty) {
          return const SizedBox.shrink();
        }

        final latest = assignments.first;
        final String eventTitle = latest.eventTitle.isNotEmpty ? latest.eventTitle : 'Assigned Event';
        final venueNameAsync = ref.watch(venueNameProvider(latest.venueId));
        final customVenue = latest.customVenueName;
        final resolvedVenue = venueNameAsync.valueOrNull;
        final String venue = (customVenue != null && customVenue.isNotEmpty)
            ? customVenue
            : (resolvedVenue != null && resolvedVenue != 'Campus Venue' && resolvedVenue != 'TBA'
                ? resolvedVenue
                : (latest.venue.isNotEmpty && latest.venue != 'STI Campus' && latest.venue != 'Campus Venue'
                    ? latest.venue
                    : (resolvedVenue ?? 'Campus Venue')));
        final String formattedDate = latest.formattedStartDate;
        final int sessionCount = latest.sessions.length;

        final bool needsUpload = latest.requiresAttendanceUploadNotice;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.go('/scanner');
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: needsUpload
                      ? const [
                          Color(0xFF2C1810),
                          Color(0xFF451A03),
                        ]
                      : const [
                          AppColors.primaryDark,
                          Color(0xFF0F2C59),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: needsUpload
                      ? Colors.amber.shade400
                      : AppColors.secondary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (needsUpload ? Colors.amber.shade900 : AppColors.primaryDark)
                        .withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Gold or Amber accent side strip
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    width: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: needsUpload ? Colors.amber.shade400 : AppColors.secondary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon Box
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (needsUpload ? Colors.amber : AppColors.secondary)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (needsUpload ? Colors.amber : AppColors.secondary)
                                  .withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            needsUpload
                                ? Icons.cloud_upload_rounded
                                : Icons.qr_code_scanner_rounded,
                            color: needsUpload ? Colors.amber.shade300 : AppColors.secondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Text content block
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    needsUpload ? 'UPLOAD REQUIRED' : 'SCANNER DUTY',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: needsUpload
                                          ? Colors.amber.shade300
                                          : AppColors.secondary,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: needsUpload ? Colors.amber.shade700 : AppColors.success,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      needsUpload ? 'CONCLUDED' : 'LIVE',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                needsUpload
                                    ? 'Upload your attendance: Event has been concluded'
                                    : eventTitle,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: needsUpload ? 13 : 15,
                                ),
                                maxLines: needsUpload ? 2 : 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                needsUpload
                                    ? '$eventTitle • ${latest.pendingSyncCount} offline scan(s) pending'
                                    : '$formattedDate • $venue • $sessionCount Session(s)',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Right action button
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: needsUpload ? Colors.amber.shade400 : AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            needsUpload
                                ? Icons.cloud_upload_rounded
                                : Icons.arrow_forward_rounded,
                            color: AppColors.primaryDark,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
