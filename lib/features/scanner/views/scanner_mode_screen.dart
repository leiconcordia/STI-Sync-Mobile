import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import '../../../core/local/app_database.dart';
import '../../../shared/providers/providers.dart';
import '../widgets/session_selector_sheet.dart';

import '../models/scanner_assignment_model.dart';
import 'package:intl/intl.dart';

final sessionAttendanceProvider = StreamProvider.family.autoDispose<List<OfflineAttendanceData>, String>((ref, sessionId) {
  return ref.watch(appDatabaseProvider).attendanceDao.watchAllForSession(sessionId);
});

final sessionParticipantsProvider = StreamProvider.family.autoDispose<List<CachedParticipant>, String>((ref, eventId) {
  return ref.watch(appDatabaseProvider).participantsDao.watchAllForEvent(eventId);
});

class ScannerModeScreen extends ConsumerStatefulWidget {
  const ScannerModeScreen({super.key});

  @override
  ConsumerState<ScannerModeScreen> createState() => _ScannerModeScreenState();
}

class _ScannerModeScreenState extends ConsumerState<ScannerModeScreen> {
  String? _selectedSessionId;
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final eventId = ref.watch(scannerViewModelProvider).selectedEventId;
    final assignment = _assignment;
    
    final activeSessionId = _selectedSessionId ?? (assignment?.sessions.isNotEmpty == true ? assignment!.sessions.first['id'] as String? : null);
    
    final selectedSession = assignment?.sessions.firstWhere(
      (s) => s['id'] == activeSessionId,
      orElse: () => {},
    );
    final bool sessionHasTimeOut = selectedSession?['hasTimeOut'] == true;

