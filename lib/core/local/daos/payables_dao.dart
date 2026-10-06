import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/cached_payables_table.dart';

part 'payables_dao.g.dart';

@DriftAccessor(tables: [CachedPayables])
class PayablesDao extends DatabaseAccessor<AppDatabase>
    with _$PayablesDaoMixin {
  PayablesDao(super.db);

  Future<void> upsertPayable(CachedPayablesCompanion payable) {
    return into(cachedPayables).insertOnConflictUpdate(payable);
  }

  Future<void> batchUpsertPayables(List<CachedPayablesCompanion> payables) {
    return batch((b) {
      for (final p in payables) {
        b.insert(cachedPayables, p, mode: InsertMode.insertOrReplace);
      }
    });
  }

  /// Stores one canonical local ticket state per student/event pair. Firestore
  /// payable IDs can change between a missing-payable fallback and a later
  /// created payable, so the local cache must not retain duplicate rows.
  Future<void> replacePayable(
    CachedPayablesCompanion payable, {
    required String studentId,
    required String eventId,
  }) {
    return transaction(() async {
      await (delete(cachedPayables)
            ..where(
              (table) =>
                  table.studentId.equals(studentId) &
                  table.eventId.equals(eventId),
            ))
          .go();
      await into(cachedPayables).insertOnConflictUpdate(payable);
    });
  }

  Future<bool> isUnlocked(String studentId, String eventId) async {
    final list = await (select(cachedPayables)
          ..where(
              (t) => t.studentId.equals(studentId) & t.eventId.equals(eventId))
          ..limit(1))
        .get();
    if (list.isEmpty) return false;
    return list.first.qrTicketUnlocked == 1;
  }

  Future<CachedPayable?> getPayable(String studentId, String eventId) async {
    final list = await (select(cachedPayables)
          ..where(
              (t) => t.studentId.equals(studentId) & t.eventId.equals(eventId))
          ..limit(1))
        .get();
    return list.firstOrNull;
  }

  Future<List<CachedPayable>> getPayablesForStudent(String studentId) {
    return (select(cachedPayables)..where((t) => t.studentId.equals(studentId))).get();
  }

  Future<CachedPayable?> getPayableByEvent(String eventId, [String? studentId]) async {
    final query = select(cachedPayables)
      ..where((t) {
        if (studentId != null && studentId.isNotEmpty) {
          return t.eventId.equals(eventId) & t.studentId.equals(studentId);
        }
        return t.eventId.equals(eventId);
      })
      ..limit(1);
    final list = await query.get();
    return list.firstOrNull;
  }

  Future<void> purgeEventPayables(String eventId) {
    return (delete(cachedPayables)..where((t) => t.eventId.equals(eventId)))
        .go();
  }
}


