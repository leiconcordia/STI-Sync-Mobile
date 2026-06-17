import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../widgets/registration_widgets.dart';
import '../../../../../shared/providers/providers.dart';

/// Step 3 — Create Your Password.
///
/// Captures email + password + confirmation, with live requirement chips and a
/// reassurance note about encryption.
class CredentialsStep extends ConsumerStatefulWidget {
  const CredentialsStep({super.key});

  @override
  ConsumerState<CredentialsStep> createState() => _CredentialsStepState();
}

class _CredentialsStepState extends ConsumerState<CredentialsStep> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _showPassword = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(registrationViewModelProvider);
    _email.text = s.email;
    _password.text = s.password;
    _confirm.text = s.confirmPassword;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.read(registrationViewModelProvider.notifier);
    final password =
        ref.watch(registrationViewModelProvider.select((s) => s.password));

    final hasLength = password.length >= 8;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(
            title: 'Create Your Password',
            subtitle: 'Choose a strong password to secure your STI Sync account.',
          ),
          const SizedBox(height: 24),

          RegistrationTextField(
            controller: _email,
            hint: 'Email Address *',
            icon: Icons.shield_outlined,
            keyboardType: TextInputType.emailAddress,
            onChanged: vm.setEmail,
          ),
          const SizedBox(height: 6),
          const Text(
            'Use a personal email you have access to — used for notifications '
            'and password reset.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          RegistrationTextField(
            controller: _password,
            hint: 'Create password *',
            icon: Icons.lock_outline,
            obscureText: !_showPassword,
            onChanged: vm.setPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
          const SizedBox(height: 14),

          // Live requirement chips.
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ReqChip(label: '8+ characters', met: hasLength),
              _ReqChip(label: 'Uppercase', met: hasUpper),
              _ReqChip(label: 'Number', met: hasNumber),
              _ReqChip(label: 'Special char', met: hasSpecial),
            ],
          ),
          const SizedBox(height: 20),

          RegistrationTextField(
            controller: _confirm,
            hint: 'Confirm Password *',
            icon: Icons.lock_outline,
            obscureText: !_showConfirm,
            onChanged: vm.setConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _showConfirm ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _showConfirm = !_showConfirm),
            ),
          ),
          const SizedBox(height: 20),

          // Encryption reassurance note.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F0FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.4)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined,
                    size: 20, color: AppColors.accentPurple),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your password is encrypted. STI staff will never ask for '
                    'your password.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.accentPurple,
                      height: 1.4,
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

/// Pill chip showing whether a password requirement is met.
class _ReqChip extends StatelessWidget {
  final String label;
  final bool met;

  const _ReqChip({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: met ? AppColors.success.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: met ? AppColors.success : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            size: 15,
            color: met ? AppColors.success : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: met ? AppColors.success : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
