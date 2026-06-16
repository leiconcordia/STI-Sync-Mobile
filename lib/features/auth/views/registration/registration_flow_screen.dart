import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../viewmodels/registration_viewmodel.dart';
import 'steps/personal_info_step.dart';
import 'steps/academic_details_step.dart';
import 'steps/credentials_step.dart';
import 'steps/profile_photo_step.dart';
import 'steps/school_id_step.dart';
import 'steps/review_step.dart';

/// Section label shown on the right of the header for each step.
const List<String> _sectionTitles = [
  'Personal Info',
  'Academic Details',
  'Credentials',
  'Profile Photo',
  'School ID',
  'Review',
];

/// Parent shell for the 6-step registration flow.
///
/// Owns the fixed header, top progress bar, the scrollable step bodies, and the
/// sticky bottom action bar (step dots + Continue button). Each step body is an
/// independently scrollable widget; the action bar never scrolls with content.
class RegistrationFlowScreen extends ConsumerWidget {
  const RegistrationFlowScreen({super.key});

  /// Bodies for each step, kept alive via [IndexedStack] so scroll/input state
  /// is preserved when moving back and forth.
  static const List<Widget> _steps = [
    PersonalInfoStep(),
    AcademicDetailsStep(),
    CredentialsStep(),
    ProfilePhotoStep(),
    SchoolIdStep(),
    ReviewStep(),
  ];

  /// Handles back navigation: previous step, or exit the flow on step 1.
  void _handleBack(BuildContext context, WidgetRef ref) {
    final vm = ref.read(registrationViewModelProvider.notifier);
    final state = ref.read(registrationViewModelProvider);
    if (state.isFirstStep) {
      // Leaving the flow entirely — pop if possible, else fall back to welcome.
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed('welcome');
      }
    } else {
      vm.previousStep();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registrationViewModelProvider);
    final vm = ref.read(registrationViewModelProvider.notifier);
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
              // ─── Top progress bar ───
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFEDE7F6),
                  valueColor: const AlwaysStoppedAnimation(AppColors.accentPurple),
                ),
              ),

              // ─── Header: back, step counter, section label ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
                      onPressed: () => _handleBack(context, ref),
                    ),
                    Expanded(
                      child: Text(
                        'Step ${step + 1} of $kRegistrationStepCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        _sectionTitles[step],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Scrollable step body ───
              Expanded(
                child: IndexedStack(index: step, children: _steps),
              ),

              // ─── Sticky bottom action bar ───
              _BottomActionBar(
                step: step,
                isLastStep: state.isLastStep,
                onContinue: () {
                  if (state.isLastStep) {
                    _submit(context);
                  } else {
                    vm.nextStep();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Placeholder submit — real Firestore write/validation wired separately.
  void _submit(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registration submitted (demo) — entering SAO review queue.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.goNamed('welcome');
  }
}
/// Sticky bottom bar: step progress dots + the primary action button.
///
/// Sits outside the scrollable body so it stays pinned at all times. The button
/// label/color switches to a purple "Submit Registration" on the final step.
class _BottomActionBar extends StatelessWidget {
  final int step;
  final bool isLastStep;
  final VoidCallback onContinue;

  const _BottomActionBar({
    required this.step,
    required this.isLastStep,
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
          // Progress dots: completed = green, current = elongated purple, rest grey.
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

          // Primary action button.
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isLastStep ? AppColors.accentPurple : AppColors.primaryDark,
                foregroundColor: isLastStep ? Colors.white : AppColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: Text(
                isLastStep ? 'Submit Registration' : 'Continue',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
