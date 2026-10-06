import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/shared/providers/providers.dart';
import 'steps/credentials_completion_step.dart';
import 'steps/personal_info_completion_step.dart';
import 'steps/identity_photos_completion_step.dart';
import 'steps/review_completion_step.dart';

const List<String> _stepTitles = [
  'Security & Email',
  'Personal Details',
  'Identity Photos',
  'Review & Activate',
];

class ProfileCompletionFlowScreen extends ConsumerWidget {
  const ProfileCompletionFlowScreen({super.key});

  static const List<Widget> _steps = [
    CredentialsCompletionStep(),
    PersonalInfoCompletionStep(),
    IdentityPhotosCompletionStep(),
    ReviewCompletionStep(),
  ];

  Future<void> _handleNext(BuildContext context, WidgetRef ref) async {
    final vm = ref.read(profileCompletionViewModelProvider.notifier);
    final s = ref.read(profileCompletionViewModelProvider);
    final authState = ref.read(authViewModelProvider);
    final student = authState.student;

    if (student == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No student record found. Please log in again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Step 0: Credentials Validation
    if (s.currentStep == 0) {
      final syncErr = vm.validateCredentials(student);
      if (syncErr != null) {
        _showError(context, syncErr);
        return;
      }
      final asyncErr = await vm.validateCredentialsAsync(student.id);
      if (!context.mounted) return;
      if (asyncErr != null) {
        _showError(context, asyncErr);
        return;
      }
      vm.nextStep();
      return;
    }

    // Step 1: Personal Info Validation
    if (s.currentStep == 1) {
      final syncErr = vm.validatePersonalInfo();
      if (syncErr != null) {
        _showError(context, syncErr);
        return;
      }
      final asyncErr = await vm.validatePersonalInfoAsync(student.id);
      if (!context.mounted) return;
      if (asyncErr != null) {
        _showError(context, asyncErr);
        return;
      }
      vm.nextStep();
      return;
    }

    // Step 2: Photos Validation
    if (s.currentStep == 2) {
      final syncErr = vm.validatePhotos();
      if (syncErr != null) {
        _showError(context, syncErr);
        return;
      }
      vm.nextStep();
      return;
    }

    // Step 3: Review & Submit
    if (s.currentStep == 3) {
      final reviewErr = vm.validateReview();
      if (reviewErr != null) {
        _showError(context, reviewErr);
        return;
      }

      final success = await vm.submit(student);
      if (!context.mounted) return;
      if (success) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Account Activated! Welcome to STI Sync.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        context.goNamed('dashboard');
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Exit Setup?'),
        content: const Text(
          'Your account setup is not finished yet. If you log out now, you will need to complete this setup the next time you log in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay & Complete'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authViewModelProvider.notifier).logout();
              context.goNamed('welcome');
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(profileCompletionViewModelProvider);
    final vm = ref.read(profileCompletionViewModelProvider.notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (s.currentStep > 0) {
            vm.previousStep();
          } else {
            _handleLogout(context, ref);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: s.currentStep > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
                  onPressed: vm.previousStep,
                )
              : null,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete Your Account',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                'Step ${s.currentStep + 1} of 4: ${_stepTitles[s.currentStep]}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () => _handleLogout(context, ref),
              icon: const Icon(Icons.logout, size: 16, color: Colors.grey),
              label: const Text('Exit', style: TextStyle(color: Colors.grey)),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6),
            child: LinearProgressIndicator(
              value: (s.currentStep + 1) / 4,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
              minHeight: 4,
            ),
          ),
        ),
        body: Column(
          children: [
            // If submitting, show progress overlay
            if (s.isSubmitting)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                color: const Color(0xFFF4F6F9),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s.submitProgressLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        Text(
                          '${(s.submitProgress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: s.submitProgress,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.secondary),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),

            // Step Content
            Expanded(
              child: IndexedStack(
                index: s.currentStep,
                children: _steps,
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                if (s.currentStep > 0) ...[
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: s.isSubmitting ? null : vm.previousStep,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                        side: const BorderSide(color: AppColors.primaryDark),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: s.isSubmitting ? null : () => _handleNext(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: s.isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            s.isLastStep ? 'Activate Account' : 'Continue',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
