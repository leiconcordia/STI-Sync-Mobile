import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/cached_payables_table.dart';

part 'payables_dao.g.dart';

@DriftAccessor(tables: [CachedPayables])
class PayablesDao extends DatabaseAccessor<AppDatabase> with _$PayablesDaoMixin {
  PayablesDao(AppDatabase db) : super(db);

  Future<void> upsertPayable(CachedPayablesCompanion payable) {
    return into(cachedPayables).insertOnConflictUpdate(payable);
  }

  Future<bool> isUnlocked(String studentId, String eventId) async {
    final p = await (select(cachedPayables)
          ..where((t) => t.studentId.equals(studentId) & t.eventId.equals(eventId)))
        .getSingleOrNull();
    if (p == null) return false;
    return p.qrTicketUnlocked == 1;
  }

  Future<void> purgeEventPayables(String eventId) {
    return (delete(cachedPayables)..where((t) => t.eventId.equals(eventId))).go();
  }
}
