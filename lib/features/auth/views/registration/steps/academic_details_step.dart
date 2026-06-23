import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../widgets/registration_widgets.dart';
import '../../../../../shared/providers/providers.dart';

/// Step 2 — Academic Details.
class AcademicDetailsStep extends ConsumerStatefulWidget {
  const AcademicDetailsStep({super.key});

  @override
  ConsumerState<AcademicDetailsStep> createState() => _AcademicDetailsStepState();
}

class _AcademicDetailsStepState extends ConsumerState<AcademicDetailsStep> {
  static const _years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];

  @override
  Widget build(BuildContext context) {
    final vm = ref.read(registrationViewModelProvider.notifier);
    final state = ref.watch(registrationViewModelProvider);

    if (state.isFetchingAcademicData && state.availableCourses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(
            title: 'Academic Details',
            subtitle: 'Select your current enrollment information for this semester.',
          ),
          const SizedBox(height: 20),

          const FieldLabel('Course *'),
          const SizedBox(height: 10),
          if (state.availableCourses.isEmpty)
            const Text('No courses available.', style: TextStyle(color: Colors.grey))
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: state.availableCourses.map((c) {
                final id = c['id'] as String? ?? 'Unknown';
                final code = (c['courseCode'] as String?) ?? (c['code'] as String?) ?? id;
                return _ChipOption(
                  label: code,
                  selected: state.courseCode == code,
                  onTap: () => vm.setCourse(id),
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
          if (state.courseCode.isEmpty)
             const Text('Select a course to view sections.', style: TextStyle(color: Colors.grey))
          else if (state.isFetchingAcademicData)
             const Padding(padding: EdgeInsets.all(8.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else if (state.availableSections.isEmpty)
             const Text('No sections found for this course.', style: TextStyle(color: Colors.grey))
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: state.availableSections.map((s) {
                final sectionName = s['name'] as String? ?? 'Unknown';
                return _ChipOption(
                  label: sectionName,
                  selected: state.section == sectionName,
                  onTap: () => vm.setSection(sectionName),
                );
              }).toList(),
            ),
          const SizedBox(height: 20),

          // Auto-filled department (read-only).
          _LockedField(
            value: state.departmentName.isEmpty
                ? 'Select a course first'
                : state.departmentName,
          ),
          const SizedBox(height: 6),
          const Text(
            'Auto-filled from your selected course',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          const FieldLabel('Semester & School Year *'),
          const SizedBox(height: 10),
          _LockedField(
            value: state.semester.isEmpty 
                ? 'Loading active semester...' 
                : '${state.semester} (AY ${state.schoolYear})',
          ),
          const SizedBox(height: 6),
          const Text(
            'Auto-filled based on the currently active semester.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ChipOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChipOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.primaryDark : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: selected ? AppColors.secondary : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

class _SelectableCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
