import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/features/auth/models/student_model.dart';

class ProfileHeader extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onEditProfile;
  final VoidCallback onQrCode;

  const ProfileHeader({
    super.key,
    required this.student,
    required this.onEditProfile,
    required this.onQrCode,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Blue Background
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 60, bottom: 60, left: 24, right: 24),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Column(
            children: [
              // Avatar with yellow border
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondary, width: 3),
                ),
                child: ClipOval(
                  child: student.profilePhotoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: student.profilePhotoUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.primaryDark,
                            child: const Icon(Icons.person, color: Colors.white, size: 50),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.primaryDark,
                            child: const Icon(Icons.person, color: Colors.white, size: 50),
                          ),
                        )
                      : Container(
                          color: AppColors.primaryDark,
                          child: const Icon(Icons.person, color: Colors.white, size: 50),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Name
              Text(
                '${student.firstName} ${student.middleName} ${student.lastName}'.replaceAll('  ', ' ').trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              
              // ID
              Text(
                student.studentId,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              
              // Academic info string
              Text(
                '${student.courseCode} · ${student.yearLevel} · ${student.section}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      student.status == 'ACTIVE' ? 'Active' : student.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Floating Action Buttons
        Positioned(
          bottom: -24,
          left: 24,
          right: 24,
          child: Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit Profile',
                  onTap: onEditProfile,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ActionButton(
                  icon: Icons.qr_code_scanner,
                  label: 'My QR Code',
                  onTap: onQrCode,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
