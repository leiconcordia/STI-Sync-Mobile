import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/features/events/models/event_model.dart';
import 'package:sti_sync/features/profile/models/student_attendance_record.dart';
import 'package:sti_sync/shared/providers/providers.dart';
import 'package:sti_sync/core/utils/date_formatter.dart';

class StudentAttendanceHistoryScreen extends ConsumerWidget {
  const StudentAttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(myAttendanceHistoryStreamProvider);
    final eventsAsync = ref.watch(eventsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Attendance History',
          style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: attendanceAsync.when(
        data: (records) {
          final eventsMap = <String, EventModel>{};
          eventsAsync.whenData((events) {
            for (final e in events) {
              eventsMap[e.id] = e;
            }
          });

          // Filter out soft-deleted events
          final visibleRecords = records.where((r) {
            final ev = eventsMap[r.eventId];
            if (ev != null && ev.isDeleted) return false;
            return true;
          }).toList();

          if (visibleRecords.isEmpty) {
            return _buildEmptyState(context);
          }

          // Group by Academic Semester (e.g., "A.Y. 2025-2026 - 1st Semester")
          final grouped = <String, List<StudentAttendanceRecord>>{};
          for (final record in visibleRecords) {
            final ev = eventsMap[record.eventId];
            final sy = record.schoolYear ?? ev?.schoolYear ?? '';
            final sem = record.semester ?? ev?.semester ?? '';

            String groupKey;
            if (sy.isNotEmpty && sem.isNotEmpty) {
              groupKey = 'A.Y. $sy - $sem';
            } else if (sy.isNotEmpty) {
              groupKey = 'A.Y. $sy';
            } else if (sem.isNotEmpty) {
              groupKey = sem;
            } else {
              groupKey = 'Academic Records';
            }

            grouped.putIfAbsent(groupKey, () => []).add(record);
          }

          final groupKeys = grouped.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: groupKeys.length,
            itemBuilder: (context, groupIndex) {
              final groupName = groupKeys[groupIndex];
              final groupRecords = grouped[groupName]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 10, top: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          groupName,
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.primaryDark,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${groupRecords.length}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...groupRecords.map(
                    (record) => _buildRecordCard(context, record, eventsMap[record.eventId]),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load attendance history: $err',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fact_check_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Attendance Records Yet',
              style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Events and sessions you check in to will be recorded and preserved here for semester clearance.',
              style: AppTextStyles.labelSmall.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(
    BuildContext context,
    StudentAttendanceRecord record,
    EventModel? event,
  ) {
    final title = record.eventTitle ?? event?.title ?? 'Event';
    final timeStr = formatAppDateTime(record.scannedAt);
    final isOut = record.gateType == 'Time-Out';
    final isLate = record.status.toLowerCase() == 'late';

    final isArchived = event?.isArchived == true;
    final isCompleted = event?.isCompleted == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: event != null ? () => context.push('/events/detail/${event.id}') : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isArchived)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF64748B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.archive_outlined, size: 11, color: Color(0xFF64748B)),
                          SizedBox(width: 3),
                          Text(
                            'Archived',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, size: 11, color: Color(0xFF10B981)),
                          SizedBox(width: 3),
                          Text(
                            'Concluded',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (record.sessionTitle != null && record.sessionTitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  record.sessionTitle!,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Gate Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOut
                              ? Colors.lightBlue.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isOut
                                ? Colors.lightBlue.shade200
                                : Colors.green.shade200,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOut ? Icons.logout : Icons.login,
                              size: 11,
                              color: isOut ? Colors.lightBlue.shade800 : Colors.green.shade800,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              record.gateType,
                              style: TextStyle(
                                color: isOut ? Colors.lightBlue.shade800 : Colors.green.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Status (Present / Late)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLate
                              ? Colors.orange.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          record.status,
                          style: TextStyle(
                            color: isLate
                                ? Colors.orange.shade800
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
