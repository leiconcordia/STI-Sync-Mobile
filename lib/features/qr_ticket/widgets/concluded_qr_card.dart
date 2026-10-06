import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/shared/providers/providers.dart';

class ConcludedQrCard extends ConsumerWidget {
  final String eventTitle;
  final String studentName;
  final String studentId;
  final String profilePhotoUrl;
  final String courseInfo;
  final bool isArchived;
  final bool certificatesEnabled;
  final String? eventId;

  const ConcludedQrCard({
    super.key,
    required this.eventTitle,
    required this.studentName,
    required this.studentId,
    required this.profilePhotoUrl,
    required this.courseInfo,
    this.isArchived = false,
    this.certificatesEnabled = false,
    this.eventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myCertificates = ref.watch(myCertificatesStreamProvider).valueOrNull ?? [];
    final matchingCert = eventId != null
        ? myCertificates.where((c) => c.eventId == eventId).firstOrNull
        : null;

    final bannerBg = isArchived ? const Color(0xFFF1F5F9) : const Color(0xFFECFDF5);
    final bannerBorder = isArchived ? const Color(0xFFCBD5E1) : const Color(0xFFA7F3D0);
    final bannerTextColor = isArchived ? const Color(0xFF334155) : const Color(0xFF065F46);
    final bannerIcon = isArchived ? Icons.archive_rounded : Icons.check_circle_outline_rounded;
    final bannerText = isArchived
        ? 'ARCHIVED EVENT · HISTORICAL AUDIT'
        : 'EVENT CONCLUDED · GATE CLOSED';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isArchived ? const Color(0xFFCBD5E1) : const Color(0xFFA7F3D0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: bannerBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
                border: Border(bottom: BorderSide(color: bannerBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(bannerIcon, color: bannerTextColor, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      bannerText,
                      style: TextStyle(
                        color: bannerTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Event Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isArchived ? Icons.history_edu_rounded : Icons.event_available,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          eventTitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Profile Photo with Soft Ring
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isArchived ? const Color(0xFF94A3B8) : const Color(0xFF10B981),
                        width: 2.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: isArchived ? const Color(0xFF64748B) : AppColors.primaryDark,
                      backgroundImage: profilePhotoUrl.isNotEmpty
                          ? CachedNetworkImageProvider(profilePhotoUrl)
                          : null,
                      child: profilePhotoUrl.isEmpty
                          ? Text(
                              studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Student Name
                  Text(
                    studentName,
                    style: AppTextStyles.h1.copyWith(
                      color: AppColors.primaryDark,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),

                  // Student ID & Course Info
                  Text(
                    studentId,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (courseInfo.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      courseInfo,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // CONCLUDED / LOCKED QR Placeholder Area
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Dimmed matrix background
                        Opacity(
                          opacity: 0.08,
                          child: Icon(
                            Icons.qr_code_2_rounded,
                            size: 210,
                            color: Colors.grey.shade900,
                          ),
                        ),

                        // Prominent Locked Overlay per Spec Section 3.2
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.lock_clock_rounded,
                                color: Color(0xFF38BDF8),
                                size: 32,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'GATE CHECK-IN CLOSED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 1.1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'This event has concluded. Gate check-in is closed.',
                                style: TextStyle(
                                  color: Color(0xFFCBD5E1),
                                  fontSize: 12,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (isArchived)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.archive_outlined, size: 16, color: Color(0xFF475569)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This event is sealed and archived for historical audit.',
                              style: TextStyle(
                                color: Color(0xFF334155),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Certificate Claiming Action Button if available
                  if (matchingCert != null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.pushNamed(
                            'certificateDetail',
                            pathParameters: {'certificateId': matchingCert.id},
                            extra: matchingCert,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5A100),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.workspace_premium_rounded, size: 20),
                        label: const Text(
                          'Claim / Download Certificate',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ] else if (certificatesEnabled) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.workspace_premium_outlined, size: 16, color: Color(0xFFB45309)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Certificates are enabled. Your certificate will be claimable once issued.',
                              style: TextStyle(
                                color: Color(0xFF92400E),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Return to Event Details
                  if (eventId != null)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back, size: 16, color: AppColors.primary),
                        label: const Text(
                          'Back to Event Details',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
