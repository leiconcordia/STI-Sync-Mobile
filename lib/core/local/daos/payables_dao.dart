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
    final p = await (select(cachedPayables)
          ..where(
              (t) => t.studentId.equals(studentId) & t.eventId.equals(eventId)))
        .getSingleOrNull();
    if (p == null) return false;
    return p.qrTicketUnlocked == 1;
  }

  Future<CachedPayable?> getPayable(String studentId, String eventId) async {
    return (select(cachedPayables)
          ..where(
              (t) => t.studentId.equals(studentId) & t.eventId.equals(eventId)))
        .getSingleOrNull();
  }

  Future<void> purgeEventPayables(String eventId) {
    return (delete(cachedPayables)..where((t) => t.eventId.equals(eventId)))
        .go();
  }
}
