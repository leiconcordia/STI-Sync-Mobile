// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payables_dao.dart';

// ignore_for_file: type=lint
mixin _$PayablesDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedPayablesTable get cachedPayables => attachedDatabase.cachedPayables;
  PayablesDaoManager get managers => PayablesDaoManager(this);
}

class PayablesDaoManager {
  final _$PayablesDaoMixin _db;
  PayablesDaoManager(this._db);
  $$CachedPayablesTableTableManager get cachedPayables =>
      $$CachedPayablesTableTableManager(
          _db.attachedDatabase, _db.cachedPayables);
}
