import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/local/daos/attendance_dao.dart';
import '../../../core/local/daos/participants_dao.dart';
import '../../../core/local/daos/payables_dao.dart';
import '../../../core/local/daos/scanner_dao.dart';
import 'sync_service.dart';

/// Handles cleanup of locally cached event data after events have ended.
///
/// Ensures all pending offline attendance records are synced before purging,
/// then removes cached participants, payables, synced attendance, and the
/// scanner assignment itself.
class EventCleanupService {
  final AttendanceDao _attendanceDao;
  final ParticipantsDao _participantsDao;
  final PayablesDao _payablesDao;
  final ScannerDao _scannerDao;
  final SyncService _syncService;

  Timer? _periodicTimer;

  EventCleanupService({
    required AttendanceDao attendanceDao,
    required ParticipantsDao participantsDao,
    required PayablesDao payablesDao,
    required ScannerDao scannerDao,
    required SyncService syncService,
  })  : _attendanceDao = attendanceDao,
        _participantsDao = participantsDao,
        _payablesDao = payablesDao,
        _scannerDao = scannerDao,
        _syncService = syncService;

  /// Purges all locally cached data for a specific event.
  ///
  /// Steps:
  /// 1. Delete cached_participants for this event
  /// 2. Delete cached_payables for this event
  /// 3. Sync any pending offline_attendance for this event first
  /// 4. Delete only synced offline_attendance for this event
  /// 5. Delete the scanner_assignment for this event
  Future<void> purgeEventData(String eventId) async {
    debugPrint('EventCleanupService: Purging data for event $eventId');

    // 1. Delete cached participants
    await _participantsDao.purgeEventParticipants(eventId);
    debugPrint('EventCleanupService: Purged participants for $eventId');

    // 2. Delete cached payables
    await _payablesDao.purgeEventPayables(eventId);
    debugPrint('EventCleanupService: Purged payables for $eventId');

    // 3. Ensure all offline attendance for this event is synced first
    final pending = await _attendanceDao.getPendingSyncsForEvent(eventId);
    if (pending.isNotEmpty) {
      debugPrint('EventCleanupService: ${pending.length} pending records — syncing before purge');
      try {
        await _syncService.uploadPendingAttendance();
      } catch (e) {
        debugPrint('EventCleanupService: Sync failed during purge: $e');
        // Don't block purge — leave unsynced records in place
      }
    }

    // 4. Delete only already-synced attendance records
    await _attendanceDao.deleteSyncedForEvent(eventId);
    debugPrint('EventCleanupService: Purged synced attendance for $eventId');

    // 5. Delete the scanner assignment
    await _scannerDao.deleteAssignment(eventId);
    debugPrint('EventCleanupService: Deleted scanner assignment for $eventId');

    debugPrint('EventCleanupService: Purge complete for event $eventId');
  }

  /// Checks all local scanner assignments and purges data for expired events.
  ///
  /// An event is considered expired when `now > eventEndTime + 12 hours`.
  /// This matches the same grace period used by [ScannerAssignmentModel.isActive].
  Future<void> checkAndPurgeExpiredEvents() async {
    debugPrint('EventCleanupService: Checking for expired events...');

    final assignments = await _scannerDao.getAllAssignments();
    if (assignments.isEmpty) {
      debugPrint('EventCleanupService: No local assignments found');
      return;
    }

    final now = DateTime.now();

    for (final assignment in assignments) {
      final endTime = DateTime.fromMillisecondsSinceEpoch(assignment.eventEndTime);
      final expiryTime = endTime.add(const Duration(hours: 12));

      if (now.isAfter(expiryTime)) {
        debugPrint(
          'EventCleanupService: Event ${assignment.eventId} '
          '("${assignment.eventTitle}") expired at $expiryTime — purging',
        );
        await purgeEventData(assignment.eventId);
      }
    }

    debugPrint('EventCleanupService: Expired event check complete');
  }

  /// Starts a periodic timer that checks for and purges expired events
  /// every 30 minutes while the app is open.
  ///
  /// Also runs an immediate check on startup.
  void startPeriodicCheck() {
    // Run immediately on startup
    checkAndPurgeExpiredEvents();

    // Then every 30 minutes
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => checkAndPurgeExpiredEvents(),
    );
    debugPrint('EventCleanupService: Periodic cleanup started (every 30 min)');
  }

  /// Stops the periodic cleanup timer.
  void dispose() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }
}
