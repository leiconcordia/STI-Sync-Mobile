// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_dao.dart';

// ignore_for_file: type=lint
mixin _$AttendanceDaoMixin on DatabaseAccessor<AppDatabase> {
  $OfflineAttendanceTable get offlineAttendance =>
      attachedDatabase.offlineAttendance;
  AttendanceDaoManager get managers => AttendanceDaoManager(this);
}

class AttendanceDaoManager {
  final _$AttendanceDaoMixin _db;
  AttendanceDaoManager(this._db);
  $$OfflineAttendanceTableTableManager get offlineAttendance =>
      $$OfflineAttendanceTableTableManager(
          _db.attachedDatabase, _db.offlineAttendance);
}
