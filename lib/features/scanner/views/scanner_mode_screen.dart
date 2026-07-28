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

final eventAttendanceProvider =
    StreamProvider.family.autoDispose<List<OfflineAttendanceData>, String>(
  (ref, eventId) {
    // Stream all records but filter out unsynced flagged entries.
    // Normal QR scans (isFlagged=0) show immediately; flagged entries
    // only appear after they've been synced to Firestore (synced=1).
    return ref
        .watch(appDatabaseProvider)
        .attendanceDao
        .watchAllForEvent(eventId)
        .map((records) => records
            .where((r) => r.isFlagged != 1 || r.synced == 1)
            .toList());
  },
);

final sessionParticipantsProvider =
    StreamProvider.family.autoDispose<List<CachedParticipant>, String>(
  (ref, eventId) {
    return ref
        .watch(appDatabaseProvider)
        .participantsDao
        .watchAllForEvent(eventId);
  },
);

class ScannerModeScreen extends ConsumerStatefulWidget {
  const ScannerModeScreen({super.key});

  @override
  ConsumerState<ScannerModeScreen> createState() => _ScannerModeScreenState();
}

class _ScannerModeScreenState extends ConsumerState<ScannerModeScreen> {
  String? _selectedSessionId;
  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _showSummary = false; // Hidden by default as requested

  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  bool get _hasManualPermission {
    final assignment = _assignment;
    if (assignment == null) return false;
    return assignment.permissions['fullAccess'] == true ||
        assignment.permissions['allowManualAttendance'] == true;
  }

