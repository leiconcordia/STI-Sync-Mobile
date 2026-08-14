import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
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
  int get schemaVersion => 9;

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
        if (from < 3) {
          // scanner_assignments gained eventTitle, eventFormat, eventEndTime,
          // proposalStatus columns in schema v3.
          await m.addColumn(
              scannerAssignments, scannerAssignments.eventTitle);
          await m.addColumn(
              scannerAssignments, scannerAssignments.eventFormat);
          await m.addColumn(
              scannerAssignments, scannerAssignments.eventEndTime);
          await m.addColumn(
              scannerAssignments, scannerAssignments.proposalStatus);
        }
        if (from < 4) {
          await m.deleteTable(cachedParticipants.actualTableName);
          await m.createTable(cachedParticipants);
        }
        if (from < 5) {
          // Recreate scanner_assignments to handle column rename/type change
          await m.deleteTable(scannerAssignments.actualTableName);
          await m.createTable(scannerAssignments);
        }
        if (from < 6) {
          try {
            await m.addColumn(scannerAssignments, scannerAssignments.gracePeriodMinutes);
          } catch (e) {
            // Ignore if column already exists
          }
          try {
            await m.addColumn(offlineAttendance, offlineAttendance.status);
          } catch (e) {
            // Ignore if column already exists
          }
        }
        if (from < 7) {
          try {
            await m.addColumn(scannerAssignments, scannerAssignments.gracePeriodMinutes);
          } catch (e) {
            // Ignore if column already exists
          }
        }
        if (from < 8) {
          // Add flagged/manual attendance columns to offline_attendance
          try {
            await m.addColumn(offlineAttendance, offlineAttendance.isFlagged);
          } catch (e) {
            // Ignore if column already exists
          }
          try {
            await m.addColumn(offlineAttendance, offlineAttendance.flagReason);
          } catch (e) {
            // Ignore if column already exists
          }
          try {
            await m.addColumn(offlineAttendance, offlineAttendance.flagNote);
          } catch (e) {
            // Ignore if column already exists
          }
          try {
            await m.addColumn(offlineAttendance, offlineAttendance.isManual);
          } catch (e) {
            // Ignore if column already exists
          }
        }
        if (from < 9) {
          try {
            await m.addColumn(cachedPayables, cachedPayables.studentSchoolId);
            await m.addColumn(cachedPayables, cachedPayables.type);
            await m.addColumn(cachedPayables, cachedPayables.label);
            await m.addColumn(cachedPayables, cachedPayables.description);
            await m.addColumn(cachedPayables, cachedPayables.organizationId);
            await m.addColumn(cachedPayables, cachedPayables.organizationName);
            await m.addColumn(cachedPayables, cachedPayables.semesterId);
            await m.addColumn(cachedPayables, cachedPayables.assignedAmount);
            await m.addColumn(cachedPayables, cachedPayables.paidAmount);
            await m.addColumn(cachedPayables, cachedPayables.status);
            await m.addColumn(cachedPayables, cachedPayables.dueDate);
            await m.addColumn(cachedPayables, cachedPayables.paidAt);
          } catch (e) {
            // Ignore if column already exists
          }
        }
      },
    );
  }

  @override
  EventsDao get eventsDao => EventsDao(this);
  @override
  ParticipantsDao get participantsDao => ParticipantsDao(this);
  @override
  AttendanceDao get attendanceDao => AttendanceDao(this);
  @override
  PayablesDao get payablesDao => PayablesDao(this);
  @override
  ScannerDao get scannerDao => ScannerDao(this);


  Future<void> clearAllData() async {
    await customStatement('PRAGMA foreign_keys = OFF');
    try {
      for (final table in allTables) {
        int retries = 0;
        while (retries < 3) {
          try {
            await delete(table).go();
            break;
          } catch (e) {
            retries++;
            if (retries >= 3) {
              debugPrint('⚠️ Warning: Failed to purge table ${table.actualTableName} on logout: $e');
              break;
            }
            await Future.delayed(const Duration(milliseconds: 150));
          }
        }
      }
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
