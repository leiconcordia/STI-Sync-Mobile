import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/shared/providers/providers.dart';
import 'package:sti_sync/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:sti_sync/features/profile/widgets/profile_header.dart';
import 'package:sti_sync/features/profile/widgets/profile_info_card.dart';
import 'package:sti_sync/features/profile/widgets/profile_danger_card.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '—';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final student = authState.student;

    if (student == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Hide scrollbar but allow scrolling
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ProfileHeader(
                student: student,
                onEditProfile: () {
                  // TODO: Implement Edit Profile
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit Profile coming soon')),
                  );
                },
                onQrCode: () {
                  // As requested, navigate to dashboard for now
                  context.goNamed('dashboard');
                },
              ),
              
              // We need padding to clear the overlapping buttons from header
              // The buttons are position -24 from bottom, they are around 48px tall
              const SizedBox(height: 48),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    ProfileInfoCard(
                      title: 'Personal Information',
                      children: [
                        ProfileInfoRow(
                          icon: Icons.person_outline,
                          label: 'Full Name',
                          value: '${student.firstName} ${student.middleName} ${student.lastName}'.replaceAll('  ', ' ').trim(),
                        ),
                        ProfileInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Date of Birth',
                          value: _formatDate(student.dateOfBirth),
                        ),
                        ProfileInfoRow(
                          icon: Icons.person_outline,
                          label: 'Sex',
                          value: student.sex,
                        ),
                        ProfileInfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Contact',
                          value: '+63 ${student.contactNumber}',
                        ),
                        ProfileInfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: student.email,
                          isLast: true,
                          isLink: true,
                        ),
                      ],
                    ),
                    
                    ProfileInfoCard(
                      title: 'Academic Information',
                      children: [
                        ProfileInfoRow(
                          icon: Icons.credit_card_outlined,
                          label: 'Student ID',
                          value: student.studentId,
                        ),
                        ProfileInfoRow(
                          icon: Icons.menu_book_outlined,
                          label: 'Course',
                          value: student.courseCode.isNotEmpty ? student.courseCode : student.courseId,
                        ),
                        ProfileInfoRow(
                          icon: Icons.layers_outlined,
                          label: 'Year Level',
                          value: student.yearLevel,
                        ),
                        ProfileInfoRow(
                          icon: Icons.groups_outlined,
                          label: 'Section',
                          value: student.section,
                        ),
                        ProfileInfoRow(
                          icon: Icons.business_outlined,
                          label: 'Department',
                          value: student.departmentName.isNotEmpty ? student.departmentName : student.departmentId,
                        ),
                        ProfileInfoRow(
                          icon: Icons.account_balance_outlined,
                          label: 'School Year',
                          value: '${student.schoolYear} · ${student.semester == '1st Semester' ? '1st Sem' : '2nd Sem'}',
                          isLast: true,
                        ),
                      ],
                    ),
                    
                    // Mock Organizations
                    ProfileInfoCard(
                      title: 'My Organizations',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      children: [
                        _MockOrgRow(
                          initials: 'IC',
                          title: 'ICT Student Org',
                          subtitle: 'Academic',
                          role: 'Member',
                        ),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                        _MockOrgRow(
                          initials: 'ST',
                          title: "Student Gov't",
                          subtitle: 'Governance',
                          role: 'Representative',
                        ),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                        InkWell(
                          onTap: () {},
                          child: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(Icons.add, color: AppColors.primary, size: 20),
                                SizedBox(width: 8),
                                Text('Join Organization', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Mock Certificates
                    ProfileInfoCard(
                      title: 'My Certificates',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      children: [
                        _MockCertRow(
                          title: 'Tech Summit 2025',
                          date: 'Nov 20, 2025',
                        ),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                        _MockCertRow(
                          title: 'Leadership Seminar',
                          date: 'Sep 5, 2025',
                        ),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                        InkWell(
                          onTap: () {},
                          child: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('View All Certificates', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    
                    ProfileDangerCard(
                      onLogOut: () {
                        ref.read(authViewModelProvider.notifier).logout();
                      },
                      onDeactivate: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Deactivation request coming soon')),
                        );
                      },
                    ),
                    
                    // Extra padding to clear the bottom navigation bar
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockOrgRow extends StatelessWidget {
  final String initials;
  final String title;
  final String subtitle;
  final String role;

  const _MockOrgRow({
    required this.initials,
    required this.title,
    required this.subtitle,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary,
            child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 15)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(role, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _MockCertRow extends StatelessWidget {
  final String title;
  final String date;

  const _MockCertRow({
    required this.title,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.success,
            child: Icon(Icons.workspace_premium, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 15)),
                Text(date, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          const Text('Download', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