    // Watch providers
    final participantsAsync = eventId != null ? ref.watch(sessionParticipantsProvider(eventId)) : const AsyncValue<List<CachedParticipant>>.data([]);
    final attendanceAsync = activeSessionId != null ? ref.watch(sessionAttendanceProvider(activeSessionId)) : const AsyncValue<List<OfflineAttendanceData>>.data([]);

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
            _buildStatsRow(attendanceAsync, participantsAsync),
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
                        _buildFilterChips(sessionHasTimeOut),
                        Expanded(
                          child: _buildAttendanceList(attendanceAsync),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 32,
                      right: 24,
                      child: FloatingActionButton(
                        onPressed: _openScannerConfig,
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

  void _openScannerConfig() {
    final eventId = ref.read(scannerViewModelProvider).selectedEventId;
    if (eventId == null) return;
    
    final assignment = ref.read(scannerViewModelProvider).assignments.firstWhere(
      (a) => a.eventId == eventId,
    );
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SessionSelectorSheet(
        assignment: assignment,
        onStartScanning: (sessionId, gateType) {
          context.push('/scanner/camera/$eventId/$sessionId/$gateType');
        },
      ),
    );
  }
  ScannerAssignmentModel? get _assignment {
    final eventId = ref.watch(scannerViewModelProvider).selectedEventId;
    if (eventId == null) return null;
    final assignments = ref.watch(scannerViewModelProvider).assignments;
    for (final a in assignments) {
      if (a.eventId == eventId) return a;
    }
    return null;
  }

  Widget _buildHeader(BuildContext context) {
    final eventTitle = _assignment?.eventTitle ?? 'Unknown Event';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scanner Mode',
                  style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 20),
                ),
                Text(
                  eventTitle,
                  style: AppTextStyles.labelSmall.copyWith(color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionSelector() {
    final assignment = _assignment;
    if (assignment == null || assignment.sessions.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeSessionId = _selectedSessionId ?? assignment.sessions.first['id'] as String?;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: assignment.sessions.map((s) {
          final id = s['id'] as String? ?? '';
          final name = s['title'] as String? ?? 'Unnamed Session';
          final startTime = s['startTime'] as String? ?? '';
          final endTime = s['endTime'] as String? ?? '';
          final time = '$startTime - $endTime';
          final isSelected = id == activeSessionId;
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedSessionId = id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.3),
                  border: Border.all(
                    color: isSelected ? AppColors.secondary : Colors.white24,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      name,
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
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsRow(AsyncValue<List<OfflineAttendanceData>> attendanceAsync, AsyncValue<List<CachedParticipant>> participantsAsync) {
    return attendanceAsync.when(
      data: (attendance) {
        int inCount = 0;
        int outCount = 0;
        for (var r in attendance) {
          if (r.gateType == 'Time-In') inCount++;
          if (r.gateType == 'Time-Out') outCount++;
        }
        
        final totalStudents = participantsAsync.valueOrNull?.length ?? 0;
        final absentCount = totalStudents > 0 ? (totalStudents - inCount) : 0;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(inCount.toString(), 'In', Colors.greenAccent),
              _buildStatCard(outCount.toString(), 'Out', Colors.lightBlueAccent),
              _buildStatCard(absentCount.toString(), 'Absent', Colors.redAccent),
              _buildStatCard('0', 'Flagged', AppColors.secondary),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox(),
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

  Widget _buildFilterChips(bool hasTimeOut) {
    final filters = ['All', 'Checked In'];
    if (hasTimeOut) filters.add('Checked Out');
    filters.addAll(['Absent', 'Flagged']);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: filters.map((filter) {
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

  Widget _buildAttendanceList(AsyncValue<List<OfflineAttendanceData>> attendanceAsync) {
    final eventId = ref.watch(scannerViewModelProvider).selectedEventId;
    if (eventId == null) {
      return const Center(child: Text('No event selected'));
    }

    final participantsAsync = ref.watch(sessionParticipantsProvider(eventId));

    return participantsAsync.when(
      data: (participants) {
        final attendanceList = attendanceAsync.valueOrNull ?? [];
        
        // Filter participants based on _selectedFilter
        final filteredParticipants = participants.where((student) {
          final studentId = student.id;
          final records = attendanceList.where((r) => r.studentId == studentId).toList();
          final timeInRecord = records.where((r) => r.gateType == 'Time-In').firstOrNull;
          final timeOutRecord = records.where((r) => r.gateType == 'Time-Out').firstOrNull;
          
          if (_selectedFilter == 'Checked In') {
            return timeInRecord != null && timeOutRecord == null;
          } else if (_selectedFilter == 'Checked Out') {
            return timeOutRecord != null;
          } else if (_selectedFilter == 'Absent') {
            return timeInRecord == null;
          } else if (_selectedFilter == 'Flagged') {
            return false; // Implement flagged logic if needed
          }
          return true; // 'All'
        }).toList();

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
                            _selectedFilter,
                            style: AppTextStyles.labelSmall.copyWith(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '${filteredParticipants.length} students',
                    style: AppTextStyles.labelSmall.copyWith(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                itemCount: filteredParticipants.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final student = filteredParticipants[index];
                  final studentId = student.id;
                  final records = attendanceList.where((r) => r.studentId == studentId).toList();
                  return _buildStudentCard(student, records);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildStudentCard(CachedParticipant student, List<OfflineAttendanceData> records) {
    String status = 'Not Scanned';
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;
    Color statusBgColor = Colors.grey.withOpacity(0.1);
    String timeLabel = 'N/A';

    final timeInRecord = records.where((r) => r.gateType == 'Time-In').firstOrNull;
    final timeOutRecord = records.where((r) => r.gateType == 'Time-Out').firstOrNull;

    if (timeOutRecord != null) {
      status = 'Checked Out';
      statusColor = Colors.blue;
      statusIcon = Icons.logout;
      statusBgColor = Colors.blue.withOpacity(0.1);
      final date = DateTime.fromMillisecondsSinceEpoch(timeOutRecord.scannedAt);
      timeLabel = DateFormat.jm().format(date);
    } else if (timeInRecord != null) {
      status = timeInRecord.status; // "Present" or "Late"
      if (status == 'Present') {
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusBgColor = Colors.green.withOpacity(0.1);
      } else {
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        statusBgColor = Colors.orange.withOpacity(0.1);
      }
      final date = DateTime.fromMillisecondsSinceEpoch(timeInRecord.scannedAt);
      timeLabel = DateFormat.jm().format(date);
    }

    return InkWell(
      onTap: () => _showDeleteAttendanceModal(student, timeInRecord, timeOutRecord),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                        student.studentName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${student.studentNumber} · ${student.course} ${student.yearLevel}',
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
                      status,
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
                    timeLabel,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  void _showDeleteAttendanceModal(
    CachedParticipant student,
    OfflineAttendanceData? timeInRecord,
    OfflineAttendanceData? timeOutRecord,
  ) {
    if (timeInRecord == null && timeOutRecord == null) return; // Nothing to delete
    
    final eventId = ref.read(scannerViewModelProvider).selectedEventId;
    final activeSessionId = _selectedSessionId ?? _assignment?.sessions.firstOrNull?['id'] as String?;
    if (eventId == null || activeSessionId == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance Details',
                style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark),
              ),
              const SizedBox(height: 8),
              Text(
                student.studentName,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              if (timeInRecord != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Time-In', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600)),
                    Text(
                      DateFormat.jm().format(DateTime.fromMillisecondsSinceEpoch(timeInRecord.scannedAt)),
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (timeOutRecord != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Time-Out', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600)),
                    Text(
                      DateFormat.jm().format(DateTime.fromMillisecondsSinceEpoch(timeOutRecord.scannedAt)),
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final studentId = student.id;
                    await ref.read(appDatabaseProvider).attendanceDao.deleteRecordsForStudent(studentId, activeSessionId);
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Delete Record', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
