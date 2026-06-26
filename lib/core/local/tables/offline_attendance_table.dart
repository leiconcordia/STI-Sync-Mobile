import 'package:drift/drift.dart';

class OfflineAttendance extends Table {
  TextColumn get localId => text()();
  TextColumn get eventId => text()();
  TextColumn get sessionId => text()();
  TextColumn get studentId => text()();
  TextColumn get studentName => text()();
  TextColumn get gateType => text()();
  TextColumn get scanMethod => text()();
  TextColumn get scannedBy => text()();
  IntColumn get scannedAt => integer()();
  IntColumn get synced => integer()();
  IntColumn get syncedAt => integer().nullable()();
  IntColumn get conflictResolved => integer()();

  @override
  Set<Column> get primaryKey => {localId};
}
