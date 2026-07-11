import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/scanner_assignment_model.dart';
import '../../../core/local/daos/scanner_dao.dart';
import '../../../core/constants/firestore_paths.dart';

/// Repository for all scanner-related Firestore and local database operations.
///
/// Firestore access: reads from `/events` collection via `scannerUserIds` field.
/// Local access: read/write to Drift `scanner_assignments` table.
class ScannerRepository {
  final FirebaseFirestore _firestore;
  final ScannerDao _scannerDao;

  ScannerRepository({
    required FirebaseFirestore firestore,
    required ScannerDao scannerDao,
  })  : _firestore = firestore,
        _scannerDao = scannerDao;

  /// Live stream of events where [officerUserId] is listed as a scanner.
  ///
  /// Uses the denormalized `scannerUserIds` array field on each event document,
  /// which the web admin populates whenever the `scanners[]` array is updated.
  /// Query filters for `proposalStatus == 'approved'` so only actionable events
  /// are returned.
  Stream<List<ScannerAssignmentModel>> watchScannerAssignments(
    String officerUserId,
  ) {
    debugPrint('ScannerRepository: watchScannerAssignments started for UID: $officerUserId');
    return _firestore
        .collection(FirestorePaths.events)
        // Note: We filter proposalStatus client-side (via canScan) to avoid
        // requiring a composite index in Firestore for array-contains + equality.
        .where('scannerUserIds', arrayContains: officerUserId)
        .snapshots()
        .map((snapshot) {
      debugPrint('ScannerRepository: Snapshot received with ${snapshot.docs.length} docs');
      return snapshot.docs.map((doc) {
        try {
          final model = ScannerAssignmentModel.fromEventDoc(doc, officerUserId);
          return model;
        } catch (e) {
          debugPrint('ScannerRepository: Failed to parse event ${doc.id}: $e');
          // Officer entry removed from scanners[] while scannerUserIds was
          // not yet updated — skip this doc gracefully.
          return null;
        }
      }).whereType<ScannerAssignmentModel>().toList();
    });
  }

  /// Persists [assignment] to the local Drift database for offline access.
  Future<void> saveAssignmentLocally(ScannerAssignmentModel assignment) async {
    await _scannerDao.saveAssignment(assignment.toCompanion());
  }

  /// Returns all scanner assignments cached locally in Drift.
  Future<List<ScannerAssignmentModel>> getLocalAssignments() async {
    final entities = await _scannerDao.getAllAssignments();
    return entities.map(ScannerAssignmentModel.fromDrift).toList();
  }

  /// Returns true if the event's last session end time is in the past.
  ///
  /// First checks the locally cached `eventEndTime` from the Drift row to
  /// avoid a network round-trip. Falls back to a Firestore fetch if the event
  /// is not cached locally.
  Future<bool> isEventEnded(String eventId) async {
    // Fast path: use locally cached end time
    final cached = await _scannerDao.getAssignment(eventId);
    if (cached != null && cached.eventEndTime > 0) {
      final endTime = DateTime.fromMillisecondsSinceEpoch(cached.eventEndTime)
          .add(const Duration(hours: 12));
      return DateTime.now().isAfter(endTime);
    }

    // Slow path: fetch from Firestore
    try {
      final doc = await _firestore
          .collection(FirestorePaths.events)
          .doc(eventId)
          .get();
      if (!doc.exists) return true;

      final data = doc.data();
      if (data == null) return true;
      final dataMap = data as Map<String, dynamic>;

      final sessions = dataMap['sessions'] as List<dynamic>? ?? [];
      if (sessions.isEmpty) return true;

      DateTime? latestEndTime;
      for (final session in sessions) {
        final dateStr = (session as Map<String, dynamic>)['date'] as String?;
        final endTimeStr = session['endTime'] as String?;
        if (dateStr != null && endTimeStr != null) {
          try {
            final dt = DateTime.parse('${dateStr}T$endTimeStr:00');
            if (latestEndTime == null || dt.isAfter(latestEndTime)) {
              latestEndTime = dt;
            }
          } catch (_) {}
        }
      }

      return latestEndTime != null
          ? DateTime.now().isAfter(latestEndTime.add(const Duration(hours: 12)))
          : false;
    } catch (_) {
      return false;
    }
  }

  /// Deletes all locally cached assignments whose events have ended.
  ///
  /// Should be called after each Firestore stream emission to keep the local
  /// cache clean. Calls `EventCleanupService.purgeEventData()` for each
  /// expired event once that service is implemented.
  Future<void> removeExpiredAssignments() async {
    final assignments = await _scannerDao.getAllAssignments();

    for (final assignment in assignments) {
      final hasEnded = await isEventEnded(assignment.eventId);
      if (hasEnded) {
        await _scannerDao.deleteAssignment(assignment.eventId);
        // TODO: EventCleanupService.purgeEventData(assignment.eventId)
        // — deletes cached_participants and offline_attendance rows for this event
      }
    }
  }
}
