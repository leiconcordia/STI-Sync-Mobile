import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/core/utils/date_formatter.dart';

class CancelledQrCard extends StatelessWidget {
  final String eventTitle;
  final String studentName;
  final String studentId;
  final String profilePhotoUrl;
  final String courseInfo;
  final String? cancellationReason;
  final String? refundPolicy;
  final DateTime? cancelledAt;

  const CancelledQrCard({
    super.key,
    required this.eventTitle,
    required this.studentName,
    required this.studentId,
    required this.profilePhotoUrl,
    required this.courseInfo,
    this.cancellationReason,
    this.refundPolicy,
    this.cancelledAt,
  });

  String _formatRefundPolicy(String? policy) {
    switch (policy) {
      case 'refund_cash':
        return 'Full Cash Refund';
      case 'credit_next_event':
        return 'Credited to Next Event';
      case 'no_fees_collected':
        return 'Free Event / No Fees';
      default:
        return 'Refund In Progress';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.red.shade200, width: 1.5),
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
            // Top Danger Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
                border: Border(bottom: BorderSide(color: Colors.red.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel_rounded, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'EVENT CANCELLED · PASS REVOKED',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.8,
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
                      Icon(Icons.event_busy, color: Colors.grey.shade600, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          eventTitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Student Profile Photo
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red.shade300, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: profilePhotoUrl.isNotEmpty
                          ? CachedNetworkImageProvider(profilePhotoUrl)
                          : null,
                      child: profilePhotoUrl.isEmpty
                          ? Text(
                              studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
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
                    style: AppTextStyles.h2.copyWith(
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

                  // VOIDED QR Placeholder Area
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Dimmed matrix background
                        Opacity(
                          opacity: 0.1,
                          child: Icon(
                            Icons.qr_code_2_rounded,
                            size: 200,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        // VOID Stamp
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.block_flipped, color: Colors.white, size: 28),
                              SizedBox(height: 6),
                              Text(
                                'QR VOIDED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'EVENT CANCELLED',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Pass revoked. Campus scanners will reject this ticket.',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // Cancellation Reason & Policy Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: Colors.red.shade800),
                            const SizedBox(width: 6),
                            Text(
                              'Official Notice',
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        if (cancellationReason != null && cancellationReason!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            cancellationReason!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.red.shade900,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                        if (cancelledAt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Date: ${formatAppDateTime(cancelledAt)}',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Divider(color: Colors.red.shade100, height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Refund Policy:',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Text(
                                _formatRefundPolicy(refundPolicy),
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
