import 'package:drift/drift.dart';

class CachedPayables extends Table {
  TextColumn get id => text()();
  TextColumn get eventId => text()();
  TextColumn get studentId => text()();
  IntColumn get qrTicketUnlocked => integer()();
  RealColumn get amountDue => real()();
  TextColumn get paymentStatus => text()();
  IntColumn get cachedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
