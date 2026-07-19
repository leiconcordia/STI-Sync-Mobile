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

  Future<OfflineAttendanceData?> checkDuplicate(String studentId, String sessionId, String gateType) {
    return (select(offlineAttendance)
          ..where((t) =>
              t.studentId.equals(studentId) &
              t.sessionId.equals(sessionId) &
              t.gateType.equals(gateType)))
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

  Future<void> deleteRecordsForStudent(String studentId, String sessionId) {
    return (delete(offlineAttendance)
          ..where((t) =>
              t.studentId.equals(studentId) & t.sessionId.equals(sessionId)))
        .go();
  }
}
