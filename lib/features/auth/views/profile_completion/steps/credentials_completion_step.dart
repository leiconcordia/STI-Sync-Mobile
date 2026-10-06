import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/shared/providers/providers.dart';
import '../widgets/completion_widgets.dart';

class CredentialsCompletionStep extends ConsumerStatefulWidget {
  const CredentialsCompletionStep({super.key});

  @override
  ConsumerState<CredentialsCompletionStep> createState() =>
      _CredentialsCompletionStepState();
}

class _CredentialsCompletionStepState
    extends ConsumerState<CredentialsCompletionStep> {
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final s = ref.read(profileCompletionViewModelProvider);
    _passwordController = TextEditingController(text: s.newPassword);
    _confirmController = TextEditingController(text: s.confirmPassword);
    _emailController = TextEditingController(text: s.personalEmail);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(profileCompletionViewModelProvider);
    final vm = ref.read(profileCompletionViewModelProvider.notifier);
    final currentStudent = ref.watch(authViewModelProvider).student;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Password strength calculation
    final pwd = s.newPassword;
    int strengthScore = 0;
    if (pwd.length >= 8) strengthScore++;
    if (RegExp(r'[A-Z]').hasMatch(pwd)) strengthScore++;
    if (RegExp(r'[0-9]').hasMatch(pwd)) strengthScore++;
    if (RegExp(r'[!@#\$&*~%^()_+=|<>?{}\[\]-]').hasMatch(pwd)) strengthScore++;

    Color strengthColor = Colors.grey.shade300;
    String strengthText = 'Too weak';
    if (pwd.isEmpty) {
      strengthColor = Colors.grey.shade300;
      strengthText = 'Enter password';
    } else if (strengthScore <= 1) {
      strengthColor = AppColors.error;
      strengthText = 'Weak';
    } else if (strengthScore == 2) {
      strengthColor = Colors.orange;
      strengthText = 'Fair';
    } else if (strengthScore >= 3) {
      strengthColor = AppColors.success;
      strengthText = 'Strong';
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 8, 24, bottomInset + 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(
            title: 'Set Your Credentials',
            subtitle:
                'Replace your temporary registrar password with your permanent private password and personal recovery email.',
          ),
          const SizedBox(height: 16),

          // Security guidance banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined,
                    color: AppColors.primaryDark, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Welcome, ${currentStudent?.firstName ?? 'Student'}! Your account was pre-registered by the Registrar. Please secure your account to continue.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryDark,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // New Password Field
          const FieldLabel(text: 'New Password *'),
          const SizedBox(height: 8),
          CompletionTextField(
            controller: _passwordController,
            hint: 'Min. 8 characters (Uppercase & Number)',
            icon: Icons.lock_outline,
            obscureText: !s.isPasswordVisible,
            suffixIcon: IconButton(
              icon: Icon(
                s.isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: vm.togglePasswordVisibility,
            ),
            onChanged: vm.setNewPassword,
          ),
          const SizedBox(height: 8),

          // Password Strength Bar
          if (pwd.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pwd.isEmpty ? 0 : (strengthScore / 4).clamp(0.2, 1.0),
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                      minHeight: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  strengthText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: strengthColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          const Text(
            'Must be at least 8 characters with 1 uppercase letter and 1 number or symbol.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Confirm Password Field
          const FieldLabel(text: 'Confirm New Password *'),
          const SizedBox(height: 8),
          CompletionTextField(
            controller: _confirmController,
            hint: 'Re-enter your new password',
            icon: Icons.lock_reset_outlined,
            obscureText: !s.isConfirmPasswordVisible,
            suffixIcon: IconButton(
              icon: Icon(
                s.isConfirmPasswordVisible
                    ? Icons.visibility
                    : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: vm.toggleConfirmPasswordVisibility,
            ),
            onChanged: vm.setConfirmPassword,
          ),
          if (s.confirmPassword.isNotEmpty && s.newPassword != s.confirmPassword) ...[
            const SizedBox(height: 6),
            const Text(
              'Passwords do not match.',
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 24),

          // Personal Email Field
          const FieldLabel(text: 'Personal Email Address *'),
          const SizedBox(height: 8),
          CompletionTextField(
            controller: _emailController,
            hint: 'e.g. name@gmail.com or outlook.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            onChanged: vm.setPersonalEmail,
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter an active personal email for password resets and official school notifications. Do not use the provisional @student.sti.edu email.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
