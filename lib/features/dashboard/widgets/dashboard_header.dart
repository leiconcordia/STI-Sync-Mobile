import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/shared/providers/providers.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final student = authState.student;

    final hour = DateTime.now().hour;
    final String greetingPrefix = hour < 12
        ? 'Good morning,'
        : (hour < 18 ? 'Good afternoon,' : 'Good evening,');
    final String firstName = (student?.firstName.isNotEmpty == true)
        ? (student?.firstName ?? 'Student')
        : 'Student';

    final activeSemesterAsync = ref.watch(activeSemesterProvider);
    final bool isShs = student?.isShs == true;

    // Resolve raw active semester string
    String rawSemester = activeSemesterAsync.valueOrNull ?? '';
    if (rawSemester.isEmpty) {
      rawSemester = student?.semester ?? '';
    }

    // Strictly enforce cohort: College = Semester (never Trimester), SHS = Trimester (never Semester)
    String dedicatedSemester;
    if (isShs) {
      if (rawSemester.toLowerCase().contains('semester')) {
        dedicatedSemester = rawSemester.replaceAll(RegExp(r'Semester', caseSensitive: false), 'Trimester');
      } else if (rawSemester.isNotEmpty) {
        dedicatedSemester = rawSemester;
      } else {
        dedicatedSemester = '1st Trimester';
      }
    } else {
      // College student: MUST be Semester, strictly NO Trimester
      if (rawSemester.toLowerCase().contains('trimester')) {
        dedicatedSemester = rawSemester.replaceAll(RegExp(r'Trimester', caseSensitive: false), 'Semester');
      } else if (rawSemester.isNotEmpty) {
        dedicatedSemester = rawSemester;
      } else {
        dedicatedSemester = '2nd Semester';
      }
    }

    // Ensure Academic Year is present
    final String defaultSy = student?.schoolYear.isNotEmpty == true ? (student?.schoolYear ?? '2026-2027') : '2026-2027';
    final String semesterDisplay = dedicatedSemester.contains('A.Y.') || dedicatedSemester.contains('202')
        ? dedicatedSemester
        : '$dedicatedSemester · A.Y. $defaultSy';

    final String photoUrl = student?.profilePhotoUrl ?? '';
    final String initials = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'S';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greetingPrefix,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    firstName,
                    style: AppTextStyles.h1.copyWith(
                      color: AppColors.primaryDark,
                      fontSize: 28,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.primaryDark,
                        size: 28,
                      ),
                      onPressed: () {},
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '3',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryDark,
                    backgroundImage: photoUrl.isNotEmpty
                        ? CachedNetworkImageProvider(photoUrl)
                        : null,
                    child: photoUrl.isEmpty
                        ? Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.school_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  semesterDisplay,
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryDark),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                height: 16,
                width: 1,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'STI College Ormoc',
                  style: AppTextStyles.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
