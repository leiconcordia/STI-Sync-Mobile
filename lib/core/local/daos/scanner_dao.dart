import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/scanner_assignments_table.dart';

part 'scanner_dao.g.dart';

@DriftAccessor(tables: [ScannerAssignments])
class ScannerDao extends DatabaseAccessor<AppDatabase> with _$ScannerDaoMixin {
  ScannerDao(AppDatabase db) : super(db);

  Future<void> saveAssignment(ScannerAssignmentsCompanion assignment) async {
    final existing = await getAssignment(assignment.eventId.value);
    if (existing != null) {
      final isDownloaded = (assignment.dataDownloaded.present && assignment.dataDownloaded.value == 1) ||
          existing.dataDownloaded == 1;
      final dlAt = (assignment.downloadedAt.present && assignment.downloadedAt.value > 0)
          ? assignment.downloadedAt.value
          : existing.downloadedAt;
      await into(scannerAssignments).insertOnConflictUpdate(assignment.copyWith(
        dataDownloaded: Value(isDownloaded ? 1 : 0),
        downloadedAt: Value(dlAt),
      ));
      return;
    }
    await into(scannerAssignments).insertOnConflictUpdate(assignment);
  }

  Future<ScannerAssignment?> getAssignment(String eventId) async {
    final list = await (select(scannerAssignments)
          ..where((t) => t.eventId.equals(eventId))
          ..limit(1))
        .get();
    return list.firstOrNull;
  }

  Future<void> markDataDownloaded(String eventId) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await (update(scannerAssignments)..where((t) => t.eventId.equals(eventId))).write(
      ScannerAssignmentsCompanion(
        dataDownloaded: const Value(1),
        downloadedAt: Value(nowMs),
      ),
    );
  }

  Future<void> deleteAssignment(String eventId) {
    return (delete(scannerAssignments)..where((t) => t.eventId.equals(eventId))).go();
  }

  Future<List<ScannerAssignment>> getAllAssignments() {
    return select(scannerAssignments).get();
  }

  Future<List<ScannerAssignment>> getAssignmentsForOfficer(String officerUserId) {
    return (select(scannerAssignments)
          ..where((t) => t.officerUserId.equals(officerUserId)))
        .get();
  }

  Future<int> clearAllAssignments() {
    return delete(scannerAssignments).go();
  }

  Future<int> deleteAssignmentsForOfficer(String officerUserId) {
    return (delete(scannerAssignments)
          ..where((t) => t.officerUserId.equals(officerUserId)))
        .go();
  }
}
