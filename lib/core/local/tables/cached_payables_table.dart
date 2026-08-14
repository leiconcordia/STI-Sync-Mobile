import 'package:drift/drift.dart';

class CachedPayables extends Table {
  TextColumn get id => text()();
  TextColumn get studentId => text()();
  TextColumn get studentName => text().nullable()();
  TextColumn get studentSchoolId => text().nullable()();
  TextColumn get type => text().withDefault(const Constant('event_fee'))();
  TextColumn get label => text().withDefault(const Constant('Payable Fee'))();
  TextColumn get description => text().nullable()();
  TextColumn get organizationId => text().nullable()();
  TextColumn get organizationName => text().nullable()();
  TextColumn get eventId => text().nullable()();
  TextColumn get semesterId => text().withDefault(const Constant(''))();
  RealColumn get assignedAmount => real().withDefault(const Constant(0.0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  RealColumn get amountDue => real().withDefault(const Constant(0.0))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get paymentStatus => text().withDefault(const Constant('unpaid'))();
  IntColumn get qrTicketUnlocked => integer().withDefault(const Constant(0))();
  IntColumn get dueDate => integer().nullable()();
  IntColumn get paidAt => integer().nullable()();
  IntColumn get cachedAt => integer().withDefault(const Constant(0))();

  // Denormalized student & event details for offline ticket rendering
  TextColumn get studentIdNumber => text().nullable()();
  TextColumn get profilePhotoUrl => text().nullable()();
  TextColumn get eventTitle => text().nullable()();
  TextColumn get courseInfo => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

