import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../viewmodels/registration_viewmodel.dart';
import '../widgets/registration_widgets.dart';

/// Step 4 — Take Your Profile Photo.
///
/// Dashed-circle capture target, Take Selfie / Upload actions, and a photo
/// requirements callout. Actual camera/upload wiring is deferred; tapping marks
/// the photo as captured so the Review step reflects it.
class ProfilePhotoStep extends ConsumerWidget {
  const ProfilePhotoStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(registrationViewModelProvider.notifier);
    final hasPhoto = ref.watch(
      registrationViewModelProvider.select((s) => s.hasProfilePhoto),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(
            title: 'Take Your Profile Photo',
            subtitle: 'This photo is shown to officers during attendance '
                'verification. Face must be clearly visible.',
          ),
          const SizedBox(height: 28),

          // Dashed circular capture target.
          Center(
            child: GestureDetector(
              onTap: () => vm.setHasProfilePhoto(true),
              child: Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E9FA),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accentPurple.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasPhoto ? Icons.check_circle : Icons.photo_camera_outlined,
                      size: 48,
                      color: AppColors.accentPurple,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      hasPhoto ? 'Photo captured' : 'Tap to take photo',
                      style: const TextStyle(
                        color: AppColors.accentPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Take Selfie / Upload actions.
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Take Selfie',
                  icon: Icons.photo_camera_outlined,
                  filled: true,
                  onTap: () => vm.setHasProfilePhoto(true),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _ActionButton(
                  label: 'Upload',
                  icon: Icons.image_outlined,
                  filled: false,
                  onTap: () => vm.setHasProfilePhoto(true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Photo requirements callout.
          const _RequirementsBox(
            title: 'Photo Requirements',
            items: [
              'Face clearly visible and centered',
              'Good lighting, no shadows on face',
              'No sunglasses, hats, or face coverings',
              'Neutral expression, looking at camera',
            ],
          ),
        ],
      ),
    );
  }
}

/// Filled (purple) or outlined action button used for capture/upload.
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 20),
              label: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPurple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 20),
              label: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentPurple,
                side: const BorderSide(color: AppColors.accentPurple, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );
  }
}

/// Yellow-tinted requirements callout used in photo/ID steps.
class _RequirementsBox extends StatelessWidget {
  final String title;
  final List<String> items;

  const _RequirementsBox({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE08A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: Color(0xFFE0A100)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE0A100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ',
                      style: TextStyle(color: AppColors.primaryDark)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryDark,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
