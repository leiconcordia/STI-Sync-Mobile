import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/shared/providers/providers.dart';
import '../widgets/completion_widgets.dart';

class IdentityPhotosCompletionStep extends ConsumerWidget {
  const IdentityPhotosCompletionStep({super.key});

  Future<void> _pickImage({
    required BuildContext context,
    required WidgetRef ref,
    required ImageSource source,
    required bool isProfilePhoto,
  }) async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (xFile == null) return;

      final file = File(xFile.path);
      final vm = ref.read(profileCompletionViewModelProvider.notifier);
      if (isProfilePhoto) {
        vm.setProfilePhotoFile(file);
      } else {
        vm.setSchoolIdPhotoFile(file);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showImageSourcePicker({
    required BuildContext context,
    required WidgetRef ref,
    required bool isProfilePhoto,
  }) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  isProfilePhoto ? 'Upload Profile Photo' : 'Upload School ID',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8EEF5),
                    child: Icon(Icons.camera_alt, color: AppColors.primaryDark),
                  ),
                  title: const Text('Take Photo with Camera'),
                  subtitle: Text(isProfilePhoto
                      ? 'Capture a clear face photo'
                      : 'Capture front of your ID card'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(
                      context: context,
                      ref: ref,
                      source: ImageSource.camera,
                      isProfilePhoto: isProfilePhoto,
                    );
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8EEF5),
                    child: Icon(Icons.photo_library, color: AppColors.primaryDark),
                  ),
                  title: const Text('Choose from Gallery'),
                  subtitle: const Text('Select an existing photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(
                      context: context,
                      ref: ref,
                      source: ImageSource.gallery,
                      isProfilePhoto: isProfilePhoto,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(profileCompletionViewModelProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 8, 24, bottomInset + 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(
            title: 'Identity Verification Photos',
            subtitle:
                'Upload your profile selfie and STI School ID card for campus identification and QR event check-in.',
          ),
          const SizedBox(height: 20),

          // 1. Profile Photo Section
          const FieldLabel(text: '1. Profile Photo (Selfie / ID Headshot) *'),
          const SizedBox(height: 4),
          const Text(
            'Face must be clearly visible, centered, and well-lit.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          Center(
            child: GestureDetector(
              onTap: () => _showImageSourcePicker(
                context: context,
                ref: ref,
                isProfilePhoto: true,
              ),
              child: Stack(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: s.profilePhotoFile != null
                            ? AppColors.success
                            : AppColors.primaryDark.withValues(alpha: 0.3),
                        width: 2.5,
                      ),
                      image: s.profilePhotoFile != null
                          ? DecorationImage(
                              image: FileImage(s.profilePhotoFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: s.profilePhotoFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.person, size: 48, color: Colors.grey),
                              SizedBox(height: 4),
                              Text(
                                'Tap to add',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: s.profilePhotoFile != null
                          ? AppColors.success
                          : AppColors.primaryDark,
                      child: Icon(
                        s.profilePhotoFile != null
                            ? Icons.check
                            : Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // 2. School ID Section
          const FieldLabel(text: '2. School ID Card or Registration Assessment *'),
          const SizedBox(height: 4),
          const Text(
            'Upload the front side of your STI ID card or official Registration Assessment Form (RAF).',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: () => _showImageSourcePicker(
              context: context,
              ref: ref,
              isProfilePhoto: false,
            ),
            child: Container(
              width: double.infinity,
              height: 190,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: s.schoolIdPhotoFile != null
                      ? AppColors.success
                      : AppColors.primaryDark.withValues(alpha: 0.3),
                  width: 2,
                ),
                image: s.schoolIdPhotoFile != null
                    ? DecorationImage(
                        image: FileImage(s.schoolIdPhotoFile!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: s.schoolIdPhotoFile == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.badge_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Tap to capture or upload School ID',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Ensure Student No. and Full Name are legible',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle,
                                    size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'ID Attached',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
