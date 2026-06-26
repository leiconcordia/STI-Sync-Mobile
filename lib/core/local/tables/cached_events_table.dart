import 'package:drift/drift.dart';

class CachedEvents extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get eventJson => text()();
  IntColumn get cachedAt => integer()();
  IntColumn get expiresAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
