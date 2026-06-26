// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scanner_dao.dart';

// ignore_for_file: type=lint
mixin _$ScannerDaoMixin on DatabaseAccessor<AppDatabase> {
  $ScannerAssignmentsTable get scannerAssignments =>
      attachedDatabase.scannerAssignments;
  ScannerDaoManager get managers => ScannerDaoManager(this);
}

class ScannerDaoManager {
  final _$ScannerDaoMixin _db;
  ScannerDaoManager(this._db);
  $$ScannerAssignmentsTableTableManager get scannerAssignments =>
      $$ScannerAssignmentsTableTableManager(
          _db.attachedDatabase, _db.scannerAssignments);
}
