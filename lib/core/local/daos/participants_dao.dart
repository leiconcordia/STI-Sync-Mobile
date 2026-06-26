import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/cached_participants_table.dart';

part 'participants_dao.g.dart';

@DriftAccessor(tables: [CachedParticipants])
class ParticipantsDao extends DatabaseAccessor<AppDatabase> with _$ParticipantsDaoMixin {
  ParticipantsDao(AppDatabase db) : super(db);

  Future<void> upsertParticipants(List<CachedParticipantsCompanion> participants) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(cachedParticipants, participants);
    });
  }

  Future<CachedParticipant?> getParticipantByStudentId(String studentId, String eventId) {
    return (select(cachedParticipants)
          ..where((t) => t.id.equals(studentId) & t.eventId.equals(eventId)))
        .getSingleOrNull();
  }

  Future<List<CachedParticipant>> getAllForEvent(String eventId) {
    return (select(cachedParticipants)..where((t) => t.eventId.equals(eventId))).get();
  }

  Future<void> purgeEventParticipants(String eventId) {
    return (delete(cachedParticipants)..where((t) => t.eventId.equals(eventId))).go();
  }

  Future<bool> isQrUnlocked(String studentId, String eventId) async {
    final p = await getParticipantByStudentId(studentId, eventId);
    if (p == null) return false;
    return p.qrTicketUnlocked == 1;
  }
}
