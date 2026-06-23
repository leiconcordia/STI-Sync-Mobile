import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
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
    final student = authState.pendingStudent;

    if (student == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryDark)),
      );
    }

    final isReturned = student.status == 'RETURNED';
    
    // Derived registration number: REG-YYYY-XXXX (where XXXX is first 4 of doc ID, uppercase)
    final year = student.createdAt.year.toString();
    final docIdChars = student.id.length >= 4 ? student.id.substring(0, 4).toUpperCase() : student.id.toUpperCase();
    final regNumber = 'REG-$year-$docIdChars';

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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                  const SizedBox(height: 32),
                  
                  // Status Icon
                  Icon(
                    isReturned ? Icons.error_outline : Icons.access_time,
                    color: isReturned ? AppColors.error : AppColors.secondary,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    isReturned ? 'Application Returned' : 'Account Under Review',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Reg Number
                  Text(
                    regNumber,
                    style: TextStyle(
                      color: isReturned ? AppColors.error : AppColors.secondary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
                            subtitle: DateFormat('MMMM d, yyyy - h:mm a').format(student.createdAt),
                            isLast: false,
                          ),
                          _TimelineStep(
                            icon: isReturned ? Icons.cancel : Icons.access_time_filled,
                            iconColor: isReturned ? AppColors.error : AppColors.secondary,
                            title: isReturned ? 'Application Returned' : 'SAO Review In Progress',
                            subtitle: isReturned ? 'Action required' : 'Usually 1–3 working days',
                            isLast: false,
                          ),
                          _TimelineStep(
                            icon: null, // Shows number '3'
                            iconColor: Colors.grey.shade400,
                            title: 'Account Activated',
                            subtitle: 'Pending',
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Info Banner or Rejection Card
                    if (isReturned && student.rejectionReason != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Reason for Return',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              student.rejectionReason!,
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.accentPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.notifications_active, color: AppColors.accentPurple, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "You'll receive a notification at your email the moment a decision is made.",
                                style: TextStyle(color: AppColors.accentPurple),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _handleRegisterAgain(context, ref, student),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'Register Again',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Note: The UI is already reactive to the stream.
                          // This is mostly for user feel.
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
                  const SizedBox(height: 16),
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
