import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'tables/cached_events_table.dart';
import 'tables/cached_participants_table.dart';
import 'tables/cached_payables_table.dart';
import 'tables/offline_attendance_table.dart';
import 'tables/scanner_assignments_table.dart';

import 'daos/events_dao.dart';
import 'daos/participants_dao.dart';
import 'daos/attendance_dao.dart';
import 'daos/payables_dao.dart';
import 'daos/scanner_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    CachedEvents,
    CachedParticipants,
    OfflineAttendance,
    CachedPayables,
    ScannerAssignments,
  ],
  daos: [
    EventsDao,
    ParticipantsDao,
    AttendanceDao,
    PayablesDao,
    ScannerDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(cachedPayables, cachedPayables.studentName);
          await m.addColumn(cachedPayables, cachedPayables.studentIdNumber);
          await m.addColumn(cachedPayables, cachedPayables.profilePhotoUrl);
          await m.addColumn(cachedPayables, cachedPayables.eventTitle);
          await m.addColumn(cachedPayables, cachedPayables.courseInfo);
        }
      },
    );
  }

  EventsDao get eventsDao => EventsDao(this);
  ParticipantsDao get participantsDao => ParticipantsDao(this);
  AttendanceDao get attendanceDao => AttendanceDao(this);
  PayablesDao get payablesDao => PayablesDao(this);
  ScannerDao get scannerDao => ScannerDao(this);

  Future<void> clearAllData() async {
    await customStatement('PRAGMA foreign_keys = OFF');
    try {
      await transaction(() async {
        for (final table in allTables) {
          await delete(table).go();
        }
      });
    } finally {
      await customStatement('PRAGMA foreign_keys = ON');
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'sti_sync.sqlite'));

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});
