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

  /// Purges all locally cached data for a specific event IF AND ONLY IF
  /// all offline attendance records are completely synced to the cloud.
  ///
  /// Steps:
  /// 1. Check if there are unsynced offline attendance records for this event.
  /// 2. If unsynced records exist, attempt to upload/sync them first.
  /// 3. Re-verify if any unsynced records still remain.
  ///    - If unsynced records STILL remain (e.g. offline, connection error) -> ABORT cleanup completely.
  /// 4. Once 0 unsynced records remain:
  ///    a. Delete cached_participants for this event
  ///    b. Delete cached_payables for this event
  ///    c. Delete only synced offline_attendance for this event
  ///    d. Delete the scanner_assignment for this event
  Future<bool> purgeEventData(String eventId) async {
    debugPrint('EventCleanupService: Checking sync status before purging event $eventId');

    // 1. Check for pending unsynced records
    final pending = await _attendanceDao.getPendingSyncsForEvent(eventId);
    if (pending.isNotEmpty) {
      debugPrint('EventCleanupService: ${pending.length} unsynced records for $eventId — attempting sync...');
      try {
        await _syncService.uploadPendingAttendance();
      } catch (e) {
        debugPrint('EventCleanupService: Sync failed during purge check: $e');
      }
    }

    // 2. Strict validation: Re-check if any unsynced records still remain
    final remainingPending = await _attendanceDao.getPendingSyncsForEvent(eventId);
    if (remainingPending.isNotEmpty) {
      debugPrint(
        'EventCleanupService: ABORTING cleanup for event $eventId. '
        '${remainingPending.length} unsynced attendance records still pending upload.',
      );
      return false; // Retain all event data in SQLite until synced
    }

    // 3. All attendance is 100% synced — proceed with complete local cleanup
    debugPrint('EventCleanupService: All attendance verified synced. Purging event $eventId cache...');

    // 1. Delete cached participants
    await _participantsDao.purgeEventParticipants(eventId);
    debugPrint('EventCleanupService: Purged participants for $eventId');

    // 2. Delete cached payables
    await _payablesDao.purgeEventPayables(eventId);
    debugPrint('EventCleanupService: Purged payables for $eventId');

    // 3. Delete synced attendance records
    await _attendanceDao.deleteSyncedForEvent(eventId);
    debugPrint('EventCleanupService: Purged synced attendance for $eventId');

    // 4. Delete the scanner assignment
    await _scannerDao.deleteAssignment(eventId);
    debugPrint('EventCleanupService: Deleted scanner assignment for $eventId');

    debugPrint('EventCleanupService: Purge complete for event $eventId');
    return true;
  }

  /// Checks all local scanner assignments and purges data for expired events.
  ///
  /// An event is considered expired when `now > eventEndTime + 12 hours`.
  /// If expired, it verifies that all attendance is synced before purging.
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
          '("${assignment.eventTitle}") passed 12h post-event window ($expiryTime) — evaluating sync status...',
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
