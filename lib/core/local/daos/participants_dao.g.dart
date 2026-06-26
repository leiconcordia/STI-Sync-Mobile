// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participants_dao.dart';

// ignore_for_file: type=lint
mixin _$ParticipantsDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedParticipantsTable get cachedParticipants =>
      attachedDatabase.cachedParticipants;
  ParticipantsDaoManager get managers => ParticipantsDaoManager(this);
}

class ParticipantsDaoManager {
  final _$ParticipantsDaoMixin _db;
  ParticipantsDaoManager(this._db);
  $$CachedParticipantsTableTableManager get cachedParticipants =>
      $$CachedParticipantsTableTableManager(
          _db.attachedDatabase, _db.cachedParticipants);
}
