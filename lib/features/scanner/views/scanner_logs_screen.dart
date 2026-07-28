import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/local/app_database.dart';
import '../../../shared/providers/providers.dart';
import '../../sync/models/sync_status_model.dart';

/// Provider that streams only pending (unsynced) offline attendance records for a given event.
final eventAttendanceProvider =
    StreamProvider.family.autoDispose<List<OfflineAttendanceData>, String>(
  (ref, eventId) {
    return ref
        .watch(appDatabaseProvider)
        .attendanceDao
        .watchUnsyncedForEvent(eventId);
  },
);

/// Scanner attendance logs showing unsynced pending records for an event.
///
/// Route: `/scanner/:eventId/logs`
///
/// Shows only unsynced records (synced records are removed once posted to DB).
/// Pressing and holding an item allows deleting the unsynced entry locally.
class ScannerLogsScreen extends ConsumerStatefulWidget {
  final String eventId;

  const ScannerLogsScreen({super.key, required this.eventId});

  @override
  ConsumerState<ScannerLogsScreen> createState() => _ScannerLogsScreenState();
}

class _ScannerLogsScreenState extends ConsumerState<ScannerLogsScreen> {
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

  Future<void> _confirmDeleteUnsynced(OfflineAttendanceData record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Unsynced Entry?'),
        content: Text(
          'Remove offline scan for "${record.studentName}"?\n\nThis record has not been synced to the database yet and will be permanently deleted locally.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(appDatabaseProvider)
          .attendanceDao
          .deleteRecordByLocalId(record.localId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted unsynced scan for ${record.studentName}'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        title: const Text('Unsynced Attendance Logs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          attendanceAsync.whenOrNull(
                data: (unsyncedRecords) {
                  final pendingCount = unsyncedRecords.length;
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
        data: (unsyncedRecords) {
          final pendingCount = unsyncedRecords.length;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(eventAttendanceProvider(widget.eventId));
            },
            child: Column(
              children: [
                // Pending sync banner
                if (pendingCount > 0) _buildPendingBanner(pendingCount),

                // Metric summary cards
                _buildMetricCards(unsyncedRecords),

                // Subtitle instructions
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Hold (long press) any entry to delete it before syncing.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Attendance list
                Expanded(
                  child: unsyncedRecords.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: unsyncedRecords.length,
                          itemBuilder: (context, index) =>
                              _buildAttendanceRow(unsyncedRecords[index]),
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
            '$count unsynced record${count == 1 ? '' : 's'} pending upload',
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

  Widget _buildMetricCards(List<OfflineAttendanceData> unsynced) {
    final checkedIn = unsynced.where((r) => r.gateType == 'Time-In').length;
    final checkedOut = unsynced.where((r) => r.gateType == 'Time-Out').length;
    final flagged = unsynced.where((r) => r.isFlagged == 1).length;
    final totalPending = unsynced.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
                'Pending In', checkedIn, AppColors.success),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricCard(
                'Pending Out', checkedOut, const Color(0xFF1565C0)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricCard(
                'Flagged', flagged, Colors.amber.shade700),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricCard(
                'Total Unsynced', totalPending, Colors.orange.shade700),
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

  // ─── Attendance Rows ───────────────────────────────────────────────────

  Widget _buildAttendanceRow(OfflineAttendanceData record) {
    final time = DateFormat('hh:mm a').format(
      DateTime.fromMillisecondsSinceEpoch(record.scannedAt),
    );
    final isEntry = record.gateType == 'Time-In';
    final isFlagged = record.isFlagged == 1;
    final isManual = record.isManual == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onLongPress: () => _confirmDeleteUnsynced(record),
        borderRadius: BorderRadius.circular(12),
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
                          future: ref
                              .read(appDatabaseProvider)
                              .participantsDao
                              .getParticipantByStudentId(
                                  record.studentId, widget.eventId),
                          builder: (context, snapshot) {
                            final studentIdDisplay = snapshot
                                    .data?.studentNumber ??
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

              // Pending indicator dot
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
          Icon(Icons.cloud_done_outlined,
              size: 56,
              color: AppColors.success.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            'All records synced!',
            style: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'There are no pending offline attendance logs.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
