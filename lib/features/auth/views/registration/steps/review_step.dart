import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../widgets/registration_widgets.dart';
import '../../../../../shared/providers/providers.dart';

/// Step 6 — Review Your Registration.
///
/// Read-back summary card, an accuracy confirmation checkbox, and an
/// "After You Submit" timeline. Tapping any reviewable row jumps back to the
/// owning step for editing.
class ReviewStep extends ConsumerWidget {
  const ReviewStep({super.key});

  /// Formats the stored date of birth as YYYY-MM-DD, or a dash if unset.
  String _formatDob(DateTime? dob) {
    if (dob == null) return '—';
    final m = dob.month.toString().padLeft(2, '0');
    final d = dob.day.toString().padLeft(2, '0');
    return '${dob.year}-$m-$d';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(registrationViewModelProvider.notifier);
    final s = ref.watch(registrationViewModelProvider);

    String orDash(String v) => v.trim().isEmpty ? '—' : v;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(
            title: 'Review Your Registration',
            subtitle: 'Check everything carefully. Tap any field to go back '
                'and edit.',
          ),
          const SizedBox(height: 20),

          // Identity header card.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.firstName.isEmpty && s.lastName.isEmpty
                            ? 'Your Name'
                            : '${s.firstName} ${s.lastName}'.trim(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        orDash(s.studentId),
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        orDash(s.courseCode),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Editable summary rows.
          _ReviewCard(
            rows: [
              _ReviewRow(
                label: 'Full Name',
                value: s.firstName.isEmpty ? '—' : s.displayFullName,
                onTap: () => vm.goToStep(0),
              ),
              _ReviewRow(
                label: 'Student ID',
                value: orDash(s.studentId),
                onTap: () => vm.goToStep(0),
              ),
              _ReviewRow(
                label: 'Date of Birth',
                value: _formatDob(s.dateOfBirth),
                onTap: () => vm.goToStep(0),
              ),
              _ReviewRow(
                label: 'Sex',
                value: orDash(s.sex),
                onTap: () => vm.goToStep(0),
              ),
              _ReviewRow(
                label: 'Contact',
                value: orDash(s.contactNumber),
                onTap: () => vm.goToStep(0),
              ),
              _ReviewRow(
                label: 'Email',
                value: orDash(s.email),
                onTap: () => vm.goToStep(2),
              ),
              _ReviewRow(
                label: 'Course',
                value: orDash(s.courseCode),
                onTap: () => vm.goToStep(1),
              ),
              _ReviewRow(
                label: 'Year Level',
                value: orDash(s.yearLevel),
                onTap: () => vm.goToStep(1),
              ),
              _ReviewRow(
                label: 'Section',
                value: orDash(s.section),
                onTap: () => vm.goToStep(1),
              ),
              _ReviewRow(
                label: 'Department',
                value: orDash(s.departmentName),
                editable: false,
              ),
              _ReviewRow(
                label: 'Semester',
                value: orDash(s.semester),
                onTap: () => vm.goToStep(1),
              ),
              _ReviewRow(
                label: 'Profile Photo',
                value: s.profilePhotoFile != null ? 'Uploaded' : 'Not uploaded',
                ok: s.profilePhotoFile != null,
                onTap: () => vm.goToStep(3),
              ),
              _ReviewRow(
                label: 'School ID',
                value: s.schoolIdFile != null ? 'Uploaded' : 'Not uploaded',
                ok: s.schoolIdFile != null,
                onTap: () => vm.goToStep(4),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Accuracy confirmation.
          GestureDetector(
            onTap: () => vm.setConfirmedAccuracy(!s.confirmedAccuracy),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F0FA),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.accentPurple.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    s.confirmedAccuracy
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: AppColors.accentPurple,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'I confirm that all information I provided is accurate and '
                      'truthful. I understand that providing false information '
                      'may result in permanent rejection of my registration.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // After You Submit timeline.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE08A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.info_outline, size: 18, color: Color(0xFFE0A100)),
                    SizedBox(width: 8),
                    Text(
                      'After You Submit',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE0A100),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...[
                  'Registration enters SAO review queue',
                  'SAO Adviser verifies your identity (1–3 working days)',
                  "You'll be notified: Approved / Correction Needed / Rejected",
                  'Once approved — log in and access all features',
                ].asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${e.key + 1}. ',
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                e.value,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primaryDark,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
/// White card grouping the editable review rows with hairline dividers.
class _ReviewCard extends StatelessWidget {
  final List<_ReviewRow> rows;
  const _ReviewCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(children: rows),
    );
  }
}

/// A single label/value review row. Tappable rows jump to the owning step;
/// a trailing check (purple) marks confirmed fields, red text marks missing
/// uploads.
class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool editable;
  final bool isLast;

  /// When non-null, drives the trailing indicator: true = purple check,
  /// false = red "missing" styling. Null = plain check for filled text fields.
  final bool? ok;

  const _ReviewRow({
    required this.label,
    required this.value,
    this.onTap,
    this.editable = true,
    this.isLast = false,
    this.ok,
  });

  @override
  Widget build(BuildContext context) {
    final isMissing = ok == false;

    return InkWell(
      onTap: editable ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isMissing ? AppColors.error : AppColors.primaryDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (!isMissing && editable)
              const Icon(Icons.check, size: 16, color: AppColors.accentPurple)
            else
              const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
