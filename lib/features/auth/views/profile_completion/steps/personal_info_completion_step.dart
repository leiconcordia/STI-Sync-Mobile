import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/shared/providers/providers.dart';
import '../widgets/completion_widgets.dart';

class PersonalInfoCompletionStep extends ConsumerStatefulWidget {
  const PersonalInfoCompletionStep({super.key});

  @override
  ConsumerState<PersonalInfoCompletionStep> createState() =>
      _PersonalInfoCompletionStepState();
}

class _PersonalInfoCompletionStepState
    extends ConsumerState<PersonalInfoCompletionStep> {
  late final TextEditingController _contactController;

  @override
  void initState() {
    super.initState();
    final s = ref.read(profileCompletionViewModelProvider);
    _contactController = TextEditingController(text: s.contactNumber);
  }

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth(BuildContext context) async {
    final s = ref.read(profileCompletionViewModelProvider);
    final vm = ref.read(profileCompletionViewModelProvider.notifier);

    final now = DateTime.now();
    final initial = s.dateOfBirth ?? DateTime(now.year - 18, 1, 1);
    final firstDate = DateTime(now.year - 80, 1, 1);
    final lastDate = DateTime(now.year - 14, 12, 31);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : (initial.isAfter(lastDate) ? lastDate : initial),
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select your Date of Birth',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryDark,
              onPrimary: Colors.white,
              onSurface: AppColors.primaryDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      vm.setDateOfBirth(picked);
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Select Date of Birth';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
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
            title: 'Personal Information',
            subtitle:
                'Verify your official academic placement and provide your date of birth and contact number.',
          ),
          const SizedBox(height: 16),

          // Official Registrar Record Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 14, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'Registrar Verified',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      currentStudent?.standardizedAcademicLevel ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${currentStudent?.lastName ?? ''}, ${currentStudent?.firstName ?? ''} ${currentStudent?.middleName ?? ''}'.trim(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Student No: ${currentStudent?.studentId ?? '—'}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.school_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${currentStudent?.courseCode ?? ''} — ${currentStudent?.yearLevel ?? ''}',
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                const Text(
                  'Academic records are official imports from the Registrar. If any course or year level is incorrect, visit the SAO.',
                  style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Date of Birth Picker
          const FieldLabel(text: 'Date of Birth *'),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _pickDateOfBirth(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: s.dateOfBirth != null
                      ? AppColors.primaryDark
                      : Colors.grey.shade300,
                  width: s.dateOfBirth != null ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: s.dateOfBirth != null
                        ? AppColors.primaryDark
                        : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatDate(s.dateOfBirth),
                    style: TextStyle(
                      fontSize: 15,
                      color: s.dateOfBirth != null
                          ? Colors.black87
                          : Colors.grey.shade500,
                      fontWeight: s.dateOfBirth != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Contact Number Field
          const FieldLabel(text: 'Mobile Contact Number *'),
          const SizedBox(height: 8),
          CompletionTextField(
            controller: _contactController,
            hint: '9123456789',
            icon: Icons.phone_android_outlined,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            prefix: const Padding(
              padding: EdgeInsets.only(right: 6.0),
              child: Text(
                '+63 ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                  fontSize: 15,
                ),
              ),
            ),
            onChanged: vm.setContactNumber,
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter 10 digits starting with 9 (e.g. 9171234567). Used for SMS alerts and identity recovery.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
