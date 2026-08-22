import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_colors.dart';
import '../widgets/registration_widgets.dart';
import '../../../../../shared/providers/providers.dart';

/// Step 5 — Upload Your School ID.
class SchoolIdStep extends ConsumerWidget {
  const SchoolIdStep({super.key});

  Future<void> _pick(WidgetRef ref, ImageSource source) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: source,
      imageQuality: 85, // Reduced from 90 for better upload reliability
      maxWidth: 1024,   // Reduced from 1600 to prevent oversized uploads
    );
    if (xFile == null) return;
    
    // Explicitly update the viewmodel state
    ref.read(registrationViewModelProvider.notifier)
        .setSchoolIdFile(File(xFile.path));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registrationViewModelProvider);
    final idFile = state.schoolIdFile;
    final hasId = state.hasSchoolId;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 8, 24, bottomInset + 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(
            title: 'Upload School ID / COR',
            subtitle: 'Take a clear photo of your official STI Student ID card.',
          ),
          const SizedBox(height: 20),

          // Capture target (Portrait Orientation).
          Center(
            child: GestureDetector(
              onTap: () => _pick(ref, ImageSource.camera),
              child: Container(
                width: 240,
                height: 330,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accentPurple.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasId
                    ? (idFile != null
                        ? Image.file(idFile, fit: BoxFit.cover)
                        : Image.network(
                            ref.read(registrationViewModelProvider).existingSchoolIdUrl!,
                            fit: BoxFit.cover,
                          ))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.badge_outlined, size: 54, color: AppColors.accentPurple),
                          SizedBox(height: 12),
                          Text(
                            'Tap to photograph ID or COR',
                            style: TextStyle(
                                color: AppColors.accentPurple,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                          SizedBox(height: 4),
                          Text('STI ID card front or Registration Form',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const _IdPreviewCard(),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => _pick(ref, ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined, size: 20),
                    label: const Text('Take Photo',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPurple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ref, ImageSource.gallery),
                    icon: const Icon(Icons.image_outlined, size: 20),
                    label: const Text('Upload',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentPurple,
                      side: const BorderSide(color: AppColors.accentPurple, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Container(
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
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Color(0xFFE0A100)),
                    SizedBox(width: 8),
                    Text('Requirements',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE0A100))),
                  ],
                ),
                const SizedBox(height: 10),
                ...['Full vertical portrait card visible', 'STI logo and name readable'].map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  ',
                            style: TextStyle(color: AppColors.primaryDark)),
                        Expanded(
                          child: Text(item,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.primaryDark)),
                        ),
                      ],
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

class _IdPreviewCard extends StatelessWidget {
  const _IdPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What your Portrait ID should show',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.accentPurple)),
          const SizedBox(height: 14),
          Center(
            child: Container(
              width: 140,
              height: 180,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: 22,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('STI',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 50,
                    width: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE7E7E7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, size: 34, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 6,
                    width: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 6,
                    width: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(3),
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
