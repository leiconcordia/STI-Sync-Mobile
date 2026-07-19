import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/providers/providers.dart';
import '../../sync/models/sync_status_model.dart';

/// Screen for reviewing and resolving duplicate attendance records
/// discovered during sync.
///
/// Route: `/scanner/sync-conflicts`
///
/// Each conflict shows the local record vs the existing Firestore record.
/// The user can skip (keep existing) or force upload (replace) individually
/// or in bulk.
class SyncConflictsScreen extends ConsumerStatefulWidget {
  final List<SyncConflict> conflicts;

  const SyncConflictsScreen({super.key, required this.conflicts});

  @override
  ConsumerState<SyncConflictsScreen> createState() =>
      _SyncConflictsScreenState();
}

class _SyncConflictsScreenState extends ConsumerState<SyncConflictsScreen> {
  late List<SyncConflict> _remainingConflicts;
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    _remainingConflicts = List.from(widget.conflicts);
  }

  Future<void> _resolveOne(SyncConflict conflict, ConflictAction action) async {
    setState(() => _isResolving = true);
    try {
      final syncService = ref.read(syncServiceProvider);
      await syncService.resolveConflict(
        conflict.localRecord.localId,
        action,
        firestoreDocId: conflict.firestoreDocId,
      );

      setState(() {
        _remainingConflicts.remove(conflict);
      });

      if (mounted && _remainingConflicts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All conflicts resolved'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  Future<void> _resolveAll(ConflictAction action) async {
    setState(() => _isResolving = true);
    try {
      final syncService = ref.read(syncServiceProvider);
      await syncService.resolveAllConflicts(_remainingConflicts, action);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == ConflictAction.skip
                ? 'Skipped all duplicates'
                : 'Force-uploaded all records'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Sync Conflicts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.amber.shade200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.amber.shade700, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Duplicate Entries Found (${_remainingConflicts.length})',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'These attendance records already exist in the system. '
                  'Review each one and decide whether to skip or force upload.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.amber.shade800),
                ),
              ],
            ),
          ),

          // Conflict list
          Expanded(
            child: _remainingConflicts.isEmpty
                ? const Center(child: Text('All conflicts resolved'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _remainingConflicts.length,
                    itemBuilder: (context, index) {
                      return _buildConflictCard(_remainingConflicts[index]);
                    },
                  ),
          ),

          // Bottom action bar
          if (_remainingConflicts.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isResolving
                          ? null
                          : () => _resolveAll(ConflictAction.skip),
                      icon: const Icon(Icons.skip_next, size: 18),
                      label: const Text('Skip All'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isResolving
                          ? null
                          : () => _resolveAll(ConflictAction.forceUpload),
                      icon: const Icon(Icons.upload, size: 18),
                      label: const Text('Force All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConflictCard(SyncConflict conflict) {
    final local = conflict.localRecord;
    final remote = conflict.firestoreRecord;

    final localTime = DateFormat('MMM dd, hh:mm a').format(
      DateTime.fromMillisecondsSinceEpoch(local.scannedAt),
    );

    String remoteTime = 'Unknown';
    if (remote['scannedAt'] != null) {
      try {
        if (remote['scannedAt'] is String) {
          remoteTime = DateFormat('MMM dd, hh:mm a')
              .format(DateTime.parse(remote['scannedAt']));
        }
      } catch (_) {}
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    local.studentName.isNotEmpty
                        ? local.studentName[0].toUpperCase()
                        : '?',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(local.studentName,
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        local.studentId,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                _buildGateTypePill(local.gateType),
              ],
            ),

            const Divider(height: 24),

            // Time comparison
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Local Record',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(localTime,
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Icon(Icons.compare_arrows,
                    color: AppColors.textSecondary.withValues(alpha: 0.4)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Firestore Record',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(remoteTime,
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isResolving
                        ? null
                        : () => _resolveOne(conflict, ConflictAction.skip),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Keep Existing (Skip)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isResolving
                        ? null
                        : () =>
                            _resolveOne(conflict, ConflictAction.forceUpload),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Force Upload'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGateTypePill(String gateType) {
    final isEntry = gateType == 'Time-In' || gateType == 'entry';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isEntry ? AppColors.success : AppColors.error)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isEntry ? 'Time-In' : 'Time-Out',
        style: AppTextStyles.bodySmall.copyWith(
          color: isEntry ? AppColors.success : AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
