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
      await into(scannerAssignments).insertOnConflictUpdate(assignment.copyWith(
        dataDownloaded: Value(existing.dataDownloaded),
        downloadedAt: Value(existing.downloadedAt),
      ));
      return;
    }
    await into(scannerAssignments).insertOnConflictUpdate(assignment);
  }

  Future<ScannerAssignment?> getAssignment(String eventId) {
    return (select(scannerAssignments)..where((t) => t.eventId.equals(eventId))).getSingleOrNull();
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
}
