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
    final idFile = ref.watch(
      registrationViewModelProvider.select((s) => s.schoolIdFile),
    );
    final hasId = idFile != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(
            title: 'Upload Your School ID',
            subtitle: 'Take a clear photo of your physical STI College Ormoc ID card.',
          ),
          const SizedBox(height: 20),

          // Capture target.
          GestureDetector(
            onTap: () => _pick(ref, ImageSource.camera),
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E9FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.accentPurple.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasId
                  ? Image.file(idFile, fit: BoxFit.cover)
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.credit_card, size: 42, color: AppColors.accentPurple),
                        SizedBox(height: 10),
                        Text(
                          'Tap to photograph your ID',
                          style: TextStyle(
                              color: AppColors.accentPurple,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text('or upload from gallery',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
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
                ...['Full card visible, no cropping', 'All text readable'].map(
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
    Widget bar(double width, {double height = 8}) => Container(
          height: height,
          width: width,
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(4),
          ),
        );

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
          const Text('What your ID should show',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.accentPurple)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      height: 28,
                      width: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC9D4E5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('STI',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 44,
                      width: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7E7E7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Photo',
                          style: TextStyle(fontSize: 9, color: Colors.grey)),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(double.infinity),
                      bar(140),
                      bar(110),
                      const SizedBox(height: 10),
                      bar(double.infinity, height: 12),
                    ],
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
