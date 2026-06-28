import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';

class LockedQrCard extends StatelessWidget {
  final double amountDue;
  final String paymentStatus;
  final String eventTitle;
  final String studentName;
  final String studentId;
  final String profilePhotoUrl;

  const LockedQrCard({
    super.key,
    required this.amountDue,
    required this.paymentStatus,
    required this.eventTitle,
    required this.studentName,
    required this.studentId,
    required this.profilePhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
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
            // Header: STI College
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
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: ClipOval(
                child: profilePhotoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: profilePhotoUrl,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _buildAvatarPlaceholder(),
                        errorWidget: (context, url, error) => _buildAvatarPlaceholder(),
                      )
                    : _buildAvatarPlaceholder(),
              ),
            ),
            const SizedBox(height: 16),
            // Student Info
            Text(
              studentName.isNotEmpty ? studentName : 'Student',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              studentId.isNotEmpty ? studentId : '-',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade200, height: 1, indent: 32, endIndent: 32),
            const SizedBox(height: 24),
            
            // Payment Required Section (replacing QR)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
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
                    '₱${amountDue.toStringAsFixed(2)}',
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
                      color: AppColors.error.withOpacity(0.1),
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
                  Divider(color: AppColors.error.withOpacity(0.2), height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'See the SAO Adviser to pay',
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
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 120,
      height: 120,
      color: Colors.grey.shade200,
      child: const Icon(Icons.person, size: 60, color: Colors.grey),
    );
  }
}
