import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../viewmodels/registration_viewmodel.dart';
import '../../../../shared/providers/providers.dart';
import 'steps/personal_info_step.dart';
import 'steps/academic_details_step.dart';
import 'steps/credentials_step.dart';
import 'steps/profile_photo_step.dart';
import 'steps/school_id_step.dart';
import 'steps/review_step.dart';

const List<String> _sectionTitles = [
  'Personal Info',
  'Academic Details',
  'Credentials',
  'Profile Photo',
  'School ID',
  'Review',
];

class RegistrationFlowScreen extends ConsumerWidget {
  const RegistrationFlowScreen({super.key});

  static const List<Widget> _steps = [
    PersonalInfoStep(),
    AcademicDetailsStep(),
    CredentialsStep(),
    ProfilePhotoStep(),
    SchoolIdStep(),
    ReviewStep(),
  ];

  void _handleBack(BuildContext context, WidgetRef ref) {
    final vm = ref.read(registrationViewModelProvider.notifier);
    final s = ref.read(registrationViewModelProvider);
    if (s.isFirstStep) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed('welcome');
      }
    } else {
      vm.previousStep();
    }
  }

  /// Validates the current step and advances on success, or shows an error.
  void _handleContinue(BuildContext context, WidgetRef ref) {
    final vm = ref.read(registrationViewModelProvider.notifier);
    final s = ref.read(registrationViewModelProvider);

    if (s.isLastStep) {
      _submit(context, ref);
      return;
    }

    final error = vm.validateStep(s.currentStep);
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      return;
    }

    vm.nextStep();
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final vm = ref.read(registrationViewModelProvider.notifier);
    final error = vm.validateStep(5);
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      return;
    }
    final authVm = ref.read(authViewModelProvider.notifier);
    final statePre = ref.read(registrationViewModelProvider);
    
    // Quick pre-flight check for photos before we lock the auth stream.
    if (!statePre.hasProfilePhoto || !statePre.hasSchoolId) {
       // Just call submit to let it trigger its own error snackbar state.
       await vm.submit();
       return;
    }
    
    authVm.setRegistrationInProgress(true);
    await vm.submit();
    authVm.setRegistrationInProgress(false);
    
    // Check result — if still mounted and no error, navigate away.
    if (!context.mounted) return;
    final state = ref.read(registrationViewModelProvider);
    if (state.submitSuccess) {
      _showSuccessAndExit(context);
    } else if (state.submitError != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(state.submitError!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  void _showSuccessAndExit(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 64),
            SizedBox(height: 16),
            Text(
              'Registration Submitted!',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark),
            ),
            SizedBox(height: 10),
            Text(
              'Your registration is under review by the SAO office. '
              'You will be notified once it is approved (1–3 working days).',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.goNamed('pendingStatus');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View Status'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registrationViewModelProvider);
    final step = state.currentStep;
    final progress = (step + 1) / kRegistrationStepCount;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack(context, ref);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Top progress bar.
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFEDE7F6),
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.accentPurple),
                ),
              ),

              // Header: back arrow · "Step X of 6" · section label.
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: AppColors.primaryDark),
                      onPressed: () => _handleBack(context, ref),
                    ),
                    Expanded(
                      child: Text(
                        'Step ${step + 1} of $kRegistrationStepCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        _sectionTitles[step],
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentPurple),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable step body — kept alive so input isn't lost.
              Expanded(
                child: IndexedStack(index: step, children: _steps),
              ),

              // Sticky bottom bar.
              _BottomActionBar(
                step: step,
                isResubmit: state.isResubmit,
                isLastStep: state.isLastStep,
                isSubmitting: state.isSubmitting,
                submitProgress: state.submitProgress,
                submitProgressLabel: state.submitProgressLabel,
                onContinue: () => _handleContinue(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final int step;
  final bool isResubmit;
  final bool isLastStep;
  final bool isSubmitting;
  final double submitProgress;
  final String submitProgressLabel;
  final VoidCallback onContinue;

  const _BottomActionBar({
    required this.step,
    required this.isResubmit,
    required this.isLastStep,
    required this.isSubmitting,
    required this.submitProgress,
    required this.submitProgressLabel,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress dots.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(kRegistrationStepCount, (i) {
              final isCurrent = i == step;
              final isDone = i < step;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 7,
                width: isCurrent ? 22 : 7,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.accentPurple
                      : isDone
                          ? AppColors.success
                          : const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),

          // Submit progress bar (visible only during submission).
          if (isSubmitting) ...[
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: submitProgress,
                    backgroundColor: const Color(0xFFEDE7F6),
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.accentPurple),
                  ),
                ),
                const SizedBox(width: 12),
                Text(submitProgressLabel,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.accentPurple)),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Primary action button.
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isLastStep ? AppColors.accentPurple : AppColors.primaryDark,
                foregroundColor:
                    isLastStep ? Colors.white : AppColors.secondary,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isLastStep 
                          ? (isResubmit ? 'Resubmit Registration' : 'Submit Registration') 
                          : 'Continue',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
