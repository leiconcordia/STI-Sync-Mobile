import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../viewmodels/registration_viewmodel.dart';
import '../widgets/registration_widgets.dart';

/// Step 2 — Academic Details.
///
/// Course selection (chips), year level (cards), section input, an auto-filled
/// department field, and semester selection.
class AcademicDetailsStep extends ConsumerStatefulWidget {
  const AcademicDetailsStep({super.key});

  @override
  ConsumerState<AcademicDetailsStep> createState() =>
      _AcademicDetailsStepState();
}

class _AcademicDetailsStepState extends ConsumerState<AcademicDetailsStep> {
  static const _courses = ['BSIT', 'BSCS', 'BSCE', 'BSED', 'BSA', 'BSBA'];
  static const _years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
  static const _semesters = ['1st Semester', '2nd Semester'];

  final _section = TextEditingController();

  @override
  void initState() {
    super.initState();
    _section.text = ref.read(registrationViewModelProvider).section;
  }

  @override
  void dispose() {
    _section.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.read(registrationViewModelProvider.notifier);
    final state = ref.watch(registrationViewModelProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(
            title: 'Academic Details',
            subtitle:
                'Select your current enrollment information for this semester.',
          ),
          const SizedBox(height: 20),

          const FieldLabel('Course *'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _courses.map((c) {
              return _ChipOption(
                label: c,
                selected: state.course == c,
                onTap: () => vm.setCourse(c),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          const FieldLabel('Year Level *'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            children: _years.map((y) {
              return _SelectableCard(
                label: y,
                selected: state.yearLevel == y,
                onTap: () => vm.setYearLevel(y),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          const FieldLabel('Section *'),
          const SizedBox(height: 10),
          RegistrationTextField(
            controller: _section,
            hint: 'e.g. BSIT-2A',
            icon: Icons.groups_outlined,
            onChanged: vm.setSection,
          ),
          const SizedBox(height: 16),

          // Auto-filled department (read-only, locked).
          _LockedField(
            value: state.department.isEmpty
                ? 'Select a course first'
                : state.department,
          ),
          const SizedBox(height: 6),
          const Text(
            'Auto-filled from your selected course',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          const FieldLabel('Semester *'),
          const SizedBox(height: 10),
          Column(
            children: _semesters.map((s) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SelectableCard(
                  label: s,
                  selected: state.semester == s,
                  onTap: () => vm.setSemester(s),
                  fullWidth: true,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
/// Rounded chip used for course selection (purple when selected).
class _ChipOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChipOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentPurple : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.accentPurple : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

/// Outlined card used for year level / semester selection (navy when selected).
class _SelectableCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool fullWidth;

  const _SelectableCard({
    required this.label,
    required this.selected,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: fullWidth ? double.infinity : null,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryDark : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: selected ? AppColors.secondary : Colors.grey,
          ),
        ),
      ),
    );
  }
}

/// Greyed, lock-iconed read-only field for the auto-filled department.
class _LockedField extends StatelessWidget {
  final String value;
  const _LockedField({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.apartment_outlined, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
        ],
      ),
    );
  }
}
