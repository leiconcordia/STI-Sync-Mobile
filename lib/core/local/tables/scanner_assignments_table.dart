import 'package:drift/drift.dart';

class ScannerAssignments extends Table {
  TextColumn get eventId => text()();
  TextColumn get sessionIds => text()();
  TextColumn get officerUserId => text()();
  TextColumn get permissions => text()();
  IntColumn get dataDownloaded => integer()();
  IntColumn get downloadedAt => integer()();

  @override
  Set<Column> get primaryKey => {eventId};
}