  Future<void> _refreshData() async {
    // Check if online before allowing refresh
    final isOnline = ref.read(connectivityStatusProvider).valueOrNull ?? false;
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cannot refresh. No internet connection.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final eventId = ref.read(scannerViewModelProvider).selectedEventId;

    if (eventId != null) {
      await ref
          .read(offlineAttendanceRepositoryProvider)
          .fetchAndCacheRemoteAttendance(eventId);
      ref.invalidate(sessionParticipantsProvider(eventId));
      ref.invalidate(eventAttendanceProvider(eventId));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Refreshing attendance list...'),
            ],
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventId = ref.watch(scannerViewModelProvider).selectedEventId;
    final assignment = _assignment;

    final activeSessionId = _selectedSessionId ??
        (assignment?.sessions.isNotEmpty == true
            ? assignment!.sessions.first['id'] as String?
            : null);

    final selectedSession = assignment?.sessions.firstWhere(
      (s) => s['id'] == activeSessionId,
      orElse: () => {},
    );
    final bool sessionHasTimeOut = selectedSession?['hasTimeOut'] == true;

    final participantsAsync = eventId != null
        ? ref.watch(sessionParticipantsProvider(eventId))
        : const AsyncValue<List<CachedParticipant>>.data([]);
    final attendanceAsync = eventId != null
        ? ref.watch(eventAttendanceProvider(eventId))
        : const AsyncValue<List<OfflineAttendanceData>>.data([]);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.primary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context, eventId, activeSessionId),
            const SizedBox(height: 12),
            _buildSessionSelector(),
            const SizedBox(height: 16),
            _buildCollapsibleStatsRow(attendanceAsync, participantsAsync),
            const SizedBox(height: 16),
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
                        const SizedBox(height: 8),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async {
                              _refreshData();
                            },
                            child: _buildAttendanceList(attendanceAsync),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 32,
                      right: 24,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (eventId != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: FloatingActionButton.small(
                                heroTag: 'logs_fab',
                                onPressed: () =>
                                    context.push('/scanner/$eventId/logs'),
                                backgroundColor: Colors.white,
                                elevation: 3,
                                child: const Icon(Icons.list_alt,
                                    color: AppColors.primary, size: 22),
                              ),
                            ),
                          if (eventId != null && _hasManualPermission)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: FloatingActionButton.small(
                                heroTag: 'manual_fab',
                                onPressed: () =>
                                    context.push('/scanner/$eventId/manual'),
                                backgroundColor: Colors.white,
                                elevation: 3,
                                child: Icon(Icons.person_add_alt_1,
                                    color: Colors.amber.shade700, size: 22),
                              ),
                            ),
                          FloatingActionButton(
                            heroTag: 'scan_fab',
                            onPressed: _openScannerConfig,
                            backgroundColor: AppColors.secondary,
                            elevation: 4,
                            child: const Icon(Icons.qr_code_scanner,
                                color: AppColors.primaryDark, size: 28),
                          ),
                        ],
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

    final assignment =
        ref.read(scannerViewModelProvider).assignments.firstWhere(
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

  Widget _buildHeader(
      BuildContext context, String? eventId, String? activeSessionId) {
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
                  style: AppTextStyles.h1
                      .copyWith(color: Colors.white, fontSize: 20),
                ),
                Text(
                  eventTitle,
                  style:
                      AppTextStyles.labelSmall.copyWith(color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Refresh Icon Button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh attendance list',
            onPressed: _refreshData,
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

    final activeSessionId = _selectedSessionId ??
        assignment.sessions.first['id'] as String?;

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        color:
                            isSelected ? AppColors.secondary : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
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

  // ─── Collapsible Attendance Summary Dropdown ────────────────────────────────

  Widget _buildCollapsibleStatsRow(
    AsyncValue<List<OfflineAttendanceData>> attendanceAsync,
    AsyncValue<List<CachedParticipant>> participantsAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showSummary = !_showSummary),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics_outlined,
                          color: AppColors.secondary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Attendance Summary',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        _showSummary ? 'Hide' : 'Show',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: Colors.white70),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _showSummary
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_showSummary) ...[
            const SizedBox(height: 12),
            _buildStatsRow(attendanceAsync, participantsAsync),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    AsyncValue<List<OfflineAttendanceData>> attendanceAsync,
    AsyncValue<List<CachedParticipant>> participantsAsync,
  ) {
    return attendanceAsync.when(
      data: (attendance) {
        int inCount = 0;
        int outCount = 0;
        int flaggedCount = 0;

        for (var r in attendance) {
          if (r.gateType == 'Time-In') inCount++;
          if (r.gateType == 'Time-Out') outCount++;
          if (r.isFlagged == 1) flaggedCount++;
        }

        final totalStudents = participantsAsync.valueOrNull?.length ?? 0;
        final absentCount = totalStudents > 0 ? (totalStudents - inCount) : 0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatCard(inCount.toString(), 'In', Colors.greenAccent),
            _buildStatCard(outCount.toString(), 'Out', Colors.lightBlueAccent),
            _buildStatCard(
                absentCount < 0 ? '0' : absentCount.toString(), 'Absent', Colors.redAccent),
            _buildStatCard(
                flaggedCount.toString(), 'Flagged', AppColors.secondary),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildStatCard(String count, String label, Color countColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryDark.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: AppTextStyles.h1.copyWith(color: countColor, fontSize: 22),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Search Bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            icon: Icon(Icons.search, color: Colors.grey.shade400),
            hintText: 'Search by name or student ID...',
            hintStyle:
                AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade400),
            border: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  // ─── Filter Chips ──────────────────────────────────────────────────────────

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

  // ─── Attendance List ───────────────────────────────────────────────────────

  Widget _buildAttendanceList(
      AsyncValue<List<OfflineAttendanceData>> attendanceAsync) {
    final eventId = ref.watch(scannerViewModelProvider).selectedEventId;
    if (eventId == null) {
      return const Center(child: Text('No event selected'));
    }

    final participantsAsync = ref.watch(sessionParticipantsProvider(eventId));

    return participantsAsync.when(
      data: (participants) {
        final attendanceList = attendanceAsync.valueOrNull ?? [];

        // Build combined unique map (cached participants + unknown manual walk-ins from attendance records)
        final uniqueParticipantsMap = <String, CachedParticipant>{};
        for (final p in participants) {
          final key = (p.studentNumber != null && p.studentNumber!.isNotEmpty)
              ? p.studentNumber!
              : p.id;
          if (!uniqueParticipantsMap.containsKey(key)) {
            uniqueParticipantsMap[key] = p;
          }
          // Also map by Auth UID if different
          if (!uniqueParticipantsMap.containsKey(p.id)) {
            uniqueParticipantsMap[p.id] = p;
          }
        }

        // Synthesize entries for any walk-in attendance records not in cached_participants
        for (final record in attendanceList) {
          if (!uniqueParticipantsMap.containsKey(record.studentId)) {
            final synthStudent = CachedParticipant(
              id: record.studentId,
              eventId: eventId,
              studentName: record.studentName.isNotEmpty
                  ? record.studentName
                  : 'Unknown Walk-in',
              studentNumber: record.studentId.length <= 15
                  ? record.studentId
                  : 'Walk-in',
              course: 'Manual Entry',
              yearLevel: 0,
              qrTicketUnlocked: 1,
              participantJson: '{}',
              downloadedAt: DateTime.now().millisecondsSinceEpoch,
            );
            uniqueParticipantsMap[record.studentId] = synthStudent;
          }
        }

        final uniqueParticipants =
            uniqueParticipantsMap.values.toSet().toList();

        // Filter participants based on _searchQuery AND _selectedFilter
        final filteredParticipants = uniqueParticipants.where((student) {
          // Search query check
          if (_searchQuery.trim().isNotEmpty) {
            final query = _searchQuery.trim().toLowerCase();
            final nameMatch = student.studentName.toLowerCase().contains(query);
            final numMatch =
                (student.studentNumber?.toLowerCase() ?? '').contains(query);
            if (!nameMatch && !numMatch) return false;
          }

          // Category filter check — match by Auth UID OR student number
          final studentId = student.id;
          final studentNum = student.studentNumber;
          final records = attendanceList.where((r) =>
              r.studentId == studentId ||
              (studentNum != null && studentNum.isNotEmpty && r.studentId == studentNum)).toList();
          final timeInRecord =
              records.where((r) => r.gateType == 'Time-In').firstOrNull;
          final timeOutRecord =
              records.where((r) => r.gateType == 'Time-Out').firstOrNull;
          final isFlagged = records.any((r) => r.isFlagged == 1);

          if (_selectedFilter == 'Checked In') {
            return timeInRecord != null && timeOutRecord == null;
          } else if (_selectedFilter == 'Checked Out') {
            return timeOutRecord != null;
          } else if (_selectedFilter == 'Absent') {
            return timeInRecord == null && !isFlagged;
          } else if (_selectedFilter == 'Flagged') {
            return isFlagged;
          }
          return true; // 'All'
        }).toList();

        if (filteredParticipants.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No students match "$_searchQuery"'
                      : 'No records match filter "$_selectedFilter"',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                        style: AppTextStyles.labelSmall
                            .copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  Text(
                    '${filteredParticipants.length} student${filteredParticipants.length == 1 ? '' : 's'}',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 100),
                itemCount: filteredParticipants.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final student = filteredParticipants[index];
                  final studentId = student.id;
                  final studentNum = student.studentNumber;
                  final records = attendanceList
                      .where((r) =>
                          r.studentId == studentId ||
                          (studentNum != null &&
                              studentNum.isNotEmpty &&
                              r.studentId == studentNum))
                      .toList();
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

  Widget _buildStudentCard(
      CachedParticipant student, List<OfflineAttendanceData> records) {
    String status = 'Absent';
    Color statusColor = Colors.grey.shade600;
    IconData statusIcon = Icons.remove_circle_outline;
    Color statusBgColor = Colors.grey.withValues(alpha: 0.12);
    String timeLabel = 'Not Scanned';

    final timeInRecord =
        records.where((r) => r.gateType == 'Time-In').firstOrNull;
    final timeOutRecord =
        records.where((r) => r.gateType == 'Time-Out').firstOrNull;
    final isFlagged = records.any((r) => r.isFlagged == 1);

    if (timeOutRecord != null) {
      status = 'Checked Out';
      statusColor = Colors.blue;
      statusIcon = Icons.logout;
      statusBgColor = Colors.blue.withValues(alpha: 0.1);
      final date = DateTime.fromMillisecondsSinceEpoch(timeOutRecord.scannedAt);
      timeLabel = DateFormat.jm().format(date);
    } else if (timeInRecord != null) {
      status = timeInRecord.status; // "Present" or "Late"
      if (status == 'Present') {
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusBgColor = Colors.green.withValues(alpha: 0.1);
      } else {
        statusColor = Colors.orange.shade700;
        statusIcon = Icons.warning_amber_rounded;
        statusBgColor = Colors.orange.withValues(alpha: 0.1);
      }
      final date = DateTime.fromMillisecondsSinceEpoch(timeInRecord.scannedAt);
      timeLabel = DateFormat.jm().format(date);
    }

    return InkWell(
      onTap: () =>
          _showDeleteAttendanceModal(student, timeInRecord, timeOutRecord),
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: AppColors.primaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.studentName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${student.studentNumber} · ${student.course} ${student.yearLevel == 0 ? '' : student.yearLevel}',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isFlagged)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Flagged',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, color: Colors.grey.shade400, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      timeLabel,
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 11),
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
    if (timeInRecord == null && timeOutRecord == null) return;

    final eventId = ref.read(scannerViewModelProvider).selectedEventId;
    final activeSessionId = _selectedSessionId ??
        _assignment?.sessions.firstOrNull?['id'] as String?;
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
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              if (timeInRecord != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Time-In',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: Colors.grey.shade600)),
                    Text(
                      DateFormat.jm().format(
                          DateTime.fromMillisecondsSinceEpoch(
                              timeInRecord.scannedAt)),
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (timeOutRecord != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Time-Out',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: Colors.grey.shade600)),
                    Text(
                      DateFormat.jm().format(
                          DateTime.fromMillisecondsSinceEpoch(
                              timeOutRecord.scannedAt)),
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.bold),
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
                    // Check if online before allowing deletion
                    final isOnline = ref.read(connectivityStatusProvider).valueOrNull ?? false;
                    if (!isOnline) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('You cannot delete this record. No internet connection.'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                      return;
                    }

                    final repository =
                        ref.read(offlineAttendanceRepositoryProvider);
                    await repository.deleteAttendanceRecord(
                      eventId: eventId,
                      sessionId: activeSessionId,
                      studentId: student.id,
                      studentNumber: student.studentNumber,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Attendance record deleted for ${student.studentName}'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Delete Record',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
