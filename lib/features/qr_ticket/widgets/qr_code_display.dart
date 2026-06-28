import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import '../models/qr_ticket_model.dart';

class QrCodeDisplay extends StatelessWidget {
  final QrTicketModel ticket;

  const QrCodeDisplay({super.key, required this.ticket});

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
                    ticket.eventTitle,
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
                child: ticket.profilePhotoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: ticket.profilePhotoUrl,
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
              ticket.studentName.isNotEmpty ? ticket.studentName : 'Student',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              ticket.studentId.isNotEmpty ? ticket.studentId : '-',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              ticket.courseInfo.isNotEmpty ? ticket.courseInfo : 'Course Info',
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade200, height: 1, indent: 32, endIndent: 32),
            const SizedBox(height: 24),
            // QR Code (tappable to expand)
            GestureDetector(
              onTap: () => _showExpandedQr(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: ticket.toQrPayload(),
                  version: QrVersions.auto,
                  size: 200,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scan to verify attendance',
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade200, height: 1, indent: 32, endIndent: 32),
            const SizedBox(height: 16),
            // Footer: Valid badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'VALID',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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

  void _showExpandedQr(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
          backgroundColor: Colors.black87,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: QrImageView(
                    data: ticket.toQrPayload(),
                    version: QrVersions.auto,
                    size: 260,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF001A4D),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF001A4D),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  ticket.studentName,
                  style: AppTextStyles.h2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  ticket.studentId,
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  ticket.eventTitle,
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Text(
                  'Tap anywhere to close',
                  style: AppTextStyles.labelSmall.copyWith(color: Colors.white38),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
