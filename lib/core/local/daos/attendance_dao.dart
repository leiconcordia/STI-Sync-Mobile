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
}
