import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/features/auth/models/student_model.dart';
import '../models/semester_model.dart';
import '../viewmodels/re_enrollment_viewmodel.dart';

class ReEnrollmentBottomSheet extends ConsumerStatefulWidget {
  final StudentModel student;
  final SemesterModel activeSemester;

  const ReEnrollmentBottomSheet({
    super.key,
    required this.student,
    required this.activeSemester,
  });

  static Future<void> show(
    BuildContext context, {
    required StudentModel student,
    required SemesterModel activeSemester,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReEnrollmentBottomSheet(
        student: student,
        activeSemester: activeSemester,
      ),
    );
  }

  @override
  ConsumerState<ReEnrollmentBottomSheet> createState() =>
      _ReEnrollmentBottomSheetState();
}

class _ReEnrollmentBottomSheetState
    extends ConsumerState<ReEnrollmentBottomSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(reEnrollmentViewModelProvider.notifier)
          .init(widget.student, widget.activeSemester);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reEnrollmentViewModelProvider);
    final notifier = ref.read(reEnrollmentViewModelProvider.notifier);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header Icon & Title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: AppColors.secondary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to ${widget.activeSemester.semester}!',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.primaryDark,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'A.Y. ${widget.activeSemester.academicYear}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Please confirm your enrollment and section for this semester before ${widget.activeSemester.formattedDeadline}.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey.shade700,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Error banner if any
            if (state.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 1. Academic Year & Term (Locked)
            _buildFieldLabel('Academic Year & Term (Active Semester)'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${widget.activeSemester.academicYear} · ${widget.activeSemester.semester}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Year Level Selection
            _buildFieldLabel('Year Level'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: state.selectedYearLevel.isNotEmpty
                      ? state.selectedYearLevel
                      : '1st Year',
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryDark),
                  items: ReEnrollmentViewModel.yearLevels.map((lvl) {
                    return DropdownMenuItem<String>(
                      value: lvl,
                      child: Text(
                        lvl,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryDark),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) notifier.setYearLevel(val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Course & Section Selection
            _buildFieldLabel('Course & Section'),
            if (state.isLoadingSections)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (state.sections.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: state.sections.contains(state.selectedSection)
                        ? state.selectedSection
                        : state.sections.first,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryDark),
                    items: state.sections.map((sec) {
                      return DropdownMenuItem<String>(
                        value: sec,
                        child: Text(
                          sec,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryDark),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) notifier.setSection(val);
                    },
                  ),
                ),
              )
            else
              TextFormField(
                initialValue: state.selectedSection,
                onChanged: notifier.setSection,
                decoration: InputDecoration(
                  hintText: 'Enter your section (e.g. BSIT 2101)',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),

                ),
              ),
            const SizedBox(height: 20),

            // 4. Confirmation Checkbox
            InkWell(
              onTap: () => notifier.setConfirmed(!state.isConfirmed),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: state.isConfirmed
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: state.isConfirmed,
                      activeColor: AppColors.primary,
                      onChanged: (val) => notifier.setConfirmed(val ?? false),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Text(
                          'I confirm that I am officially enrolled for this semester and my section details are accurate.',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 5. Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: state.isSubmitting
                    ? null
                    : () async {
                        final success = await notifier.submit(
                          widget.student,
                          widget.activeSemester,
                        );
                        if (success && context.mounted) {
                          Navigator.of(context).pop();
                          _showSuccessDialog(context);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Confirm Re-enrollment',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 56,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Re-enrollment Confirmed!',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.primaryDark,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You have full access to events, attendance, and QR tickets for ${widget.activeSemester.semester} (A.Y. ${widget.activeSemester.academicYear}).',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey.shade700,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Awesome'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
