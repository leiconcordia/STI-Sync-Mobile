// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedEventsTable extends CachedEvents
    with TableInfo<$CachedEventsTable, CachedEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventJsonMeta =
      const VerificationMeta('eventJson');
  @override
  late final GeneratedColumn<String> eventJson = GeneratedColumn<String>(
      'event_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>(
      'expires_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, eventJson, cachedAt, expiresAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_events';
  @override
  VerificationContext validateIntegrity(Insertable<CachedEvent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('event_json')) {
      context.handle(_eventJsonMeta,
          eventJson.isAcceptableOrUnknown(data['event_json']!, _eventJsonMeta));
    } else if (isInserting) {
      context.missing(_eventJsonMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedEvent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      eventJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_json'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cached_at'])!,
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}expires_at'])!,
    );
  }

  @override
  $CachedEventsTable createAlias(String alias) {
    return $CachedEventsTable(attachedDatabase, alias);
  }
}

class CachedEvent extends DataClass implements Insertable<CachedEvent> {
  final String id;
  final String title;
  final String eventJson;
  final int cachedAt;
  final int expiresAt;
  const CachedEvent(
      {required this.id,
      required this.title,
      required this.eventJson,
      required this.cachedAt,
      required this.expiresAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['event_json'] = Variable<String>(eventJson);
    map['cached_at'] = Variable<int>(cachedAt);
    map['expires_at'] = Variable<int>(expiresAt);
    return map;
  }

  CachedEventsCompanion toCompanion(bool nullToAbsent) {
    return CachedEventsCompanion(
      id: Value(id),
      title: Value(title),
      eventJson: Value(eventJson),
      cachedAt: Value(cachedAt),
      expiresAt: Value(expiresAt),
    );
  }

  factory CachedEvent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedEvent(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      eventJson: serializer.fromJson<String>(json['eventJson']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
      expiresAt: serializer.fromJson<int>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'eventJson': serializer.toJson<String>(eventJson),
      'cachedAt': serializer.toJson<int>(cachedAt),
      'expiresAt': serializer.toJson<int>(expiresAt),
    };
  }

  CachedEvent copyWith(
          {String? id,
          String? title,
          String? eventJson,
          int? cachedAt,
          int? expiresAt}) =>
      CachedEvent(
        id: id ?? this.id,
        title: title ?? this.title,
        eventJson: eventJson ?? this.eventJson,
        cachedAt: cachedAt ?? this.cachedAt,
        expiresAt: expiresAt ?? this.expiresAt,
      );
  CachedEvent copyWithCompanion(CachedEventsCompanion data) {
    return CachedEvent(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      eventJson: data.eventJson.present ? data.eventJson.value : this.eventJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedEvent(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('eventJson: $eventJson, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, eventJson, cachedAt, expiresAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedEvent &&
          other.id == this.id &&
          other.title == this.title &&
          other.eventJson == this.eventJson &&
          other.cachedAt == this.cachedAt &&
          other.expiresAt == this.expiresAt);
}

class CachedEventsCompanion extends UpdateCompanion<CachedEvent> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> eventJson;
  final Value<int> cachedAt;
  final Value<int> expiresAt;
  final Value<int> rowid;
  const CachedEventsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.eventJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedEventsCompanion.insert({
    required String id,
    required String title,
    required String eventJson,
    required int cachedAt,
    required int expiresAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        eventJson = Value(eventJson),
        cachedAt = Value(cachedAt),
        expiresAt = Value(expiresAt);
  static Insertable<CachedEvent> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? eventJson,
    Expression<int>? cachedAt,
    Expression<int>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (eventJson != null) 'event_json': eventJson,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedEventsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? eventJson,
      Value<int>? cachedAt,
      Value<int>? expiresAt,
      Value<int>? rowid}) {
    return CachedEventsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      eventJson: eventJson ?? this.eventJson,
      cachedAt: cachedAt ?? this.cachedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (eventJson.present) {
      map['event_json'] = Variable<String>(eventJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedEventsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('eventJson: $eventJson, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedParticipantsTable extends CachedParticipants
    with TableInfo<$CachedParticipantsTable, CachedParticipant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedParticipantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _studentNameMeta =
      const VerificationMeta('studentName');
  @override
  late final GeneratedColumn<String> studentName = GeneratedColumn<String>(
      'student_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _studentNumberMeta =
      const VerificationMeta('studentNumber');
  @override
  late final GeneratedColumn<String> studentNumber = GeneratedColumn<String>(
      'student_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _courseMeta = const VerificationMeta('course');
  @override
  late final GeneratedColumn<String> course = GeneratedColumn<String>(
      'course', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _yearLevelMeta =
      const VerificationMeta('yearLevel');
  @override
  late final GeneratedColumn<int> yearLevel = GeneratedColumn<int>(
      'year_level', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _profilePhotoUrlMeta =
      const VerificationMeta('profilePhotoUrl');
  @override
  late final GeneratedColumn<String> profilePhotoUrl = GeneratedColumn<String>(
      'profile_photo_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _qrTicketUnlockedMeta =
      const VerificationMeta('qrTicketUnlocked');
  @override
  late final GeneratedColumn<int> qrTicketUnlocked = GeneratedColumn<int>(
      'qr_ticket_unlocked', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _participantJsonMeta =
      const VerificationMeta('participantJson');
  @override
  late final GeneratedColumn<String> participantJson = GeneratedColumn<String>(
      'participant_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _downloadedAtMeta =
      const VerificationMeta('downloadedAt');
  @override
  late final GeneratedColumn<int> downloadedAt = GeneratedColumn<int>(
      'downloaded_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        eventId,
        studentName,
        studentNumber,
        course,
        yearLevel,
        profilePhotoUrl,
        qrTicketUnlocked,
        participantJson,
        downloadedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_participants';
  @override
  VerificationContext validateIntegrity(Insertable<CachedParticipant> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('student_name')) {
      context.handle(
          _studentNameMeta,
          studentName.isAcceptableOrUnknown(
              data['student_name']!, _studentNameMeta));
    } else if (isInserting) {
      context.missing(_studentNameMeta);
    }
    if (data.containsKey('student_number')) {
      context.handle(
          _studentNumberMeta,
          studentNumber.isAcceptableOrUnknown(
              data['student_number']!, _studentNumberMeta));
    }
    if (data.containsKey('course')) {
      context.handle(_courseMeta,
          course.isAcceptableOrUnknown(data['course']!, _courseMeta));
    }
    if (data.containsKey('year_level')) {
      context.handle(_yearLevelMeta,
          yearLevel.isAcceptableOrUnknown(data['year_level']!, _yearLevelMeta));
    }
    if (data.containsKey('profile_photo_url')) {
      context.handle(
          _profilePhotoUrlMeta,
          profilePhotoUrl.isAcceptableOrUnknown(
              data['profile_photo_url']!, _profilePhotoUrlMeta));
    }
    if (data.containsKey('qr_ticket_unlocked')) {
      context.handle(
          _qrTicketUnlockedMeta,
          qrTicketUnlocked.isAcceptableOrUnknown(
              data['qr_ticket_unlocked']!, _qrTicketUnlockedMeta));
    } else if (isInserting) {
      context.missing(_qrTicketUnlockedMeta);
    }
    if (data.containsKey('participant_json')) {
      context.handle(
          _participantJsonMeta,
          participantJson.isAcceptableOrUnknown(
              data['participant_json']!, _participantJsonMeta));
    } else if (isInserting) {
      context.missing(_participantJsonMeta);
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
          _downloadedAtMeta,
          downloadedAt.isAcceptableOrUnknown(
              data['downloaded_at']!, _downloadedAtMeta));
    } else if (isInserting) {
      context.missing(_downloadedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedParticipant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedParticipant(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      studentName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}student_name'])!,
      studentNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}student_number']),
      course: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}course']),
      yearLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}year_level']),
      profilePhotoUrl: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}profile_photo_url']),
      qrTicketUnlocked: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}qr_ticket_unlocked'])!,
      participantJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}participant_json'])!,
      downloadedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}downloaded_at'])!,
    );
  }

  @override
  $CachedParticipantsTable createAlias(String alias) {
    return $CachedParticipantsTable(attachedDatabase, alias);
  }
}

class CachedParticipant extends DataClass
    implements Insertable<CachedParticipant> {
  final String id;
  final String eventId;
  final String studentName;
  final String? studentNumber;
  final String? course;
  final int? yearLevel;
  final String? profilePhotoUrl;
  final int qrTicketUnlocked;
  final String participantJson;
  final int downloadedAt;
  const CachedParticipant(
      {required this.id,
      required this.eventId,
      required this.studentName,
      this.studentNumber,
      this.course,
      this.yearLevel,
      this.profilePhotoUrl,
      required this.qrTicketUnlocked,
      required this.participantJson,
      required this.downloadedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['event_id'] = Variable<String>(eventId);
    map['student_name'] = Variable<String>(studentName);
    if (!nullToAbsent || studentNumber != null) {
      map['student_number'] = Variable<String>(studentNumber);
    }
    if (!nullToAbsent || course != null) {
      map['course'] = Variable<String>(course);
    }
    if (!nullToAbsent || yearLevel != null) {
      map['year_level'] = Variable<int>(yearLevel);
    }
    if (!nullToAbsent || profilePhotoUrl != null) {
      map['profile_photo_url'] = Variable<String>(profilePhotoUrl);
    }
    map['qr_ticket_unlocked'] = Variable<int>(qrTicketUnlocked);
    map['participant_json'] = Variable<String>(participantJson);
    map['downloaded_at'] = Variable<int>(downloadedAt);
    return map;
  }

  CachedParticipantsCompanion toCompanion(bool nullToAbsent) {
    return CachedParticipantsCompanion(
      id: Value(id),
      eventId: Value(eventId),
      studentName: Value(studentName),
      studentNumber: studentNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(studentNumber),
      course:
          course == null && nullToAbsent ? const Value.absent() : Value(course),
      yearLevel: yearLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(yearLevel),
      profilePhotoUrl: profilePhotoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(profilePhotoUrl),
      qrTicketUnlocked: Value(qrTicketUnlocked),
      participantJson: Value(participantJson),
      downloadedAt: Value(downloadedAt),
    );
  }

  factory CachedParticipant.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedParticipant(
      id: serializer.fromJson<String>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      studentName: serializer.fromJson<String>(json['studentName']),
      studentNumber: serializer.fromJson<String?>(json['studentNumber']),
      course: serializer.fromJson<String?>(json['course']),
      yearLevel: serializer.fromJson<int?>(json['yearLevel']),
      profilePhotoUrl: serializer.fromJson<String?>(json['profilePhotoUrl']),
      qrTicketUnlocked: serializer.fromJson<int>(json['qrTicketUnlocked']),
      participantJson: serializer.fromJson<String>(json['participantJson']),
      downloadedAt: serializer.fromJson<int>(json['downloadedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventId': serializer.toJson<String>(eventId),
      'studentName': serializer.toJson<String>(studentName),
      'studentNumber': serializer.toJson<String?>(studentNumber),
      'course': serializer.toJson<String?>(course),
      'yearLevel': serializer.toJson<int?>(yearLevel),
      'profilePhotoUrl': serializer.toJson<String?>(profilePhotoUrl),
      'qrTicketUnlocked': serializer.toJson<int>(qrTicketUnlocked),
      'participantJson': serializer.toJson<String>(participantJson),
      'downloadedAt': serializer.toJson<int>(downloadedAt),
    };
  }

  CachedParticipant copyWith(
          {String? id,
          String? eventId,
          String? studentName,
          Value<String?> studentNumber = const Value.absent(),
          Value<String?> course = const Value.absent(),
          Value<int?> yearLevel = const Value.absent(),
          Value<String?> profilePhotoUrl = const Value.absent(),
          int? qrTicketUnlocked,
          String? participantJson,
          int? downloadedAt}) =>
      CachedParticipant(
        id: id ?? this.id,
        eventId: eventId ?? this.eventId,
        studentName: studentName ?? this.studentName,
        studentNumber:
            studentNumber.present ? studentNumber.value : this.studentNumber,
        course: course.present ? course.value : this.course,
        yearLevel: yearLevel.present ? yearLevel.value : this.yearLevel,
        profilePhotoUrl: profilePhotoUrl.present
            ? profilePhotoUrl.value
            : this.profilePhotoUrl,
        qrTicketUnlocked: qrTicketUnlocked ?? this.qrTicketUnlocked,
        participantJson: participantJson ?? this.participantJson,
        downloadedAt: downloadedAt ?? this.downloadedAt,
      );
  CachedParticipant copyWithCompanion(CachedParticipantsCompanion data) {
    return CachedParticipant(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      studentName:
          data.studentName.present ? data.studentName.value : this.studentName,
      studentNumber: data.studentNumber.present
          ? data.studentNumber.value
          : this.studentNumber,
      course: data.course.present ? data.course.value : this.course,
      yearLevel: data.yearLevel.present ? data.yearLevel.value : this.yearLevel,
      profilePhotoUrl: data.profilePhotoUrl.present
          ? data.profilePhotoUrl.value
          : this.profilePhotoUrl,
      qrTicketUnlocked: data.qrTicketUnlocked.present
          ? data.qrTicketUnlocked.value
          : this.qrTicketUnlocked,
      participantJson: data.participantJson.present
          ? data.participantJson.value
          : this.participantJson,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedParticipant(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('studentName: $studentName, ')
          ..write('studentNumber: $studentNumber, ')
          ..write('course: $course, ')
          ..write('yearLevel: $yearLevel, ')
          ..write('profilePhotoUrl: $profilePhotoUrl, ')
          ..write('qrTicketUnlocked: $qrTicketUnlocked, ')
          ..write('participantJson: $participantJson, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      eventId,
      studentName,
      studentNumber,
      course,
      yearLevel,
      profilePhotoUrl,
      qrTicketUnlocked,
      participantJson,
      downloadedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedParticipant &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.studentName == this.studentName &&
          other.studentNumber == this.studentNumber &&
          other.course == this.course &&
          other.yearLevel == this.yearLevel &&
          other.profilePhotoUrl == this.profilePhotoUrl &&
          other.qrTicketUnlocked == this.qrTicketUnlocked &&
          other.participantJson == this.participantJson &&
          other.downloadedAt == this.downloadedAt);
}

class CachedParticipantsCompanion extends UpdateCompanion<CachedParticipant> {
  final Value<String> id;
  final Value<String> eventId;
  final Value<String> studentName;
  final Value<String?> studentNumber;
  final Value<String?> course;
  final Value<int?> yearLevel;
  final Value<String?> profilePhotoUrl;
  final Value<int> qrTicketUnlocked;
  final Value<String> participantJson;
  final Value<int> downloadedAt;
  final Value<int> rowid;
  const CachedParticipantsCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.studentName = const Value.absent(),
    this.studentNumber = const Value.absent(),
    this.course = const Value.absent(),
    this.yearLevel = const Value.absent(),
    this.profilePhotoUrl = const Value.absent(),
    this.qrTicketUnlocked = const Value.absent(),
    this.participantJson = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedParticipantsCompanion.insert({
    required String id,
    required String eventId,
    required String studentName,
    this.studentNumber = const Value.absent(),
    this.course = const Value.absent(),
    this.yearLevel = const Value.absent(),
    this.profilePhotoUrl = const Value.absent(),
    required int qrTicketUnlocked,
    required String participantJson,
    required int downloadedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        eventId = Value(eventId),
        studentName = Value(studentName),
        qrTicketUnlocked = Value(qrTicketUnlocked),
        participantJson = Value(participantJson),
        downloadedAt = Value(downloadedAt);
  static Insertable<CachedParticipant> custom({
    Expression<String>? id,
    Expression<String>? eventId,
    Expression<String>? studentName,
    Expression<String>? studentNumber,
    Expression<String>? course,
    Expression<int>? yearLevel,
    Expression<String>? profilePhotoUrl,
    Expression<int>? qrTicketUnlocked,
    Expression<String>? participantJson,
    Expression<int>? downloadedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (studentName != null) 'student_name': studentName,
      if (studentNumber != null) 'student_number': studentNumber,
      if (course != null) 'course': course,
      if (yearLevel != null) 'year_level': yearLevel,
      if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
      if (qrTicketUnlocked != null) 'qr_ticket_unlocked': qrTicketUnlocked,
      if (participantJson != null) 'participant_json': participantJson,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedParticipantsCompanion copyWith(
      {Value<String>? id,
      Value<String>? eventId,
      Value<String>? studentName,
      Value<String?>? studentNumber,
      Value<String?>? course,
      Value<int?>? yearLevel,
      Value<String?>? profilePhotoUrl,
      Value<int>? qrTicketUnlocked,
      Value<String>? participantJson,
      Value<int>? downloadedAt,
      Value<int>? rowid}) {
    return CachedParticipantsCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      studentName: studentName ?? this.studentName,
      studentNumber: studentNumber ?? this.studentNumber,
      course: course ?? this.course,
      yearLevel: yearLevel ?? this.yearLevel,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      qrTicketUnlocked: qrTicketUnlocked ?? this.qrTicketUnlocked,
      participantJson: participantJson ?? this.participantJson,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (studentName.present) {
      map['student_name'] = Variable<String>(studentName.value);
    }
    if (studentNumber.present) {
      map['student_number'] = Variable<String>(studentNumber.value);
    }
    if (course.present) {
      map['course'] = Variable<String>(course.value);
    }
    if (yearLevel.present) {
      map['year_level'] = Variable<int>(yearLevel.value);
    }
    if (profilePhotoUrl.present) {
      map['profile_photo_url'] = Variable<String>(profilePhotoUrl.value);
    }
    if (qrTicketUnlocked.present) {
      map['qr_ticket_unlocked'] = Variable<int>(qrTicketUnlocked.value);
    }
    if (participantJson.present) {
      map['participant_json'] = Variable<String>(participantJson.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<int>(downloadedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedParticipantsCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('studentName: $studentName, ')
          ..write('studentNumber: $studentNumber, ')
          ..write('course: $course, ')
          ..write('yearLevel: $yearLevel, ')
          ..write('profilePhotoUrl: $profilePhotoUrl, ')
          ..write('qrTicketUnlocked: $qrTicketUnlocked, ')
          ..write('participantJson: $participantJson, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfflineAttendanceTable extends OfflineAttendance
    with TableInfo<$OfflineAttendanceTable, OfflineAttendanceData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineAttendanceTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
      'local_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _studentIdMeta =
      const VerificationMeta('studentId');
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
      'student_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _studentNameMeta =
      const VerificationMeta('studentName');
  @override
  late final GeneratedColumn<String> studentName = GeneratedColumn<String>(
      'student_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _gateTypeMeta =
      const VerificationMeta('gateType');
  @override
  late final GeneratedColumn<String> gateType = GeneratedColumn<String>(
      'gate_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scanMethodMeta =
      const VerificationMeta('scanMethod');
  @override
  late final GeneratedColumn<String> scanMethod = GeneratedColumn<String>(
      'scan_method', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scannedByMeta =
      const VerificationMeta('scannedBy');
  @override
  late final GeneratedColumn<String> scannedBy = GeneratedColumn<String>(
      'scanned_by', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scannedAtMeta =
      const VerificationMeta('scannedAt');
  @override
  late final GeneratedColumn<int> scannedAt = GeneratedColumn<int>(
      'scanned_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
      'synced', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<int> syncedAt = GeneratedColumn<int>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _conflictResolvedMeta =
      const VerificationMeta('conflictResolved');
  @override
  late final GeneratedColumn<int> conflictResolved = GeneratedColumn<int>(
      'conflict_resolved', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        eventId,
        sessionId,
        studentId,
        studentName,
        gateType,
        scanMethod,
        scannedBy,
        scannedAt,
        synced,
        syncedAt,
        conflictResolved
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_attendance';
  @override
  VerificationContext validateIntegrity(
      Insertable<OfflineAttendanceData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(_studentIdMeta,
          studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta));
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('student_name')) {
      context.handle(
          _studentNameMeta,
          studentName.isAcceptableOrUnknown(
              data['student_name']!, _studentNameMeta));
    } else if (isInserting) {
      context.missing(_studentNameMeta);
    }
    if (data.containsKey('gate_type')) {
      context.handle(_gateTypeMeta,
          gateType.isAcceptableOrUnknown(data['gate_type']!, _gateTypeMeta));
    } else if (isInserting) {
      context.missing(_gateTypeMeta);
    }
    if (data.containsKey('scan_method')) {
      context.handle(
          _scanMethodMeta,
          scanMethod.isAcceptableOrUnknown(
              data['scan_method']!, _scanMethodMeta));
    } else if (isInserting) {
      context.missing(_scanMethodMeta);
    }
    if (data.containsKey('scanned_by')) {
      context.handle(_scannedByMeta,
          scannedBy.isAcceptableOrUnknown(data['scanned_by']!, _scannedByMeta));
    } else if (isInserting) {
      context.missing(_scannedByMeta);
    }
    if (data.containsKey('scanned_at')) {
      context.handle(_scannedAtMeta,
          scannedAt.isAcceptableOrUnknown(data['scanned_at']!, _scannedAtMeta));
    } else if (isInserting) {
      context.missing(_scannedAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    } else if (isInserting) {
      context.missing(_syncedMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    if (data.containsKey('conflict_resolved')) {
      context.handle(
          _conflictResolvedMeta,
          conflictResolved.isAcceptableOrUnknown(
              data['conflict_resolved']!, _conflictResolvedMeta));
    } else if (isInserting) {
      context.missing(_conflictResolvedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  OfflineAttendanceData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineAttendanceData(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_id'])!,
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      studentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}student_id'])!,
      studentName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}student_name'])!,
      gateType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gate_type'])!,
      scanMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scan_method'])!,
      scannedBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scanned_by'])!,
      scannedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}scanned_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}synced'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}synced_at']),
      conflictResolved: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}conflict_resolved'])!,
    );
  }

  @override
  $OfflineAttendanceTable createAlias(String alias) {
    return $OfflineAttendanceTable(attachedDatabase, alias);
  }
}

class OfflineAttendanceData extends DataClass
    implements Insertable<OfflineAttendanceData> {
  final String localId;
  final String eventId;
  final String sessionId;
  final String studentId;
  final String studentName;
  final String gateType;
  final String scanMethod;
  final String scannedBy;
  final int scannedAt;
  final int synced;
  final int? syncedAt;
  final int conflictResolved;
  const OfflineAttendanceData(
      {required this.localId,
      required this.eventId,
      required this.sessionId,
      required this.studentId,
      required this.studentName,
      required this.gateType,
      required this.scanMethod,
      required this.scannedBy,
      required this.scannedAt,
      required this.synced,
      this.syncedAt,
      required this.conflictResolved});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    map['event_id'] = Variable<String>(eventId);
    map['session_id'] = Variable<String>(sessionId);
    map['student_id'] = Variable<String>(studentId);
    map['student_name'] = Variable<String>(studentName);
    map['gate_type'] = Variable<String>(gateType);
    map['scan_method'] = Variable<String>(scanMethod);
    map['scanned_by'] = Variable<String>(scannedBy);
    map['scanned_at'] = Variable<int>(scannedAt);
    map['synced'] = Variable<int>(synced);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<int>(syncedAt);
    }
    map['conflict_resolved'] = Variable<int>(conflictResolved);
    return map;
  }

  OfflineAttendanceCompanion toCompanion(bool nullToAbsent) {
    return OfflineAttendanceCompanion(
      localId: Value(localId),
      eventId: Value(eventId),
      sessionId: Value(sessionId),
      studentId: Value(studentId),
      studentName: Value(studentName),
      gateType: Value(gateType),
      scanMethod: Value(scanMethod),
      scannedBy: Value(scannedBy),
      scannedAt: Value(scannedAt),
      synced: Value(synced),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      conflictResolved: Value(conflictResolved),
    );
  }

  factory OfflineAttendanceData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineAttendanceData(
      localId: serializer.fromJson<String>(json['localId']),
      eventId: serializer.fromJson<String>(json['eventId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      studentId: serializer.fromJson<String>(json['studentId']),
      studentName: serializer.fromJson<String>(json['studentName']),
      gateType: serializer.fromJson<String>(json['gateType']),
      scanMethod: serializer.fromJson<String>(json['scanMethod']),
      scannedBy: serializer.fromJson<String>(json['scannedBy']),
      scannedAt: serializer.fromJson<int>(json['scannedAt']),
      synced: serializer.fromJson<int>(json['synced']),
      syncedAt: serializer.fromJson<int?>(json['syncedAt']),
      conflictResolved: serializer.fromJson<int>(json['conflictResolved']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'eventId': serializer.toJson<String>(eventId),
      'sessionId': serializer.toJson<String>(sessionId),
      'studentId': serializer.toJson<String>(studentId),
      'studentName': serializer.toJson<String>(studentName),
      'gateType': serializer.toJson<String>(gateType),
      'scanMethod': serializer.toJson<String>(scanMethod),
      'scannedBy': serializer.toJson<String>(scannedBy),
      'scannedAt': serializer.toJson<int>(scannedAt),
      'synced': serializer.toJson<int>(synced),
      'syncedAt': serializer.toJson<int?>(syncedAt),
      'conflictResolved': serializer.toJson<int>(conflictResolved),
    };
  }

  OfflineAttendanceData copyWith(
          {String? localId,
          String? eventId,
          String? sessionId,
          String? studentId,
          String? studentName,
          String? gateType,
          String? scanMethod,
          String? scannedBy,
          int? scannedAt,
          int? synced,
          Value<int?> syncedAt = const Value.absent(),
          int? conflictResolved}) =>
      OfflineAttendanceData(
        localId: localId ?? this.localId,
        eventId: eventId ?? this.eventId,
        sessionId: sessionId ?? this.sessionId,
        studentId: studentId ?? this.studentId,
        studentName: studentName ?? this.studentName,
        gateType: gateType ?? this.gateType,
        scanMethod: scanMethod ?? this.scanMethod,
        scannedBy: scannedBy ?? this.scannedBy,
        scannedAt: scannedAt ?? this.scannedAt,
        synced: synced ?? this.synced,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
        conflictResolved: conflictResolved ?? this.conflictResolved,
      );
  OfflineAttendanceData copyWithCompanion(OfflineAttendanceCompanion data) {
    return OfflineAttendanceData(
      localId: data.localId.present ? data.localId.value : this.localId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      studentName:
          data.studentName.present ? data.studentName.value : this.studentName,
      gateType: data.gateType.present ? data.gateType.value : this.gateType,
      scanMethod:
          data.scanMethod.present ? data.scanMethod.value : this.scanMethod,
      scannedBy: data.scannedBy.present ? data.scannedBy.value : this.scannedBy,
      scannedAt: data.scannedAt.present ? data.scannedAt.value : this.scannedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      conflictResolved: data.conflictResolved.present
          ? data.conflictResolved.value
          : this.conflictResolved,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineAttendanceData(')
          ..write('localId: $localId, ')
          ..write('eventId: $eventId, ')
          ..write('sessionId: $sessionId, ')
          ..write('studentId: $studentId, ')
          ..write('studentName: $studentName, ')
          ..write('gateType: $gateType, ')
          ..write('scanMethod: $scanMethod, ')
          ..write('scannedBy: $scannedBy, ')
          ..write('scannedAt: $scannedAt, ')
          ..write('synced: $synced, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('conflictResolved: $conflictResolved')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      localId,
      eventId,
      sessionId,
      studentId,
      studentName,
      gateType,
      scanMethod,
      scannedBy,
      scannedAt,
      synced,
      syncedAt,
      conflictResolved);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineAttendanceData &&
          other.localId == this.localId &&
          other.eventId == this.eventId &&
          other.sessionId == this.sessionId &&
          other.studentId == this.studentId &&
          other.studentName == this.studentName &&
          other.gateType == this.gateType &&
          other.scanMethod == this.scanMethod &&
          other.scannedBy == this.scannedBy &&
          other.scannedAt == this.scannedAt &&
          other.synced == this.synced &&
          other.syncedAt == this.syncedAt &&
          other.conflictResolved == this.conflictResolved);
}

class OfflineAttendanceCompanion
    extends UpdateCompanion<OfflineAttendanceData> {
  final Value<String> localId;
  final Value<String> eventId;
  final Value<String> sessionId;
  final Value<String> studentId;
  final Value<String> studentName;
  final Value<String> gateType;
  final Value<String> scanMethod;
  final Value<String> scannedBy;
  final Value<int> scannedAt;
  final Value<int> synced;
  final Value<int?> syncedAt;
  final Value<int> conflictResolved;
  final Value<int> rowid;
  const OfflineAttendanceCompanion({
    this.localId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.studentName = const Value.absent(),
    this.gateType = const Value.absent(),
    this.scanMethod = const Value.absent(),
    this.scannedBy = const Value.absent(),
    this.scannedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.conflictResolved = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfflineAttendanceCompanion.insert({
    required String localId,
    required String eventId,
    required String sessionId,
    required String studentId,
    required String studentName,
    required String gateType,
    required String scanMethod,
    required String scannedBy,
    required int scannedAt,
    required int synced,
    this.syncedAt = const Value.absent(),
    required int conflictResolved,
    this.rowid = const Value.absent(),
  })  : localId = Value(localId),
        eventId = Value(eventId),
        sessionId = Value(sessionId),
        studentId = Value(studentId),
        studentName = Value(studentName),
        gateType = Value(gateType),
        scanMethod = Value(scanMethod),
        scannedBy = Value(scannedBy),
        scannedAt = Value(scannedAt),
        synced = Value(synced),
        conflictResolved = Value(conflictResolved);
  static Insertable<OfflineAttendanceData> custom({
    Expression<String>? localId,
    Expression<String>? eventId,
    Expression<String>? sessionId,
    Expression<String>? studentId,
    Expression<String>? studentName,
    Expression<String>? gateType,
    Expression<String>? scanMethod,
    Expression<String>? scannedBy,
    Expression<int>? scannedAt,
    Expression<int>? synced,
    Expression<int>? syncedAt,
    Expression<int>? conflictResolved,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (eventId != null) 'event_id': eventId,
      if (sessionId != null) 'session_id': sessionId,
      if (studentId != null) 'student_id': studentId,
      if (studentName != null) 'student_name': studentName,
      if (gateType != null) 'gate_type': gateType,
      if (scanMethod != null) 'scan_method': scanMethod,
      if (scannedBy != null) 'scanned_by': scannedBy,
      if (scannedAt != null) 'scanned_at': scannedAt,
      if (synced != null) 'synced': synced,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (conflictResolved != null) 'conflict_resolved': conflictResolved,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfflineAttendanceCompanion copyWith(
      {Value<String>? localId,
      Value<String>? eventId,
      Value<String>? sessionId,
      Value<String>? studentId,
      Value<String>? studentName,
      Value<String>? gateType,
      Value<String>? scanMethod,
      Value<String>? scannedBy,
      Value<int>? scannedAt,
      Value<int>? synced,
      Value<int?>? syncedAt,
      Value<int>? conflictResolved,
      Value<int>? rowid}) {
    return OfflineAttendanceCompanion(
      localId: localId ?? this.localId,
      eventId: eventId ?? this.eventId,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      gateType: gateType ?? this.gateType,
      scanMethod: scanMethod ?? this.scanMethod,
      scannedBy: scannedBy ?? this.scannedBy,
      scannedAt: scannedAt ?? this.scannedAt,
      synced: synced ?? this.synced,
      syncedAt: syncedAt ?? this.syncedAt,
      conflictResolved: conflictResolved ?? this.conflictResolved,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (studentName.present) {
      map['student_name'] = Variable<String>(studentName.value);
    }
    if (gateType.present) {
      map['gate_type'] = Variable<String>(gateType.value);
    }
    if (scanMethod.present) {
      map['scan_method'] = Variable<String>(scanMethod.value);
    }
    if (scannedBy.present) {
      map['scanned_by'] = Variable<String>(scannedBy.value);
    }
    if (scannedAt.present) {
      map['scanned_at'] = Variable<int>(scannedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<int>(syncedAt.value);
    }
    if (conflictResolved.present) {
      map['conflict_resolved'] = Variable<int>(conflictResolved.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineAttendanceCompanion(')
          ..write('localId: $localId, ')
          ..write('eventId: $eventId, ')
          ..write('sessionId: $sessionId, ')
          ..write('studentId: $studentId, ')
          ..write('studentName: $studentName, ')
          ..write('gateType: $gateType, ')
          ..write('scanMethod: $scanMethod, ')
          ..write('scannedBy: $scannedBy, ')
          ..write('scannedAt: $scannedAt, ')
          ..write('synced: $synced, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('conflictResolved: $conflictResolved, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedPayablesTable extends CachedPayables
    with TableInfo<$CachedPayablesTable, CachedPayable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPayablesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _studentIdMeta =
      const VerificationMeta('studentId');
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
      'student_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _qrTicketUnlockedMeta =
      const VerificationMeta('qrTicketUnlocked');
  @override
  late final GeneratedColumn<int> qrTicketUnlocked = GeneratedColumn<int>(
      'qr_ticket_unlocked', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _amountDueMeta =
      const VerificationMeta('amountDue');
  @override
  late final GeneratedColumn<double> amountDue = GeneratedColumn<double>(
      'amount_due', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _paymentStatusMeta =
      const VerificationMeta('paymentStatus');
  @override
  late final GeneratedColumn<String> paymentStatus = GeneratedColumn<String>(
      'payment_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _studentNameMeta =
      const VerificationMeta('studentName');
  @override
  late final GeneratedColumn<String> studentName = GeneratedColumn<String>(
      'student_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _studentIdNumberMeta =
      const VerificationMeta('studentIdNumber');
  @override
  late final GeneratedColumn<String> studentIdNumber = GeneratedColumn<String>(
      'student_id_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _profilePhotoUrlMeta =
      const VerificationMeta('profilePhotoUrl');
  @override
  late final GeneratedColumn<String> profilePhotoUrl = GeneratedColumn<String>(
      'profile_photo_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _eventTitleMeta =
      const VerificationMeta('eventTitle');
  @override
  late final GeneratedColumn<String> eventTitle = GeneratedColumn<String>(
      'event_title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _courseInfoMeta =
      const VerificationMeta('courseInfo');
  @override
  late final GeneratedColumn<String> courseInfo = GeneratedColumn<String>(
      'course_info', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        eventId,
        studentId,
        qrTicketUnlocked,
        amountDue,
        paymentStatus,
        cachedAt,
        studentName,
        studentIdNumber,
        profilePhotoUrl,
        eventTitle,
        courseInfo
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_payables';
  @override
  VerificationContext validateIntegrity(Insertable<CachedPayable> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(_studentIdMeta,
          studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta));
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('qr_ticket_unlocked')) {
      context.handle(
          _qrTicketUnlockedMeta,
          qrTicketUnlocked.isAcceptableOrUnknown(
              data['qr_ticket_unlocked']!, _qrTicketUnlockedMeta));
    } else if (isInserting) {
      context.missing(_qrTicketUnlockedMeta);
    }
    if (data.containsKey('amount_due')) {
      context.handle(_amountDueMeta,
          amountDue.isAcceptableOrUnknown(data['amount_due']!, _amountDueMeta));
    } else if (isInserting) {
      context.missing(_amountDueMeta);
    }
    if (data.containsKey('payment_status')) {
      context.handle(
          _paymentStatusMeta,
          paymentStatus.isAcceptableOrUnknown(
              data['payment_status']!, _paymentStatusMeta));
    } else if (isInserting) {
      context.missing(_paymentStatusMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('student_name')) {
      context.handle(
          _studentNameMeta,
          studentName.isAcceptableOrUnknown(
              data['student_name']!, _studentNameMeta));
    }
    if (data.containsKey('student_id_number')) {
      context.handle(
          _studentIdNumberMeta,
          studentIdNumber.isAcceptableOrUnknown(
              data['student_id_number']!, _studentIdNumberMeta));
    }
    if (data.containsKey('profile_photo_url')) {
      context.handle(
          _profilePhotoUrlMeta,
          profilePhotoUrl.isAcceptableOrUnknown(
              data['profile_photo_url']!, _profilePhotoUrlMeta));
    }
    if (data.containsKey('event_title')) {
      context.handle(
          _eventTitleMeta,
          eventTitle.isAcceptableOrUnknown(
              data['event_title']!, _eventTitleMeta));
    }
    if (data.containsKey('course_info')) {
      context.handle(
          _courseInfoMeta,
          courseInfo.isAcceptableOrUnknown(
              data['course_info']!, _courseInfoMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedPayable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPayable(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      studentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}student_id'])!,
      qrTicketUnlocked: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}qr_ticket_unlocked'])!,
      amountDue: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount_due'])!,
      paymentStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_status'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cached_at'])!,
      studentName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}student_name']),
      studentIdNumber: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}student_id_number']),
      profilePhotoUrl: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}profile_photo_url']),
      eventTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_title']),
      courseInfo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}course_info']),
    );
  }

  @override
  $CachedPayablesTable createAlias(String alias) {
    return $CachedPayablesTable(attachedDatabase, alias);
  }
}

class CachedPayable extends DataClass implements Insertable<CachedPayable> {
  final String id;
  final String eventId;
  final String studentId;
  final int qrTicketUnlocked;
  final double amountDue;
  final String paymentStatus;
  final int cachedAt;
  final String? studentName;
  final String? studentIdNumber;
  final String? profilePhotoUrl;
  final String? eventTitle;
  final String? courseInfo;
  const CachedPayable(
      {required this.id,
      required this.eventId,
      required this.studentId,
      required this.qrTicketUnlocked,
      required this.amountDue,
      required this.paymentStatus,
      required this.cachedAt,
      this.studentName,
      this.studentIdNumber,
      this.profilePhotoUrl,
      this.eventTitle,
      this.courseInfo});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['event_id'] = Variable<String>(eventId);
    map['student_id'] = Variable<String>(studentId);
    map['qr_ticket_unlocked'] = Variable<int>(qrTicketUnlocked);
    map['amount_due'] = Variable<double>(amountDue);
    map['payment_status'] = Variable<String>(paymentStatus);
    map['cached_at'] = Variable<int>(cachedAt);
    if (!nullToAbsent || studentName != null) {
      map['student_name'] = Variable<String>(studentName);
    }
    if (!nullToAbsent || studentIdNumber != null) {
      map['student_id_number'] = Variable<String>(studentIdNumber);
    }
    if (!nullToAbsent || profilePhotoUrl != null) {
      map['profile_photo_url'] = Variable<String>(profilePhotoUrl);
    }
    if (!nullToAbsent || eventTitle != null) {
      map['event_title'] = Variable<String>(eventTitle);
    }
    if (!nullToAbsent || courseInfo != null) {
      map['course_info'] = Variable<String>(courseInfo);
    }
    return map;
  }

  CachedPayablesCompanion toCompanion(bool nullToAbsent) {
    return CachedPayablesCompanion(
      id: Value(id),
      eventId: Value(eventId),
      studentId: Value(studentId),
      qrTicketUnlocked: Value(qrTicketUnlocked),
      amountDue: Value(amountDue),
      paymentStatus: Value(paymentStatus),
      cachedAt: Value(cachedAt),
      studentName: studentName == null && nullToAbsent
          ? const Value.absent()
          : Value(studentName),
      studentIdNumber: studentIdNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(studentIdNumber),
      profilePhotoUrl: profilePhotoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(profilePhotoUrl),
      eventTitle: eventTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(eventTitle),
      courseInfo: courseInfo == null && nullToAbsent
          ? const Value.absent()
          : Value(courseInfo),
    );
  }

  factory CachedPayable.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPayable(
      id: serializer.fromJson<String>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      studentId: serializer.fromJson<String>(json['studentId']),
      qrTicketUnlocked: serializer.fromJson<int>(json['qrTicketUnlocked']),
      amountDue: serializer.fromJson<double>(json['amountDue']),
      paymentStatus: serializer.fromJson<String>(json['paymentStatus']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
      studentName: serializer.fromJson<String?>(json['studentName']),
      studentIdNumber: serializer.fromJson<String?>(json['studentIdNumber']),
      profilePhotoUrl: serializer.fromJson<String?>(json['profilePhotoUrl']),
      eventTitle: serializer.fromJson<String?>(json['eventTitle']),
      courseInfo: serializer.fromJson<String?>(json['courseInfo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventId': serializer.toJson<String>(eventId),
      'studentId': serializer.toJson<String>(studentId),
      'qrTicketUnlocked': serializer.toJson<int>(qrTicketUnlocked),
      'amountDue': serializer.toJson<double>(amountDue),
      'paymentStatus': serializer.toJson<String>(paymentStatus),
      'cachedAt': serializer.toJson<int>(cachedAt),
      'studentName': serializer.toJson<String?>(studentName),
      'studentIdNumber': serializer.toJson<String?>(studentIdNumber),
      'profilePhotoUrl': serializer.toJson<String?>(profilePhotoUrl),
      'eventTitle': serializer.toJson<String?>(eventTitle),
      'courseInfo': serializer.toJson<String?>(courseInfo),
    };
  }

  CachedPayable copyWith(
          {String? id,
          String? eventId,
          String? studentId,
          int? qrTicketUnlocked,
          double? amountDue,
          String? paymentStatus,
          int? cachedAt,
          Value<String?> studentName = const Value.absent(),
          Value<String?> studentIdNumber = const Value.absent(),
          Value<String?> profilePhotoUrl = const Value.absent(),
          Value<String?> eventTitle = const Value.absent(),
          Value<String?> courseInfo = const Value.absent()}) =>
      CachedPayable(
        id: id ?? this.id,
        eventId: eventId ?? this.eventId,
        studentId: studentId ?? this.studentId,
        qrTicketUnlocked: qrTicketUnlocked ?? this.qrTicketUnlocked,
        amountDue: amountDue ?? this.amountDue,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        cachedAt: cachedAt ?? this.cachedAt,
        studentName: studentName.present ? studentName.value : this.studentName,
        studentIdNumber: studentIdNumber.present
            ? studentIdNumber.value
            : this.studentIdNumber,
        profilePhotoUrl: profilePhotoUrl.present
            ? profilePhotoUrl.value
            : this.profilePhotoUrl,
        eventTitle: eventTitle.present ? eventTitle.value : this.eventTitle,
        courseInfo: courseInfo.present ? courseInfo.value : this.courseInfo,
      );
  CachedPayable copyWithCompanion(CachedPayablesCompanion data) {
    return CachedPayable(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      qrTicketUnlocked: data.qrTicketUnlocked.present
          ? data.qrTicketUnlocked.value
          : this.qrTicketUnlocked,
      amountDue: data.amountDue.present ? data.amountDue.value : this.amountDue,
      paymentStatus: data.paymentStatus.present
          ? data.paymentStatus.value
          : this.paymentStatus,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      studentName:
          data.studentName.present ? data.studentName.value : this.studentName,
      studentIdNumber: data.studentIdNumber.present
          ? data.studentIdNumber.value
          : this.studentIdNumber,
      profilePhotoUrl: data.profilePhotoUrl.present
          ? data.profilePhotoUrl.value
          : this.profilePhotoUrl,
      eventTitle:
          data.eventTitle.present ? data.eventTitle.value : this.eventTitle,
      courseInfo:
          data.courseInfo.present ? data.courseInfo.value : this.courseInfo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPayable(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('studentId: $studentId, ')
          ..write('qrTicketUnlocked: $qrTicketUnlocked, ')
          ..write('amountDue: $amountDue, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('studentName: $studentName, ')
          ..write('studentIdNumber: $studentIdNumber, ')
          ..write('profilePhotoUrl: $profilePhotoUrl, ')
          ..write('eventTitle: $eventTitle, ')
          ..write('courseInfo: $courseInfo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      eventId,
      studentId,
      qrTicketUnlocked,
      amountDue,
      paymentStatus,
      cachedAt,
      studentName,
      studentIdNumber,
      profilePhotoUrl,
      eventTitle,
      courseInfo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPayable &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.studentId == this.studentId &&
          other.qrTicketUnlocked == this.qrTicketUnlocked &&
          other.amountDue == this.amountDue &&
          other.paymentStatus == this.paymentStatus &&
          other.cachedAt == this.cachedAt &&
          other.studentName == this.studentName &&
          other.studentIdNumber == this.studentIdNumber &&
          other.profilePhotoUrl == this.profilePhotoUrl &&
          other.eventTitle == this.eventTitle &&
          other.courseInfo == this.courseInfo);
}

class CachedPayablesCompanion extends UpdateCompanion<CachedPayable> {
  final Value<String> id;
  final Value<String> eventId;
  final Value<String> studentId;
  final Value<int> qrTicketUnlocked;
  final Value<double> amountDue;
  final Value<String> paymentStatus;
  final Value<int> cachedAt;
  final Value<String?> studentName;
  final Value<String?> studentIdNumber;
  final Value<String?> profilePhotoUrl;
  final Value<String?> eventTitle;
  final Value<String?> courseInfo;
  final Value<int> rowid;
  const CachedPayablesCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.qrTicketUnlocked = const Value.absent(),
    this.amountDue = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.studentName = const Value.absent(),
    this.studentIdNumber = const Value.absent(),
    this.profilePhotoUrl = const Value.absent(),
    this.eventTitle = const Value.absent(),
    this.courseInfo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedPayablesCompanion.insert({
    required String id,
    required String eventId,
    required String studentId,
    required int qrTicketUnlocked,
    required double amountDue,
    required String paymentStatus,
    required int cachedAt,
    this.studentName = const Value.absent(),
    this.studentIdNumber = const Value.absent(),
    this.profilePhotoUrl = const Value.absent(),
    this.eventTitle = const Value.absent(),
    this.courseInfo = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        eventId = Value(eventId),
        studentId = Value(studentId),
        qrTicketUnlocked = Value(qrTicketUnlocked),
        amountDue = Value(amountDue),
        paymentStatus = Value(paymentStatus),
        cachedAt = Value(cachedAt);
  static Insertable<CachedPayable> custom({
    Expression<String>? id,
    Expression<String>? eventId,
    Expression<String>? studentId,
    Expression<int>? qrTicketUnlocked,
    Expression<double>? amountDue,
    Expression<String>? paymentStatus,
    Expression<int>? cachedAt,
    Expression<String>? studentName,
    Expression<String>? studentIdNumber,
    Expression<String>? profilePhotoUrl,
    Expression<String>? eventTitle,
    Expression<String>? courseInfo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (studentId != null) 'student_id': studentId,
      if (qrTicketUnlocked != null) 'qr_ticket_unlocked': qrTicketUnlocked,
      if (amountDue != null) 'amount_due': amountDue,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (studentName != null) 'student_name': studentName,
      if (studentIdNumber != null) 'student_id_number': studentIdNumber,
      if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
      if (eventTitle != null) 'event_title': eventTitle,
      if (courseInfo != null) 'course_info': courseInfo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedPayablesCompanion copyWith(
      {Value<String>? id,
      Value<String>? eventId,
      Value<String>? studentId,
      Value<int>? qrTicketUnlocked,
      Value<double>? amountDue,
      Value<String>? paymentStatus,
      Value<int>? cachedAt,
      Value<String?>? studentName,
      Value<String?>? studentIdNumber,
      Value<String?>? profilePhotoUrl,
      Value<String?>? eventTitle,
      Value<String?>? courseInfo,
      Value<int>? rowid}) {
    return CachedPayablesCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      studentId: studentId ?? this.studentId,
      qrTicketUnlocked: qrTicketUnlocked ?? this.qrTicketUnlocked,
      amountDue: amountDue ?? this.amountDue,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      cachedAt: cachedAt ?? this.cachedAt,
      studentName: studentName ?? this.studentName,
      studentIdNumber: studentIdNumber ?? this.studentIdNumber,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      eventTitle: eventTitle ?? this.eventTitle,
      courseInfo: courseInfo ?? this.courseInfo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (qrTicketUnlocked.present) {
      map['qr_ticket_unlocked'] = Variable<int>(qrTicketUnlocked.value);
    }
    if (amountDue.present) {
      map['amount_due'] = Variable<double>(amountDue.value);
    }
    if (paymentStatus.present) {
      map['payment_status'] = Variable<String>(paymentStatus.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (studentName.present) {
      map['student_name'] = Variable<String>(studentName.value);
    }
    if (studentIdNumber.present) {
      map['student_id_number'] = Variable<String>(studentIdNumber.value);
    }
    if (profilePhotoUrl.present) {
      map['profile_photo_url'] = Variable<String>(profilePhotoUrl.value);
    }
    if (eventTitle.present) {
      map['event_title'] = Variable<String>(eventTitle.value);
    }
    if (courseInfo.present) {
      map['course_info'] = Variable<String>(courseInfo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPayablesCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('studentId: $studentId, ')
          ..write('qrTicketUnlocked: $qrTicketUnlocked, ')
          ..write('amountDue: $amountDue, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('studentName: $studentName, ')
          ..write('studentIdNumber: $studentIdNumber, ')
          ..write('profilePhotoUrl: $profilePhotoUrl, ')
          ..write('eventTitle: $eventTitle, ')
          ..write('courseInfo: $courseInfo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScannerAssignmentsTable extends ScannerAssignments
    with TableInfo<$ScannerAssignmentsTable, ScannerAssignment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScannerAssignmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionIdsMeta =
      const VerificationMeta('sessionIds');
  @override
  late final GeneratedColumn<String> sessionIds = GeneratedColumn<String>(
      'session_ids', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _officerUserIdMeta =
      const VerificationMeta('officerUserId');
  @override
  late final GeneratedColumn<String> officerUserId = GeneratedColumn<String>(
      'officer_user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _permissionsMeta =
      const VerificationMeta('permissions');
  @override
  late final GeneratedColumn<String> permissions = GeneratedColumn<String>(
      'permissions', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataDownloadedMeta =
      const VerificationMeta('dataDownloaded');
  @override
  late final GeneratedColumn<int> dataDownloaded = GeneratedColumn<int>(
      'data_downloaded', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _downloadedAtMeta =
      const VerificationMeta('downloadedAt');
  @override
  late final GeneratedColumn<int> downloadedAt = GeneratedColumn<int>(
      'downloaded_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        eventId,
        sessionIds,
        officerUserId,
        permissions,
        dataDownloaded,
        downloadedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scanner_assignments';
  @override
  VerificationContext validateIntegrity(Insertable<ScannerAssignment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('session_ids')) {
      context.handle(
          _sessionIdsMeta,
          sessionIds.isAcceptableOrUnknown(
              data['session_ids']!, _sessionIdsMeta));
    } else if (isInserting) {
      context.missing(_sessionIdsMeta);
    }
    if (data.containsKey('officer_user_id')) {
      context.handle(
          _officerUserIdMeta,
          officerUserId.isAcceptableOrUnknown(
              data['officer_user_id']!, _officerUserIdMeta));
    } else if (isInserting) {
      context.missing(_officerUserIdMeta);
    }
    if (data.containsKey('permissions')) {
      context.handle(
          _permissionsMeta,
          permissions.isAcceptableOrUnknown(
              data['permissions']!, _permissionsMeta));
    } else if (isInserting) {
      context.missing(_permissionsMeta);
    }
    if (data.containsKey('data_downloaded')) {
      context.handle(
          _dataDownloadedMeta,
          dataDownloaded.isAcceptableOrUnknown(
              data['data_downloaded']!, _dataDownloadedMeta));
    } else if (isInserting) {
      context.missing(_dataDownloadedMeta);
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
          _downloadedAtMeta,
          downloadedAt.isAcceptableOrUnknown(
              data['downloaded_at']!, _downloadedAtMeta));
    } else if (isInserting) {
      context.missing(_downloadedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId};
  @override
  ScannerAssignment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScannerAssignment(
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      sessionIds: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_ids'])!,
      officerUserId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}officer_user_id'])!,
      permissions: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}permissions'])!,
      dataDownloaded: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}data_downloaded'])!,
      downloadedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}downloaded_at'])!,
    );
  }

  @override
  $ScannerAssignmentsTable createAlias(String alias) {
    return $ScannerAssignmentsTable(attachedDatabase, alias);
  }
}

class ScannerAssignment extends DataClass
    implements Insertable<ScannerAssignment> {
  final String eventId;
  final String sessionIds;
  final String officerUserId;
  final String permissions;
  final int dataDownloaded;
  final int downloadedAt;
  const ScannerAssignment(
      {required this.eventId,
      required this.sessionIds,
      required this.officerUserId,
      required this.permissions,
      required this.dataDownloaded,
      required this.downloadedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['session_ids'] = Variable<String>(sessionIds);
    map['officer_user_id'] = Variable<String>(officerUserId);
    map['permissions'] = Variable<String>(permissions);
    map['data_downloaded'] = Variable<int>(dataDownloaded);
    map['downloaded_at'] = Variable<int>(downloadedAt);
    return map;
  }

  ScannerAssignmentsCompanion toCompanion(bool nullToAbsent) {
    return ScannerAssignmentsCompanion(
      eventId: Value(eventId),
      sessionIds: Value(sessionIds),
      officerUserId: Value(officerUserId),
      permissions: Value(permissions),
      dataDownloaded: Value(dataDownloaded),
      downloadedAt: Value(downloadedAt),
    );
  }

  factory ScannerAssignment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScannerAssignment(
      eventId: serializer.fromJson<String>(json['eventId']),
      sessionIds: serializer.fromJson<String>(json['sessionIds']),
      officerUserId: serializer.fromJson<String>(json['officerUserId']),
      permissions: serializer.fromJson<String>(json['permissions']),
      dataDownloaded: serializer.fromJson<int>(json['dataDownloaded']),
      downloadedAt: serializer.fromJson<int>(json['downloadedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'sessionIds': serializer.toJson<String>(sessionIds),
      'officerUserId': serializer.toJson<String>(officerUserId),
      'permissions': serializer.toJson<String>(permissions),
      'dataDownloaded': serializer.toJson<int>(dataDownloaded),
      'downloadedAt': serializer.toJson<int>(downloadedAt),
    };
  }

  ScannerAssignment copyWith(
          {String? eventId,
          String? sessionIds,
          String? officerUserId,
          String? permissions,
          int? dataDownloaded,
          int? downloadedAt}) =>
      ScannerAssignment(
        eventId: eventId ?? this.eventId,
        sessionIds: sessionIds ?? this.sessionIds,
        officerUserId: officerUserId ?? this.officerUserId,
        permissions: permissions ?? this.permissions,
        dataDownloaded: dataDownloaded ?? this.dataDownloaded,
        downloadedAt: downloadedAt ?? this.downloadedAt,
      );
  ScannerAssignment copyWithCompanion(ScannerAssignmentsCompanion data) {
    return ScannerAssignment(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      sessionIds:
          data.sessionIds.present ? data.sessionIds.value : this.sessionIds,
      officerUserId: data.officerUserId.present
          ? data.officerUserId.value
          : this.officerUserId,
      permissions:
          data.permissions.present ? data.permissions.value : this.permissions,
      dataDownloaded: data.dataDownloaded.present
          ? data.dataDownloaded.value
          : this.dataDownloaded,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScannerAssignment(')
          ..write('eventId: $eventId, ')
          ..write('sessionIds: $sessionIds, ')
          ..write('officerUserId: $officerUserId, ')
          ..write('permissions: $permissions, ')
          ..write('dataDownloaded: $dataDownloaded, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(eventId, sessionIds, officerUserId,
      permissions, dataDownloaded, downloadedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScannerAssignment &&
          other.eventId == this.eventId &&
          other.sessionIds == this.sessionIds &&
          other.officerUserId == this.officerUserId &&
          other.permissions == this.permissions &&
          other.dataDownloaded == this.dataDownloaded &&
          other.downloadedAt == this.downloadedAt);
}

class ScannerAssignmentsCompanion extends UpdateCompanion<ScannerAssignment> {
  final Value<String> eventId;
  final Value<String> sessionIds;
  final Value<String> officerUserId;
  final Value<String> permissions;
  final Value<int> dataDownloaded;
  final Value<int> downloadedAt;
  final Value<int> rowid;
  const ScannerAssignmentsCompanion({
    this.eventId = const Value.absent(),
    this.sessionIds = const Value.absent(),
    this.officerUserId = const Value.absent(),
    this.permissions = const Value.absent(),
    this.dataDownloaded = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScannerAssignmentsCompanion.insert({
    required String eventId,
    required String sessionIds,
    required String officerUserId,
    required String permissions,
    required int dataDownloaded,
    required int downloadedAt,
    this.rowid = const Value.absent(),
  })  : eventId = Value(eventId),
        sessionIds = Value(sessionIds),
        officerUserId = Value(officerUserId),
        permissions = Value(permissions),
        dataDownloaded = Value(dataDownloaded),
        downloadedAt = Value(downloadedAt);
  static Insertable<ScannerAssignment> custom({
    Expression<String>? eventId,
    Expression<String>? sessionIds,
    Expression<String>? officerUserId,
    Expression<String>? permissions,
    Expression<int>? dataDownloaded,
    Expression<int>? downloadedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (sessionIds != null) 'session_ids': sessionIds,
      if (officerUserId != null) 'officer_user_id': officerUserId,
      if (permissions != null) 'permissions': permissions,
      if (dataDownloaded != null) 'data_downloaded': dataDownloaded,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScannerAssignmentsCompanion copyWith(
      {Value<String>? eventId,
      Value<String>? sessionIds,
      Value<String>? officerUserId,
      Value<String>? permissions,
      Value<int>? dataDownloaded,
      Value<int>? downloadedAt,
      Value<int>? rowid}) {
    return ScannerAssignmentsCompanion(
      eventId: eventId ?? this.eventId,
      sessionIds: sessionIds ?? this.sessionIds,
      officerUserId: officerUserId ?? this.officerUserId,
      permissions: permissions ?? this.permissions,
      dataDownloaded: dataDownloaded ?? this.dataDownloaded,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (sessionIds.present) {
      map['session_ids'] = Variable<String>(sessionIds.value);
    }
    if (officerUserId.present) {
      map['officer_user_id'] = Variable<String>(officerUserId.value);
    }
    if (permissions.present) {
      map['permissions'] = Variable<String>(permissions.value);
    }
    if (dataDownloaded.present) {
      map['data_downloaded'] = Variable<int>(dataDownloaded.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<int>(downloadedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScannerAssignmentsCompanion(')
          ..write('eventId: $eventId, ')
          ..write('sessionIds: $sessionIds, ')
          ..write('officerUserId: $officerUserId, ')
          ..write('permissions: $permissions, ')
          ..write('dataDownloaded: $dataDownloaded, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedEventsTable cachedEvents = $CachedEventsTable(this);
  late final $CachedParticipantsTable cachedParticipants =
      $CachedParticipantsTable(this);
  late final $OfflineAttendanceTable offlineAttendance =
      $OfflineAttendanceTable(this);
  late final $CachedPayablesTable cachedPayables = $CachedPayablesTable(this);
  late final $ScannerAssignmentsTable scannerAssignments =
      $ScannerAssignmentsTable(this);
  late final EventsDao eventsDao = EventsDao(this as AppDatabase);
  late final ParticipantsDao participantsDao =
      ParticipantsDao(this as AppDatabase);
  late final AttendanceDao attendanceDao = AttendanceDao(this as AppDatabase);
  late final PayablesDao payablesDao = PayablesDao(this as AppDatabase);
  late final ScannerDao scannerDao = ScannerDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        cachedEvents,
        cachedParticipants,
        offlineAttendance,
        cachedPayables,
        scannerAssignments
      ];
}

typedef $$CachedEventsTableCreateCompanionBuilder = CachedEventsCompanion
    Function({
  required String id,
  required String title,
  required String eventJson,
  required int cachedAt,
  required int expiresAt,
  Value<int> rowid,
});
typedef $$CachedEventsTableUpdateCompanionBuilder = CachedEventsCompanion
    Function({
  Value<String> id,
  Value<String> title,
  Value<String> eventJson,
  Value<int> cachedAt,
  Value<int> expiresAt,
  Value<int> rowid,
});

class $$CachedEventsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedEventsTable> {
  $$CachedEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventJson => $composableBuilder(
      column: $table.eventJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));
}

class $$CachedEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedEventsTable> {
  $$CachedEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventJson => $composableBuilder(
      column: $table.eventJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedEventsTable> {
  $$CachedEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get eventJson =>
      $composableBuilder(column: $table.eventJson, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$CachedEventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedEventsTable,
    CachedEvent,
    $$CachedEventsTableFilterComposer,
    $$CachedEventsTableOrderingComposer,
    $$CachedEventsTableAnnotationComposer,
    $$CachedEventsTableCreateCompanionBuilder,
    $$CachedEventsTableUpdateCompanionBuilder,
    (
      CachedEvent,
      BaseReferences<_$AppDatabase, $CachedEventsTable, CachedEvent>
    ),
    CachedEvent,
    PrefetchHooks Function()> {
  $$CachedEventsTableTableManager(_$AppDatabase db, $CachedEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> eventJson = const Value.absent(),
            Value<int> cachedAt = const Value.absent(),
            Value<int> expiresAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedEventsCompanion(
            id: id,
            title: title,
            eventJson: eventJson,
            cachedAt: cachedAt,
            expiresAt: expiresAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            required String eventJson,
            required int cachedAt,
            required int expiresAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedEventsCompanion.insert(
            id: id,
            title: title,
            eventJson: eventJson,
            cachedAt: cachedAt,
            expiresAt: expiresAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedEventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedEventsTable,
    CachedEvent,
    $$CachedEventsTableFilterComposer,
    $$CachedEventsTableOrderingComposer,
    $$CachedEventsTableAnnotationComposer,
    $$CachedEventsTableCreateCompanionBuilder,
    $$CachedEventsTableUpdateCompanionBuilder,
    (
      CachedEvent,
      BaseReferences<_$AppDatabase, $CachedEventsTable, CachedEvent>
    ),
    CachedEvent,
    PrefetchHooks Function()>;
typedef $$CachedParticipantsTableCreateCompanionBuilder
    = CachedParticipantsCompanion Function({
  required String id,
  required String eventId,
  required String studentName,
  Value<String?> studentNumber,
  Value<String?> course,
  Value<int?> yearLevel,
  Value<String?> profilePhotoUrl,
  required int qrTicketUnlocked,
  required String participantJson,
  required int downloadedAt,
  Value<int> rowid,
});
typedef $$CachedParticipantsTableUpdateCompanionBuilder
    = CachedParticipantsCompanion Function({
  Value<String> id,
  Value<String> eventId,
  Value<String> studentName,
  Value<String?> studentNumber,
  Value<String?> course,
  Value<int?> yearLevel,
  Value<String?> profilePhotoUrl,
  Value<int> qrTicketUnlocked,
  Value<String> participantJson,
  Value<int> downloadedAt,
  Value<int> rowid,
});

class $$CachedParticipantsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedParticipantsTable> {
  $$CachedParticipantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get studentName => $composableBuilder(
      column: $table.studentName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get studentNumber => $composableBuilder(
      column: $table.studentNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get course => $composableBuilder(
      column: $table.course, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get yearLevel => $composableBuilder(
      column: $table.yearLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get profilePhotoUrl => $composableBuilder(
      column: $table.profilePhotoUrl,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get qrTicketUnlocked => $composableBuilder(
      column: $table.qrTicketUnlocked,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get participantJson => $composableBuilder(
      column: $table.participantJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedParticipantsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedParticipantsTable> {
  $$CachedParticipantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get studentName => $composableBuilder(
      column: $table.studentName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get studentNumber => $composableBuilder(
      column: $table.studentNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get course => $composableBuilder(
      column: $table.course, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get yearLevel => $composableBuilder(
      column: $table.yearLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get profilePhotoUrl => $composableBuilder(
      column: $table.profilePhotoUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get qrTicketUnlocked => $composableBuilder(
      column: $table.qrTicketUnlocked,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get participantJson => $composableBuilder(
      column: $table.participantJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$CachedParticipantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedParticipantsTable> {
  $$CachedParticipantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get studentName => $composableBuilder(
      column: $table.studentName, builder: (column) => column);

  GeneratedColumn<String> get studentNumber => $composableBuilder(
      column: $table.studentNumber, builder: (column) => column);

  GeneratedColumn<String> get course =>
      $composableBuilder(column: $table.course, builder: (column) => column);

  GeneratedColumn<int> get yearLevel =>
      $composableBuilder(column: $table.yearLevel, builder: (column) => column);

  GeneratedColumn<String> get profilePhotoUrl => $composableBuilder(
      column: $table.profilePhotoUrl, builder: (column) => column);

  GeneratedColumn<int> get qrTicketUnlocked => $composableBuilder(
      column: $table.qrTicketUnlocked, builder: (column) => column);

  GeneratedColumn<String> get participantJson => $composableBuilder(
      column: $table.participantJson, builder: (column) => column);

  GeneratedColumn<int> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt, builder: (column) => column);
}

class $$CachedParticipantsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedParticipantsTable,
    CachedParticipant,
    $$CachedParticipantsTableFilterComposer,
    $$CachedParticipantsTableOrderingComposer,
    $$CachedParticipantsTableAnnotationComposer,
    $$CachedParticipantsTableCreateCompanionBuilder,
    $$CachedParticipantsTableUpdateCompanionBuilder,
    (
      CachedParticipant,
      BaseReferences<_$AppDatabase, $CachedParticipantsTable, CachedParticipant>
    ),
    CachedParticipant,
    PrefetchHooks Function()> {
  $$CachedParticipantsTableTableManager(
      _$AppDatabase db, $CachedParticipantsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedParticipantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedParticipantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedParticipantsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> eventId = const Value.absent(),
            Value<String> studentName = const Value.absent(),
            Value<String?> studentNumber = const Value.absent(),
            Value<String?> course = const Value.absent(),
            Value<int?> yearLevel = const Value.absent(),
            Value<String?> profilePhotoUrl = const Value.absent(),
            Value<int> qrTicketUnlocked = const Value.absent(),
            Value<String> participantJson = const Value.absent(),
            Value<int> downloadedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedParticipantsCompanion(
            id: id,
            eventId: eventId,
            studentName: studentName,
            studentNumber: studentNumber,
            course: course,
            yearLevel: yearLevel,
            profilePhotoUrl: profilePhotoUrl,
            qrTicketUnlocked: qrTicketUnlocked,
            participantJson: participantJson,
            downloadedAt: downloadedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String eventId,
            required String studentName,
            Value<String?> studentNumber = const Value.absent(),
            Value<String?> course = const Value.absent(),
            Value<int?> yearLevel = const Value.absent(),
            Value<String?> profilePhotoUrl = const Value.absent(),
            required int qrTicketUnlocked,
            required String participantJson,
            required int downloadedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedParticipantsCompanion.insert(
            id: id,
            eventId: eventId,
            studentName: studentName,
            studentNumber: studentNumber,
            course: course,
            yearLevel: yearLevel,
            profilePhotoUrl: profilePhotoUrl,
            qrTicketUnlocked: qrTicketUnlocked,
            participantJson: participantJson,
            downloadedAt: downloadedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedParticipantsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedParticipantsTable,
    CachedParticipant,
    $$CachedParticipantsTableFilterComposer,
    $$CachedParticipantsTableOrderingComposer,
    $$CachedParticipantsTableAnnotationComposer,
    $$CachedParticipantsTableCreateCompanionBuilder,
    $$CachedParticipantsTableUpdateCompanionBuilder,
    (
      CachedParticipant,
      BaseReferences<_$AppDatabase, $CachedParticipantsTable, CachedParticipant>
    ),
    CachedParticipant,
    PrefetchHooks Function()>;
typedef $$OfflineAttendanceTableCreateCompanionBuilder
    = OfflineAttendanceCompanion Function({
  required String localId,
  required String eventId,
  required String sessionId,
  required String studentId,
  required String studentName,
  required String gateType,
  required String scanMethod,
  required String scannedBy,
  required int scannedAt,
  required int synced,
  Value<int?> syncedAt,
  required int conflictResolved,
  Value<int> rowid,
});
typedef $$OfflineAttendanceTableUpdateCompanionBuilder
    = OfflineAttendanceCompanion Function({
  Value<String> localId,
  Value<String> eventId,
  Value<String> sessionId,
  Value<String> studentId,
  Value<String> studentName,
  Value<String> gateType,
  Value<String> scanMethod,
  Value<String> scannedBy,
  Value<int> scannedAt,
  Value<int> synced,
  Value<int?> syncedAt,
  Value<int> conflictResolved,
  Value<int> rowid,
});

class $$OfflineAttendanceTableFilterComposer
    extends Composer<_$AppDatabase, $OfflineAttendanceTable> {
  $$OfflineAttendanceTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get studentName => $composableBuilder(
      column: $table.studentName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gateType => $composableBuilder(
      column: $table.gateType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get scanMethod => $composableBuilder(
      column: $table.scanMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get scannedBy => $composableBuilder(
      column: $table.scannedBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get scannedAt => $composableBuilder(
      column: $table.scannedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get conflictResolved => $composableBuilder(
      column: $table.conflictResolved,
      builder: (column) => ColumnFilters(column));
}

class $$OfflineAttendanceTableOrderingComposer
    extends Composer<_$AppDatabase, $OfflineAttendanceTable> {
  $$OfflineAttendanceTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get studentName => $composableBuilder(
      column: $table.studentName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gateType => $composableBuilder(
      column: $table.gateType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scanMethod => $composableBuilder(
      column: $table.scanMethod, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scannedBy => $composableBuilder(
      column: $table.scannedBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get scannedAt => $composableBuilder(
      column: $table.scannedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get conflictResolved => $composableBuilder(
      column: $table.conflictResolved,
      builder: (column) => ColumnOrderings(column));
}

class $$OfflineAttendanceTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfflineAttendanceTable> {
  $$OfflineAttendanceTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<String> get studentName => $composableBuilder(
      column: $table.studentName, builder: (column) => column);

  GeneratedColumn<String> get gateType =>
      $composableBuilder(column: $table.gateType, builder: (column) => column);

  GeneratedColumn<String> get scanMethod => $composableBuilder(
      column: $table.scanMethod, builder: (column) => column);

  GeneratedColumn<String> get scannedBy =>
      $composableBuilder(column: $table.scannedBy, builder: (column) => column);

  GeneratedColumn<int> get scannedAt =>
      $composableBuilder(column: $table.scannedAt, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<int> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<int> get conflictResolved => $composableBuilder(
      column: $table.conflictResolved, builder: (column) => column);
}

class $$OfflineAttendanceTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OfflineAttendanceTable,
    OfflineAttendanceData,
    $$OfflineAttendanceTableFilterComposer,
    $$OfflineAttendanceTableOrderingComposer,
    $$OfflineAttendanceTableAnnotationComposer,
    $$OfflineAttendanceTableCreateCompanionBuilder,
    $$OfflineAttendanceTableUpdateCompanionBuilder,
    (
      OfflineAttendanceData,
      BaseReferences<_$AppDatabase, $OfflineAttendanceTable,
          OfflineAttendanceData>
    ),
    OfflineAttendanceData,
    PrefetchHooks Function()> {
  $$OfflineAttendanceTableTableManager(
      _$AppDatabase db, $OfflineAttendanceTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineAttendanceTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflineAttendanceTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfflineAttendanceTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> localId = const Value.absent(),
            Value<String> eventId = const Value.absent(),
            Value<String> sessionId = const Value.absent(),
            Value<String> studentId = const Value.absent(),
            Value<String> studentName = const Value.absent(),
            Value<String> gateType = const Value.absent(),
            Value<String> scanMethod = const Value.absent(),
            Value<String> scannedBy = const Value.absent(),
            Value<int> scannedAt = const Value.absent(),
            Value<int> synced = const Value.absent(),
            Value<int?> syncedAt = const Value.absent(),
            Value<int> conflictResolved = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OfflineAttendanceCompanion(
            localId: localId,
            eventId: eventId,
            sessionId: sessionId,
            studentId: studentId,
            studentName: studentName,
            gateType: gateType,
            scanMethod: scanMethod,
            scannedBy: scannedBy,
            scannedAt: scannedAt,
            synced: synced,
            syncedAt: syncedAt,
            conflictResolved: conflictResolved,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String localId,
            required String eventId,
            required String sessionId,
            required String studentId,
            required String studentName,
            required String gateType,
            required String scanMethod,
            required String scannedBy,
            required int scannedAt,
            required int synced,
            Value<int?> syncedAt = const Value.absent(),
            required int conflictResolved,
            Value<int> rowid = const Value.absent(),
          }) =>
              OfflineAttendanceCompanion.insert(
            localId: localId,
            eventId: eventId,
            sessionId: sessionId,
            studentId: studentId,
            studentName: studentName,
            gateType: gateType,
            scanMethod: scanMethod,
            scannedBy: scannedBy,
            scannedAt: scannedAt,
            synced: synced,
            syncedAt: syncedAt,
            conflictResolved: conflictResolved,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OfflineAttendanceTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OfflineAttendanceTable,
    OfflineAttendanceData,
    $$OfflineAttendanceTableFilterComposer,
    $$OfflineAttendanceTableOrderingComposer,
    $$OfflineAttendanceTableAnnotationComposer,
    $$OfflineAttendanceTableCreateCompanionBuilder,
    $$OfflineAttendanceTableUpdateCompanionBuilder,
    (
      OfflineAttendanceData,
      BaseReferences<_$AppDatabase, $OfflineAttendanceTable,
          OfflineAttendanceData>
    ),
    OfflineAttendanceData,
    PrefetchHooks Function()>;
typedef $$CachedPayablesTableCreateCompanionBuilder = CachedPayablesCompanion
    Function({
  required String id,
  required String eventId,
  required String studentId,
  required int qrTicketUnlocked,
  required double amountDue,
  required String paymentStatus,
  required int cachedAt,
  Value<String?> studentName,
  Value<String?> studentIdNumber,
  Value<String?> profilePhotoUrl,
  Value<String?> eventTitle,
  Value<String?> courseInfo,
  Value<int> rowid,
});
typedef $$CachedPayablesTableUpdateCompanionBuilder = CachedPayablesCompanion
    Function({
  Value<String> id,
  Value<String> eventId,
  Value<String> studentId,
  Value<int> qrTicketUnlocked,
  Value<double> amountDue,
  Value<String> paymentStatus,
  Value<int> cachedAt,
  Value<String?> studentName,
  Value<String?> studentIdNumber,
  Value<String?> profilePhotoUrl,
  Value<String?> eventTitle,
  Value<String?> courseInfo,
  Value<int> rowid,
});

class $$CachedPayablesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedPayablesTable> {
  $$CachedPayablesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get qrTicketUnlocked => $composableBuilder(
      column: $table.qrTicketUnlocked,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amountDue => $composableBuilder(
      column: $table.amountDue, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentStatus => $composableBuilder(
      column: $table.paymentStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get studentName => $composableBuilder(
      column: $table.studentName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get studentIdNumber => $composableBuilder(
      column: $table.studentIdNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get profilePhotoUrl => $composableBuilder(
      column: $table.profilePhotoUrl,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventTitle => $composableBuilder(
      column: $table.eventTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get courseInfo => $composableBuilder(
      column: $table.courseInfo, builder: (column) => ColumnFilters(column));
}

class $$CachedPayablesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedPayablesTable> {
  $$CachedPayablesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get qrTicketUnlocked => $composableBuilder(
      column: $table.qrTicketUnlocked,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amountDue => $composableBuilder(
      column: $table.amountDue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentStatus => $composableBuilder(
      column: $table.paymentStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get studentName => $composableBuilder(
      column: $table.studentName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get studentIdNumber => $composableBuilder(
      column: $table.studentIdNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get profilePhotoUrl => $composableBuilder(
      column: $table.profilePhotoUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventTitle => $composableBuilder(
      column: $table.eventTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get courseInfo => $composableBuilder(
      column: $table.courseInfo, builder: (column) => ColumnOrderings(column));
}

class $$CachedPayablesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedPayablesTable> {
  $$CachedPayablesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<int> get qrTicketUnlocked => $composableBuilder(
      column: $table.qrTicketUnlocked, builder: (column) => column);

  GeneratedColumn<double> get amountDue =>
      $composableBuilder(column: $table.amountDue, builder: (column) => column);

  GeneratedColumn<String> get paymentStatus => $composableBuilder(
      column: $table.paymentStatus, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<String> get studentName => $composableBuilder(
      column: $table.studentName, builder: (column) => column);

  GeneratedColumn<String> get studentIdNumber => $composableBuilder(
      column: $table.studentIdNumber, builder: (column) => column);

  GeneratedColumn<String> get profilePhotoUrl => $composableBuilder(
      column: $table.profilePhotoUrl, builder: (column) => column);

  GeneratedColumn<String> get eventTitle => $composableBuilder(
      column: $table.eventTitle, builder: (column) => column);

  GeneratedColumn<String> get courseInfo => $composableBuilder(
      column: $table.courseInfo, builder: (column) => column);
}

class $$CachedPayablesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedPayablesTable,
    CachedPayable,
    $$CachedPayablesTableFilterComposer,
    $$CachedPayablesTableOrderingComposer,
    $$CachedPayablesTableAnnotationComposer,
    $$CachedPayablesTableCreateCompanionBuilder,
    $$CachedPayablesTableUpdateCompanionBuilder,
    (
      CachedPayable,
      BaseReferences<_$AppDatabase, $CachedPayablesTable, CachedPayable>
    ),
    CachedPayable,
    PrefetchHooks Function()> {
  $$CachedPayablesTableTableManager(
      _$AppDatabase db, $CachedPayablesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPayablesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedPayablesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedPayablesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> eventId = const Value.absent(),
            Value<String> studentId = const Value.absent(),
            Value<int> qrTicketUnlocked = const Value.absent(),
            Value<double> amountDue = const Value.absent(),
            Value<String> paymentStatus = const Value.absent(),
            Value<int> cachedAt = const Value.absent(),
            Value<String?> studentName = const Value.absent(),
            Value<String?> studentIdNumber = const Value.absent(),
            Value<String?> profilePhotoUrl = const Value.absent(),
            Value<String?> eventTitle = const Value.absent(),
            Value<String?> courseInfo = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedPayablesCompanion(
            id: id,
            eventId: eventId,
            studentId: studentId,
            qrTicketUnlocked: qrTicketUnlocked,
            amountDue: amountDue,
            paymentStatus: paymentStatus,
            cachedAt: cachedAt,
            studentName: studentName,
            studentIdNumber: studentIdNumber,
            profilePhotoUrl: profilePhotoUrl,
            eventTitle: eventTitle,
            courseInfo: courseInfo,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String eventId,
            required String studentId,
            required int qrTicketUnlocked,
            required double amountDue,
            required String paymentStatus,
            required int cachedAt,
            Value<String?> studentName = const Value.absent(),
            Value<String?> studentIdNumber = const Value.absent(),
            Value<String?> profilePhotoUrl = const Value.absent(),
            Value<String?> eventTitle = const Value.absent(),
            Value<String?> courseInfo = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedPayablesCompanion.insert(
            id: id,
            eventId: eventId,
            studentId: studentId,
            qrTicketUnlocked: qrTicketUnlocked,
            amountDue: amountDue,
            paymentStatus: paymentStatus,
            cachedAt: cachedAt,
            studentName: studentName,
            studentIdNumber: studentIdNumber,
            profilePhotoUrl: profilePhotoUrl,
            eventTitle: eventTitle,
            courseInfo: courseInfo,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedPayablesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedPayablesTable,
    CachedPayable,
    $$CachedPayablesTableFilterComposer,
    $$CachedPayablesTableOrderingComposer,
    $$CachedPayablesTableAnnotationComposer,
    $$CachedPayablesTableCreateCompanionBuilder,
    $$CachedPayablesTableUpdateCompanionBuilder,
    (
      CachedPayable,
      BaseReferences<_$AppDatabase, $CachedPayablesTable, CachedPayable>
    ),
    CachedPayable,
    PrefetchHooks Function()>;
typedef $$ScannerAssignmentsTableCreateCompanionBuilder
    = ScannerAssignmentsCompanion Function({
  required String eventId,
  required String sessionIds,
  required String officerUserId,
  required String permissions,
  required int dataDownloaded,
  required int downloadedAt,
  Value<int> rowid,
});
typedef $$ScannerAssignmentsTableUpdateCompanionBuilder
    = ScannerAssignmentsCompanion Function({
  Value<String> eventId,
  Value<String> sessionIds,
  Value<String> officerUserId,
  Value<String> permissions,
  Value<int> dataDownloaded,
  Value<int> downloadedAt,
  Value<int> rowid,
});

class $$ScannerAssignmentsTableFilterComposer
    extends Composer<_$AppDatabase, $ScannerAssignmentsTable> {
  $$ScannerAssignmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionIds => $composableBuilder(
      column: $table.sessionIds, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get officerUserId => $composableBuilder(
      column: $table.officerUserId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get permissions => $composableBuilder(
      column: $table.permissions, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dataDownloaded => $composableBuilder(
      column: $table.dataDownloaded,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt, builder: (column) => ColumnFilters(column));
}

class $$ScannerAssignmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScannerAssignmentsTable> {
  $$ScannerAssignmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionIds => $composableBuilder(
      column: $table.sessionIds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get officerUserId => $composableBuilder(
      column: $table.officerUserId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get permissions => $composableBuilder(
      column: $table.permissions, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dataDownloaded => $composableBuilder(
      column: $table.dataDownloaded,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$ScannerAssignmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScannerAssignmentsTable> {
  $$ScannerAssignmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get sessionIds => $composableBuilder(
      column: $table.sessionIds, builder: (column) => column);

  GeneratedColumn<String> get officerUserId => $composableBuilder(
      column: $table.officerUserId, builder: (column) => column);

  GeneratedColumn<String> get permissions => $composableBuilder(
      column: $table.permissions, builder: (column) => column);

  GeneratedColumn<int> get dataDownloaded => $composableBuilder(
      column: $table.dataDownloaded, builder: (column) => column);

  GeneratedColumn<int> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt, builder: (column) => column);
}

class $$ScannerAssignmentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ScannerAssignmentsTable,
    ScannerAssignment,
    $$ScannerAssignmentsTableFilterComposer,
    $$ScannerAssignmentsTableOrderingComposer,
    $$ScannerAssignmentsTableAnnotationComposer,
    $$ScannerAssignmentsTableCreateCompanionBuilder,
    $$ScannerAssignmentsTableUpdateCompanionBuilder,
    (
      ScannerAssignment,
      BaseReferences<_$AppDatabase, $ScannerAssignmentsTable, ScannerAssignment>
    ),
    ScannerAssignment,
    PrefetchHooks Function()> {
  $$ScannerAssignmentsTableTableManager(
      _$AppDatabase db, $ScannerAssignmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScannerAssignmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScannerAssignmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScannerAssignmentsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> eventId = const Value.absent(),
            Value<String> sessionIds = const Value.absent(),
            Value<String> officerUserId = const Value.absent(),
            Value<String> permissions = const Value.absent(),
            Value<int> dataDownloaded = const Value.absent(),
            Value<int> downloadedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ScannerAssignmentsCompanion(
            eventId: eventId,
            sessionIds: sessionIds,
            officerUserId: officerUserId,
            permissions: permissions,
            dataDownloaded: dataDownloaded,
            downloadedAt: downloadedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String eventId,
            required String sessionIds,
            required String officerUserId,
            required String permissions,
            required int dataDownloaded,
            required int downloadedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ScannerAssignmentsCompanion.insert(
            eventId: eventId,
            sessionIds: sessionIds,
            officerUserId: officerUserId,
            permissions: permissions,
            dataDownloaded: dataDownloaded,
            downloadedAt: downloadedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ScannerAssignmentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ScannerAssignmentsTable,
    ScannerAssignment,
    $$ScannerAssignmentsTableFilterComposer,
    $$ScannerAssignmentsTableOrderingComposer,
    $$ScannerAssignmentsTableAnnotationComposer,
    $$ScannerAssignmentsTableCreateCompanionBuilder,
    $$ScannerAssignmentsTableUpdateCompanionBuilder,
    (
      ScannerAssignment,
      BaseReferences<_$AppDatabase, $ScannerAssignmentsTable, ScannerAssignment>
    ),
    ScannerAssignment,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedEventsTableTableManager get cachedEvents =>
      $$CachedEventsTableTableManager(_db, _db.cachedEvents);
  $$CachedParticipantsTableTableManager get cachedParticipants =>
      $$CachedParticipantsTableTableManager(_db, _db.cachedParticipants);
  $$OfflineAttendanceTableTableManager get offlineAttendance =>
      $$OfflineAttendanceTableTableManager(_db, _db.offlineAttendance);
  $$CachedPayablesTableTableManager get cachedPayables =>
      $$CachedPayablesTableTableManager(_db, _db.cachedPayables);
  $$ScannerAssignmentsTableTableManager get scannerAssignments =>
      $$ScannerAssignmentsTableTableManager(_db, _db.scannerAssignments);
}
