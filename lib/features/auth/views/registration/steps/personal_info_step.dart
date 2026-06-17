import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../widgets/registration_widgets.dart';
import '../../../../../shared/providers/providers.dart';

/// Step 1 — Personal Information.
class PersonalInfoStep extends ConsumerStatefulWidget {
  const PersonalInfoStep({super.key});

  @override
  ConsumerState<PersonalInfoStep> createState() => _PersonalInfoStepState();
}

class _PersonalInfoStepState extends ConsumerState<PersonalInfoStep> {
  final _lastName = TextEditingController();
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _studentId = TextEditingController();
  final _contact = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = ref.read(registrationViewModelProvider);
    _lastName.text = s.lastName;
    _firstName.text = s.firstName;
    _middleName.text = s.middleName;
    _studentId.text = s.studentId;
    _contact.text = s.contactNumber;
  }

  @override
  void dispose() {
    _lastName.dispose();
    _firstName.dispose();
    _middleName.dispose();
    _studentId.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final vm = ref.read(registrationViewModelProvider.notifier);
    final current = ref.read(registrationViewModelProvider).dateOfBirth;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(2000),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.accentPurple,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) vm.setDateOfBirth(picked);
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.read(registrationViewModelProvider.notifier);
    final dob = ref.watch(registrationViewModelProvider.select((s) => s.dateOfBirth));
    final sex = ref.watch(registrationViewModelProvider.select((s) => s.sex));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(
            title: 'Personal Information',
            subtitle: 'Enter your details exactly as they appear in your school records.',
          ),
          const SizedBox(height: 24),

          RegistrationTextField(
            controller: _lastName,
            hint: 'Last Name *',
            icon: Icons.person_outline,
            onChanged: vm.setLastName,
          ),
          const SizedBox(height: 16),
          RegistrationTextField(
            controller: _firstName,
            hint: 'First Name *',
            icon: Icons.person_outline,
            onChanged: vm.setFirstName,
          ),
          const SizedBox(height: 16),
          RegistrationTextField(
            controller: _middleName,
            hint: 'Middle Name (Optional)',
            icon: Icons.person_outline,
            onChanged: vm.setMiddleName,
          ),
          const SizedBox(height: 16),
          RegistrationTextField(
            controller: _studentId,
            hint: 'Student ID Number *',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            onChanged: vm.setStudentId,
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your official STI student ID exactly as shown on your ID card (11 digits).',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          _DateField(date: dob, onTap: _pickDate),
          const SizedBox(height: 20),

          const FieldLabel('Sex *'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SexButton(
                  label: 'Male',
                  selected: sex == 'Male',
                  onTap: () => vm.setSex('Male'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SexButton(
                  label: 'Female',
                  selected: sex == 'Female',
                  onTap: () => vm.setSex('Female'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          RegistrationTextField(
            controller: _contact,
            hint: 'Contact Number * (e.g. 9171234567)',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            onChanged: vm.setContactNumber,
          ),
          const SizedBox(height: 4),
          const Text(
            '10 digits starting with 9, no country code.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;
  const _DateField({required this.date, required this.onTap});

  String get _formatted {
    if (date == null) return 'Select date';
    final m = date!.month.toString().padLeft(2, '0');
    final d = date!.day.toString().padLeft(2, '0');
    return '$m/$d/${date!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accentPurple, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.accentPurple),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date of Birth *',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.accentPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatted,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.event, color: AppColors.primaryDark),
          ],
        ),
      ),
    );
  }
}

class _SexButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SexButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(30),
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
