import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/features/auth/models/student_model.dart';
import 'package:sti_sync/shared/providers/providers.dart';

class EditProfileSheet extends ConsumerStatefulWidget {
  final StudentModel student;

  const EditProfileSheet({super.key, required this.student});

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _contactController;

  File? _selectedImageFile;
  String? _newUploadedPhotoUrl;
  bool _isUploadingPhoto = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _contactController = TextEditingController(text: widget.student.contactNumber);
  }

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
      );

      if (pickedFile == null) return;

      setState(() {
        _selectedImageFile = File(pickedFile.path);
        _isUploadingPhoto = true;
      });

      final cloudinary = ref.read(cloudinaryServiceProvider);
      final uploadedUrl = await cloudinary.uploadFile(
        _selectedImageFile!,
        folder: 'profile_photos',
      );

      if (mounted) {
        setState(() {
          _newUploadedPhotoUrl = uploadedUrl;
          _isUploadingPhoto = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedImageFile = null;
          _isUploadingPhoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change Profile Photo',
                style: AppTextStyles.h2.copyWith(fontSize: 18, color: AppColors.primaryDark),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.photo_library, color: AppColors.primary),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isUploadingPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for photo upload to finish.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final newContact = _contactController.text.trim();
      final hasContactChanged = newContact != widget.student.contactNumber;
      final hasPhotoChanged = _newUploadedPhotoUrl != null && _newUploadedPhotoUrl!.isNotEmpty;

      if (!hasContactChanged && !hasPhotoChanged) {
        Navigator.pop(context);
        return;
      }

      await ref.read(authViewModelProvider.notifier).updateProfile(
        contactNumber: hasContactChanged ? newContact : null,
        profilePhotoUrl: hasPhotoChanged ? _newUploadedPhotoUrl : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPhotoUrl = _newUploadedPhotoUrl ?? widget.student.profilePhotoUrl;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Profile',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.primaryDark,
                        fontSize: 20,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Form Content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Profile Photo Section
                      Center(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.secondary, width: 3),
                              ),
                              child: ClipOval(
                                child: _selectedImageFile != null
                                    ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                                    : (currentPhotoUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: currentPhotoUrl,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => Container(
                                              color: AppColors.primaryDark,
                                              child: const Icon(Icons.person, color: Colors.white, size: 55),
                                            ),
                                            errorWidget: (_, __, ___) => Container(
                                              color: AppColors.primaryDark,
                                              child: const Icon(Icons.person, color: Colors.white, size: 55),
                                            ),
                                          )
                                        : Container(
                                            color: AppColors.primaryDark,
                                            child: const Icon(Icons.person, color: Colors.white, size: 55),
                                          )),
                              ),
                            ),
                            if (_isUploadingPhoto)
                              Positioned.fill(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(color: AppColors.secondary, strokeWidth: 3),
                                  ),
                                ),
                              ),
                            GestureDetector(
                              onTap: _isUploadingPhoto || _isSaving ? null : _showPhotoOptions,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: _isUploadingPhoto || _isSaving ? null : _showPhotoOptions,
                          icon: const Icon(Icons.photo_camera_outlined, size: 16, color: AppColors.primary),
                          label: const Text(
                            'Change Profile Photo',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Contact Number Field (Editable)
                      Text(
                        'CONTACT INFORMATION',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _contactController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          prefixText: '+63 ',
                          prefixStyle: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          hintText: '9123456789',
                          prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your contact number.';
                          }
                          final trimmed = value.trim();
                          if (!RegExp(r'^9\d{9}$').hasMatch(trimmed)) {
                            return 'Must be 10 digits starting with 9 (e.g., 9123456789).';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      // Locked Official Academic & Identity Information
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'OFFICIAL ACADEMIC DETAILS',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.lock_outline, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'School-Controlled',
                                style: AppTextStyles.labelSmall.copyWith(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildLockedField(
                              label: 'Full Name',
                              value: '${widget.student.firstName} ${widget.student.middleName} ${widget.student.lastName}'.replaceAll('  ', ' ').trim(),
                              icon: Icons.person_outline,
                            ),
                            const Divider(height: 16),
                            _buildLockedField(
                              label: 'Student ID',
                              value: widget.student.studentId,
                              icon: Icons.credit_card_outlined,
                            ),
                            const Divider(height: 16),
                            _buildLockedField(
                              label: 'Institutional Email',
                              value: widget.student.email,
                              icon: Icons.email_outlined,
                            ),
                            const Divider(height: 16),
                            _buildLockedField(
                              label: 'Course & Section',
                              value: '${widget.student.courseCode} · ${widget.student.yearLevel} - ${widget.student.section}',
                              icon: Icons.school_outlined,
                            ),
                            const Divider(height: 16),
                            _buildLockedField(
                              label: 'Department',
                              value: widget.student.departmentName.isNotEmpty
                                  ? widget.student.departmentName
                                  : widget.student.departmentId,
                              icon: Icons.business_outlined,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'To request official updates to your student name, program, or section, please visit the School Registrar or SAO office.',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSaving ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _handleSave,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Save Changes',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLockedField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade400),
      ],
    );
  }
}
