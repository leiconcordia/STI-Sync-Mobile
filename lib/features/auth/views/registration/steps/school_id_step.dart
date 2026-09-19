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
      imageQuality: 80,
      maxWidth: 1024,
      maxHeight: 1024,
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
            subtitle: 'Take a clear photo of the front of your STI Student ID card.',
          ),
          const SizedBox(height: 16),

          // Return guidance banner if resubmitting
          if (state.returnReason != null && state.returnReason!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Previous Review Note:',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.returnReason!,
                          style: const TextStyle(color: Colors.black87, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

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
                            'Tap to photograph ID Front',
                            style: TextStyle(
                                color: AppColors.accentPurple,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                          SizedBox(height: 4),
                          Text('STI ID Front or Certificate of Registration',
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
                    Text('STI ID Card Requirements',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE0A100))),
                  ],
                ),
                const SizedBox(height: 10),
                ...[
                  'Official STI ID Card Front or Certificate of Registration (COR)',
                  'STI College Ormoc header & logo clearly visible',
                  'Printed student name matches your registration name',
                  'Portrait photo on card must be sharp and free of glare',
                  'Place ID flat on a plain surface and keep all 4 corners in frame',
                ].map(
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
          const Text('STI Student ID Front Layout',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.accentPurple)),
          const SizedBox(height: 14),
          Center(
            child: Container(
              width: 170,
              height: 230,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)
                ],
              ),
              child: Column(
                children: [
                  // STI Header with yellow/blue
                  Container(
                    height: 28,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('STI',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFFD100))),
                        SizedBox(width: 4),
                        Text('COLLEGE ORMOC',
                            style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Portrait Photo
                  Container(
                    height: 64,
                    width: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: const Icon(Icons.person, size: 40, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  // Name representation
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'STUDENT FULL NAME',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Semester sticker badge
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE08A),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE0A100), width: 0.8),
                      ),
                      child: const Text(
                        'SY 2026-27 1st Term',
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7A5800),
                        ),
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

