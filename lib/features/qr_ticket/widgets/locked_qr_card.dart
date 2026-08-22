import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/core/utils/currency_formatter.dart';
import 'package:sti_sync/shared/providers/providers.dart';
import 'package:sti_sync/features/semester/widgets/re_enrollment_bottom_sheet.dart';

class LockedQrCard extends ConsumerWidget {
  final double amountDue;
  final String paymentStatus;
  final String eventTitle;
  final String studentName;
  final String studentId;
  final String profilePhotoUrl;
  final String? lockReason;

  const LockedQrCard({
    super.key,
    required this.amountDue,
    required this.paymentStatus,
    required this.eventTitle,
    required this.studentName,
    required this.studentId,
    required this.profilePhotoUrl,
    this.lockReason,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isReEnrollment =
        paymentStatus.toUpperCase() == 'RE_ENROLLMENT_REQUIRED';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Header: Event Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_note, color: AppColors.primaryDark, size: 24),
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
            const SizedBox(height: 24),
            // Centered Profile Photo in circle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isReEnrollment ? AppColors.secondary : AppColors.error,
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primaryDark,
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
            const SizedBox(height: 16),
            // Student Name
            Text(
              studentName,
              style: AppTextStyles.h1.copyWith(
                color: AppColors.primaryDark,
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            // Student ID Number
            Text(
              studentId,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade200, height: 1, indent: 32, endIndent: 32),
            const SizedBox(height: 24),
            
            // Locked Notice Section (Re-enrollment or Unpaid Fee)
            if (isReEnrollment)
              _buildReEnrollmentLock(context, ref)
            else
              _buildPaymentLock(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildReEnrollmentLock(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7), // Warm amber background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pending_actions_rounded,
              size: 36,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Re-enrollment Required',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lockReason ??
                'Please complete your semester re-enrollment confirmation to unlock your event QR tickets.',
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.grey.shade800,
              fontSize: 12,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                final student = ref.read(authViewModelProvider).student;
                final activeSemester = ref.read(activeSemesterModelProvider).valueOrNull;
                if (student != null && activeSemester != null) {
                  ReEnrollmentBottomSheet.show(
                    context,
                    student: student,
                    activeSemester: activeSemester,
                  );
                }
              },
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text(
                'Complete Re-enrollment',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentLock() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.lock, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'QR Locked',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Payment Required',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatCurrency(amountDue),
            style: AppTextStyles.h1.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              paymentStatus.toUpperCase(),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.error.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'See the SAO or Club Officer to pay',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
