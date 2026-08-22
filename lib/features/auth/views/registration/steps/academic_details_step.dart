import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../widgets/registration_widgets.dart';
import '../../../../../shared/providers/providers.dart';

/// Step 2 — Academic Details with Top-to-Bottom Dynamic Cascading:
/// 1. Academic Level (Tertiary vs Senior High School)
/// 2. Program / Course / Strand (Filtered by Level)
/// 3. Department (Auto-filled from Course)
/// 4. Year / Grade Level (Dynamic for College / Fixed for SHS)
/// 5. Section (Filtered by Course + Year Level)
/// 6. Semester / Term & School Year (Auto-filled)
class AcademicDetailsStep extends ConsumerStatefulWidget {
  const AcademicDetailsStep({super.key});

  @override
  ConsumerState<AcademicDetailsStep> createState() => _AcademicDetailsStepState();
}

class _AcademicDetailsStepState extends ConsumerState<AcademicDetailsStep> {
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

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final filteredCourses = state.filteredCourses;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 8, 24, bottomInset + 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(
            title: 'Academic Details',
            subtitle: 'Select your enrollment information from top to bottom.',
          ),
          const SizedBox(height: 20),

          // ── 1. Academic Level Selection ────────────────────────────────────
          const FieldLabel('Academic Level *'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _AcademicLevelCard(
                  icon: Icons.school_outlined,
                  title: 'Tertiary',
                  subtitle: 'College Degrees & Diplomas',
                  selected: state.academicLevel != 'SHS',
                  onTap: () => vm.setAcademicLevel('Tertiary'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AcademicLevelCard(
                  icon: Icons.backpack_outlined,
                  title: 'Senior High',
                  subtitle: 'Grade 11 & 12 Strands',
                  selected: state.academicLevel == 'SHS',
                  onTap: () => vm.setAcademicLevel('SHS'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // ── 2. Program / Course / Strand Selection ────────────────────────
          FieldLabel(state.isSeniorHighSchool ? 'SHS Track / Strand *' : 'College Program / Course *'),
          const SizedBox(height: 10),
          if (filteredCourses.isEmpty)
            Text(
              'No ${state.isSeniorHighSchool ? 'SHS strands' : 'college programs'} available.',
              style: const TextStyle(color: Colors.grey),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: filteredCourses.map((c) {
                final id = c['id'] as String? ?? 'Unknown';
                final code = (c['courseCode'] as String?) ?? (c['code'] as String?) ?? id;
                return _ChipOption(
                  label: code,
                  selected: state.courseCode == code,
                  onTap: () => vm.setCourse(id),
                );
              }).toList(),
            ),
          const SizedBox(height: 22),

          // ── 3. Auto-filled Department ──────────────────────────────────────
          const FieldLabel('Department'),
          const SizedBox(height: 8),
          _LockedField(
            value: state.departmentName.isEmpty
                ? (state.courseCode.isEmpty ? 'Select a program / course first' : 'Loading department...')
                : state.departmentName,
            icon: Icons.apartment_outlined,
          ),
          const SizedBox(height: 4),
          const Text(
            'Auto-resolved from your selected program / strand',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 22),

          // ── 4. Dynamic Year Level / Grade Level ────────────────────────────
          FieldLabel(state.isSeniorHighSchool ? 'Grade Level *' : 'Year Level *'),
          const SizedBox(height: 10),
          if (state.courseCode.isEmpty)
            const Text(
              'Select a program / course above to view available levels.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            )
          else
            GridView.count(
              crossAxisCount: state.availableYearLevels.length > 3 ? 2 : state.availableYearLevels.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: state.availableYearLevels.length > 3 ? 3.0 : 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: state.availableYearLevels.map((y) {
                return _SelectableCard(
                  label: y,
                  selected: state.yearLevel == y,
                  onTap: () => vm.setYearLevel(y),
                );
              }).toList(),
            ),
          const SizedBox(height: 22),

          // ── 5. Section Selection (Filtered by Course + Year Level) ────────
          const FieldLabel('Section *'),
          const SizedBox(height: 10),
          if (state.courseCode.isEmpty)
            const Text('Select a program / course first.', style: TextStyle(color: Colors.grey, fontSize: 13))
          else if (state.yearLevel.isEmpty)
            Text(
              'Select a ${state.isSeniorHighSchool ? "grade" : "year"} level above to view sections.',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            )
          else if (state.isFetchingAcademicData)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (state.availableSections.isEmpty)
            Text(
              'No sections found for ${state.courseCode} (${state.yearLevel}).',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            )
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
          const SizedBox(height: 22),

          // ── 6. Semester / Term & School Year ──────────────────────────────
          FieldLabel(state.isSeniorHighSchool ? 'Term / Trimester & School Year *' : 'Semester & School Year *'),
          const SizedBox(height: 8),
          _LockedField(
            value: state.semester.isEmpty 
                ? 'Loading active semester...' 
                : '${state.semester} (AY ${state.schoolYear})',
            icon: Icons.calendar_today_outlined,
          ),
          const SizedBox(height: 4),
          const Text(
            'Auto-filled based on the currently active academic period.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _AcademicLevelCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _AcademicLevelCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryDark : Colors.grey.shade300,
            width: selected ? 2.0 : 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? AppColors.secondary : AppColors.primaryDark,
                ),
                const Spacer(),
                if (selected)
                  const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: AppColors.secondary,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: selected ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.primaryDark : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: selected ? AppColors.secondary : Colors.grey.shade700,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryDark : Colors.grey.shade300,
            width: selected ? 2.0 : 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: selected ? AppColors.secondary : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class _LockedField extends StatelessWidget {
  final String value;
  final IconData icon;
  const _LockedField({required this.value, this.icon = Icons.apartment_outlined});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
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
