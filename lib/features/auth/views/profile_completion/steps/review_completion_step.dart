import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/shared/providers/providers.dart';
import '../widgets/completion_widgets.dart';

class ReviewCompletionStep extends ConsumerWidget {
  const ReviewCompletionStep({super.key});

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(profileCompletionViewModelProvider);
    final vm = ref.read(profileCompletionViewModelProvider.notifier);
    final currentStudent = ref.watch(authViewModelProvider).student;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 8, 24, bottomInset + 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(
            title: 'Review & Activate Account',
            subtitle:
                'Review your details carefully. Tap any section if you need to make changes.',
          ),
          const SizedBox(height: 16),

          // Official Identity Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  backgroundImage: s.profilePhotoFile != null
                      ? FileImage(s.profilePhotoFile!)
                      : null,
                  child: s.profilePhotoFile == null
                      ? const Icon(Icons.person, color: Colors.white, size: 30)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${currentStudent?.firstName ?? ''} ${currentStudent?.lastName ?? ''}'.trim(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${currentStudent?.studentId ?? '—'}',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${currentStudent?.courseCode ?? ''} (${currentStudent?.yearLevel ?? ''})',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Detailed Review Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                _ReviewTile(
                  icon: Icons.lock_outline,
                  label: 'Account Password',
                  value: '•••••••• (Updated)',
                  onTap: () => vm.setStep(0),
                ),
                const Divider(height: 1),
                _ReviewTile(
                  icon: Icons.email_outlined,
                  label: 'Personal Email',
                  value: s.personalEmail.isEmpty ? '—' : s.personalEmail,
                  onTap: () => vm.setStep(0),
                ),
                const Divider(height: 1),
                _ReviewTile(
                  icon: Icons.cake_outlined,
                  label: 'Date of Birth',
                  value: _formatDate(s.dateOfBirth),
                  onTap: () => vm.setStep(1),
                ),
                const Divider(height: 1),
                _ReviewTile(
                  icon: Icons.phone_android_outlined,
                  label: 'Contact Number',
                  value: s.contactNumber.isEmpty ? '—' : '+63 ${s.contactNumber}',
                  onTap: () => vm.setStep(1),
                ),
                const Divider(height: 1),
                _ReviewTile(
                  icon: Icons.face_outlined,
                  label: 'Profile Photo',
                  value: s.profilePhotoFile != null ? 'Attached' : 'Missing',
                  isSuccess: s.profilePhotoFile != null,
                  onTap: () => vm.setStep(2),
                ),
                const Divider(height: 1),
                _ReviewTile(
                  icon: Icons.badge_outlined,
                  label: 'School ID Card',
                  value: s.schoolIdPhotoFile != null ? 'Attached' : 'Missing',
                  isSuccess: s.schoolIdPhotoFile != null,
                  onTap: () => vm.setStep(2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Accuracy Confirmation Checkbox
          InkWell(
            onTap: () => vm.setConfirmedAccuracy(!s.confirmedAccuracy),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: s.confirmedAccuracy
                    ? AppColors.success.withValues(alpha: 0.08)
                    : const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: s.confirmedAccuracy
                      ? AppColors.success.withValues(alpha: 0.3)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: s.confirmedAccuracy,
                    activeColor: AppColors.primaryDark,
                    onChanged: (val) => vm.setConfirmedAccuracy(val ?? false),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'I certify that I am the official student identified in this record. The password, email, and photos provided are accurate and belong to me.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryDark,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Submission error banner if any
          if (s.submitError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.submitError!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
}

class _ReviewTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool? isSuccess;
  final VoidCallback onTap;

  const _ReviewTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isSuccess,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primaryDark, size: 22),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isSuccess == null
              ? Colors.black87
              : (isSuccess! ? AppColors.success : AppColors.error),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
    );
  }
}
