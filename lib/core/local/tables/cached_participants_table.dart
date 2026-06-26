import 'package:drift/drift.dart';

class CachedParticipants extends Table {
  TextColumn get id => text()();
  TextColumn get eventId => text()();
  TextColumn get studentName => text()();
  TextColumn get studentNumber => text().nullable()();
  TextColumn get course => text().nullable()();
  IntColumn get yearLevel => integer().nullable()();
  TextColumn get profilePhotoUrl => text().nullable()();
  IntColumn get qrTicketUnlocked => integer()();
  TextColumn get participantJson => text()();
  IntColumn get downloadedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
