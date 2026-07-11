import 'package:drift/drift.dart';

/// Local SQLite table that caches scanner assignments for offline access.
///
/// Schema version 3 — added eventTitle, eventEndTime, proposalStatus.
class ScannerAssignments extends Table {
  /// Firestore event document ID (primary key).
  TextColumn get eventId => text()();

  /// Human-readable event name for offline display.
  TextColumn get eventTitle => text().withDefault(const Constant(''))();

  /// Event format: 'On-Campus' | 'Online' | 'Hybrid'.
  TextColumn get eventFormat => text().withDefault(const Constant(''))();

  /// JSON-encoded List<Map<String,dynamic>> of all sessions for this event.
  TextColumn get sessions => text().withDefault(const Constant('[]'))();

  /// Firebase Auth UID of the officer who holds this assignment.
  TextColumn get officerUserId => text()();

  /// JSON-encoded Map<String, dynamic> of EventScanner permission flags.
  TextColumn get permissions => text()();

  /// End DateTime of the last session, stored as Unix milliseconds.
  /// Used for offline `isActive` and `canScan` checks without hitting Firestore.
  IntColumn get eventEndTime => integer().withDefault(const Constant(0))();

  /// Firestore proposalStatus — 'approved' | 'draft'.
  TextColumn get proposalStatus => text().withDefault(const Constant(''))();
  IntColumn get gracePeriodMinutes => integer().nullable()();

  /// 1 if participant data has been downloaded for offline scanning, else 0.
  IntColumn get dataDownloaded => integer()();

  /// Unix milliseconds when participant data was last downloaded; 0 if never.
  IntColumn get downloadedAt => integer()();

  @override
  Set<Column> get primaryKey => {eventId};
}
