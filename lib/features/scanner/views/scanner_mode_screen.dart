import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';

class ScannerModeScreen extends StatefulWidget {
  const ScannerModeScreen({super.key});

  @override
  State<ScannerModeScreen> createState() => _ScannerModeScreenState();
}

class _ScannerModeScreenState extends State<ScannerModeScreen> {
  int _selectedSessionIndex = 1; // 0 = Morning, 1 = Afternoon
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Checked In', 'Checked Out', 'Absent', 'Flagged'];

  // Fake Data matching the UI screenshot exactly
  final List<Map<String, dynamic>> _students = [
    {
      'name': 'Mark D. Villanu...',
      'details': '2023-0102 · BSIT 2B',
      'status': 'Checked In',
      'time': '1:05 PM',
      'isManual': false,
    },
    {
      'name': 'Rhea S. Mendoza',
      'details': '2023-0115 · BSCS 1B',
      'status': 'Absent',
      'time': '—',
      'isManual': false,
    },
    {
      'name': 'Kevin ...',
      'details': '2023-0130 · BSIT 1B',
      'status': 'Checked In',
      'time': '1:12 PM',
      'isManual': true,
    },
    {
      'name': 'Claire N. Garcia',
      'details': '2023-0145 · BSCS 2B',
      'status': 'Checked Out',
      'time': '3:40 PM',
      'isManual': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // User requested primary instead of dark blue
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildSessionSelector(),
            const SizedBox(height: 24),
            _buildStatsRow(),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _buildSearchBar(),
                        _buildFilterChips(),
                        Expanded(
                          child: _buildAttendanceList(),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 32,
                      right: 24,
                      child: FloatingActionButton(
                        onPressed: () {},
                        backgroundColor: AppColors.secondary,
                        elevation: 4,
                        child: const Icon(Icons.qr_code_scanner, color: AppColors.primaryDark, size: 28),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scanner Mode',
                    style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 20),
                  ),
                  Text(
                    'Tech Summit 2026 - Afternoon Session',
                    style: AppTextStyles.labelSmall.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: IconButton(
              icon: const Icon(Icons.file_download_outlined, color: Colors.white, size: 20),
              onPressed: () {},
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildSessionCard(0, 'Morning Session', '8:00 – 12:00 PM'),
          const SizedBox(width: 12),
          _buildSessionCard(1, 'Afternoon Session', '1:00 – 5:00 PM'),
        ],
      ),
    );
  }

  Widget _buildSessionCard(int index, String title, String time) {
    final isSelected = _selectedSessionIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedSessionIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryDark.withOpacity(0.3),
          border: Border.all(
            color: isSelected ? AppColors.secondary : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppColors.secondary : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard('2', 'In', Colors.greenAccent),
          _buildStatCard('1', 'Out', Colors.lightBlueAccent),
          _buildStatCard('1', 'Absent', Colors.redAccent),
          _buildStatCard('0', 'Flagged', AppColors.secondary),
        ],
      ),
    );
  }

  Widget _buildStatCard(String count, String label, Color countColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryDark.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: AppTextStyles.h1.copyWith(color: countColor, fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            icon: Icon(Icons.search, color: Colors.grey.shade400),
            hintText: 'Search by name or student ID...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade400),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedFilter = filter);
              },
              backgroundColor: Colors.grey.shade200,
              selectedColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.transparent),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAttendanceList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance List',
                    style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Afternoon Session · 1:00 – 5:00 PM',
                        style: AppTextStyles.labelSmall.copyWith(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '4 students',
                style: AppTextStyles.labelSmall.copyWith(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
            itemCount: _students.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final student = _students[index];
              return _buildStudentCard(student);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    Color statusColor;
    IconData statusIcon;
    Color statusBgColor;

    switch (student['status']) {
      case 'Checked In':
        statusColor = AppColors.success;
        statusIcon = Icons.login;
        statusBgColor = AppColors.success.withOpacity(0.1);
        break;
      case 'Checked Out':
        statusColor = AppColors.primary;
        statusIcon = Icons.logout;
        statusBgColor = AppColors.primary.withOpacity(0.1);
        break;
      case 'Absent':
        statusColor = AppColors.error;
        statusIcon = Icons.person_off;
        statusBgColor = AppColors.error.withOpacity(0.1);
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusBgColor = Colors.grey.withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        student['name'],
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (student['isManual'] == true) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'MANUAL',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  student['details'],
                  style: AppTextStyles.labelSmall.copyWith(color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      student['status'],
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.schedule, color: Colors.grey.shade400, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    student['time'],
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
