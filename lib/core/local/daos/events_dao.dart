import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/cached_events_table.dart';

part 'events_dao.g.dart';

@DriftAccessor(tables: [CachedEvents])
class EventsDao extends DatabaseAccessor<AppDatabase> with _$EventsDaoMixin {
  EventsDao(AppDatabase db) : super(db);

  Future<void> upsertEvent(CachedEventsCompanion event) {
    return into(cachedEvents).insertOnConflictUpdate(event);
  }

  Future<CachedEvent?> getEvent(String eventId) {
    return (select(cachedEvents)..where((t) => t.id.equals(eventId))).getSingleOrNull();
  }

  Future<List<CachedEvent>> getAllEvents() {
    return select(cachedEvents).get();
  }

  Future<void> deleteExpiredEvents() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return (delete(cachedEvents)..where((t) => t.expiresAt.isSmallerThanValue(nowMs))).go();
  }

  Stream<List<CachedEvent>> watchAllEvents() {
    return select(cachedEvents).watch();
  }
}
