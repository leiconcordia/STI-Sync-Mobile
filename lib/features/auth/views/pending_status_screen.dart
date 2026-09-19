import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/student_model.dart';
import '../../../shared/providers/providers.dart';

class PendingStatusScreen extends ConsumerWidget {
  const PendingStatusScreen({super.key});

  void _handleRegisterAgain(BuildContext context, WidgetRef ref, StudentModel student) {
    // 1. Populate the registration view model with the existing student data.
    ref.read(registrationViewModelProvider.notifier).populateFromStudent(student);
    
    // 2. Navigate to the registration flow
    context.pushNamed('register');
  }

  void _handleLogOut(WidgetRef ref) {
    ref.read(authViewModelProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final student = authState.pendingStudent ?? authState.student;

    if (student == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryDark)),
      );
    }

    final isReturned = student.status == 'RETURNED';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Section (Dark Navy)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/STI_SYNC_LOGO.jpg',
                          height: 32,
                          width: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.sync,
                            size: 32,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'STI Sync',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Status Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: (isReturned ? AppColors.error : AppColors.secondary).withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isReturned
                          ? Icons.assignment_return_outlined
                          : Icons.hourglass_top_rounded,
                      color: isReturned
                          ? const Color(0xFFFF6B6B)
                          : AppColors.secondary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    isReturned
                        ? 'Application Returned'
                        : 'Account Under Review',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isReturned
                        ? 'Please update the requested document to proceed'
                        : 'SAO staff will verify your registration within 1-2 days',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            
            // Middle Section (Timeline & Info)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Timeline Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          _TimelineStep(
                            icon: Icons.check_circle,
                            iconColor: AppColors.success,
                            title: 'Registration Submitted',
                            subtitle: formatAppDateTime(student.createdAt),
                            isLast: false,
                          ),
                          _TimelineStep(
                            icon: isReturned
                                ? Icons.cancel
                                : Icons.access_time_filled,
                            iconColor: isReturned
                                ? AppColors.error
                                : AppColors.secondary,
                            title: isReturned
                                ? 'Application Returned'
                                : 'SAO Review In Progress',
                            subtitle: isReturned
                                ? 'Action required — see details below'
                                : 'Under manual inspection by SAO staff',
                            isLast: false,
                          ),
                          _TimelineStep(
                            icon: null, // Shows number '3'
                            iconColor: Colors.grey.shade400,
                            title: 'Account Activated',
                            subtitle: 'Pending verification',
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Categorized Rejection or Under Review Card
                    if (student.rejectionReason != null && student.rejectionReason!.isNotEmpty)
                      _buildGuidanceCard(student.rejectionReason!, isReturned),

                    // Full History of Revisions and Comments
                    if (student.revisionHistory.isNotEmpty)
                      _buildRevisionHistoryCard(student.revisionHistory),
                  ],
                ),
              ),
            ),
            
            // Bottom Action Area
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isReturned)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleRegisterAgain(context, ref, student),
                        icon: const Icon(Icons.edit_document, size: 20),
                        label: const Text(
                          'Update & Resubmit',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Status is up to date.'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.sync),
                        label: const Text(
                          'Check Status',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryDark,
                          side: const BorderSide(color: AppColors.primaryDark),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (!isReturned)
                    const Text(
                      'Last checked: just now',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _handleLogOut(ref),
                    child: const Text(
                      'Log Out',
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
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

  Widget _buildGuidanceCard(String rawReason, bool isReturned) {
    // Strip technical prefixes if legacy strings exist
    final cleanReason = rawReason
        .replaceAll(RegExp(r'^AI Verification Returned:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^AI Flagged for Admin Review:\s*', caseSensitive: false), '')
        .trim();

    final lower = cleanReason.toLowerCase();
    IconData icon = Icons.info_outline;
    String header = isReturned ? 'Verification Note' : 'Review Status';
    String actionTip = '';
    Color themeColor = isReturned ? AppColors.error : AppColors.primaryDark;

    if (lower.contains('blur') || lower.contains('glare') || lower.contains('focus') || lower.contains('illegible')) {
      icon = Icons.camera_alt_outlined;
      header = 'Photo is Blurry or Has Glare';
      actionTip = 'Lay your ID flat on a table under clear lighting without camera flash glare, and ensure text is in sharp focus.';
    } else if (lower.contains('sti') && (lower.contains('not') || lower.contains('unrecognized') || lower.contains('valid'))) {
      icon = Icons.badge_outlined;
      header = 'Document Not Recognized as STI ID';
      actionTip = 'Please upload your official STI Student ID Card (Front) or STI Certificate of Registration (COR).';
    } else if (lower.contains('name') && (lower.contains('match') || lower.contains('spelling') || lower.contains('different'))) {
      icon = Icons.person_search_outlined;
      header = 'Name Mismatch Detected';
      actionTip = 'Make sure the first and last name entered during registration exactly match the name printed on your school ID.';
    } else if (lower.contains('selfie') || lower.contains('face')) {
      icon = Icons.face_retouching_natural_outlined;
      header = 'Clear Selfie Required';
      actionTip = 'Take a clear front-facing selfie in good light. Ensure your face is centered and remove caps, sunglasses, or masks.';
    } else {
      actionTip = isReturned
          ? 'Please review your uploaded photos and ensure all information is clear and authentic.'
          : 'Your registration has been submitted and is currently being verified by SAO staff.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: themeColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: themeColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  header,
                  style: TextStyle(
                    color: themeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            cleanReason,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (actionTip.isNotEmpty && isReturned) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: themeColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFFE0A100)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      actionTip,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRevisionHistoryCard(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_edu, size: 20, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              Text(
                'Revision History (${history.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.8),
          const SizedBox(height: 12),
          ...history.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final revNum = item['revisionNumber'] ?? (idx + 1);
            final status = item['status']?.toString().toUpperCase() ?? 'RETURNED';
            final reason = item['reason']?.toString() ?? 'No comment provided.';
            final rawTime = item['timestamp']?.toString();
            final reviewedBy = item['reviewedBy'] == 'AI_VERIFICATION'
                ? 'AI Verification'
                : 'Adviser / SAO Staff';

            Color badgeColor;
            if (status == 'ACTIVE') {
              badgeColor = AppColors.success;
            } else if (status == 'RETURNED') {
              badgeColor = AppColors.error;
            } else {
              badgeColor = Colors.amber.shade800;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: badgeColor, width: 1.2),
                    ),
                    child: Text(
                      '$revNum',
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Revision #$revNum ($reviewedBy)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reason,
                          style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                        ),
                        if (rawTime != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            rawTime.contains('T') ? rawTime.split('T').first : rawTime,
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final IconData? icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isLast;

  const _TimelineStep({
    this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: icon == null ? Colors.grey.shade200 : Colors.transparent,
              ),
              child: icon != null
                  ? Icon(icon, color: iconColor, size: 24)
                  : Center(
                      child: Text(
                        '3',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: iconColor,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: icon == null ? Colors.grey.shade500 : AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: icon == null ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              if (!isLast) const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}
