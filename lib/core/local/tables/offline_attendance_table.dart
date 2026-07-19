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
  TextColumn get status => text().withDefault(const Constant('Present'))();

  /// 1 = flagged for review, 0 = normal scan
  IntColumn get isFlagged => integer().withDefault(const Constant(0))();

  /// Reason for flagging: 'no_phone' | 'payment_pending' | 'not_registered' | 'device_error' | 'other'
  TextColumn get flagReason => text().nullable()();

  /// Optional free-text note from the scanner officer
  TextColumn get flagNote => text().nullable()();

  /// 1 = manually entered (not QR scanned), 0 = QR scanned
  IntColumn get isManual => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {localId};
}
