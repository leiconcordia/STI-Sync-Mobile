import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/local/app_database.dart';
import '../../../shared/providers/providers.dart';
import '../../sync/models/sync_status_model.dart';

/// Provider that streams all offline attendance records for a given event.
final eventAttendanceProvider =
    StreamProvider.family.autoDispose<List<OfflineAttendanceData>, String>(
  (ref, eventId) {
    return ref
        .watch(appDatabaseProvider)
        .attendanceDao
        .watchAllForEvent(eventId);
  },
);

/// Scanner attendance logs showing all local + synced records for an event.
///
/// Route: `/scanner/:eventId/logs`
///
/// Hybrid data source: reads from Drift offline_attendance (including unsynced).
/// Provides filter pills, metric cards, and a "Sync Now" button.
class ScannerLogsScreen extends ConsumerStatefulWidget {
  final String eventId;

  const ScannerLogsScreen({super.key, required this.eventId});

  @override
  ConsumerState<ScannerLogsScreen> createState() => _ScannerLogsScreenState();
}

class _ScannerLogsScreenState extends ConsumerState<ScannerLogsScreen> {
  String _activeFilter = 'All';

  static const _filters = [
    'All',
    'Time-In',
    'Time-Out',
    'Flagged',
    'Manual',
    'Pending Sync',
  ];

  List<OfflineAttendanceData> _applyFilter(List<OfflineAttendanceData> all) {
    switch (_activeFilter) {
      case 'Time-In':
        return all.where((r) => r.gateType == 'Time-In').toList();
      case 'Time-Out':
        return all.where((r) => r.gateType == 'Time-Out').toList();
      case 'Flagged':
        return all.where((r) => r.isFlagged == 1).toList();
      case 'Manual':
        return all.where((r) => r.isManual == 1).toList();
      case 'Pending Sync':
        return all.where((r) => r.synced == 0).toList();
      default:
        return all;
    }
  }

  Future<void> _syncNow() async {
    final syncService = ref.read(syncServiceProvider);
    final result = await syncService.uploadPendingAttendance();

    if (!mounted) return;

    if (result.type == SyncResultType.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Synced ${result.uploadedCount} records'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (result.type == SyncResultType.hasConflicts) {
      context.push('/scanner/sync-conflicts', extra: result.conflicts);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Sync failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(eventAttendanceProvider(widget.eventId));
    final isOnline =
        ref.watch(connectivityStatusProvider).valueOrNull ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Attendance Logs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          attendanceAsync.whenOrNull(
                data: (all) {
                  final pendingCount = all.where((r) => r.synced == 0).length;
                  if (pendingCount > 0 && isOnline) {
                    return TextButton.icon(
                      onPressed: _syncNow,
                      icon: const Icon(Icons.cloud_upload,
                          color: AppColors.secondary, size: 20),
                      label: Text(
                        'Sync ($pendingCount)',
                        style: const TextStyle(color: AppColors.secondary),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: attendanceAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('Error loading logs: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
        data: (allRecords) {
          final filtered = _applyFilter(allRecords);
          final pendingCount = allRecords.where((r) => r.synced == 0).length;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(eventAttendanceProvider(widget.eventId));
            },
            child: Column(
              children: [
                // Pending sync banner
                if (pendingCount > 0) _buildPendingBanner(pendingCount),

                // Metric cards
                _buildMetricCards(allRecords),

                // Filter pills
                _buildFilterPills(),

                // Attendance list
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) =>
                              _buildAttendanceRow(filtered[index]),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Pending Banner ──────────────────────────────────────────────────────

  Widget _buildPendingBanner(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.amber.shade50,
      child: Row(
        children: [
          Icon(Icons.sync_problem, color: Colors.amber.shade700, size: 20),
          const SizedBox(width: 8),
          Text(
            '$count record${count == 1 ? '' : 's'} pending sync',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.amber.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Metric Cards ───────────────────────────────────────────────────────

  Widget _buildMetricCards(List<OfflineAttendanceData> all) {
    final checkedIn = all.where((r) => r.gateType == 'Time-In').length;
    final checkedOut = all.where((r) => r.gateType == 'Time-Out').length;
    final flagged = all.where((r) => r.isFlagged == 1).length;
    final pending = all.where((r) => r.synced == 0).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child:
                _buildMetricCard('Checked In', checkedIn, AppColors.success),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricCard(
                'Checked Out', checkedOut, const Color(0xFF1565C0)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricCard(
                'Flagged', flagged, Colors.amber.shade700),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricCard(
                'Pending', pending, Colors.orange.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: AppTextStyles.headlineMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── Filter Pills ──────────────────────────────────────────────────────

  Widget _buildFilterPills() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isActive = _activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isActive,
              onSelected: (_) => setState(() => _activeFilter = filter),
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
              labelStyle: AppTextStyles.bodySmall.copyWith(
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: BorderSide(
                color: isActive
                    ? AppColors.primary
                    : Colors.grey.shade300,
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Attendance Rows ───────────────────────────────────────────────────

  Widget _buildAttendanceRow(OfflineAttendanceData record) {
    final time = DateFormat('hh:mm a').format(
      DateTime.fromMillisecondsSinceEpoch(record.scannedAt),
    );
    final isEntry = record.gateType == 'Time-In';
    final isPending = record.synced == 0;
    final isFlagged = record.isFlagged == 1;
    final isManual = record.isManual == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                record.studentName.isNotEmpty
                    ? record.studentName[0].toUpperCase()
                    : '?',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name + ID
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.studentName,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      FutureBuilder<CachedParticipant?>(
                        future: ref.read(appDatabaseProvider)
                            .participantsDao
                            .getParticipantByStudentId(record.studentId, widget.eventId),
                        builder: (context, snapshot) {
                          final studentIdDisplay = snapshot.data?.studentNumber ??
                              (record.studentId.length > 20
                                  ? '${record.studentId.substring(0, 8)}...'
                                  : record.studentId);
                          return Text(
                            studentIdDisplay,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  // Pills row
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _buildSmallPill(
                        isEntry ? 'Time-In' : 'Time-Out',
                        isEntry ? AppColors.success : AppColors.error,
                      ),
                      if (isManual)
                        _buildSmallPill('Manual', Colors.amber.shade700),
                      if (isFlagged)
                        _buildSmallPill(
                          _flagReasonLabel(record.flagReason),
                          Colors.amber.shade700,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Pending sync dot
            if (isPending)
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _flagReasonLabel(String? reason) {
    switch (reason) {
      case 'no_phone':
        return 'No Phone';
      case 'payment_pending':
        return 'Payment Pending';
      case 'not_registered':
        return 'Not Registered';
      case 'device_error':
        return 'Device Error';
      case 'other':
        return 'Other';
      default:
        return 'Flagged';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_note,
              size: 56,
              color: AppColors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            'No records',
            style: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            _activeFilter == 'All'
                ? 'No attendance records yet'
                : 'No records match this filter',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

