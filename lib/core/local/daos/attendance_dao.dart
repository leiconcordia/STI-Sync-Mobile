import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/offline_attendance_table.dart';

part 'attendance_dao.g.dart';

@DriftAccessor(tables: [OfflineAttendance])
class AttendanceDao extends DatabaseAccessor<AppDatabase> with _$AttendanceDaoMixin {
  AttendanceDao(AppDatabase db) : super(db);

  Future<void> insertOfflineRecord(OfflineAttendanceCompanion record) {
    return into(offlineAttendance).insert(record);
  }

  Future<void> upsertOfflineRecord(OfflineAttendanceCompanion record) {
    return into(offlineAttendance).insertOnConflictUpdate(record);
  }

  Future<List<OfflineAttendanceData>> getPendingSyncs() {
    return (select(offlineAttendance)..where((t) => t.synced.equals(0))).get();
  }

  /// Returns all pending (unsynced) records for a specific event.
  Future<List<OfflineAttendanceData>> getPendingSyncsForEvent(String eventId) {
    return (select(offlineAttendance)
          ..where((t) => t.synced.equals(0) & t.eventId.equals(eventId)))
        .get();
  }

  Future<void> markSynced(String localId) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await (update(offlineAttendance)..where((t) => t.localId.equals(localId))).write(
      OfflineAttendanceCompanion(
        synced: const Value(1),
        syncedAt: Value(nowMs),
      ),
    );
  }

  Future<OfflineAttendanceData?> checkDuplicate({
    required String studentId,
    String? studentNumber,
    required String eventId,
    required String sessionId,
    required String gateType,
  }) {
    final isTimeIn = gateType == 'Time-In' || gateType == 'time_in';
    return (select(offlineAttendance)
          ..where((t) {
            Expression<bool> idPredicate = t.studentId.equals(studentId);
            if (studentNumber != null && studentNumber.isNotEmpty) {
              idPredicate = idPredicate | t.studentId.equals(studentNumber);
            }
            Expression<bool> gatePredicate = isTimeIn
                ? (t.gateType.equals('Time-In') | t.gateType.equals('time_in'))
                : (t.gateType.equals('Time-Out') | t.gateType.equals('time_out'));

            Expression<bool> sessionPredicate = sessionId.isNotEmpty
                ? (t.sessionId.equals(sessionId) | t.sessionId.equals(''))
                : const Constant(true);

            return t.eventId.equals(eventId) & sessionPredicate & idPredicate & gatePredicate;
          }))
        .getSingleOrNull();
  }

  Future<List<OfflineAttendanceData>> getAllForSession(String sessionId) {
    return (select(offlineAttendance)..where((t) => t.sessionId.equals(sessionId))).get();
  }

  Stream<List<OfflineAttendanceData>> watchAllForSession(String sessionId) {
    return (select(offlineAttendance)..where((t) => t.sessionId.equals(sessionId))).watch();
  }

  /// Streams all attendance records for an event (all sessions).
  Stream<List<OfflineAttendanceData>> watchAllForEvent(String eventId) {
    return (select(offlineAttendance)
          ..where((t) => t.eventId.equals(eventId))
          ..orderBy([(t) => OrderingTerm.desc(t.scannedAt)]))
        .watch();
  }

  /// Streams only SYNCED attendance records for an event.
  /// Use this for the Scanner Attendance List so local unsynced flagged entries
  /// don't appear until they're uploaded to Firestore.
  Stream<List<OfflineAttendanceData>> watchSyncedForEvent(String eventId) {
    return (select(offlineAttendance)
          ..where((t) => t.eventId.equals(eventId) & t.synced.equals(1))
          ..orderBy([(t) => OrderingTerm.desc(t.scannedAt)]))
        .watch();
  }

  /// Streams only pending (unsynced) attendance records for an event.
  Stream<List<OfflineAttendanceData>> watchUnsyncedForEvent(String eventId) {
    return (select(offlineAttendance)
          ..where((t) => t.eventId.equals(eventId) & t.synced.equals(0))
          ..orderBy([(t) => OrderingTerm.desc(t.scannedAt)]))
        .watch();
  }

  /// Returns all attendance records for an event (all sessions).
  Future<List<OfflineAttendanceData>> getAllForEvent(String eventId) {
    return (select(offlineAttendance)..where((t) => t.eventId.equals(eventId))).get();
  }

  /// Returns all records in the offline attendance table.
  Future<List<OfflineAttendanceData>> getAll() {
    return select(offlineAttendance).get();
  }

  /// Deletes only already-synced records for a specific event.
  /// Used by EventCleanupService to safely purge after sync.
  Future<void> deleteSyncedForEvent(String eventId) {
    return (delete(offlineAttendance)
          ..where((t) => t.eventId.equals(eventId) & t.synced.equals(1)))
        .go();
  }

  Future<void> deleteRecordsForStudent({
    required String eventId,
    required String studentId,
    String? studentNumber,
    String? sessionId,
  }) {
    return (delete(offlineAttendance)
          ..where((t) {
            Expression<bool> idPredicate = t.studentId.equals(studentId);
            if (studentNumber != null && studentNumber.isNotEmpty) {
              idPredicate = idPredicate | t.studentId.equals(studentNumber);
            }
            Expression<bool> predicate = t.eventId.equals(eventId) & idPredicate;
            if (sessionId != null && sessionId.isNotEmpty) {
              predicate = predicate & (t.sessionId.equals(sessionId) | t.sessionId.equals(''));
            }
            return predicate;
          }))
        .go();
  }

  /// Deletes a single offline attendance record by its localId.
  Future<void> deleteRecordByLocalId(String localId) {
    return (delete(offlineAttendance)..where((t) => t.localId.equals(localId))).go();
  }
}
