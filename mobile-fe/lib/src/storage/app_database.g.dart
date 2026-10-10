// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AppKeyValuesTable extends AppKeyValues
    with TableInfo<$AppKeyValuesTable, AppKeyValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppKeyValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_key_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppKeyValue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppKeyValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppKeyValue(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppKeyValuesTable createAlias(String alias) {
    return $AppKeyValuesTable(attachedDatabase, alias);
  }
}

class AppKeyValue extends DataClass implements Insertable<AppKeyValue> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const AppKeyValue({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppKeyValuesCompanion toCompanion(bool nullToAbsent) {
    return AppKeyValuesCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppKeyValue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppKeyValue(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppKeyValue copyWith({String? key, String? value, DateTime? updatedAt}) =>
      AppKeyValue(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppKeyValue copyWithCompanion(AppKeyValuesCompanion data) {
    return AppKeyValue(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppKeyValue(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppKeyValue &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppKeyValuesCompanion extends UpdateCompanion<AppKeyValue> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppKeyValuesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppKeyValuesCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<AppKeyValue> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppKeyValuesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppKeyValuesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppKeyValuesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedDocumentsTable extends CachedDocuments
    with TableInfo<$CachedDocumentsTable, CachedDocument> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedDocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [cacheKey, etag, json, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedDocument> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  CachedDocument map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedDocument(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedDocumentsTable createAlias(String alias) {
    return $CachedDocumentsTable(attachedDatabase, alias);
  }
}

class CachedDocument extends DataClass implements Insertable<CachedDocument> {
  final String cacheKey;
  final String? etag;
  final String json;
  final DateTime updatedAt;
  const CachedDocument({
    required this.cacheKey,
    this.etag,
    required this.json,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    map['json'] = Variable<String>(json);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedDocumentsCompanion toCompanion(bool nullToAbsent) {
    return CachedDocumentsCompanion(
      cacheKey: Value(cacheKey),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      json: Value(json),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedDocument.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedDocument(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      etag: serializer.fromJson<String?>(json['etag']),
      json: serializer.fromJson<String>(json['json']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'etag': serializer.toJson<String?>(etag),
      'json': serializer.toJson<String>(json),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedDocument copyWith({
    String? cacheKey,
    Value<String?> etag = const Value.absent(),
    String? json,
    DateTime? updatedAt,
  }) => CachedDocument(
    cacheKey: cacheKey ?? this.cacheKey,
    etag: etag.present ? etag.value : this.etag,
    json: json ?? this.json,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedDocument copyWithCompanion(CachedDocumentsCompanion data) {
    return CachedDocument(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      etag: data.etag.present ? data.etag.value : this.etag,
      json: data.json.present ? data.json.value : this.json,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedDocument(')
          ..write('cacheKey: $cacheKey, ')
          ..write('etag: $etag, ')
          ..write('json: $json, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cacheKey, etag, json, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedDocument &&
          other.cacheKey == this.cacheKey &&
          other.etag == this.etag &&
          other.json == this.json &&
          other.updatedAt == this.updatedAt);
}

class CachedDocumentsCompanion extends UpdateCompanion<CachedDocument> {
  final Value<String> cacheKey;
  final Value<String?> etag;
  final Value<String> json;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedDocumentsCompanion({
    this.cacheKey = const Value.absent(),
    this.etag = const Value.absent(),
    this.json = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedDocumentsCompanion.insert({
    required String cacheKey,
    this.etag = const Value.absent(),
    required String json,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       json = Value(json),
       updatedAt = Value(updatedAt);
  static Insertable<CachedDocument> custom({
    Expression<String>? cacheKey,
    Expression<String>? etag,
    Expression<String>? json,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (etag != null) 'etag': etag,
      if (json != null) 'json': json,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedDocumentsCompanion copyWith({
    Value<String>? cacheKey,
    Value<String?>? etag,
    Value<String>? json,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedDocumentsCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      etag: etag ?? this.etag,
      json: json ?? this.json,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedDocumentsCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('etag: $etag, ')
          ..write('json: $json, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalWorkoutsTable extends LocalWorkouts
    with TableInfo<$LocalWorkoutsTable, LocalWorkout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalWorkoutsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _workoutIdMeta = const VerificationMeta(
    'workoutId',
  );
  @override
  late final GeneratedColumn<String> workoutId = GeneratedColumn<String>(
    'workout_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planRunIdMeta = const VerificationMeta(
    'planRunId',
  );
  @override
  late final GeneratedColumn<int> planRunId = GeneratedColumn<int>(
    'plan_run_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workoutUnitNameMeta = const VerificationMeta(
    'workoutUnitName',
  );
  @override
  late final GeneratedColumn<String> workoutUnitName = GeneratedColumn<String>(
    'workout_unit_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lifecycleMeta = const VerificationMeta(
    'lifecycle',
  );
  @override
  late final GeneratedColumn<String> lifecycle = GeneratedColumn<String>(
    'lifecycle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending_start'),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prescriptionJsonMeta = const VerificationMeta(
    'prescriptionJson',
  );
  @override
  late final GeneratedColumn<String> prescriptionJson = GeneratedColumn<String>(
    'prescription_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startPayloadJsonMeta = const VerificationMeta(
    'startPayloadJson',
  );
  @override
  late final GeneratedColumn<String> startPayloadJson = GeneratedColumn<String>(
    'start_payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverSnapshotJsonMeta =
      const VerificationMeta('serverSnapshotJson');
  @override
  late final GeneratedColumn<String> serverSnapshotJson =
      GeneratedColumn<String>(
        'server_snapshot_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _leaseEpochMeta = const VerificationMeta(
    'leaseEpoch',
  );
  @override
  late final GeneratedColumn<int> leaseEpoch = GeneratedColumn<int>(
    'lease_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _appliedSeqMeta = const VerificationMeta(
    'appliedSeq',
  );
  @override
  late final GeneratedColumn<int> appliedSeq = GeneratedColumn<int>(
    'applied_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextSeqMeta = const VerificationMeta(
    'nextSeq',
  );
  @override
  late final GeneratedColumn<int> nextSeq = GeneratedColumn<int>(
    'next_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currentExerciseMeta = const VerificationMeta(
    'currentExercise',
  );
  @override
  late final GeneratedColumn<int> currentExercise = GeneratedColumn<int>(
    'current_exercise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currentSetMeta = const VerificationMeta(
    'currentSet',
  );
  @override
  late final GeneratedColumn<int> currentSet = GeneratedColumn<int>(
    'current_set',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cursorPhaseMeta = const VerificationMeta(
    'cursorPhase',
  );
  @override
  late final GeneratedColumn<String> cursorPhase = GeneratedColumn<String>(
    'cursor_phase',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('set'),
  );
  static const VerificationMeta _restEndsAtMeta = const VerificationMeta(
    'restEndsAt',
  );
  @override
  late final GeneratedColumn<DateTime> restEndsAt = GeneratedColumn<DateTime>(
    'rest_ends_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _restDurationSMeta = const VerificationMeta(
    'restDurationS',
  );
  @override
  late final GeneratedColumn<int> restDurationS = GeneratedColumn<int>(
    'rest_duration_s',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entryDraftJsonMeta = const VerificationMeta(
    'entryDraftJson',
  );
  @override
  late final GeneratedColumn<String> entryDraftJson = GeneratedColumn<String>(
    'entry_draft_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workoutCommentMeta = const VerificationMeta(
    'workoutComment',
  );
  @override
  late final GeneratedColumn<String> workoutComment = GeneratedColumn<String>(
    'workout_comment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('saving'),
  );
  static const VerificationMeta _syncErrorCodeMeta = const VerificationMeta(
    'syncErrorCode',
  );
  @override
  late final GeneratedColumn<String> syncErrorCode = GeneratedColumn<String>(
    'sync_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncAttemptsMeta = const VerificationMeta(
    'syncAttempts',
  );
  @override
  late final GeneratedColumn<int> syncAttempts = GeneratedColumn<int>(
    'sync_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextSyncAtMeta = const VerificationMeta(
    'nextSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextSyncAt = GeneratedColumn<DateTime>(
    'next_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finalizePayloadJsonMeta =
      const VerificationMeta('finalizePayloadJson');
  @override
  late final GeneratedColumn<String> finalizePayloadJson =
      GeneratedColumn<String>(
        'finalize_payload_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _finalizedAtMeta = const VerificationMeta(
    'finalizedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finalizedAt = GeneratedColumn<DateTime>(
    'finalized_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    workoutId,
    sessionId,
    planRunId,
    workoutUnitName,
    lifecycle,
    startedAt,
    finishedAt,
    prescriptionJson,
    startPayloadJson,
    serverSnapshotJson,
    etag,
    leaseEpoch,
    appliedSeq,
    nextSeq,
    revision,
    currentExercise,
    currentSet,
    cursorPhase,
    restEndsAt,
    restDurationS,
    entryDraftJson,
    workoutComment,
    syncState,
    syncErrorCode,
    syncAttempts,
    nextSyncAt,
    finalizePayloadJson,
    finalizedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_workouts';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalWorkout> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('workout_id')) {
      context.handle(
        _workoutIdMeta,
        workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('plan_run_id')) {
      context.handle(
        _planRunIdMeta,
        planRunId.isAcceptableOrUnknown(data['plan_run_id']!, _planRunIdMeta),
      );
    }
    if (data.containsKey('workout_unit_name')) {
      context.handle(
        _workoutUnitNameMeta,
        workoutUnitName.isAcceptableOrUnknown(
          data['workout_unit_name']!,
          _workoutUnitNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workoutUnitNameMeta);
    }
    if (data.containsKey('lifecycle')) {
      context.handle(
        _lifecycleMeta,
        lifecycle.isAcceptableOrUnknown(data['lifecycle']!, _lifecycleMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('prescription_json')) {
      context.handle(
        _prescriptionJsonMeta,
        prescriptionJson.isAcceptableOrUnknown(
          data['prescription_json']!,
          _prescriptionJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_prescriptionJsonMeta);
    }
    if (data.containsKey('start_payload_json')) {
      context.handle(
        _startPayloadJsonMeta,
        startPayloadJson.isAcceptableOrUnknown(
          data['start_payload_json']!,
          _startPayloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startPayloadJsonMeta);
    }
    if (data.containsKey('server_snapshot_json')) {
      context.handle(
        _serverSnapshotJsonMeta,
        serverSnapshotJson.isAcceptableOrUnknown(
          data['server_snapshot_json']!,
          _serverSnapshotJsonMeta,
        ),
      );
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('lease_epoch')) {
      context.handle(
        _leaseEpochMeta,
        leaseEpoch.isAcceptableOrUnknown(data['lease_epoch']!, _leaseEpochMeta),
      );
    }
    if (data.containsKey('applied_seq')) {
      context.handle(
        _appliedSeqMeta,
        appliedSeq.isAcceptableOrUnknown(data['applied_seq']!, _appliedSeqMeta),
      );
    }
    if (data.containsKey('next_seq')) {
      context.handle(
        _nextSeqMeta,
        nextSeq.isAcceptableOrUnknown(data['next_seq']!, _nextSeqMeta),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('current_exercise')) {
      context.handle(
        _currentExerciseMeta,
        currentExercise.isAcceptableOrUnknown(
          data['current_exercise']!,
          _currentExerciseMeta,
        ),
      );
    }
    if (data.containsKey('current_set')) {
      context.handle(
        _currentSetMeta,
        currentSet.isAcceptableOrUnknown(data['current_set']!, _currentSetMeta),
      );
    }
    if (data.containsKey('cursor_phase')) {
      context.handle(
        _cursorPhaseMeta,
        cursorPhase.isAcceptableOrUnknown(
          data['cursor_phase']!,
          _cursorPhaseMeta,
        ),
      );
    }
    if (data.containsKey('rest_ends_at')) {
      context.handle(
        _restEndsAtMeta,
        restEndsAt.isAcceptableOrUnknown(
          data['rest_ends_at']!,
          _restEndsAtMeta,
        ),
      );
    }
    if (data.containsKey('rest_duration_s')) {
      context.handle(
        _restDurationSMeta,
        restDurationS.isAcceptableOrUnknown(
          data['rest_duration_s']!,
          _restDurationSMeta,
        ),
      );
    }
    if (data.containsKey('entry_draft_json')) {
      context.handle(
        _entryDraftJsonMeta,
        entryDraftJson.isAcceptableOrUnknown(
          data['entry_draft_json']!,
          _entryDraftJsonMeta,
        ),
      );
    }
    if (data.containsKey('workout_comment')) {
      context.handle(
        _workoutCommentMeta,
        workoutComment.isAcceptableOrUnknown(
          data['workout_comment']!,
          _workoutCommentMeta,
        ),
      );
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    }
    if (data.containsKey('sync_error_code')) {
      context.handle(
        _syncErrorCodeMeta,
        syncErrorCode.isAcceptableOrUnknown(
          data['sync_error_code']!,
          _syncErrorCodeMeta,
        ),
      );
    }
    if (data.containsKey('sync_attempts')) {
      context.handle(
        _syncAttemptsMeta,
        syncAttempts.isAcceptableOrUnknown(
          data['sync_attempts']!,
          _syncAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('next_sync_at')) {
      context.handle(
        _nextSyncAtMeta,
        nextSyncAt.isAcceptableOrUnknown(
          data['next_sync_at']!,
          _nextSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('finalize_payload_json')) {
      context.handle(
        _finalizePayloadJsonMeta,
        finalizePayloadJson.isAcceptableOrUnknown(
          data['finalize_payload_json']!,
          _finalizePayloadJsonMeta,
        ),
      );
    }
    if (data.containsKey('finalized_at')) {
      context.handle(
        _finalizedAtMeta,
        finalizedAt.isAcceptableOrUnknown(
          data['finalized_at']!,
          _finalizedAtMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {workoutId};
  @override
  LocalWorkout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalWorkout(
      workoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      planRunId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_run_id'],
      ),
      workoutUnitName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_unit_name'],
      )!,
      lifecycle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lifecycle'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
      prescriptionJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prescription_json'],
      )!,
      startPayloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_payload_json'],
      )!,
      serverSnapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_snapshot_json'],
      ),
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      leaseEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lease_epoch'],
      )!,
      appliedSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}applied_seq'],
      )!,
      nextSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_seq'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      currentExercise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_exercise'],
      )!,
      currentSet: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_set'],
      )!,
      cursorPhase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor_phase'],
      )!,
      restEndsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}rest_ends_at'],
      ),
      restDurationS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rest_duration_s'],
      ),
      entryDraftJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_draft_json'],
      ),
      workoutComment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_comment'],
      ),
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
      syncErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error_code'],
      ),
      syncAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_attempts'],
      )!,
      nextSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_sync_at'],
      ),
      finalizePayloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}finalize_payload_json'],
      ),
      finalizedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finalized_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalWorkoutsTable createAlias(String alias) {
    return $LocalWorkoutsTable(attachedDatabase, alias);
  }
}

class LocalWorkout extends DataClass implements Insertable<LocalWorkout> {
  final String workoutId;
  final int sessionId;
  final int? planRunId;
  final String workoutUnitName;
  final String lifecycle;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String prescriptionJson;
  final String startPayloadJson;
  final String? serverSnapshotJson;
  final String? etag;
  final int leaseEpoch;
  final int appliedSeq;
  final int nextSeq;
  final int revision;
  final int currentExercise;
  final int currentSet;
  final String cursorPhase;
  final DateTime? restEndsAt;
  final int? restDurationS;
  final String? entryDraftJson;
  final String? workoutComment;
  final String syncState;
  final String? syncErrorCode;
  final int syncAttempts;
  final DateTime? nextSyncAt;
  final String? finalizePayloadJson;
  final DateTime? finalizedAt;
  final DateTime updatedAt;
  const LocalWorkout({
    required this.workoutId,
    required this.sessionId,
    this.planRunId,
    required this.workoutUnitName,
    required this.lifecycle,
    required this.startedAt,
    this.finishedAt,
    required this.prescriptionJson,
    required this.startPayloadJson,
    this.serverSnapshotJson,
    this.etag,
    required this.leaseEpoch,
    required this.appliedSeq,
    required this.nextSeq,
    required this.revision,
    required this.currentExercise,
    required this.currentSet,
    required this.cursorPhase,
    this.restEndsAt,
    this.restDurationS,
    this.entryDraftJson,
    this.workoutComment,
    required this.syncState,
    this.syncErrorCode,
    required this.syncAttempts,
    this.nextSyncAt,
    this.finalizePayloadJson,
    this.finalizedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['workout_id'] = Variable<String>(workoutId);
    map['session_id'] = Variable<int>(sessionId);
    if (!nullToAbsent || planRunId != null) {
      map['plan_run_id'] = Variable<int>(planRunId);
    }
    map['workout_unit_name'] = Variable<String>(workoutUnitName);
    map['lifecycle'] = Variable<String>(lifecycle);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    map['prescription_json'] = Variable<String>(prescriptionJson);
    map['start_payload_json'] = Variable<String>(startPayloadJson);
    if (!nullToAbsent || serverSnapshotJson != null) {
      map['server_snapshot_json'] = Variable<String>(serverSnapshotJson);
    }
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    map['lease_epoch'] = Variable<int>(leaseEpoch);
    map['applied_seq'] = Variable<int>(appliedSeq);
    map['next_seq'] = Variable<int>(nextSeq);
    map['revision'] = Variable<int>(revision);
    map['current_exercise'] = Variable<int>(currentExercise);
    map['current_set'] = Variable<int>(currentSet);
    map['cursor_phase'] = Variable<String>(cursorPhase);
    if (!nullToAbsent || restEndsAt != null) {
      map['rest_ends_at'] = Variable<DateTime>(restEndsAt);
    }
    if (!nullToAbsent || restDurationS != null) {
      map['rest_duration_s'] = Variable<int>(restDurationS);
    }
    if (!nullToAbsent || entryDraftJson != null) {
      map['entry_draft_json'] = Variable<String>(entryDraftJson);
    }
    if (!nullToAbsent || workoutComment != null) {
      map['workout_comment'] = Variable<String>(workoutComment);
    }
    map['sync_state'] = Variable<String>(syncState);
    if (!nullToAbsent || syncErrorCode != null) {
      map['sync_error_code'] = Variable<String>(syncErrorCode);
    }
    map['sync_attempts'] = Variable<int>(syncAttempts);
    if (!nullToAbsent || nextSyncAt != null) {
      map['next_sync_at'] = Variable<DateTime>(nextSyncAt);
    }
    if (!nullToAbsent || finalizePayloadJson != null) {
      map['finalize_payload_json'] = Variable<String>(finalizePayloadJson);
    }
    if (!nullToAbsent || finalizedAt != null) {
      map['finalized_at'] = Variable<DateTime>(finalizedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalWorkoutsCompanion toCompanion(bool nullToAbsent) {
    return LocalWorkoutsCompanion(
      workoutId: Value(workoutId),
      sessionId: Value(sessionId),
      planRunId: planRunId == null && nullToAbsent
          ? const Value.absent()
          : Value(planRunId),
      workoutUnitName: Value(workoutUnitName),
      lifecycle: Value(lifecycle),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      prescriptionJson: Value(prescriptionJson),
      startPayloadJson: Value(startPayloadJson),
      serverSnapshotJson: serverSnapshotJson == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSnapshotJson),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      leaseEpoch: Value(leaseEpoch),
      appliedSeq: Value(appliedSeq),
      nextSeq: Value(nextSeq),
      revision: Value(revision),
      currentExercise: Value(currentExercise),
      currentSet: Value(currentSet),
      cursorPhase: Value(cursorPhase),
      restEndsAt: restEndsAt == null && nullToAbsent
          ? const Value.absent()
          : Value(restEndsAt),
      restDurationS: restDurationS == null && nullToAbsent
          ? const Value.absent()
          : Value(restDurationS),
      entryDraftJson: entryDraftJson == null && nullToAbsent
          ? const Value.absent()
          : Value(entryDraftJson),
      workoutComment: workoutComment == null && nullToAbsent
          ? const Value.absent()
          : Value(workoutComment),
      syncState: Value(syncState),
      syncErrorCode: syncErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(syncErrorCode),
      syncAttempts: Value(syncAttempts),
      nextSyncAt: nextSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextSyncAt),
      finalizePayloadJson: finalizePayloadJson == null && nullToAbsent
          ? const Value.absent()
          : Value(finalizePayloadJson),
      finalizedAt: finalizedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finalizedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalWorkout.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalWorkout(
      workoutId: serializer.fromJson<String>(json['workoutId']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      planRunId: serializer.fromJson<int?>(json['planRunId']),
      workoutUnitName: serializer.fromJson<String>(json['workoutUnitName']),
      lifecycle: serializer.fromJson<String>(json['lifecycle']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
      prescriptionJson: serializer.fromJson<String>(json['prescriptionJson']),
      startPayloadJson: serializer.fromJson<String>(json['startPayloadJson']),
      serverSnapshotJson: serializer.fromJson<String?>(
        json['serverSnapshotJson'],
      ),
      etag: serializer.fromJson<String?>(json['etag']),
      leaseEpoch: serializer.fromJson<int>(json['leaseEpoch']),
      appliedSeq: serializer.fromJson<int>(json['appliedSeq']),
      nextSeq: serializer.fromJson<int>(json['nextSeq']),
      revision: serializer.fromJson<int>(json['revision']),
      currentExercise: serializer.fromJson<int>(json['currentExercise']),
      currentSet: serializer.fromJson<int>(json['currentSet']),
      cursorPhase: serializer.fromJson<String>(json['cursorPhase']),
      restEndsAt: serializer.fromJson<DateTime?>(json['restEndsAt']),
      restDurationS: serializer.fromJson<int?>(json['restDurationS']),
      entryDraftJson: serializer.fromJson<String?>(json['entryDraftJson']),
      workoutComment: serializer.fromJson<String?>(json['workoutComment']),
      syncState: serializer.fromJson<String>(json['syncState']),
      syncErrorCode: serializer.fromJson<String?>(json['syncErrorCode']),
      syncAttempts: serializer.fromJson<int>(json['syncAttempts']),
      nextSyncAt: serializer.fromJson<DateTime?>(json['nextSyncAt']),
      finalizePayloadJson: serializer.fromJson<String?>(
        json['finalizePayloadJson'],
      ),
      finalizedAt: serializer.fromJson<DateTime?>(json['finalizedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workoutId': serializer.toJson<String>(workoutId),
      'sessionId': serializer.toJson<int>(sessionId),
      'planRunId': serializer.toJson<int?>(planRunId),
      'workoutUnitName': serializer.toJson<String>(workoutUnitName),
      'lifecycle': serializer.toJson<String>(lifecycle),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
      'prescriptionJson': serializer.toJson<String>(prescriptionJson),
      'startPayloadJson': serializer.toJson<String>(startPayloadJson),
      'serverSnapshotJson': serializer.toJson<String?>(serverSnapshotJson),
      'etag': serializer.toJson<String?>(etag),
      'leaseEpoch': serializer.toJson<int>(leaseEpoch),
      'appliedSeq': serializer.toJson<int>(appliedSeq),
      'nextSeq': serializer.toJson<int>(nextSeq),
      'revision': serializer.toJson<int>(revision),
      'currentExercise': serializer.toJson<int>(currentExercise),
      'currentSet': serializer.toJson<int>(currentSet),
      'cursorPhase': serializer.toJson<String>(cursorPhase),
      'restEndsAt': serializer.toJson<DateTime?>(restEndsAt),
      'restDurationS': serializer.toJson<int?>(restDurationS),
      'entryDraftJson': serializer.toJson<String?>(entryDraftJson),
      'workoutComment': serializer.toJson<String?>(workoutComment),
      'syncState': serializer.toJson<String>(syncState),
      'syncErrorCode': serializer.toJson<String?>(syncErrorCode),
      'syncAttempts': serializer.toJson<int>(syncAttempts),
      'nextSyncAt': serializer.toJson<DateTime?>(nextSyncAt),
      'finalizePayloadJson': serializer.toJson<String?>(finalizePayloadJson),
      'finalizedAt': serializer.toJson<DateTime?>(finalizedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalWorkout copyWith({
    String? workoutId,
    int? sessionId,
    Value<int?> planRunId = const Value.absent(),
    String? workoutUnitName,
    String? lifecycle,
    DateTime? startedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
    String? prescriptionJson,
    String? startPayloadJson,
    Value<String?> serverSnapshotJson = const Value.absent(),
    Value<String?> etag = const Value.absent(),
    int? leaseEpoch,
    int? appliedSeq,
    int? nextSeq,
    int? revision,
    int? currentExercise,
    int? currentSet,
    String? cursorPhase,
    Value<DateTime?> restEndsAt = const Value.absent(),
    Value<int?> restDurationS = const Value.absent(),
    Value<String?> entryDraftJson = const Value.absent(),
    Value<String?> workoutComment = const Value.absent(),
    String? syncState,
    Value<String?> syncErrorCode = const Value.absent(),
    int? syncAttempts,
    Value<DateTime?> nextSyncAt = const Value.absent(),
    Value<String?> finalizePayloadJson = const Value.absent(),
    Value<DateTime?> finalizedAt = const Value.absent(),
    DateTime? updatedAt,
  }) => LocalWorkout(
    workoutId: workoutId ?? this.workoutId,
    sessionId: sessionId ?? this.sessionId,
    planRunId: planRunId.present ? planRunId.value : this.planRunId,
    workoutUnitName: workoutUnitName ?? this.workoutUnitName,
    lifecycle: lifecycle ?? this.lifecycle,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    prescriptionJson: prescriptionJson ?? this.prescriptionJson,
    startPayloadJson: startPayloadJson ?? this.startPayloadJson,
    serverSnapshotJson: serverSnapshotJson.present
        ? serverSnapshotJson.value
        : this.serverSnapshotJson,
    etag: etag.present ? etag.value : this.etag,
    leaseEpoch: leaseEpoch ?? this.leaseEpoch,
    appliedSeq: appliedSeq ?? this.appliedSeq,
    nextSeq: nextSeq ?? this.nextSeq,
    revision: revision ?? this.revision,
    currentExercise: currentExercise ?? this.currentExercise,
    currentSet: currentSet ?? this.currentSet,
    cursorPhase: cursorPhase ?? this.cursorPhase,
    restEndsAt: restEndsAt.present ? restEndsAt.value : this.restEndsAt,
    restDurationS: restDurationS.present
        ? restDurationS.value
        : this.restDurationS,
    entryDraftJson: entryDraftJson.present
        ? entryDraftJson.value
        : this.entryDraftJson,
    workoutComment: workoutComment.present
        ? workoutComment.value
        : this.workoutComment,
    syncState: syncState ?? this.syncState,
    syncErrorCode: syncErrorCode.present
        ? syncErrorCode.value
        : this.syncErrorCode,
    syncAttempts: syncAttempts ?? this.syncAttempts,
    nextSyncAt: nextSyncAt.present ? nextSyncAt.value : this.nextSyncAt,
    finalizePayloadJson: finalizePayloadJson.present
        ? finalizePayloadJson.value
        : this.finalizePayloadJson,
    finalizedAt: finalizedAt.present ? finalizedAt.value : this.finalizedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalWorkout copyWithCompanion(LocalWorkoutsCompanion data) {
    return LocalWorkout(
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      planRunId: data.planRunId.present ? data.planRunId.value : this.planRunId,
      workoutUnitName: data.workoutUnitName.present
          ? data.workoutUnitName.value
          : this.workoutUnitName,
      lifecycle: data.lifecycle.present ? data.lifecycle.value : this.lifecycle,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      prescriptionJson: data.prescriptionJson.present
          ? data.prescriptionJson.value
          : this.prescriptionJson,
      startPayloadJson: data.startPayloadJson.present
          ? data.startPayloadJson.value
          : this.startPayloadJson,
      serverSnapshotJson: data.serverSnapshotJson.present
          ? data.serverSnapshotJson.value
          : this.serverSnapshotJson,
      etag: data.etag.present ? data.etag.value : this.etag,
      leaseEpoch: data.leaseEpoch.present
          ? data.leaseEpoch.value
          : this.leaseEpoch,
      appliedSeq: data.appliedSeq.present
          ? data.appliedSeq.value
          : this.appliedSeq,
      nextSeq: data.nextSeq.present ? data.nextSeq.value : this.nextSeq,
      revision: data.revision.present ? data.revision.value : this.revision,
      currentExercise: data.currentExercise.present
          ? data.currentExercise.value
          : this.currentExercise,
      currentSet: data.currentSet.present
          ? data.currentSet.value
          : this.currentSet,
      cursorPhase: data.cursorPhase.present
          ? data.cursorPhase.value
          : this.cursorPhase,
      restEndsAt: data.restEndsAt.present
          ? data.restEndsAt.value
          : this.restEndsAt,
      restDurationS: data.restDurationS.present
          ? data.restDurationS.value
          : this.restDurationS,
      entryDraftJson: data.entryDraftJson.present
          ? data.entryDraftJson.value
          : this.entryDraftJson,
      workoutComment: data.workoutComment.present
          ? data.workoutComment.value
          : this.workoutComment,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      syncErrorCode: data.syncErrorCode.present
          ? data.syncErrorCode.value
          : this.syncErrorCode,
      syncAttempts: data.syncAttempts.present
          ? data.syncAttempts.value
          : this.syncAttempts,
      nextSyncAt: data.nextSyncAt.present
          ? data.nextSyncAt.value
          : this.nextSyncAt,
      finalizePayloadJson: data.finalizePayloadJson.present
          ? data.finalizePayloadJson.value
          : this.finalizePayloadJson,
      finalizedAt: data.finalizedAt.present
          ? data.finalizedAt.value
          : this.finalizedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalWorkout(')
          ..write('workoutId: $workoutId, ')
          ..write('sessionId: $sessionId, ')
          ..write('planRunId: $planRunId, ')
          ..write('workoutUnitName: $workoutUnitName, ')
          ..write('lifecycle: $lifecycle, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('prescriptionJson: $prescriptionJson, ')
          ..write('startPayloadJson: $startPayloadJson, ')
          ..write('serverSnapshotJson: $serverSnapshotJson, ')
          ..write('etag: $etag, ')
          ..write('leaseEpoch: $leaseEpoch, ')
          ..write('appliedSeq: $appliedSeq, ')
          ..write('nextSeq: $nextSeq, ')
          ..write('revision: $revision, ')
          ..write('currentExercise: $currentExercise, ')
          ..write('currentSet: $currentSet, ')
          ..write('cursorPhase: $cursorPhase, ')
          ..write('restEndsAt: $restEndsAt, ')
          ..write('restDurationS: $restDurationS, ')
          ..write('entryDraftJson: $entryDraftJson, ')
          ..write('workoutComment: $workoutComment, ')
          ..write('syncState: $syncState, ')
          ..write('syncErrorCode: $syncErrorCode, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('nextSyncAt: $nextSyncAt, ')
          ..write('finalizePayloadJson: $finalizePayloadJson, ')
          ..write('finalizedAt: $finalizedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    workoutId,
    sessionId,
    planRunId,
    workoutUnitName,
    lifecycle,
    startedAt,
    finishedAt,
    prescriptionJson,
    startPayloadJson,
    serverSnapshotJson,
    etag,
    leaseEpoch,
    appliedSeq,
    nextSeq,
    revision,
    currentExercise,
    currentSet,
    cursorPhase,
    restEndsAt,
    restDurationS,
    entryDraftJson,
    workoutComment,
    syncState,
    syncErrorCode,
    syncAttempts,
    nextSyncAt,
    finalizePayloadJson,
    finalizedAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalWorkout &&
          other.workoutId == this.workoutId &&
          other.sessionId == this.sessionId &&
          other.planRunId == this.planRunId &&
          other.workoutUnitName == this.workoutUnitName &&
          other.lifecycle == this.lifecycle &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.prescriptionJson == this.prescriptionJson &&
          other.startPayloadJson == this.startPayloadJson &&
          other.serverSnapshotJson == this.serverSnapshotJson &&
          other.etag == this.etag &&
          other.leaseEpoch == this.leaseEpoch &&
          other.appliedSeq == this.appliedSeq &&
          other.nextSeq == this.nextSeq &&
          other.revision == this.revision &&
          other.currentExercise == this.currentExercise &&
          other.currentSet == this.currentSet &&
          other.cursorPhase == this.cursorPhase &&
          other.restEndsAt == this.restEndsAt &&
          other.restDurationS == this.restDurationS &&
          other.entryDraftJson == this.entryDraftJson &&
          other.workoutComment == this.workoutComment &&
          other.syncState == this.syncState &&
          other.syncErrorCode == this.syncErrorCode &&
          other.syncAttempts == this.syncAttempts &&
          other.nextSyncAt == this.nextSyncAt &&
          other.finalizePayloadJson == this.finalizePayloadJson &&
          other.finalizedAt == this.finalizedAt &&
          other.updatedAt == this.updatedAt);
}

class LocalWorkoutsCompanion extends UpdateCompanion<LocalWorkout> {
  final Value<String> workoutId;
  final Value<int> sessionId;
  final Value<int?> planRunId;
  final Value<String> workoutUnitName;
  final Value<String> lifecycle;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<String> prescriptionJson;
  final Value<String> startPayloadJson;
  final Value<String?> serverSnapshotJson;
  final Value<String?> etag;
  final Value<int> leaseEpoch;
  final Value<int> appliedSeq;
  final Value<int> nextSeq;
  final Value<int> revision;
  final Value<int> currentExercise;
  final Value<int> currentSet;
  final Value<String> cursorPhase;
  final Value<DateTime?> restEndsAt;
  final Value<int?> restDurationS;
  final Value<String?> entryDraftJson;
  final Value<String?> workoutComment;
  final Value<String> syncState;
  final Value<String?> syncErrorCode;
  final Value<int> syncAttempts;
  final Value<DateTime?> nextSyncAt;
  final Value<String?> finalizePayloadJson;
  final Value<DateTime?> finalizedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalWorkoutsCompanion({
    this.workoutId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.planRunId = const Value.absent(),
    this.workoutUnitName = const Value.absent(),
    this.lifecycle = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.prescriptionJson = const Value.absent(),
    this.startPayloadJson = const Value.absent(),
    this.serverSnapshotJson = const Value.absent(),
    this.etag = const Value.absent(),
    this.leaseEpoch = const Value.absent(),
    this.appliedSeq = const Value.absent(),
    this.nextSeq = const Value.absent(),
    this.revision = const Value.absent(),
    this.currentExercise = const Value.absent(),
    this.currentSet = const Value.absent(),
    this.cursorPhase = const Value.absent(),
    this.restEndsAt = const Value.absent(),
    this.restDurationS = const Value.absent(),
    this.entryDraftJson = const Value.absent(),
    this.workoutComment = const Value.absent(),
    this.syncState = const Value.absent(),
    this.syncErrorCode = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.nextSyncAt = const Value.absent(),
    this.finalizePayloadJson = const Value.absent(),
    this.finalizedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalWorkoutsCompanion.insert({
    required String workoutId,
    required int sessionId,
    this.planRunId = const Value.absent(),
    required String workoutUnitName,
    this.lifecycle = const Value.absent(),
    required DateTime startedAt,
    this.finishedAt = const Value.absent(),
    required String prescriptionJson,
    required String startPayloadJson,
    this.serverSnapshotJson = const Value.absent(),
    this.etag = const Value.absent(),
    this.leaseEpoch = const Value.absent(),
    this.appliedSeq = const Value.absent(),
    this.nextSeq = const Value.absent(),
    this.revision = const Value.absent(),
    this.currentExercise = const Value.absent(),
    this.currentSet = const Value.absent(),
    this.cursorPhase = const Value.absent(),
    this.restEndsAt = const Value.absent(),
    this.restDurationS = const Value.absent(),
    this.entryDraftJson = const Value.absent(),
    this.workoutComment = const Value.absent(),
    this.syncState = const Value.absent(),
    this.syncErrorCode = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.nextSyncAt = const Value.absent(),
    this.finalizePayloadJson = const Value.absent(),
    this.finalizedAt = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : workoutId = Value(workoutId),
       sessionId = Value(sessionId),
       workoutUnitName = Value(workoutUnitName),
       startedAt = Value(startedAt),
       prescriptionJson = Value(prescriptionJson),
       startPayloadJson = Value(startPayloadJson),
       updatedAt = Value(updatedAt);
  static Insertable<LocalWorkout> custom({
    Expression<String>? workoutId,
    Expression<int>? sessionId,
    Expression<int>? planRunId,
    Expression<String>? workoutUnitName,
    Expression<String>? lifecycle,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<String>? prescriptionJson,
    Expression<String>? startPayloadJson,
    Expression<String>? serverSnapshotJson,
    Expression<String>? etag,
    Expression<int>? leaseEpoch,
    Expression<int>? appliedSeq,
    Expression<int>? nextSeq,
    Expression<int>? revision,
    Expression<int>? currentExercise,
    Expression<int>? currentSet,
    Expression<String>? cursorPhase,
    Expression<DateTime>? restEndsAt,
    Expression<int>? restDurationS,
    Expression<String>? entryDraftJson,
    Expression<String>? workoutComment,
    Expression<String>? syncState,
    Expression<String>? syncErrorCode,
    Expression<int>? syncAttempts,
    Expression<DateTime>? nextSyncAt,
    Expression<String>? finalizePayloadJson,
    Expression<DateTime>? finalizedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workoutId != null) 'workout_id': workoutId,
      if (sessionId != null) 'session_id': sessionId,
      if (planRunId != null) 'plan_run_id': planRunId,
      if (workoutUnitName != null) 'workout_unit_name': workoutUnitName,
      if (lifecycle != null) 'lifecycle': lifecycle,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (prescriptionJson != null) 'prescription_json': prescriptionJson,
      if (startPayloadJson != null) 'start_payload_json': startPayloadJson,
      if (serverSnapshotJson != null)
        'server_snapshot_json': serverSnapshotJson,
      if (etag != null) 'etag': etag,
      if (leaseEpoch != null) 'lease_epoch': leaseEpoch,
      if (appliedSeq != null) 'applied_seq': appliedSeq,
      if (nextSeq != null) 'next_seq': nextSeq,
      if (revision != null) 'revision': revision,
      if (currentExercise != null) 'current_exercise': currentExercise,
      if (currentSet != null) 'current_set': currentSet,
      if (cursorPhase != null) 'cursor_phase': cursorPhase,
      if (restEndsAt != null) 'rest_ends_at': restEndsAt,
      if (restDurationS != null) 'rest_duration_s': restDurationS,
      if (entryDraftJson != null) 'entry_draft_json': entryDraftJson,
      if (workoutComment != null) 'workout_comment': workoutComment,
      if (syncState != null) 'sync_state': syncState,
      if (syncErrorCode != null) 'sync_error_code': syncErrorCode,
      if (syncAttempts != null) 'sync_attempts': syncAttempts,
      if (nextSyncAt != null) 'next_sync_at': nextSyncAt,
      if (finalizePayloadJson != null)
        'finalize_payload_json': finalizePayloadJson,
      if (finalizedAt != null) 'finalized_at': finalizedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalWorkoutsCompanion copyWith({
    Value<String>? workoutId,
    Value<int>? sessionId,
    Value<int?>? planRunId,
    Value<String>? workoutUnitName,
    Value<String>? lifecycle,
    Value<DateTime>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<String>? prescriptionJson,
    Value<String>? startPayloadJson,
    Value<String?>? serverSnapshotJson,
    Value<String?>? etag,
    Value<int>? leaseEpoch,
    Value<int>? appliedSeq,
    Value<int>? nextSeq,
    Value<int>? revision,
    Value<int>? currentExercise,
    Value<int>? currentSet,
    Value<String>? cursorPhase,
    Value<DateTime?>? restEndsAt,
    Value<int?>? restDurationS,
    Value<String?>? entryDraftJson,
    Value<String?>? workoutComment,
    Value<String>? syncState,
    Value<String?>? syncErrorCode,
    Value<int>? syncAttempts,
    Value<DateTime?>? nextSyncAt,
    Value<String?>? finalizePayloadJson,
    Value<DateTime?>? finalizedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalWorkoutsCompanion(
      workoutId: workoutId ?? this.workoutId,
      sessionId: sessionId ?? this.sessionId,
      planRunId: planRunId ?? this.planRunId,
      workoutUnitName: workoutUnitName ?? this.workoutUnitName,
      lifecycle: lifecycle ?? this.lifecycle,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      prescriptionJson: prescriptionJson ?? this.prescriptionJson,
      startPayloadJson: startPayloadJson ?? this.startPayloadJson,
      serverSnapshotJson: serverSnapshotJson ?? this.serverSnapshotJson,
      etag: etag ?? this.etag,
      leaseEpoch: leaseEpoch ?? this.leaseEpoch,
      appliedSeq: appliedSeq ?? this.appliedSeq,
      nextSeq: nextSeq ?? this.nextSeq,
      revision: revision ?? this.revision,
      currentExercise: currentExercise ?? this.currentExercise,
      currentSet: currentSet ?? this.currentSet,
      cursorPhase: cursorPhase ?? this.cursorPhase,
      restEndsAt: restEndsAt ?? this.restEndsAt,
      restDurationS: restDurationS ?? this.restDurationS,
      entryDraftJson: entryDraftJson ?? this.entryDraftJson,
      workoutComment: workoutComment ?? this.workoutComment,
      syncState: syncState ?? this.syncState,
      syncErrorCode: syncErrorCode ?? this.syncErrorCode,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      nextSyncAt: nextSyncAt ?? this.nextSyncAt,
      finalizePayloadJson: finalizePayloadJson ?? this.finalizePayloadJson,
      finalizedAt: finalizedAt ?? this.finalizedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workoutId.present) {
      map['workout_id'] = Variable<String>(workoutId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (planRunId.present) {
      map['plan_run_id'] = Variable<int>(planRunId.value);
    }
    if (workoutUnitName.present) {
      map['workout_unit_name'] = Variable<String>(workoutUnitName.value);
    }
    if (lifecycle.present) {
      map['lifecycle'] = Variable<String>(lifecycle.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (prescriptionJson.present) {
      map['prescription_json'] = Variable<String>(prescriptionJson.value);
    }
    if (startPayloadJson.present) {
      map['start_payload_json'] = Variable<String>(startPayloadJson.value);
    }
    if (serverSnapshotJson.present) {
      map['server_snapshot_json'] = Variable<String>(serverSnapshotJson.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (leaseEpoch.present) {
      map['lease_epoch'] = Variable<int>(leaseEpoch.value);
    }
    if (appliedSeq.present) {
      map['applied_seq'] = Variable<int>(appliedSeq.value);
    }
    if (nextSeq.present) {
      map['next_seq'] = Variable<int>(nextSeq.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (currentExercise.present) {
      map['current_exercise'] = Variable<int>(currentExercise.value);
    }
    if (currentSet.present) {
      map['current_set'] = Variable<int>(currentSet.value);
    }
    if (cursorPhase.present) {
      map['cursor_phase'] = Variable<String>(cursorPhase.value);
    }
    if (restEndsAt.present) {
      map['rest_ends_at'] = Variable<DateTime>(restEndsAt.value);
    }
    if (restDurationS.present) {
      map['rest_duration_s'] = Variable<int>(restDurationS.value);
    }
    if (entryDraftJson.present) {
      map['entry_draft_json'] = Variable<String>(entryDraftJson.value);
    }
    if (workoutComment.present) {
      map['workout_comment'] = Variable<String>(workoutComment.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (syncErrorCode.present) {
      map['sync_error_code'] = Variable<String>(syncErrorCode.value);
    }
    if (syncAttempts.present) {
      map['sync_attempts'] = Variable<int>(syncAttempts.value);
    }
    if (nextSyncAt.present) {
      map['next_sync_at'] = Variable<DateTime>(nextSyncAt.value);
    }
    if (finalizePayloadJson.present) {
      map['finalize_payload_json'] = Variable<String>(
        finalizePayloadJson.value,
      );
    }
    if (finalizedAt.present) {
      map['finalized_at'] = Variable<DateTime>(finalizedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalWorkoutsCompanion(')
          ..write('workoutId: $workoutId, ')
          ..write('sessionId: $sessionId, ')
          ..write('planRunId: $planRunId, ')
          ..write('workoutUnitName: $workoutUnitName, ')
          ..write('lifecycle: $lifecycle, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('prescriptionJson: $prescriptionJson, ')
          ..write('startPayloadJson: $startPayloadJson, ')
          ..write('serverSnapshotJson: $serverSnapshotJson, ')
          ..write('etag: $etag, ')
          ..write('leaseEpoch: $leaseEpoch, ')
          ..write('appliedSeq: $appliedSeq, ')
          ..write('nextSeq: $nextSeq, ')
          ..write('revision: $revision, ')
          ..write('currentExercise: $currentExercise, ')
          ..write('currentSet: $currentSet, ')
          ..write('cursorPhase: $cursorPhase, ')
          ..write('restEndsAt: $restEndsAt, ')
          ..write('restDurationS: $restDurationS, ')
          ..write('entryDraftJson: $entryDraftJson, ')
          ..write('workoutComment: $workoutComment, ')
          ..write('syncState: $syncState, ')
          ..write('syncErrorCode: $syncErrorCode, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('nextSyncAt: $nextSyncAt, ')
          ..write('finalizePayloadJson: $finalizePayloadJson, ')
          ..write('finalizedAt: $finalizedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalExercisesTable extends LocalExercises
    with TableInfo<$LocalExercisesTable, LocalExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _exercisePerformanceIdMeta =
      const VerificationMeta('exercisePerformanceId');
  @override
  late final GeneratedColumn<String> exercisePerformanceId =
      GeneratedColumn<String>(
        'exercise_performance_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _workoutIdMeta = const VerificationMeta(
    'workoutId',
  );
  @override
  late final GeneratedColumn<String> workoutId = GeneratedColumn<String>(
    'workout_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_workouts (workout_id)',
    ),
  );
  static const VerificationMeta _exercisePrescriptionIdMeta =
      const VerificationMeta('exercisePrescriptionId');
  @override
  late final GeneratedColumn<int> exercisePrescriptionId = GeneratedColumn<int>(
    'exercise_prescription_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prescribedExerciseIdMeta =
      const VerificationMeta('prescribedExerciseId');
  @override
  late final GeneratedColumn<int> prescribedExerciseId = GeneratedColumn<int>(
    'prescribed_exercise_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualExerciseIdMeta = const VerificationMeta(
    'actualExerciseId',
  );
  @override
  late final GeneratedColumn<int> actualExerciseId = GeneratedColumn<int>(
    'actual_exercise_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualExerciseJsonMeta =
      const VerificationMeta('actualExerciseJson');
  @override
  late final GeneratedColumn<String> actualExerciseJson =
      GeneratedColumn<String>(
        'actual_exercise_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _performedOrdinalMeta = const VerificationMeta(
    'performedOrdinal',
  );
  @override
  late final GeneratedColumn<int> performedOrdinal = GeneratedColumn<int>(
    'performed_ordinal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('as_prescribed'),
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverRevMeta = const VerificationMeta(
    'serverRev',
  );
  @override
  late final GeneratedColumn<int> serverRev = GeneratedColumn<int>(
    'server_rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _localRevMeta = const VerificationMeta(
    'localRev',
  );
  @override
  late final GeneratedColumn<int> localRev = GeneratedColumn<int>(
    'local_rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    exercisePerformanceId,
    workoutId,
    exercisePrescriptionId,
    prescribedExerciseId,
    actualExerciseId,
    actualExerciseJson,
    performedOrdinal,
    mode,
    comment,
    serverRev,
    localRev,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exercise_performance_id')) {
      context.handle(
        _exercisePerformanceIdMeta,
        exercisePerformanceId.isAcceptableOrUnknown(
          data['exercise_performance_id']!,
          _exercisePerformanceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exercisePerformanceIdMeta);
    }
    if (data.containsKey('workout_id')) {
      context.handle(
        _workoutIdMeta,
        workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('exercise_prescription_id')) {
      context.handle(
        _exercisePrescriptionIdMeta,
        exercisePrescriptionId.isAcceptableOrUnknown(
          data['exercise_prescription_id']!,
          _exercisePrescriptionIdMeta,
        ),
      );
    }
    if (data.containsKey('prescribed_exercise_id')) {
      context.handle(
        _prescribedExerciseIdMeta,
        prescribedExerciseId.isAcceptableOrUnknown(
          data['prescribed_exercise_id']!,
          _prescribedExerciseIdMeta,
        ),
      );
    }
    if (data.containsKey('actual_exercise_id')) {
      context.handle(
        _actualExerciseIdMeta,
        actualExerciseId.isAcceptableOrUnknown(
          data['actual_exercise_id']!,
          _actualExerciseIdMeta,
        ),
      );
    }
    if (data.containsKey('actual_exercise_json')) {
      context.handle(
        _actualExerciseJsonMeta,
        actualExerciseJson.isAcceptableOrUnknown(
          data['actual_exercise_json']!,
          _actualExerciseJsonMeta,
        ),
      );
    }
    if (data.containsKey('performed_ordinal')) {
      context.handle(
        _performedOrdinalMeta,
        performedOrdinal.isAcceptableOrUnknown(
          data['performed_ordinal']!,
          _performedOrdinalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_performedOrdinalMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    }
    if (data.containsKey('server_rev')) {
      context.handle(
        _serverRevMeta,
        serverRev.isAcceptableOrUnknown(data['server_rev']!, _serverRevMeta),
      );
    }
    if (data.containsKey('local_rev')) {
      context.handle(
        _localRevMeta,
        localRev.isAcceptableOrUnknown(data['local_rev']!, _localRevMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {exercisePerformanceId};
  @override
  LocalExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalExercise(
      exercisePerformanceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_performance_id'],
      )!,
      workoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_id'],
      )!,
      exercisePrescriptionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_prescription_id'],
      ),
      prescribedExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prescribed_exercise_id'],
      ),
      actualExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_exercise_id'],
      ),
      actualExerciseJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actual_exercise_json'],
      ),
      performedOrdinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}performed_ordinal'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      ),
      serverRev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_rev'],
      )!,
      localRev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_rev'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalExercisesTable createAlias(String alias) {
    return $LocalExercisesTable(attachedDatabase, alias);
  }
}

class LocalExercise extends DataClass implements Insertable<LocalExercise> {
  final String exercisePerformanceId;
  final String workoutId;
  final int? exercisePrescriptionId;
  final int? prescribedExerciseId;
  final int? actualExerciseId;
  final String? actualExerciseJson;
  final int performedOrdinal;
  final String mode;
  final String? comment;
  final int serverRev;
  final int localRev;
  final DateTime updatedAt;
  const LocalExercise({
    required this.exercisePerformanceId,
    required this.workoutId,
    this.exercisePrescriptionId,
    this.prescribedExerciseId,
    this.actualExerciseId,
    this.actualExerciseJson,
    required this.performedOrdinal,
    required this.mode,
    this.comment,
    required this.serverRev,
    required this.localRev,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exercise_performance_id'] = Variable<String>(exercisePerformanceId);
    map['workout_id'] = Variable<String>(workoutId);
    if (!nullToAbsent || exercisePrescriptionId != null) {
      map['exercise_prescription_id'] = Variable<int>(exercisePrescriptionId);
    }
    if (!nullToAbsent || prescribedExerciseId != null) {
      map['prescribed_exercise_id'] = Variable<int>(prescribedExerciseId);
    }
    if (!nullToAbsent || actualExerciseId != null) {
      map['actual_exercise_id'] = Variable<int>(actualExerciseId);
    }
    if (!nullToAbsent || actualExerciseJson != null) {
      map['actual_exercise_json'] = Variable<String>(actualExerciseJson);
    }
    map['performed_ordinal'] = Variable<int>(performedOrdinal);
    map['mode'] = Variable<String>(mode);
    if (!nullToAbsent || comment != null) {
      map['comment'] = Variable<String>(comment);
    }
    map['server_rev'] = Variable<int>(serverRev);
    map['local_rev'] = Variable<int>(localRev);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalExercisesCompanion toCompanion(bool nullToAbsent) {
    return LocalExercisesCompanion(
      exercisePerformanceId: Value(exercisePerformanceId),
      workoutId: Value(workoutId),
      exercisePrescriptionId: exercisePrescriptionId == null && nullToAbsent
          ? const Value.absent()
          : Value(exercisePrescriptionId),
      prescribedExerciseId: prescribedExerciseId == null && nullToAbsent
          ? const Value.absent()
          : Value(prescribedExerciseId),
      actualExerciseId: actualExerciseId == null && nullToAbsent
          ? const Value.absent()
          : Value(actualExerciseId),
      actualExerciseJson: actualExerciseJson == null && nullToAbsent
          ? const Value.absent()
          : Value(actualExerciseJson),
      performedOrdinal: Value(performedOrdinal),
      mode: Value(mode),
      comment: comment == null && nullToAbsent
          ? const Value.absent()
          : Value(comment),
      serverRev: Value(serverRev),
      localRev: Value(localRev),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalExercise(
      exercisePerformanceId: serializer.fromJson<String>(
        json['exercisePerformanceId'],
      ),
      workoutId: serializer.fromJson<String>(json['workoutId']),
      exercisePrescriptionId: serializer.fromJson<int?>(
        json['exercisePrescriptionId'],
      ),
      prescribedExerciseId: serializer.fromJson<int?>(
        json['prescribedExerciseId'],
      ),
      actualExerciseId: serializer.fromJson<int?>(json['actualExerciseId']),
      actualExerciseJson: serializer.fromJson<String?>(
        json['actualExerciseJson'],
      ),
      performedOrdinal: serializer.fromJson<int>(json['performedOrdinal']),
      mode: serializer.fromJson<String>(json['mode']),
      comment: serializer.fromJson<String?>(json['comment']),
      serverRev: serializer.fromJson<int>(json['serverRev']),
      localRev: serializer.fromJson<int>(json['localRev']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'exercisePerformanceId': serializer.toJson<String>(exercisePerformanceId),
      'workoutId': serializer.toJson<String>(workoutId),
      'exercisePrescriptionId': serializer.toJson<int?>(exercisePrescriptionId),
      'prescribedExerciseId': serializer.toJson<int?>(prescribedExerciseId),
      'actualExerciseId': serializer.toJson<int?>(actualExerciseId),
      'actualExerciseJson': serializer.toJson<String?>(actualExerciseJson),
      'performedOrdinal': serializer.toJson<int>(performedOrdinal),
      'mode': serializer.toJson<String>(mode),
      'comment': serializer.toJson<String?>(comment),
      'serverRev': serializer.toJson<int>(serverRev),
      'localRev': serializer.toJson<int>(localRev),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalExercise copyWith({
    String? exercisePerformanceId,
    String? workoutId,
    Value<int?> exercisePrescriptionId = const Value.absent(),
    Value<int?> prescribedExerciseId = const Value.absent(),
    Value<int?> actualExerciseId = const Value.absent(),
    Value<String?> actualExerciseJson = const Value.absent(),
    int? performedOrdinal,
    String? mode,
    Value<String?> comment = const Value.absent(),
    int? serverRev,
    int? localRev,
    DateTime? updatedAt,
  }) => LocalExercise(
    exercisePerformanceId: exercisePerformanceId ?? this.exercisePerformanceId,
    workoutId: workoutId ?? this.workoutId,
    exercisePrescriptionId: exercisePrescriptionId.present
        ? exercisePrescriptionId.value
        : this.exercisePrescriptionId,
    prescribedExerciseId: prescribedExerciseId.present
        ? prescribedExerciseId.value
        : this.prescribedExerciseId,
    actualExerciseId: actualExerciseId.present
        ? actualExerciseId.value
        : this.actualExerciseId,
    actualExerciseJson: actualExerciseJson.present
        ? actualExerciseJson.value
        : this.actualExerciseJson,
    performedOrdinal: performedOrdinal ?? this.performedOrdinal,
    mode: mode ?? this.mode,
    comment: comment.present ? comment.value : this.comment,
    serverRev: serverRev ?? this.serverRev,
    localRev: localRev ?? this.localRev,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalExercise copyWithCompanion(LocalExercisesCompanion data) {
    return LocalExercise(
      exercisePerformanceId: data.exercisePerformanceId.present
          ? data.exercisePerformanceId.value
          : this.exercisePerformanceId,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      exercisePrescriptionId: data.exercisePrescriptionId.present
          ? data.exercisePrescriptionId.value
          : this.exercisePrescriptionId,
      prescribedExerciseId: data.prescribedExerciseId.present
          ? data.prescribedExerciseId.value
          : this.prescribedExerciseId,
      actualExerciseId: data.actualExerciseId.present
          ? data.actualExerciseId.value
          : this.actualExerciseId,
      actualExerciseJson: data.actualExerciseJson.present
          ? data.actualExerciseJson.value
          : this.actualExerciseJson,
      performedOrdinal: data.performedOrdinal.present
          ? data.performedOrdinal.value
          : this.performedOrdinal,
      mode: data.mode.present ? data.mode.value : this.mode,
      comment: data.comment.present ? data.comment.value : this.comment,
      serverRev: data.serverRev.present ? data.serverRev.value : this.serverRev,
      localRev: data.localRev.present ? data.localRev.value : this.localRev,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalExercise(')
          ..write('exercisePerformanceId: $exercisePerformanceId, ')
          ..write('workoutId: $workoutId, ')
          ..write('exercisePrescriptionId: $exercisePrescriptionId, ')
          ..write('prescribedExerciseId: $prescribedExerciseId, ')
          ..write('actualExerciseId: $actualExerciseId, ')
          ..write('actualExerciseJson: $actualExerciseJson, ')
          ..write('performedOrdinal: $performedOrdinal, ')
          ..write('mode: $mode, ')
          ..write('comment: $comment, ')
          ..write('serverRev: $serverRev, ')
          ..write('localRev: $localRev, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    exercisePerformanceId,
    workoutId,
    exercisePrescriptionId,
    prescribedExerciseId,
    actualExerciseId,
    actualExerciseJson,
    performedOrdinal,
    mode,
    comment,
    serverRev,
    localRev,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalExercise &&
          other.exercisePerformanceId == this.exercisePerformanceId &&
          other.workoutId == this.workoutId &&
          other.exercisePrescriptionId == this.exercisePrescriptionId &&
          other.prescribedExerciseId == this.prescribedExerciseId &&
          other.actualExerciseId == this.actualExerciseId &&
          other.actualExerciseJson == this.actualExerciseJson &&
          other.performedOrdinal == this.performedOrdinal &&
          other.mode == this.mode &&
          other.comment == this.comment &&
          other.serverRev == this.serverRev &&
          other.localRev == this.localRev &&
          other.updatedAt == this.updatedAt);
}

class LocalExercisesCompanion extends UpdateCompanion<LocalExercise> {
  final Value<String> exercisePerformanceId;
  final Value<String> workoutId;
  final Value<int?> exercisePrescriptionId;
  final Value<int?> prescribedExerciseId;
  final Value<int?> actualExerciseId;
  final Value<String?> actualExerciseJson;
  final Value<int> performedOrdinal;
  final Value<String> mode;
  final Value<String?> comment;
  final Value<int> serverRev;
  final Value<int> localRev;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalExercisesCompanion({
    this.exercisePerformanceId = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.exercisePrescriptionId = const Value.absent(),
    this.prescribedExerciseId = const Value.absent(),
    this.actualExerciseId = const Value.absent(),
    this.actualExerciseJson = const Value.absent(),
    this.performedOrdinal = const Value.absent(),
    this.mode = const Value.absent(),
    this.comment = const Value.absent(),
    this.serverRev = const Value.absent(),
    this.localRev = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalExercisesCompanion.insert({
    required String exercisePerformanceId,
    required String workoutId,
    this.exercisePrescriptionId = const Value.absent(),
    this.prescribedExerciseId = const Value.absent(),
    this.actualExerciseId = const Value.absent(),
    this.actualExerciseJson = const Value.absent(),
    required int performedOrdinal,
    this.mode = const Value.absent(),
    this.comment = const Value.absent(),
    this.serverRev = const Value.absent(),
    this.localRev = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : exercisePerformanceId = Value(exercisePerformanceId),
       workoutId = Value(workoutId),
       performedOrdinal = Value(performedOrdinal),
       updatedAt = Value(updatedAt);
  static Insertable<LocalExercise> custom({
    Expression<String>? exercisePerformanceId,
    Expression<String>? workoutId,
    Expression<int>? exercisePrescriptionId,
    Expression<int>? prescribedExerciseId,
    Expression<int>? actualExerciseId,
    Expression<String>? actualExerciseJson,
    Expression<int>? performedOrdinal,
    Expression<String>? mode,
    Expression<String>? comment,
    Expression<int>? serverRev,
    Expression<int>? localRev,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (exercisePerformanceId != null)
        'exercise_performance_id': exercisePerformanceId,
      if (workoutId != null) 'workout_id': workoutId,
      if (exercisePrescriptionId != null)
        'exercise_prescription_id': exercisePrescriptionId,
      if (prescribedExerciseId != null)
        'prescribed_exercise_id': prescribedExerciseId,
      if (actualExerciseId != null) 'actual_exercise_id': actualExerciseId,
      if (actualExerciseJson != null)
        'actual_exercise_json': actualExerciseJson,
      if (performedOrdinal != null) 'performed_ordinal': performedOrdinal,
      if (mode != null) 'mode': mode,
      if (comment != null) 'comment': comment,
      if (serverRev != null) 'server_rev': serverRev,
      if (localRev != null) 'local_rev': localRev,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalExercisesCompanion copyWith({
    Value<String>? exercisePerformanceId,
    Value<String>? workoutId,
    Value<int?>? exercisePrescriptionId,
    Value<int?>? prescribedExerciseId,
    Value<int?>? actualExerciseId,
    Value<String?>? actualExerciseJson,
    Value<int>? performedOrdinal,
    Value<String>? mode,
    Value<String?>? comment,
    Value<int>? serverRev,
    Value<int>? localRev,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalExercisesCompanion(
      exercisePerformanceId:
          exercisePerformanceId ?? this.exercisePerformanceId,
      workoutId: workoutId ?? this.workoutId,
      exercisePrescriptionId:
          exercisePrescriptionId ?? this.exercisePrescriptionId,
      prescribedExerciseId: prescribedExerciseId ?? this.prescribedExerciseId,
      actualExerciseId: actualExerciseId ?? this.actualExerciseId,
      actualExerciseJson: actualExerciseJson ?? this.actualExerciseJson,
      performedOrdinal: performedOrdinal ?? this.performedOrdinal,
      mode: mode ?? this.mode,
      comment: comment ?? this.comment,
      serverRev: serverRev ?? this.serverRev,
      localRev: localRev ?? this.localRev,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (exercisePerformanceId.present) {
      map['exercise_performance_id'] = Variable<String>(
        exercisePerformanceId.value,
      );
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<String>(workoutId.value);
    }
    if (exercisePrescriptionId.present) {
      map['exercise_prescription_id'] = Variable<int>(
        exercisePrescriptionId.value,
      );
    }
    if (prescribedExerciseId.present) {
      map['prescribed_exercise_id'] = Variable<int>(prescribedExerciseId.value);
    }
    if (actualExerciseId.present) {
      map['actual_exercise_id'] = Variable<int>(actualExerciseId.value);
    }
    if (actualExerciseJson.present) {
      map['actual_exercise_json'] = Variable<String>(actualExerciseJson.value);
    }
    if (performedOrdinal.present) {
      map['performed_ordinal'] = Variable<int>(performedOrdinal.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (serverRev.present) {
      map['server_rev'] = Variable<int>(serverRev.value);
    }
    if (localRev.present) {
      map['local_rev'] = Variable<int>(localRev.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalExercisesCompanion(')
          ..write('exercisePerformanceId: $exercisePerformanceId, ')
          ..write('workoutId: $workoutId, ')
          ..write('exercisePrescriptionId: $exercisePrescriptionId, ')
          ..write('prescribedExerciseId: $prescribedExerciseId, ')
          ..write('actualExerciseId: $actualExerciseId, ')
          ..write('actualExerciseJson: $actualExerciseJson, ')
          ..write('performedOrdinal: $performedOrdinal, ')
          ..write('mode: $mode, ')
          ..write('comment: $comment, ')
          ..write('serverRev: $serverRev, ')
          ..write('localRev: $localRev, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSetsTable extends LocalSets
    with TableInfo<$LocalSetsTable, LocalSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _setPerformanceIdMeta = const VerificationMeta(
    'setPerformanceId',
  );
  @override
  late final GeneratedColumn<String> setPerformanceId = GeneratedColumn<String>(
    'set_performance_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workoutIdMeta = const VerificationMeta(
    'workoutId',
  );
  @override
  late final GeneratedColumn<String> workoutId = GeneratedColumn<String>(
    'workout_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_workouts (workout_id)',
    ),
  );
  static const VerificationMeta _exercisePerformanceIdMeta =
      const VerificationMeta('exercisePerformanceId');
  @override
  late final GeneratedColumn<String> exercisePerformanceId =
      GeneratedColumn<String>(
        'exercise_performance_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES local_exercises (exercise_performance_id)',
        ),
      );
  static const VerificationMeta _exercisePrescriptionIdMeta =
      const VerificationMeta('exercisePrescriptionId');
  @override
  late final GeneratedColumn<int> exercisePrescriptionId = GeneratedColumn<int>(
    'exercise_prescription_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prescribedSetIdMeta = const VerificationMeta(
    'prescribedSetId',
  );
  @override
  late final GeneratedColumn<int> prescribedSetId = GeneratedColumn<int>(
    'prescribed_set_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ordinalMeta = const VerificationMeta(
    'ordinal',
  );
  @override
  late final GeneratedColumn<int> ordinal = GeneratedColumn<int>(
    'ordinal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loadKgMeta = const VerificationMeta('loadKg');
  @override
  late final GeneratedColumn<double> loadKg = GeneratedColumn<double>(
    'load_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repetitionsMeta = const VerificationMeta(
    'repetitions',
  );
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
    'repetitions',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rirMeta = const VerificationMeta('rir');
  @override
  late final GeneratedColumn<int> rir = GeneratedColumn<int>(
    'rir',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heartRateBpmMeta = const VerificationMeta(
    'heartRateBpm',
  );
  @override
  late final GeneratedColumn<int> heartRateBpm = GeneratedColumn<int>(
    'heart_rate_bpm',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _performedAtMeta = const VerificationMeta(
    'performedAt',
  );
  @override
  late final GeneratedColumn<DateTime> performedAt = GeneratedColumn<DateTime>(
    'performed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverRevMeta = const VerificationMeta(
    'serverRev',
  );
  @override
  late final GeneratedColumn<int> serverRev = GeneratedColumn<int>(
    'server_rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _localRevMeta = const VerificationMeta(
    'localRev',
  );
  @override
  late final GeneratedColumn<int> localRev = GeneratedColumn<int>(
    'local_rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    setPerformanceId,
    workoutId,
    exercisePerformanceId,
    exercisePrescriptionId,
    prescribedSetId,
    ordinal,
    status,
    loadKg,
    repetitions,
    rir,
    comment,
    heartRateBpm,
    performedAt,
    serverRev,
    localRev,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('set_performance_id')) {
      context.handle(
        _setPerformanceIdMeta,
        setPerformanceId.isAcceptableOrUnknown(
          data['set_performance_id']!,
          _setPerformanceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_setPerformanceIdMeta);
    }
    if (data.containsKey('workout_id')) {
      context.handle(
        _workoutIdMeta,
        workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('exercise_performance_id')) {
      context.handle(
        _exercisePerformanceIdMeta,
        exercisePerformanceId.isAcceptableOrUnknown(
          data['exercise_performance_id']!,
          _exercisePerformanceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exercisePerformanceIdMeta);
    }
    if (data.containsKey('exercise_prescription_id')) {
      context.handle(
        _exercisePrescriptionIdMeta,
        exercisePrescriptionId.isAcceptableOrUnknown(
          data['exercise_prescription_id']!,
          _exercisePrescriptionIdMeta,
        ),
      );
    }
    if (data.containsKey('prescribed_set_id')) {
      context.handle(
        _prescribedSetIdMeta,
        prescribedSetId.isAcceptableOrUnknown(
          data['prescribed_set_id']!,
          _prescribedSetIdMeta,
        ),
      );
    }
    if (data.containsKey('ordinal')) {
      context.handle(
        _ordinalMeta,
        ordinal.isAcceptableOrUnknown(data['ordinal']!, _ordinalMeta),
      );
    } else if (isInserting) {
      context.missing(_ordinalMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('load_kg')) {
      context.handle(
        _loadKgMeta,
        loadKg.isAcceptableOrUnknown(data['load_kg']!, _loadKgMeta),
      );
    }
    if (data.containsKey('repetitions')) {
      context.handle(
        _repetitionsMeta,
        repetitions.isAcceptableOrUnknown(
          data['repetitions']!,
          _repetitionsMeta,
        ),
      );
    }
    if (data.containsKey('rir')) {
      context.handle(
        _rirMeta,
        rir.isAcceptableOrUnknown(data['rir']!, _rirMeta),
      );
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    }
    if (data.containsKey('heart_rate_bpm')) {
      context.handle(
        _heartRateBpmMeta,
        heartRateBpm.isAcceptableOrUnknown(
          data['heart_rate_bpm']!,
          _heartRateBpmMeta,
        ),
      );
    }
    if (data.containsKey('performed_at')) {
      context.handle(
        _performedAtMeta,
        performedAt.isAcceptableOrUnknown(
          data['performed_at']!,
          _performedAtMeta,
        ),
      );
    }
    if (data.containsKey('server_rev')) {
      context.handle(
        _serverRevMeta,
        serverRev.isAcceptableOrUnknown(data['server_rev']!, _serverRevMeta),
      );
    }
    if (data.containsKey('local_rev')) {
      context.handle(
        _localRevMeta,
        localRev.isAcceptableOrUnknown(data['local_rev']!, _localRevMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {setPerformanceId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {workoutId, exercisePerformanceId, ordinal},
  ];
  @override
  LocalSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSet(
      setPerformanceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}set_performance_id'],
      )!,
      workoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_id'],
      )!,
      exercisePerformanceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_performance_id'],
      )!,
      exercisePrescriptionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_prescription_id'],
      ),
      prescribedSetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prescribed_set_id'],
      ),
      ordinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordinal'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      loadKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}load_kg'],
      ),
      repetitions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetitions'],
      ),
      rir: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rir'],
      ),
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      ),
      heartRateBpm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}heart_rate_bpm'],
      ),
      performedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}performed_at'],
      ),
      serverRev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_rev'],
      )!,
      localRev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_rev'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalSetsTable createAlias(String alias) {
    return $LocalSetsTable(attachedDatabase, alias);
  }
}

class LocalSet extends DataClass implements Insertable<LocalSet> {
  final String setPerformanceId;
  final String workoutId;
  final String exercisePerformanceId;
  final int? exercisePrescriptionId;
  final int? prescribedSetId;
  final int ordinal;
  final String status;
  final double? loadKg;
  final int? repetitions;
  final int? rir;
  final String? comment;
  final int? heartRateBpm;
  final DateTime? performedAt;
  final int serverRev;
  final int localRev;
  final DateTime updatedAt;
  const LocalSet({
    required this.setPerformanceId,
    required this.workoutId,
    required this.exercisePerformanceId,
    this.exercisePrescriptionId,
    this.prescribedSetId,
    required this.ordinal,
    required this.status,
    this.loadKg,
    this.repetitions,
    this.rir,
    this.comment,
    this.heartRateBpm,
    this.performedAt,
    required this.serverRev,
    required this.localRev,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['set_performance_id'] = Variable<String>(setPerformanceId);
    map['workout_id'] = Variable<String>(workoutId);
    map['exercise_performance_id'] = Variable<String>(exercisePerformanceId);
    if (!nullToAbsent || exercisePrescriptionId != null) {
      map['exercise_prescription_id'] = Variable<int>(exercisePrescriptionId);
    }
    if (!nullToAbsent || prescribedSetId != null) {
      map['prescribed_set_id'] = Variable<int>(prescribedSetId);
    }
    map['ordinal'] = Variable<int>(ordinal);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || loadKg != null) {
      map['load_kg'] = Variable<double>(loadKg);
    }
    if (!nullToAbsent || repetitions != null) {
      map['repetitions'] = Variable<int>(repetitions);
    }
    if (!nullToAbsent || rir != null) {
      map['rir'] = Variable<int>(rir);
    }
    if (!nullToAbsent || comment != null) {
      map['comment'] = Variable<String>(comment);
    }
    if (!nullToAbsent || heartRateBpm != null) {
      map['heart_rate_bpm'] = Variable<int>(heartRateBpm);
    }
    if (!nullToAbsent || performedAt != null) {
      map['performed_at'] = Variable<DateTime>(performedAt);
    }
    map['server_rev'] = Variable<int>(serverRev);
    map['local_rev'] = Variable<int>(localRev);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalSetsCompanion toCompanion(bool nullToAbsent) {
    return LocalSetsCompanion(
      setPerformanceId: Value(setPerformanceId),
      workoutId: Value(workoutId),
      exercisePerformanceId: Value(exercisePerformanceId),
      exercisePrescriptionId: exercisePrescriptionId == null && nullToAbsent
          ? const Value.absent()
          : Value(exercisePrescriptionId),
      prescribedSetId: prescribedSetId == null && nullToAbsent
          ? const Value.absent()
          : Value(prescribedSetId),
      ordinal: Value(ordinal),
      status: Value(status),
      loadKg: loadKg == null && nullToAbsent
          ? const Value.absent()
          : Value(loadKg),
      repetitions: repetitions == null && nullToAbsent
          ? const Value.absent()
          : Value(repetitions),
      rir: rir == null && nullToAbsent ? const Value.absent() : Value(rir),
      comment: comment == null && nullToAbsent
          ? const Value.absent()
          : Value(comment),
      heartRateBpm: heartRateBpm == null && nullToAbsent
          ? const Value.absent()
          : Value(heartRateBpm),
      performedAt: performedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(performedAt),
      serverRev: Value(serverRev),
      localRev: Value(localRev),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSet(
      setPerformanceId: serializer.fromJson<String>(json['setPerformanceId']),
      workoutId: serializer.fromJson<String>(json['workoutId']),
      exercisePerformanceId: serializer.fromJson<String>(
        json['exercisePerformanceId'],
      ),
      exercisePrescriptionId: serializer.fromJson<int?>(
        json['exercisePrescriptionId'],
      ),
      prescribedSetId: serializer.fromJson<int?>(json['prescribedSetId']),
      ordinal: serializer.fromJson<int>(json['ordinal']),
      status: serializer.fromJson<String>(json['status']),
      loadKg: serializer.fromJson<double?>(json['loadKg']),
      repetitions: serializer.fromJson<int?>(json['repetitions']),
      rir: serializer.fromJson<int?>(json['rir']),
      comment: serializer.fromJson<String?>(json['comment']),
      heartRateBpm: serializer.fromJson<int?>(json['heartRateBpm']),
      performedAt: serializer.fromJson<DateTime?>(json['performedAt']),
      serverRev: serializer.fromJson<int>(json['serverRev']),
      localRev: serializer.fromJson<int>(json['localRev']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'setPerformanceId': serializer.toJson<String>(setPerformanceId),
      'workoutId': serializer.toJson<String>(workoutId),
      'exercisePerformanceId': serializer.toJson<String>(exercisePerformanceId),
      'exercisePrescriptionId': serializer.toJson<int?>(exercisePrescriptionId),
      'prescribedSetId': serializer.toJson<int?>(prescribedSetId),
      'ordinal': serializer.toJson<int>(ordinal),
      'status': serializer.toJson<String>(status),
      'loadKg': serializer.toJson<double?>(loadKg),
      'repetitions': serializer.toJson<int?>(repetitions),
      'rir': serializer.toJson<int?>(rir),
      'comment': serializer.toJson<String?>(comment),
      'heartRateBpm': serializer.toJson<int?>(heartRateBpm),
      'performedAt': serializer.toJson<DateTime?>(performedAt),
      'serverRev': serializer.toJson<int>(serverRev),
      'localRev': serializer.toJson<int>(localRev),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalSet copyWith({
    String? setPerformanceId,
    String? workoutId,
    String? exercisePerformanceId,
    Value<int?> exercisePrescriptionId = const Value.absent(),
    Value<int?> prescribedSetId = const Value.absent(),
    int? ordinal,
    String? status,
    Value<double?> loadKg = const Value.absent(),
    Value<int?> repetitions = const Value.absent(),
    Value<int?> rir = const Value.absent(),
    Value<String?> comment = const Value.absent(),
    Value<int?> heartRateBpm = const Value.absent(),
    Value<DateTime?> performedAt = const Value.absent(),
    int? serverRev,
    int? localRev,
    DateTime? updatedAt,
  }) => LocalSet(
    setPerformanceId: setPerformanceId ?? this.setPerformanceId,
    workoutId: workoutId ?? this.workoutId,
    exercisePerformanceId: exercisePerformanceId ?? this.exercisePerformanceId,
    exercisePrescriptionId: exercisePrescriptionId.present
        ? exercisePrescriptionId.value
        : this.exercisePrescriptionId,
    prescribedSetId: prescribedSetId.present
        ? prescribedSetId.value
        : this.prescribedSetId,
    ordinal: ordinal ?? this.ordinal,
    status: status ?? this.status,
    loadKg: loadKg.present ? loadKg.value : this.loadKg,
    repetitions: repetitions.present ? repetitions.value : this.repetitions,
    rir: rir.present ? rir.value : this.rir,
    comment: comment.present ? comment.value : this.comment,
    heartRateBpm: heartRateBpm.present ? heartRateBpm.value : this.heartRateBpm,
    performedAt: performedAt.present ? performedAt.value : this.performedAt,
    serverRev: serverRev ?? this.serverRev,
    localRev: localRev ?? this.localRev,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalSet copyWithCompanion(LocalSetsCompanion data) {
    return LocalSet(
      setPerformanceId: data.setPerformanceId.present
          ? data.setPerformanceId.value
          : this.setPerformanceId,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      exercisePerformanceId: data.exercisePerformanceId.present
          ? data.exercisePerformanceId.value
          : this.exercisePerformanceId,
      exercisePrescriptionId: data.exercisePrescriptionId.present
          ? data.exercisePrescriptionId.value
          : this.exercisePrescriptionId,
      prescribedSetId: data.prescribedSetId.present
          ? data.prescribedSetId.value
          : this.prescribedSetId,
      ordinal: data.ordinal.present ? data.ordinal.value : this.ordinal,
      status: data.status.present ? data.status.value : this.status,
      loadKg: data.loadKg.present ? data.loadKg.value : this.loadKg,
      repetitions: data.repetitions.present
          ? data.repetitions.value
          : this.repetitions,
      rir: data.rir.present ? data.rir.value : this.rir,
      comment: data.comment.present ? data.comment.value : this.comment,
      heartRateBpm: data.heartRateBpm.present
          ? data.heartRateBpm.value
          : this.heartRateBpm,
      performedAt: data.performedAt.present
          ? data.performedAt.value
          : this.performedAt,
      serverRev: data.serverRev.present ? data.serverRev.value : this.serverRev,
      localRev: data.localRev.present ? data.localRev.value : this.localRev,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSet(')
          ..write('setPerformanceId: $setPerformanceId, ')
          ..write('workoutId: $workoutId, ')
          ..write('exercisePerformanceId: $exercisePerformanceId, ')
          ..write('exercisePrescriptionId: $exercisePrescriptionId, ')
          ..write('prescribedSetId: $prescribedSetId, ')
          ..write('ordinal: $ordinal, ')
          ..write('status: $status, ')
          ..write('loadKg: $loadKg, ')
          ..write('repetitions: $repetitions, ')
          ..write('rir: $rir, ')
          ..write('comment: $comment, ')
          ..write('heartRateBpm: $heartRateBpm, ')
          ..write('performedAt: $performedAt, ')
          ..write('serverRev: $serverRev, ')
          ..write('localRev: $localRev, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    setPerformanceId,
    workoutId,
    exercisePerformanceId,
    exercisePrescriptionId,
    prescribedSetId,
    ordinal,
    status,
    loadKg,
    repetitions,
    rir,
    comment,
    heartRateBpm,
    performedAt,
    serverRev,
    localRev,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSet &&
          other.setPerformanceId == this.setPerformanceId &&
          other.workoutId == this.workoutId &&
          other.exercisePerformanceId == this.exercisePerformanceId &&
          other.exercisePrescriptionId == this.exercisePrescriptionId &&
          other.prescribedSetId == this.prescribedSetId &&
          other.ordinal == this.ordinal &&
          other.status == this.status &&
          other.loadKg == this.loadKg &&
          other.repetitions == this.repetitions &&
          other.rir == this.rir &&
          other.comment == this.comment &&
          other.heartRateBpm == this.heartRateBpm &&
          other.performedAt == this.performedAt &&
          other.serverRev == this.serverRev &&
          other.localRev == this.localRev &&
          other.updatedAt == this.updatedAt);
}

class LocalSetsCompanion extends UpdateCompanion<LocalSet> {
  final Value<String> setPerformanceId;
  final Value<String> workoutId;
  final Value<String> exercisePerformanceId;
  final Value<int?> exercisePrescriptionId;
  final Value<int?> prescribedSetId;
  final Value<int> ordinal;
  final Value<String> status;
  final Value<double?> loadKg;
  final Value<int?> repetitions;
  final Value<int?> rir;
  final Value<String?> comment;
  final Value<int?> heartRateBpm;
  final Value<DateTime?> performedAt;
  final Value<int> serverRev;
  final Value<int> localRev;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalSetsCompanion({
    this.setPerformanceId = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.exercisePerformanceId = const Value.absent(),
    this.exercisePrescriptionId = const Value.absent(),
    this.prescribedSetId = const Value.absent(),
    this.ordinal = const Value.absent(),
    this.status = const Value.absent(),
    this.loadKg = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.rir = const Value.absent(),
    this.comment = const Value.absent(),
    this.heartRateBpm = const Value.absent(),
    this.performedAt = const Value.absent(),
    this.serverRev = const Value.absent(),
    this.localRev = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSetsCompanion.insert({
    required String setPerformanceId,
    required String workoutId,
    required String exercisePerformanceId,
    this.exercisePrescriptionId = const Value.absent(),
    this.prescribedSetId = const Value.absent(),
    required int ordinal,
    required String status,
    this.loadKg = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.rir = const Value.absent(),
    this.comment = const Value.absent(),
    this.heartRateBpm = const Value.absent(),
    this.performedAt = const Value.absent(),
    this.serverRev = const Value.absent(),
    this.localRev = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : setPerformanceId = Value(setPerformanceId),
       workoutId = Value(workoutId),
       exercisePerformanceId = Value(exercisePerformanceId),
       ordinal = Value(ordinal),
       status = Value(status),
       updatedAt = Value(updatedAt);
  static Insertable<LocalSet> custom({
    Expression<String>? setPerformanceId,
    Expression<String>? workoutId,
    Expression<String>? exercisePerformanceId,
    Expression<int>? exercisePrescriptionId,
    Expression<int>? prescribedSetId,
    Expression<int>? ordinal,
    Expression<String>? status,
    Expression<double>? loadKg,
    Expression<int>? repetitions,
    Expression<int>? rir,
    Expression<String>? comment,
    Expression<int>? heartRateBpm,
    Expression<DateTime>? performedAt,
    Expression<int>? serverRev,
    Expression<int>? localRev,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (setPerformanceId != null) 'set_performance_id': setPerformanceId,
      if (workoutId != null) 'workout_id': workoutId,
      if (exercisePerformanceId != null)
        'exercise_performance_id': exercisePerformanceId,
      if (exercisePrescriptionId != null)
        'exercise_prescription_id': exercisePrescriptionId,
      if (prescribedSetId != null) 'prescribed_set_id': prescribedSetId,
      if (ordinal != null) 'ordinal': ordinal,
      if (status != null) 'status': status,
      if (loadKg != null) 'load_kg': loadKg,
      if (repetitions != null) 'repetitions': repetitions,
      if (rir != null) 'rir': rir,
      if (comment != null) 'comment': comment,
      if (heartRateBpm != null) 'heart_rate_bpm': heartRateBpm,
      if (performedAt != null) 'performed_at': performedAt,
      if (serverRev != null) 'server_rev': serverRev,
      if (localRev != null) 'local_rev': localRev,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSetsCompanion copyWith({
    Value<String>? setPerformanceId,
    Value<String>? workoutId,
    Value<String>? exercisePerformanceId,
    Value<int?>? exercisePrescriptionId,
    Value<int?>? prescribedSetId,
    Value<int>? ordinal,
    Value<String>? status,
    Value<double?>? loadKg,
    Value<int?>? repetitions,
    Value<int?>? rir,
    Value<String?>? comment,
    Value<int?>? heartRateBpm,
    Value<DateTime?>? performedAt,
    Value<int>? serverRev,
    Value<int>? localRev,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalSetsCompanion(
      setPerformanceId: setPerformanceId ?? this.setPerformanceId,
      workoutId: workoutId ?? this.workoutId,
      exercisePerformanceId:
          exercisePerformanceId ?? this.exercisePerformanceId,
      exercisePrescriptionId:
          exercisePrescriptionId ?? this.exercisePrescriptionId,
      prescribedSetId: prescribedSetId ?? this.prescribedSetId,
      ordinal: ordinal ?? this.ordinal,
      status: status ?? this.status,
      loadKg: loadKg ?? this.loadKg,
      repetitions: repetitions ?? this.repetitions,
      rir: rir ?? this.rir,
      comment: comment ?? this.comment,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      performedAt: performedAt ?? this.performedAt,
      serverRev: serverRev ?? this.serverRev,
      localRev: localRev ?? this.localRev,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (setPerformanceId.present) {
      map['set_performance_id'] = Variable<String>(setPerformanceId.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<String>(workoutId.value);
    }
    if (exercisePerformanceId.present) {
      map['exercise_performance_id'] = Variable<String>(
        exercisePerformanceId.value,
      );
    }
    if (exercisePrescriptionId.present) {
      map['exercise_prescription_id'] = Variable<int>(
        exercisePrescriptionId.value,
      );
    }
    if (prescribedSetId.present) {
      map['prescribed_set_id'] = Variable<int>(prescribedSetId.value);
    }
    if (ordinal.present) {
      map['ordinal'] = Variable<int>(ordinal.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (loadKg.present) {
      map['load_kg'] = Variable<double>(loadKg.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (rir.present) {
      map['rir'] = Variable<int>(rir.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (heartRateBpm.present) {
      map['heart_rate_bpm'] = Variable<int>(heartRateBpm.value);
    }
    if (performedAt.present) {
      map['performed_at'] = Variable<DateTime>(performedAt.value);
    }
    if (serverRev.present) {
      map['server_rev'] = Variable<int>(serverRev.value);
    }
    if (localRev.present) {
      map['local_rev'] = Variable<int>(localRev.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSetsCompanion(')
          ..write('setPerformanceId: $setPerformanceId, ')
          ..write('workoutId: $workoutId, ')
          ..write('exercisePerformanceId: $exercisePerformanceId, ')
          ..write('exercisePrescriptionId: $exercisePrescriptionId, ')
          ..write('prescribedSetId: $prescribedSetId, ')
          ..write('ordinal: $ordinal, ')
          ..write('status: $status, ')
          ..write('loadKg: $loadKg, ')
          ..write('repetitions: $repetitions, ')
          ..write('rir: $rir, ')
          ..write('comment: $comment, ')
          ..write('heartRateBpm: $heartRateBpm, ')
          ..write('performedAt: $performedAt, ')
          ..write('serverRev: $serverRev, ')
          ..write('localRev: $localRev, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingOperationsTable extends PendingOperations
    with TableInfo<$PendingOperationsTable, PendingOperation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _workoutIdMeta = const VerificationMeta(
    'workoutId',
  );
  @override
  late final GeneratedColumn<String> workoutId = GeneratedColumn<String>(
    'workout_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_workouts (workout_id)',
    ),
  );
  static const VerificationMeta _leaseEpochMeta = const VerificationMeta(
    'leaseEpoch',
  );
  @override
  late final GeneratedColumn<int> leaseEpoch = GeneratedColumn<int>(
    'lease_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opIdMeta = const VerificationMeta('opId');
  @override
  late final GeneratedColumn<String> opId = GeneratedColumn<String>(
    'op_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deliveryStateMeta = const VerificationMeta(
    'deliveryState',
  );
  @override
  late final GeneratedColumn<String> deliveryState = GeneratedColumn<String>(
    'delivery_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('queued'),
  );
  static const VerificationMeta _resultJsonMeta = const VerificationMeta(
    'resultJson',
  );
  @override
  late final GeneratedColumn<String> resultJson = GeneratedColumn<String>(
    'result_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorCodeMeta = const VerificationMeta(
    'errorCode',
  );
  @override
  late final GeneratedColumn<String> errorCode = GeneratedColumn<String>(
    'error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workoutId,
    leaseEpoch,
    seq,
    opId,
    type,
    dataJson,
    occurredAt,
    deliveryState,
    resultJson,
    errorCode,
    attempts,
    nextAttemptAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingOperation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('workout_id')) {
      context.handle(
        _workoutIdMeta,
        workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('lease_epoch')) {
      context.handle(
        _leaseEpochMeta,
        leaseEpoch.isAcceptableOrUnknown(data['lease_epoch']!, _leaseEpochMeta),
      );
    } else if (isInserting) {
      context.missing(_leaseEpochMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('op_id')) {
      context.handle(
        _opIdMeta,
        opId.isAcceptableOrUnknown(data['op_id']!, _opIdMeta),
      );
    } else if (isInserting) {
      context.missing(_opIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('delivery_state')) {
      context.handle(
        _deliveryStateMeta,
        deliveryState.isAcceptableOrUnknown(
          data['delivery_state']!,
          _deliveryStateMeta,
        ),
      );
    }
    if (data.containsKey('result_json')) {
      context.handle(
        _resultJsonMeta,
        resultJson.isAcceptableOrUnknown(data['result_json']!, _resultJsonMeta),
      );
    }
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {workoutId, leaseEpoch, seq},
  ];
  @override
  PendingOperation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingOperation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      workoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_id'],
      )!,
      leaseEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lease_epoch'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      opId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      deliveryState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_state'],
      )!,
      resultJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_json'],
      ),
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
    );
  }

  @override
  $PendingOperationsTable createAlias(String alias) {
    return $PendingOperationsTable(attachedDatabase, alias);
  }
}

class PendingOperation extends DataClass
    implements Insertable<PendingOperation> {
  final int id;
  final String workoutId;
  final int leaseEpoch;
  final int seq;
  final String opId;
  final String type;
  final String dataJson;
  final DateTime occurredAt;
  final String deliveryState;
  final String? resultJson;
  final String? errorCode;
  final int attempts;
  final DateTime? nextAttemptAt;
  const PendingOperation({
    required this.id,
    required this.workoutId,
    required this.leaseEpoch,
    required this.seq,
    required this.opId,
    required this.type,
    required this.dataJson,
    required this.occurredAt,
    required this.deliveryState,
    this.resultJson,
    this.errorCode,
    required this.attempts,
    this.nextAttemptAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['workout_id'] = Variable<String>(workoutId);
    map['lease_epoch'] = Variable<int>(leaseEpoch);
    map['seq'] = Variable<int>(seq);
    map['op_id'] = Variable<String>(opId);
    map['type'] = Variable<String>(type);
    map['data_json'] = Variable<String>(dataJson);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['delivery_state'] = Variable<String>(deliveryState);
    if (!nullToAbsent || resultJson != null) {
      map['result_json'] = Variable<String>(resultJson);
    }
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    return map;
  }

  PendingOperationsCompanion toCompanion(bool nullToAbsent) {
    return PendingOperationsCompanion(
      id: Value(id),
      workoutId: Value(workoutId),
      leaseEpoch: Value(leaseEpoch),
      seq: Value(seq),
      opId: Value(opId),
      type: Value(type),
      dataJson: Value(dataJson),
      occurredAt: Value(occurredAt),
      deliveryState: Value(deliveryState),
      resultJson: resultJson == null && nullToAbsent
          ? const Value.absent()
          : Value(resultJson),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
      attempts: Value(attempts),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
    );
  }

  factory PendingOperation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingOperation(
      id: serializer.fromJson<int>(json['id']),
      workoutId: serializer.fromJson<String>(json['workoutId']),
      leaseEpoch: serializer.fromJson<int>(json['leaseEpoch']),
      seq: serializer.fromJson<int>(json['seq']),
      opId: serializer.fromJson<String>(json['opId']),
      type: serializer.fromJson<String>(json['type']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      deliveryState: serializer.fromJson<String>(json['deliveryState']),
      resultJson: serializer.fromJson<String?>(json['resultJson']),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'workoutId': serializer.toJson<String>(workoutId),
      'leaseEpoch': serializer.toJson<int>(leaseEpoch),
      'seq': serializer.toJson<int>(seq),
      'opId': serializer.toJson<String>(opId),
      'type': serializer.toJson<String>(type),
      'dataJson': serializer.toJson<String>(dataJson),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'deliveryState': serializer.toJson<String>(deliveryState),
      'resultJson': serializer.toJson<String?>(resultJson),
      'errorCode': serializer.toJson<String?>(errorCode),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
    };
  }

  PendingOperation copyWith({
    int? id,
    String? workoutId,
    int? leaseEpoch,
    int? seq,
    String? opId,
    String? type,
    String? dataJson,
    DateTime? occurredAt,
    String? deliveryState,
    Value<String?> resultJson = const Value.absent(),
    Value<String?> errorCode = const Value.absent(),
    int? attempts,
    Value<DateTime?> nextAttemptAt = const Value.absent(),
  }) => PendingOperation(
    id: id ?? this.id,
    workoutId: workoutId ?? this.workoutId,
    leaseEpoch: leaseEpoch ?? this.leaseEpoch,
    seq: seq ?? this.seq,
    opId: opId ?? this.opId,
    type: type ?? this.type,
    dataJson: dataJson ?? this.dataJson,
    occurredAt: occurredAt ?? this.occurredAt,
    deliveryState: deliveryState ?? this.deliveryState,
    resultJson: resultJson.present ? resultJson.value : this.resultJson,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
  );
  PendingOperation copyWithCompanion(PendingOperationsCompanion data) {
    return PendingOperation(
      id: data.id.present ? data.id.value : this.id,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      leaseEpoch: data.leaseEpoch.present
          ? data.leaseEpoch.value
          : this.leaseEpoch,
      seq: data.seq.present ? data.seq.value : this.seq,
      opId: data.opId.present ? data.opId.value : this.opId,
      type: data.type.present ? data.type.value : this.type,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      deliveryState: data.deliveryState.present
          ? data.deliveryState.value
          : this.deliveryState,
      resultJson: data.resultJson.present
          ? data.resultJson.value
          : this.resultJson,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingOperation(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('leaseEpoch: $leaseEpoch, ')
          ..write('seq: $seq, ')
          ..write('opId: $opId, ')
          ..write('type: $type, ')
          ..write('dataJson: $dataJson, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('deliveryState: $deliveryState, ')
          ..write('resultJson: $resultJson, ')
          ..write('errorCode: $errorCode, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workoutId,
    leaseEpoch,
    seq,
    opId,
    type,
    dataJson,
    occurredAt,
    deliveryState,
    resultJson,
    errorCode,
    attempts,
    nextAttemptAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingOperation &&
          other.id == this.id &&
          other.workoutId == this.workoutId &&
          other.leaseEpoch == this.leaseEpoch &&
          other.seq == this.seq &&
          other.opId == this.opId &&
          other.type == this.type &&
          other.dataJson == this.dataJson &&
          other.occurredAt == this.occurredAt &&
          other.deliveryState == this.deliveryState &&
          other.resultJson == this.resultJson &&
          other.errorCode == this.errorCode &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt);
}

class PendingOperationsCompanion extends UpdateCompanion<PendingOperation> {
  final Value<int> id;
  final Value<String> workoutId;
  final Value<int> leaseEpoch;
  final Value<int> seq;
  final Value<String> opId;
  final Value<String> type;
  final Value<String> dataJson;
  final Value<DateTime> occurredAt;
  final Value<String> deliveryState;
  final Value<String?> resultJson;
  final Value<String?> errorCode;
  final Value<int> attempts;
  final Value<DateTime?> nextAttemptAt;
  const PendingOperationsCompanion({
    this.id = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.leaseEpoch = const Value.absent(),
    this.seq = const Value.absent(),
    this.opId = const Value.absent(),
    this.type = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.deliveryState = const Value.absent(),
    this.resultJson = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
  });
  PendingOperationsCompanion.insert({
    this.id = const Value.absent(),
    required String workoutId,
    required int leaseEpoch,
    required int seq,
    required String opId,
    required String type,
    required String dataJson,
    required DateTime occurredAt,
    this.deliveryState = const Value.absent(),
    this.resultJson = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
  }) : workoutId = Value(workoutId),
       leaseEpoch = Value(leaseEpoch),
       seq = Value(seq),
       opId = Value(opId),
       type = Value(type),
       dataJson = Value(dataJson),
       occurredAt = Value(occurredAt);
  static Insertable<PendingOperation> custom({
    Expression<int>? id,
    Expression<String>? workoutId,
    Expression<int>? leaseEpoch,
    Expression<int>? seq,
    Expression<String>? opId,
    Expression<String>? type,
    Expression<String>? dataJson,
    Expression<DateTime>? occurredAt,
    Expression<String>? deliveryState,
    Expression<String>? resultJson,
    Expression<String>? errorCode,
    Expression<int>? attempts,
    Expression<DateTime>? nextAttemptAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutId != null) 'workout_id': workoutId,
      if (leaseEpoch != null) 'lease_epoch': leaseEpoch,
      if (seq != null) 'seq': seq,
      if (opId != null) 'op_id': opId,
      if (type != null) 'type': type,
      if (dataJson != null) 'data_json': dataJson,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (deliveryState != null) 'delivery_state': deliveryState,
      if (resultJson != null) 'result_json': resultJson,
      if (errorCode != null) 'error_code': errorCode,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
    });
  }

  PendingOperationsCompanion copyWith({
    Value<int>? id,
    Value<String>? workoutId,
    Value<int>? leaseEpoch,
    Value<int>? seq,
    Value<String>? opId,
    Value<String>? type,
    Value<String>? dataJson,
    Value<DateTime>? occurredAt,
    Value<String>? deliveryState,
    Value<String?>? resultJson,
    Value<String?>? errorCode,
    Value<int>? attempts,
    Value<DateTime?>? nextAttemptAt,
  }) {
    return PendingOperationsCompanion(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      leaseEpoch: leaseEpoch ?? this.leaseEpoch,
      seq: seq ?? this.seq,
      opId: opId ?? this.opId,
      type: type ?? this.type,
      dataJson: dataJson ?? this.dataJson,
      occurredAt: occurredAt ?? this.occurredAt,
      deliveryState: deliveryState ?? this.deliveryState,
      resultJson: resultJson ?? this.resultJson,
      errorCode: errorCode ?? this.errorCode,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<String>(workoutId.value);
    }
    if (leaseEpoch.present) {
      map['lease_epoch'] = Variable<int>(leaseEpoch.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (opId.present) {
      map['op_id'] = Variable<String>(opId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (deliveryState.present) {
      map['delivery_state'] = Variable<String>(deliveryState.value);
    }
    if (resultJson.present) {
      map['result_json'] = Variable<String>(resultJson.value);
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingOperationsCompanion(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('leaseEpoch: $leaseEpoch, ')
          ..write('seq: $seq, ')
          ..write('opId: $opId, ')
          ..write('type: $type, ')
          ..write('dataJson: $dataJson, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('deliveryState: $deliveryState, ')
          ..write('resultJson: $resultJson, ')
          ..write('errorCode: $errorCode, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt')
          ..write(')'))
        .toString();
  }
}

class $AtlasWorkspacesTable extends AtlasWorkspaces
    with TableInfo<$AtlasWorkspacesTable, AtlasWorkspace> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AtlasWorkspacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _navigationJsonMeta = const VerificationMeta(
    'navigationJson',
  );
  @override
  late final GeneratedColumn<String> navigationJson = GeneratedColumn<String>(
    'navigation_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _scrollOffsetMeta = const VerificationMeta(
    'scrollOffset',
  );
  @override
  late final GeneratedColumn<double> scrollOffset = GeneratedColumn<double>(
    'scroll_offset',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isCurrentMeta = const VerificationMeta(
    'isCurrent',
  );
  @override
  late final GeneratedColumn<bool> isCurrent = GeneratedColumn<bool>(
    'is_current',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_current" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    workspaceId,
    kind,
    slug,
    title,
    navigationJson,
    scrollOffset,
    isCurrent,
    openedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'atlas_workspaces';
  @override
  VerificationContext validateIntegrity(
    Insertable<AtlasWorkspace> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('navigation_json')) {
      context.handle(
        _navigationJsonMeta,
        navigationJson.isAcceptableOrUnknown(
          data['navigation_json']!,
          _navigationJsonMeta,
        ),
      );
    }
    if (data.containsKey('scroll_offset')) {
      context.handle(
        _scrollOffsetMeta,
        scrollOffset.isAcceptableOrUnknown(
          data['scroll_offset']!,
          _scrollOffsetMeta,
        ),
      );
    }
    if (data.containsKey('is_current')) {
      context.handle(
        _isCurrentMeta,
        isCurrent.isAcceptableOrUnknown(data['is_current']!, _isCurrentMeta),
      );
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_openedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {workspaceId};
  @override
  AtlasWorkspace map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AtlasWorkspace(
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      navigationJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}navigation_json'],
      )!,
      scrollOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}scroll_offset'],
      )!,
      isCurrent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_current'],
      )!,
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AtlasWorkspacesTable createAlias(String alias) {
    return $AtlasWorkspacesTable(attachedDatabase, alias);
  }
}

class AtlasWorkspace extends DataClass implements Insertable<AtlasWorkspace> {
  final String workspaceId;
  final String kind;
  final String? slug;
  final String title;
  final String navigationJson;
  final double scrollOffset;
  final bool isCurrent;
  final DateTime openedAt;
  final DateTime updatedAt;
  const AtlasWorkspace({
    required this.workspaceId,
    required this.kind,
    this.slug,
    required this.title,
    required this.navigationJson,
    required this.scrollOffset,
    required this.isCurrent,
    required this.openedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['workspace_id'] = Variable<String>(workspaceId);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || slug != null) {
      map['slug'] = Variable<String>(slug);
    }
    map['title'] = Variable<String>(title);
    map['navigation_json'] = Variable<String>(navigationJson);
    map['scroll_offset'] = Variable<double>(scrollOffset);
    map['is_current'] = Variable<bool>(isCurrent);
    map['opened_at'] = Variable<DateTime>(openedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AtlasWorkspacesCompanion toCompanion(bool nullToAbsent) {
    return AtlasWorkspacesCompanion(
      workspaceId: Value(workspaceId),
      kind: Value(kind),
      slug: slug == null && nullToAbsent ? const Value.absent() : Value(slug),
      title: Value(title),
      navigationJson: Value(navigationJson),
      scrollOffset: Value(scrollOffset),
      isCurrent: Value(isCurrent),
      openedAt: Value(openedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AtlasWorkspace.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AtlasWorkspace(
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      kind: serializer.fromJson<String>(json['kind']),
      slug: serializer.fromJson<String?>(json['slug']),
      title: serializer.fromJson<String>(json['title']),
      navigationJson: serializer.fromJson<String>(json['navigationJson']),
      scrollOffset: serializer.fromJson<double>(json['scrollOffset']),
      isCurrent: serializer.fromJson<bool>(json['isCurrent']),
      openedAt: serializer.fromJson<DateTime>(json['openedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workspaceId': serializer.toJson<String>(workspaceId),
      'kind': serializer.toJson<String>(kind),
      'slug': serializer.toJson<String?>(slug),
      'title': serializer.toJson<String>(title),
      'navigationJson': serializer.toJson<String>(navigationJson),
      'scrollOffset': serializer.toJson<double>(scrollOffset),
      'isCurrent': serializer.toJson<bool>(isCurrent),
      'openedAt': serializer.toJson<DateTime>(openedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AtlasWorkspace copyWith({
    String? workspaceId,
    String? kind,
    Value<String?> slug = const Value.absent(),
    String? title,
    String? navigationJson,
    double? scrollOffset,
    bool? isCurrent,
    DateTime? openedAt,
    DateTime? updatedAt,
  }) => AtlasWorkspace(
    workspaceId: workspaceId ?? this.workspaceId,
    kind: kind ?? this.kind,
    slug: slug.present ? slug.value : this.slug,
    title: title ?? this.title,
    navigationJson: navigationJson ?? this.navigationJson,
    scrollOffset: scrollOffset ?? this.scrollOffset,
    isCurrent: isCurrent ?? this.isCurrent,
    openedAt: openedAt ?? this.openedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AtlasWorkspace copyWithCompanion(AtlasWorkspacesCompanion data) {
    return AtlasWorkspace(
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      kind: data.kind.present ? data.kind.value : this.kind,
      slug: data.slug.present ? data.slug.value : this.slug,
      title: data.title.present ? data.title.value : this.title,
      navigationJson: data.navigationJson.present
          ? data.navigationJson.value
          : this.navigationJson,
      scrollOffset: data.scrollOffset.present
          ? data.scrollOffset.value
          : this.scrollOffset,
      isCurrent: data.isCurrent.present ? data.isCurrent.value : this.isCurrent,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AtlasWorkspace(')
          ..write('workspaceId: $workspaceId, ')
          ..write('kind: $kind, ')
          ..write('slug: $slug, ')
          ..write('title: $title, ')
          ..write('navigationJson: $navigationJson, ')
          ..write('scrollOffset: $scrollOffset, ')
          ..write('isCurrent: $isCurrent, ')
          ..write('openedAt: $openedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    workspaceId,
    kind,
    slug,
    title,
    navigationJson,
    scrollOffset,
    isCurrent,
    openedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AtlasWorkspace &&
          other.workspaceId == this.workspaceId &&
          other.kind == this.kind &&
          other.slug == this.slug &&
          other.title == this.title &&
          other.navigationJson == this.navigationJson &&
          other.scrollOffset == this.scrollOffset &&
          other.isCurrent == this.isCurrent &&
          other.openedAt == this.openedAt &&
          other.updatedAt == this.updatedAt);
}

class AtlasWorkspacesCompanion extends UpdateCompanion<AtlasWorkspace> {
  final Value<String> workspaceId;
  final Value<String> kind;
  final Value<String?> slug;
  final Value<String> title;
  final Value<String> navigationJson;
  final Value<double> scrollOffset;
  final Value<bool> isCurrent;
  final Value<DateTime> openedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AtlasWorkspacesCompanion({
    this.workspaceId = const Value.absent(),
    this.kind = const Value.absent(),
    this.slug = const Value.absent(),
    this.title = const Value.absent(),
    this.navigationJson = const Value.absent(),
    this.scrollOffset = const Value.absent(),
    this.isCurrent = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AtlasWorkspacesCompanion.insert({
    required String workspaceId,
    required String kind,
    this.slug = const Value.absent(),
    required String title,
    this.navigationJson = const Value.absent(),
    this.scrollOffset = const Value.absent(),
    this.isCurrent = const Value.absent(),
    required DateTime openedAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : workspaceId = Value(workspaceId),
       kind = Value(kind),
       title = Value(title),
       openedAt = Value(openedAt),
       updatedAt = Value(updatedAt);
  static Insertable<AtlasWorkspace> custom({
    Expression<String>? workspaceId,
    Expression<String>? kind,
    Expression<String>? slug,
    Expression<String>? title,
    Expression<String>? navigationJson,
    Expression<double>? scrollOffset,
    Expression<bool>? isCurrent,
    Expression<DateTime>? openedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (kind != null) 'kind': kind,
      if (slug != null) 'slug': slug,
      if (title != null) 'title': title,
      if (navigationJson != null) 'navigation_json': navigationJson,
      if (scrollOffset != null) 'scroll_offset': scrollOffset,
      if (isCurrent != null) 'is_current': isCurrent,
      if (openedAt != null) 'opened_at': openedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AtlasWorkspacesCompanion copyWith({
    Value<String>? workspaceId,
    Value<String>? kind,
    Value<String?>? slug,
    Value<String>? title,
    Value<String>? navigationJson,
    Value<double>? scrollOffset,
    Value<bool>? isCurrent,
    Value<DateTime>? openedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AtlasWorkspacesCompanion(
      workspaceId: workspaceId ?? this.workspaceId,
      kind: kind ?? this.kind,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      navigationJson: navigationJson ?? this.navigationJson,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      isCurrent: isCurrent ?? this.isCurrent,
      openedAt: openedAt ?? this.openedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (navigationJson.present) {
      map['navigation_json'] = Variable<String>(navigationJson.value);
    }
    if (scrollOffset.present) {
      map['scroll_offset'] = Variable<double>(scrollOffset.value);
    }
    if (isCurrent.present) {
      map['is_current'] = Variable<bool>(isCurrent.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AtlasWorkspacesCompanion(')
          ..write('workspaceId: $workspaceId, ')
          ..write('kind: $kind, ')
          ..write('slug: $slug, ')
          ..write('title: $title, ')
          ..write('navigationJson: $navigationJson, ')
          ..write('scrollOffset: $scrollOffset, ')
          ..write('isCurrent: $isCurrent, ')
          ..write('openedAt: $openedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppKeyValuesTable appKeyValues = $AppKeyValuesTable(this);
  late final $CachedDocumentsTable cachedDocuments = $CachedDocumentsTable(
    this,
  );
  late final $LocalWorkoutsTable localWorkouts = $LocalWorkoutsTable(this);
  late final $LocalExercisesTable localExercises = $LocalExercisesTable(this);
  late final $LocalSetsTable localSets = $LocalSetsTable(this);
  late final $PendingOperationsTable pendingOperations =
      $PendingOperationsTable(this);
  late final $AtlasWorkspacesTable atlasWorkspaces = $AtlasWorkspacesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appKeyValues,
    cachedDocuments,
    localWorkouts,
    localExercises,
    localSets,
    pendingOperations,
    atlasWorkspaces,
  ];
}

typedef $$AppKeyValuesTableCreateCompanionBuilder =
    AppKeyValuesCompanion Function({
      required String key,
      required String value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AppKeyValuesTableUpdateCompanionBuilder =
    AppKeyValuesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AppKeyValuesTableFilterComposer
    extends Composer<_$AppDatabase, $AppKeyValuesTable> {
  $$AppKeyValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppKeyValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $AppKeyValuesTable> {
  $$AppKeyValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppKeyValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppKeyValuesTable> {
  $$AppKeyValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppKeyValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppKeyValuesTable,
          AppKeyValue,
          $$AppKeyValuesTableFilterComposer,
          $$AppKeyValuesTableOrderingComposer,
          $$AppKeyValuesTableAnnotationComposer,
          $$AppKeyValuesTableCreateCompanionBuilder,
          $$AppKeyValuesTableUpdateCompanionBuilder,
          (
            AppKeyValue,
            BaseReferences<_$AppDatabase, $AppKeyValuesTable, AppKeyValue>,
          ),
          AppKeyValue,
          PrefetchHooks Function()
        > {
  $$AppKeyValuesTableTableManager(_$AppDatabase db, $AppKeyValuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppKeyValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppKeyValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppKeyValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppKeyValuesCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppKeyValuesCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppKeyValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppKeyValuesTable,
      AppKeyValue,
      $$AppKeyValuesTableFilterComposer,
      $$AppKeyValuesTableOrderingComposer,
      $$AppKeyValuesTableAnnotationComposer,
      $$AppKeyValuesTableCreateCompanionBuilder,
      $$AppKeyValuesTableUpdateCompanionBuilder,
      (
        AppKeyValue,
        BaseReferences<_$AppDatabase, $AppKeyValuesTable, AppKeyValue>,
      ),
      AppKeyValue,
      PrefetchHooks Function()
    >;
typedef $$CachedDocumentsTableCreateCompanionBuilder =
    CachedDocumentsCompanion Function({
      required String cacheKey,
      Value<String?> etag,
      required String json,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedDocumentsTableUpdateCompanionBuilder =
    CachedDocumentsCompanion Function({
      Value<String> cacheKey,
      Value<String?> etag,
      Value<String> json,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedDocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedDocumentsTable> {
  $$CachedDocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedDocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedDocumentsTable> {
  $$CachedDocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedDocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedDocumentsTable> {
  $$CachedDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedDocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedDocumentsTable,
          CachedDocument,
          $$CachedDocumentsTableFilterComposer,
          $$CachedDocumentsTableOrderingComposer,
          $$CachedDocumentsTableAnnotationComposer,
          $$CachedDocumentsTableCreateCompanionBuilder,
          $$CachedDocumentsTableUpdateCompanionBuilder,
          (
            CachedDocument,
            BaseReferences<
              _$AppDatabase,
              $CachedDocumentsTable,
              CachedDocument
            >,
          ),
          CachedDocument,
          PrefetchHooks Function()
        > {
  $$CachedDocumentsTableTableManager(
    _$AppDatabase db,
    $CachedDocumentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedDocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedDocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedDocumentsCompanion(
                cacheKey: cacheKey,
                etag: etag,
                json: json,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                Value<String?> etag = const Value.absent(),
                required String json,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedDocumentsCompanion.insert(
                cacheKey: cacheKey,
                etag: etag,
                json: json,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedDocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedDocumentsTable,
      CachedDocument,
      $$CachedDocumentsTableFilterComposer,
      $$CachedDocumentsTableOrderingComposer,
      $$CachedDocumentsTableAnnotationComposer,
      $$CachedDocumentsTableCreateCompanionBuilder,
      $$CachedDocumentsTableUpdateCompanionBuilder,
      (
        CachedDocument,
        BaseReferences<_$AppDatabase, $CachedDocumentsTable, CachedDocument>,
      ),
      CachedDocument,
      PrefetchHooks Function()
    >;
typedef $$LocalWorkoutsTableCreateCompanionBuilder =
    LocalWorkoutsCompanion Function({
      required String workoutId,
      required int sessionId,
      Value<int?> planRunId,
      required String workoutUnitName,
      Value<String> lifecycle,
      required DateTime startedAt,
      Value<DateTime?> finishedAt,
      required String prescriptionJson,
      required String startPayloadJson,
      Value<String?> serverSnapshotJson,
      Value<String?> etag,
      Value<int> leaseEpoch,
      Value<int> appliedSeq,
      Value<int> nextSeq,
      Value<int> revision,
      Value<int> currentExercise,
      Value<int> currentSet,
      Value<String> cursorPhase,
      Value<DateTime?> restEndsAt,
      Value<int?> restDurationS,
      Value<String?> entryDraftJson,
      Value<String?> workoutComment,
      Value<String> syncState,
      Value<String?> syncErrorCode,
      Value<int> syncAttempts,
      Value<DateTime?> nextSyncAt,
      Value<String?> finalizePayloadJson,
      Value<DateTime?> finalizedAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LocalWorkoutsTableUpdateCompanionBuilder =
    LocalWorkoutsCompanion Function({
      Value<String> workoutId,
      Value<int> sessionId,
      Value<int?> planRunId,
      Value<String> workoutUnitName,
      Value<String> lifecycle,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      Value<String> prescriptionJson,
      Value<String> startPayloadJson,
      Value<String?> serverSnapshotJson,
      Value<String?> etag,
      Value<int> leaseEpoch,
      Value<int> appliedSeq,
      Value<int> nextSeq,
      Value<int> revision,
      Value<int> currentExercise,
      Value<int> currentSet,
      Value<String> cursorPhase,
      Value<DateTime?> restEndsAt,
      Value<int?> restDurationS,
      Value<String?> entryDraftJson,
      Value<String?> workoutComment,
      Value<String> syncState,
      Value<String?> syncErrorCode,
      Value<int> syncAttempts,
      Value<DateTime?> nextSyncAt,
      Value<String?> finalizePayloadJson,
      Value<DateTime?> finalizedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$LocalWorkoutsTableReferences
    extends BaseReferences<_$AppDatabase, $LocalWorkoutsTable, LocalWorkout> {
  $$LocalWorkoutsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$LocalExercisesTable, List<LocalExercise>>
  _localExercisesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.localExercises,
    aliasName: $_aliasNameGenerator(
      db.localWorkouts.workoutId,
      db.localExercises.workoutId,
    ),
  );

  $$LocalExercisesTableProcessedTableManager get localExercisesRefs {
    final manager = $$LocalExercisesTableTableManager($_db, $_db.localExercises)
        .filter(
          (f) => f.workoutId.workoutId.sqlEquals(
            $_itemColumn<String>('workout_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_localExercisesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LocalSetsTable, List<LocalSet>>
  _localSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.localSets,
    aliasName: $_aliasNameGenerator(
      db.localWorkouts.workoutId,
      db.localSets.workoutId,
    ),
  );

  $$LocalSetsTableProcessedTableManager get localSetsRefs {
    final manager = $$LocalSetsTableTableManager($_db, $_db.localSets).filter(
      (f) =>
          f.workoutId.workoutId.sqlEquals($_itemColumn<String>('workout_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_localSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PendingOperationsTable, List<PendingOperation>>
  _pendingOperationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.pendingOperations,
        aliasName: $_aliasNameGenerator(
          db.localWorkouts.workoutId,
          db.pendingOperations.workoutId,
        ),
      );

  $$PendingOperationsTableProcessedTableManager get pendingOperationsRefs {
    final manager =
        $$PendingOperationsTableTableManager(
          $_db,
          $_db.pendingOperations,
        ).filter(
          (f) => f.workoutId.workoutId.sqlEquals(
            $_itemColumn<String>('workout_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _pendingOperationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalWorkoutsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalWorkoutsTable> {
  $$LocalWorkoutsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get workoutId => $composableBuilder(
    column: $table.workoutId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get planRunId => $composableBuilder(
    column: $table.planRunId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workoutUnitName => $composableBuilder(
    column: $table.workoutUnitName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lifecycle => $composableBuilder(
    column: $table.lifecycle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prescriptionJson => $composableBuilder(
    column: $table.prescriptionJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startPayloadJson => $composableBuilder(
    column: $table.startPayloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverSnapshotJson => $composableBuilder(
    column: $table.serverSnapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get leaseEpoch => $composableBuilder(
    column: $table.leaseEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get appliedSeq => $composableBuilder(
    column: $table.appliedSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextSeq => $composableBuilder(
    column: $table.nextSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentExercise => $composableBuilder(
    column: $table.currentExercise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentSet => $composableBuilder(
    column: $table.currentSet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursorPhase => $composableBuilder(
    column: $table.cursorPhase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get restEndsAt => $composableBuilder(
    column: $table.restEndsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restDurationS => $composableBuilder(
    column: $table.restDurationS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryDraftJson => $composableBuilder(
    column: $table.entryDraftJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workoutComment => $composableBuilder(
    column: $table.workoutComment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncErrorCode => $composableBuilder(
    column: $table.syncErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextSyncAt => $composableBuilder(
    column: $table.nextSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finalizePayloadJson => $composableBuilder(
    column: $table.finalizePayloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finalizedAt => $composableBuilder(
    column: $table.finalizedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> localExercisesRefs(
    Expression<bool> Function($$LocalExercisesTableFilterComposer f) f,
  ) {
    final $$LocalExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.localExercises,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalExercisesTableFilterComposer(
            $db: $db,
            $table: $db.localExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> localSetsRefs(
    Expression<bool> Function($$LocalSetsTableFilterComposer f) f,
  ) {
    final $$LocalSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.localSets,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalSetsTableFilterComposer(
            $db: $db,
            $table: $db.localSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pendingOperationsRefs(
    Expression<bool> Function($$PendingOperationsTableFilterComposer f) f,
  ) {
    final $$PendingOperationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.pendingOperations,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingOperationsTableFilterComposer(
            $db: $db,
            $table: $db.pendingOperations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalWorkoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalWorkoutsTable> {
  $$LocalWorkoutsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get workoutId => $composableBuilder(
    column: $table.workoutId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get planRunId => $composableBuilder(
    column: $table.planRunId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workoutUnitName => $composableBuilder(
    column: $table.workoutUnitName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lifecycle => $composableBuilder(
    column: $table.lifecycle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prescriptionJson => $composableBuilder(
    column: $table.prescriptionJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startPayloadJson => $composableBuilder(
    column: $table.startPayloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverSnapshotJson => $composableBuilder(
    column: $table.serverSnapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get leaseEpoch => $composableBuilder(
    column: $table.leaseEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get appliedSeq => $composableBuilder(
    column: $table.appliedSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextSeq => $composableBuilder(
    column: $table.nextSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentExercise => $composableBuilder(
    column: $table.currentExercise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentSet => $composableBuilder(
    column: $table.currentSet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursorPhase => $composableBuilder(
    column: $table.cursorPhase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get restEndsAt => $composableBuilder(
    column: $table.restEndsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restDurationS => $composableBuilder(
    column: $table.restDurationS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryDraftJson => $composableBuilder(
    column: $table.entryDraftJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workoutComment => $composableBuilder(
    column: $table.workoutComment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncErrorCode => $composableBuilder(
    column: $table.syncErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextSyncAt => $composableBuilder(
    column: $table.nextSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finalizePayloadJson => $composableBuilder(
    column: $table.finalizePayloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finalizedAt => $composableBuilder(
    column: $table.finalizedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalWorkoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalWorkoutsTable> {
  $$LocalWorkoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get workoutId =>
      $composableBuilder(column: $table.workoutId, builder: (column) => column);

  GeneratedColumn<int> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get planRunId =>
      $composableBuilder(column: $table.planRunId, builder: (column) => column);

  GeneratedColumn<String> get workoutUnitName => $composableBuilder(
    column: $table.workoutUnitName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lifecycle =>
      $composableBuilder(column: $table.lifecycle, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get prescriptionJson => $composableBuilder(
    column: $table.prescriptionJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startPayloadJson => $composableBuilder(
    column: $table.startPayloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverSnapshotJson => $composableBuilder(
    column: $table.serverSnapshotJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<int> get leaseEpoch => $composableBuilder(
    column: $table.leaseEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<int> get appliedSeq => $composableBuilder(
    column: $table.appliedSeq,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nextSeq =>
      $composableBuilder(column: $table.nextSeq, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<int> get currentExercise => $composableBuilder(
    column: $table.currentExercise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentSet => $composableBuilder(
    column: $table.currentSet,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cursorPhase => $composableBuilder(
    column: $table.cursorPhase,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get restEndsAt => $composableBuilder(
    column: $table.restEndsAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get restDurationS => $composableBuilder(
    column: $table.restDurationS,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entryDraftJson => $composableBuilder(
    column: $table.entryDraftJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workoutComment => $composableBuilder(
    column: $table.workoutComment,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get syncErrorCode => $composableBuilder(
    column: $table.syncErrorCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextSyncAt => $composableBuilder(
    column: $table.nextSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get finalizePayloadJson => $composableBuilder(
    column: $table.finalizePayloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get finalizedAt => $composableBuilder(
    column: $table.finalizedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> localExercisesRefs<T extends Object>(
    Expression<T> Function($$LocalExercisesTableAnnotationComposer a) f,
  ) {
    final $$LocalExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.localExercises,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.localExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> localSetsRefs<T extends Object>(
    Expression<T> Function($$LocalSetsTableAnnotationComposer a) f,
  ) {
    final $$LocalSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.localSets,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.localSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pendingOperationsRefs<T extends Object>(
    Expression<T> Function($$PendingOperationsTableAnnotationComposer a) f,
  ) {
    final $$PendingOperationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.workoutId,
          referencedTable: $db.pendingOperations,
          getReferencedColumn: (t) => t.workoutId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PendingOperationsTableAnnotationComposer(
                $db: $db,
                $table: $db.pendingOperations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$LocalWorkoutsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalWorkoutsTable,
          LocalWorkout,
          $$LocalWorkoutsTableFilterComposer,
          $$LocalWorkoutsTableOrderingComposer,
          $$LocalWorkoutsTableAnnotationComposer,
          $$LocalWorkoutsTableCreateCompanionBuilder,
          $$LocalWorkoutsTableUpdateCompanionBuilder,
          (LocalWorkout, $$LocalWorkoutsTableReferences),
          LocalWorkout,
          PrefetchHooks Function({
            bool localExercisesRefs,
            bool localSetsRefs,
            bool pendingOperationsRefs,
          })
        > {
  $$LocalWorkoutsTableTableManager(_$AppDatabase db, $LocalWorkoutsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalWorkoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalWorkoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalWorkoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> workoutId = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<int?> planRunId = const Value.absent(),
                Value<String> workoutUnitName = const Value.absent(),
                Value<String> lifecycle = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<String> prescriptionJson = const Value.absent(),
                Value<String> startPayloadJson = const Value.absent(),
                Value<String?> serverSnapshotJson = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<int> leaseEpoch = const Value.absent(),
                Value<int> appliedSeq = const Value.absent(),
                Value<int> nextSeq = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> currentExercise = const Value.absent(),
                Value<int> currentSet = const Value.absent(),
                Value<String> cursorPhase = const Value.absent(),
                Value<DateTime?> restEndsAt = const Value.absent(),
                Value<int?> restDurationS = const Value.absent(),
                Value<String?> entryDraftJson = const Value.absent(),
                Value<String?> workoutComment = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<String?> syncErrorCode = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<DateTime?> nextSyncAt = const Value.absent(),
                Value<String?> finalizePayloadJson = const Value.absent(),
                Value<DateTime?> finalizedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalWorkoutsCompanion(
                workoutId: workoutId,
                sessionId: sessionId,
                planRunId: planRunId,
                workoutUnitName: workoutUnitName,
                lifecycle: lifecycle,
                startedAt: startedAt,
                finishedAt: finishedAt,
                prescriptionJson: prescriptionJson,
                startPayloadJson: startPayloadJson,
                serverSnapshotJson: serverSnapshotJson,
                etag: etag,
                leaseEpoch: leaseEpoch,
                appliedSeq: appliedSeq,
                nextSeq: nextSeq,
                revision: revision,
                currentExercise: currentExercise,
                currentSet: currentSet,
                cursorPhase: cursorPhase,
                restEndsAt: restEndsAt,
                restDurationS: restDurationS,
                entryDraftJson: entryDraftJson,
                workoutComment: workoutComment,
                syncState: syncState,
                syncErrorCode: syncErrorCode,
                syncAttempts: syncAttempts,
                nextSyncAt: nextSyncAt,
                finalizePayloadJson: finalizePayloadJson,
                finalizedAt: finalizedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String workoutId,
                required int sessionId,
                Value<int?> planRunId = const Value.absent(),
                required String workoutUnitName,
                Value<String> lifecycle = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> finishedAt = const Value.absent(),
                required String prescriptionJson,
                required String startPayloadJson,
                Value<String?> serverSnapshotJson = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<int> leaseEpoch = const Value.absent(),
                Value<int> appliedSeq = const Value.absent(),
                Value<int> nextSeq = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> currentExercise = const Value.absent(),
                Value<int> currentSet = const Value.absent(),
                Value<String> cursorPhase = const Value.absent(),
                Value<DateTime?> restEndsAt = const Value.absent(),
                Value<int?> restDurationS = const Value.absent(),
                Value<String?> entryDraftJson = const Value.absent(),
                Value<String?> workoutComment = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<String?> syncErrorCode = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<DateTime?> nextSyncAt = const Value.absent(),
                Value<String?> finalizePayloadJson = const Value.absent(),
                Value<DateTime?> finalizedAt = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalWorkoutsCompanion.insert(
                workoutId: workoutId,
                sessionId: sessionId,
                planRunId: planRunId,
                workoutUnitName: workoutUnitName,
                lifecycle: lifecycle,
                startedAt: startedAt,
                finishedAt: finishedAt,
                prescriptionJson: prescriptionJson,
                startPayloadJson: startPayloadJson,
                serverSnapshotJson: serverSnapshotJson,
                etag: etag,
                leaseEpoch: leaseEpoch,
                appliedSeq: appliedSeq,
                nextSeq: nextSeq,
                revision: revision,
                currentExercise: currentExercise,
                currentSet: currentSet,
                cursorPhase: cursorPhase,
                restEndsAt: restEndsAt,
                restDurationS: restDurationS,
                entryDraftJson: entryDraftJson,
                workoutComment: workoutComment,
                syncState: syncState,
                syncErrorCode: syncErrorCode,
                syncAttempts: syncAttempts,
                nextSyncAt: nextSyncAt,
                finalizePayloadJson: finalizePayloadJson,
                finalizedAt: finalizedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalWorkoutsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                localExercisesRefs = false,
                localSetsRefs = false,
                pendingOperationsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (localExercisesRefs) db.localExercises,
                    if (localSetsRefs) db.localSets,
                    if (pendingOperationsRefs) db.pendingOperations,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (localExercisesRefs)
                        await $_getPrefetchedData<
                          LocalWorkout,
                          $LocalWorkoutsTable,
                          LocalExercise
                        >(
                          currentTable: table,
                          referencedTable: $$LocalWorkoutsTableReferences
                              ._localExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalWorkoutsTableReferences(
                                db,
                                table,
                                p0,
                              ).localExercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workoutId == item.workoutId,
                              ),
                          typedResults: items,
                        ),
                      if (localSetsRefs)
                        await $_getPrefetchedData<
                          LocalWorkout,
                          $LocalWorkoutsTable,
                          LocalSet
                        >(
                          currentTable: table,
                          referencedTable: $$LocalWorkoutsTableReferences
                              ._localSetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalWorkoutsTableReferences(
                                db,
                                table,
                                p0,
                              ).localSetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workoutId == item.workoutId,
                              ),
                          typedResults: items,
                        ),
                      if (pendingOperationsRefs)
                        await $_getPrefetchedData<
                          LocalWorkout,
                          $LocalWorkoutsTable,
                          PendingOperation
                        >(
                          currentTable: table,
                          referencedTable: $$LocalWorkoutsTableReferences
                              ._pendingOperationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalWorkoutsTableReferences(
                                db,
                                table,
                                p0,
                              ).pendingOperationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workoutId == item.workoutId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LocalWorkoutsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalWorkoutsTable,
      LocalWorkout,
      $$LocalWorkoutsTableFilterComposer,
      $$LocalWorkoutsTableOrderingComposer,
      $$LocalWorkoutsTableAnnotationComposer,
      $$LocalWorkoutsTableCreateCompanionBuilder,
      $$LocalWorkoutsTableUpdateCompanionBuilder,
      (LocalWorkout, $$LocalWorkoutsTableReferences),
      LocalWorkout,
      PrefetchHooks Function({
        bool localExercisesRefs,
        bool localSetsRefs,
        bool pendingOperationsRefs,
      })
    >;
typedef $$LocalExercisesTableCreateCompanionBuilder =
    LocalExercisesCompanion Function({
      required String exercisePerformanceId,
      required String workoutId,
      Value<int?> exercisePrescriptionId,
      Value<int?> prescribedExerciseId,
      Value<int?> actualExerciseId,
      Value<String?> actualExerciseJson,
      required int performedOrdinal,
      Value<String> mode,
      Value<String?> comment,
      Value<int> serverRev,
      Value<int> localRev,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LocalExercisesTableUpdateCompanionBuilder =
    LocalExercisesCompanion Function({
      Value<String> exercisePerformanceId,
      Value<String> workoutId,
      Value<int?> exercisePrescriptionId,
      Value<int?> prescribedExerciseId,
      Value<int?> actualExerciseId,
      Value<String?> actualExerciseJson,
      Value<int> performedOrdinal,
      Value<String> mode,
      Value<String?> comment,
      Value<int> serverRev,
      Value<int> localRev,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$LocalExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $LocalExercisesTable, LocalExercise> {
  $$LocalExercisesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalWorkoutsTable _workoutIdTable(_$AppDatabase db) =>
      db.localWorkouts.createAlias(
        $_aliasNameGenerator(
          db.localExercises.workoutId,
          db.localWorkouts.workoutId,
        ),
      );

  $$LocalWorkoutsTableProcessedTableManager get workoutId {
    final $_column = $_itemColumn<String>('workout_id')!;

    final manager = $$LocalWorkoutsTableTableManager(
      $_db,
      $_db.localWorkouts,
    ).filter((f) => f.workoutId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LocalSetsTable, List<LocalSet>>
  _localSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.localSets,
    aliasName: $_aliasNameGenerator(
      db.localExercises.exercisePerformanceId,
      db.localSets.exercisePerformanceId,
    ),
  );

  $$LocalSetsTableProcessedTableManager get localSetsRefs {
    final manager = $$LocalSetsTableTableManager($_db, $_db.localSets).filter(
      (f) => f.exercisePerformanceId.exercisePerformanceId.sqlEquals(
        $_itemColumn<String>('exercise_performance_id')!,
      ),
    );

    final cache = $_typedResult.readTableOrNull(_localSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalExercisesTable> {
  $$LocalExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get exercisePerformanceId => $composableBuilder(
    column: $table.exercisePerformanceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exercisePrescriptionId => $composableBuilder(
    column: $table.exercisePrescriptionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prescribedExerciseId => $composableBuilder(
    column: $table.prescribedExerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualExerciseId => $composableBuilder(
    column: $table.actualExerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actualExerciseJson => $composableBuilder(
    column: $table.actualExerciseJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get performedOrdinal => $composableBuilder(
    column: $table.performedOrdinal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverRev => $composableBuilder(
    column: $table.serverRev,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localRev => $composableBuilder(
    column: $table.localRev,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalWorkoutsTableFilterComposer get workoutId {
    final $$LocalWorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.localWorkouts,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalWorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.localWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> localSetsRefs(
    Expression<bool> Function($$LocalSetsTableFilterComposer f) f,
  ) {
    final $$LocalSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exercisePerformanceId,
      referencedTable: $db.localSets,
      getReferencedColumn: (t) => t.exercisePerformanceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalSetsTableFilterComposer(
            $db: $db,
            $table: $db.localSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalExercisesTable> {
  $$LocalExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get exercisePerformanceId => $composableBuilder(
    column: $table.exercisePerformanceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exercisePrescriptionId => $composableBuilder(
    column: $table.exercisePrescriptionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prescribedExerciseId => $composableBuilder(
    column: $table.prescribedExerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualExerciseId => $composableBuilder(
    column: $table.actualExerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actualExerciseJson => $composableBuilder(
    column: $table.actualExerciseJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get performedOrdinal => $composableBuilder(
    column: $table.performedOrdinal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverRev => $composableBuilder(
    column: $table.serverRev,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localRev => $composableBuilder(
    column: $table.localRev,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalWorkoutsTableOrderingComposer get workoutId {
    final $$LocalWorkoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.localWorkouts,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalWorkoutsTableOrderingComposer(
            $db: $db,
            $table: $db.localWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalExercisesTable> {
  $$LocalExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get exercisePerformanceId => $composableBuilder(
    column: $table.exercisePerformanceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get exercisePrescriptionId => $composableBuilder(
    column: $table.exercisePrescriptionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get prescribedExerciseId => $composableBuilder(
    column: $table.prescribedExerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualExerciseId => $composableBuilder(
    column: $table.actualExerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actualExerciseJson => $composableBuilder(
    column: $table.actualExerciseJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get performedOrdinal => $composableBuilder(
    column: $table.performedOrdinal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  GeneratedColumn<int> get serverRev =>
      $composableBuilder(column: $table.serverRev, builder: (column) => column);

  GeneratedColumn<int> get localRev =>
      $composableBuilder(column: $table.localRev, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LocalWorkoutsTableAnnotationComposer get workoutId {
    final $$LocalWorkoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.localWorkouts,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalWorkoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.localWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> localSetsRefs<T extends Object>(
    Expression<T> Function($$LocalSetsTableAnnotationComposer a) f,
  ) {
    final $$LocalSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exercisePerformanceId,
      referencedTable: $db.localSets,
      getReferencedColumn: (t) => t.exercisePerformanceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.localSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalExercisesTable,
          LocalExercise,
          $$LocalExercisesTableFilterComposer,
          $$LocalExercisesTableOrderingComposer,
          $$LocalExercisesTableAnnotationComposer,
          $$LocalExercisesTableCreateCompanionBuilder,
          $$LocalExercisesTableUpdateCompanionBuilder,
          (LocalExercise, $$LocalExercisesTableReferences),
          LocalExercise,
          PrefetchHooks Function({bool workoutId, bool localSetsRefs})
        > {
  $$LocalExercisesTableTableManager(
    _$AppDatabase db,
    $LocalExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> exercisePerformanceId = const Value.absent(),
                Value<String> workoutId = const Value.absent(),
                Value<int?> exercisePrescriptionId = const Value.absent(),
                Value<int?> prescribedExerciseId = const Value.absent(),
                Value<int?> actualExerciseId = const Value.absent(),
                Value<String?> actualExerciseJson = const Value.absent(),
                Value<int> performedOrdinal = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                Value<int> serverRev = const Value.absent(),
                Value<int> localRev = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalExercisesCompanion(
                exercisePerformanceId: exercisePerformanceId,
                workoutId: workoutId,
                exercisePrescriptionId: exercisePrescriptionId,
                prescribedExerciseId: prescribedExerciseId,
                actualExerciseId: actualExerciseId,
                actualExerciseJson: actualExerciseJson,
                performedOrdinal: performedOrdinal,
                mode: mode,
                comment: comment,
                serverRev: serverRev,
                localRev: localRev,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String exercisePerformanceId,
                required String workoutId,
                Value<int?> exercisePrescriptionId = const Value.absent(),
                Value<int?> prescribedExerciseId = const Value.absent(),
                Value<int?> actualExerciseId = const Value.absent(),
                Value<String?> actualExerciseJson = const Value.absent(),
                required int performedOrdinal,
                Value<String> mode = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                Value<int> serverRev = const Value.absent(),
                Value<int> localRev = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalExercisesCompanion.insert(
                exercisePerformanceId: exercisePerformanceId,
                workoutId: workoutId,
                exercisePrescriptionId: exercisePrescriptionId,
                prescribedExerciseId: prescribedExerciseId,
                actualExerciseId: actualExerciseId,
                actualExerciseJson: actualExerciseJson,
                performedOrdinal: performedOrdinal,
                mode: mode,
                comment: comment,
                serverRev: serverRev,
                localRev: localRev,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workoutId = false, localSetsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (localSetsRefs) db.localSets],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workoutId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workoutId,
                                referencedTable: $$LocalExercisesTableReferences
                                    ._workoutIdTable(db),
                                referencedColumn:
                                    $$LocalExercisesTableReferences
                                        ._workoutIdTable(db)
                                        .workoutId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (localSetsRefs)
                    await $_getPrefetchedData<
                      LocalExercise,
                      $LocalExercisesTable,
                      LocalSet
                    >(
                      currentTable: table,
                      referencedTable: $$LocalExercisesTableReferences
                          ._localSetsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LocalExercisesTableReferences(
                            db,
                            table,
                            p0,
                          ).localSetsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) =>
                                e.exercisePerformanceId ==
                                item.exercisePerformanceId,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LocalExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalExercisesTable,
      LocalExercise,
      $$LocalExercisesTableFilterComposer,
      $$LocalExercisesTableOrderingComposer,
      $$LocalExercisesTableAnnotationComposer,
      $$LocalExercisesTableCreateCompanionBuilder,
      $$LocalExercisesTableUpdateCompanionBuilder,
      (LocalExercise, $$LocalExercisesTableReferences),
      LocalExercise,
      PrefetchHooks Function({bool workoutId, bool localSetsRefs})
    >;
typedef $$LocalSetsTableCreateCompanionBuilder =
    LocalSetsCompanion Function({
      required String setPerformanceId,
      required String workoutId,
      required String exercisePerformanceId,
      Value<int?> exercisePrescriptionId,
      Value<int?> prescribedSetId,
      required int ordinal,
      required String status,
      Value<double?> loadKg,
      Value<int?> repetitions,
      Value<int?> rir,
      Value<String?> comment,
      Value<int?> heartRateBpm,
      Value<DateTime?> performedAt,
      Value<int> serverRev,
      Value<int> localRev,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LocalSetsTableUpdateCompanionBuilder =
    LocalSetsCompanion Function({
      Value<String> setPerformanceId,
      Value<String> workoutId,
      Value<String> exercisePerformanceId,
      Value<int?> exercisePrescriptionId,
      Value<int?> prescribedSetId,
      Value<int> ordinal,
      Value<String> status,
      Value<double?> loadKg,
      Value<int?> repetitions,
      Value<int?> rir,
      Value<String?> comment,
      Value<int?> heartRateBpm,
      Value<DateTime?> performedAt,
      Value<int> serverRev,
      Value<int> localRev,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$LocalSetsTableReferences
    extends BaseReferences<_$AppDatabase, $LocalSetsTable, LocalSet> {
  $$LocalSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LocalWorkoutsTable _workoutIdTable(_$AppDatabase db) =>
      db.localWorkouts.createAlias(
        $_aliasNameGenerator(
          db.localSets.workoutId,
          db.localWorkouts.workoutId,
        ),
      );

  $$LocalWorkoutsTableProcessedTableManager get workoutId {
    final $_column = $_itemColumn<String>('workout_id')!;

    final manager = $$LocalWorkoutsTableTableManager(
      $_db,
      $_db.localWorkouts,
    ).filter((f) => f.workoutId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LocalExercisesTable _exercisePerformanceIdTable(_$AppDatabase db) =>
      db.localExercises.createAlias(
        $_aliasNameGenerator(
          db.localSets.exercisePerformanceId,
          db.localExercises.exercisePerformanceId,
        ),
      );

  $$LocalExercisesTableProcessedTableManager get exercisePerformanceId {
    final $_column = $_itemColumn<String>('exercise_performance_id')!;

    final manager = $$LocalExercisesTableTableManager(
      $_db,
      $_db.localExercises,
    ).filter((f) => f.exercisePerformanceId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _exercisePerformanceIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalSetsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSetsTable> {
  $$LocalSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get setPerformanceId => $composableBuilder(
    column: $table.setPerformanceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exercisePrescriptionId => $composableBuilder(
    column: $table.exercisePrescriptionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prescribedSetId => $composableBuilder(
    column: $table.prescribedSetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get loadKg => $composableBuilder(
    column: $table.loadKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rir => $composableBuilder(
    column: $table.rir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get heartRateBpm => $composableBuilder(
    column: $table.heartRateBpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get performedAt => $composableBuilder(
    column: $table.performedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverRev => $composableBuilder(
    column: $table.serverRev,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localRev => $composableBuilder(
    column: $table.localRev,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalWorkoutsTableFilterComposer get workoutId {
    final $$LocalWorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.localWorkouts,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalWorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.localWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LocalExercisesTableFilterComposer get exercisePerformanceId {
    final $$LocalExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exercisePerformanceId,
      referencedTable: $db.localExercises,
      getReferencedColumn: (t) => t.exercisePerformanceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalExercisesTableFilterComposer(
            $db: $db,
            $table: $db.localExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSetsTable> {
  $$LocalSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get setPerformanceId => $composableBuilder(
    column: $table.setPerformanceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exercisePrescriptionId => $composableBuilder(
    column: $table.exercisePrescriptionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prescribedSetId => $composableBuilder(
    column: $table.prescribedSetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get loadKg => $composableBuilder(
    column: $table.loadKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rir => $composableBuilder(
    column: $table.rir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get heartRateBpm => $composableBuilder(
    column: $table.heartRateBpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get performedAt => $composableBuilder(
    column: $table.performedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverRev => $composableBuilder(
    column: $table.serverRev,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localRev => $composableBuilder(
    column: $table.localRev,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalWorkoutsTableOrderingComposer get workoutId {
    final $$LocalWorkoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.localWorkouts,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalWorkoutsTableOrderingComposer(
            $db: $db,
            $table: $db.localWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LocalExercisesTableOrderingComposer get exercisePerformanceId {
    final $$LocalExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exercisePerformanceId,
      referencedTable: $db.localExercises,
      getReferencedColumn: (t) => t.exercisePerformanceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.localExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSetsTable> {
  $$LocalSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get setPerformanceId => $composableBuilder(
    column: $table.setPerformanceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get exercisePrescriptionId => $composableBuilder(
    column: $table.exercisePrescriptionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get prescribedSetId => $composableBuilder(
    column: $table.prescribedSetId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ordinal =>
      $composableBuilder(column: $table.ordinal, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get loadKg =>
      $composableBuilder(column: $table.loadKg, builder: (column) => column);

  GeneratedColumn<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rir =>
      $composableBuilder(column: $table.rir, builder: (column) => column);

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  GeneratedColumn<int> get heartRateBpm => $composableBuilder(
    column: $table.heartRateBpm,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get performedAt => $composableBuilder(
    column: $table.performedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverRev =>
      $composableBuilder(column: $table.serverRev, builder: (column) => column);

  GeneratedColumn<int> get localRev =>
      $composableBuilder(column: $table.localRev, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LocalWorkoutsTableAnnotationComposer get workoutId {
    final $$LocalWorkoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.localWorkouts,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalWorkoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.localWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LocalExercisesTableAnnotationComposer get exercisePerformanceId {
    final $$LocalExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exercisePerformanceId,
      referencedTable: $db.localExercises,
      getReferencedColumn: (t) => t.exercisePerformanceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.localExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSetsTable,
          LocalSet,
          $$LocalSetsTableFilterComposer,
          $$LocalSetsTableOrderingComposer,
          $$LocalSetsTableAnnotationComposer,
          $$LocalSetsTableCreateCompanionBuilder,
          $$LocalSetsTableUpdateCompanionBuilder,
          (LocalSet, $$LocalSetsTableReferences),
          LocalSet,
          PrefetchHooks Function({bool workoutId, bool exercisePerformanceId})
        > {
  $$LocalSetsTableTableManager(_$AppDatabase db, $LocalSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> setPerformanceId = const Value.absent(),
                Value<String> workoutId = const Value.absent(),
                Value<String> exercisePerformanceId = const Value.absent(),
                Value<int?> exercisePrescriptionId = const Value.absent(),
                Value<int?> prescribedSetId = const Value.absent(),
                Value<int> ordinal = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double?> loadKg = const Value.absent(),
                Value<int?> repetitions = const Value.absent(),
                Value<int?> rir = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                Value<int?> heartRateBpm = const Value.absent(),
                Value<DateTime?> performedAt = const Value.absent(),
                Value<int> serverRev = const Value.absent(),
                Value<int> localRev = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSetsCompanion(
                setPerformanceId: setPerformanceId,
                workoutId: workoutId,
                exercisePerformanceId: exercisePerformanceId,
                exercisePrescriptionId: exercisePrescriptionId,
                prescribedSetId: prescribedSetId,
                ordinal: ordinal,
                status: status,
                loadKg: loadKg,
                repetitions: repetitions,
                rir: rir,
                comment: comment,
                heartRateBpm: heartRateBpm,
                performedAt: performedAt,
                serverRev: serverRev,
                localRev: localRev,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String setPerformanceId,
                required String workoutId,
                required String exercisePerformanceId,
                Value<int?> exercisePrescriptionId = const Value.absent(),
                Value<int?> prescribedSetId = const Value.absent(),
                required int ordinal,
                required String status,
                Value<double?> loadKg = const Value.absent(),
                Value<int?> repetitions = const Value.absent(),
                Value<int?> rir = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                Value<int?> heartRateBpm = const Value.absent(),
                Value<DateTime?> performedAt = const Value.absent(),
                Value<int> serverRev = const Value.absent(),
                Value<int> localRev = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalSetsCompanion.insert(
                setPerformanceId: setPerformanceId,
                workoutId: workoutId,
                exercisePerformanceId: exercisePerformanceId,
                exercisePrescriptionId: exercisePrescriptionId,
                prescribedSetId: prescribedSetId,
                ordinal: ordinal,
                status: status,
                loadKg: loadKg,
                repetitions: repetitions,
                rir: rir,
                comment: comment,
                heartRateBpm: heartRateBpm,
                performedAt: performedAt,
                serverRev: serverRev,
                localRev: localRev,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalSetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({workoutId = false, exercisePerformanceId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (workoutId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workoutId,
                                    referencedTable: $$LocalSetsTableReferences
                                        ._workoutIdTable(db),
                                    referencedColumn: $$LocalSetsTableReferences
                                        ._workoutIdTable(db)
                                        .workoutId,
                                  )
                                  as T;
                        }
                        if (exercisePerformanceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.exercisePerformanceId,
                                    referencedTable: $$LocalSetsTableReferences
                                        ._exercisePerformanceIdTable(db),
                                    referencedColumn: $$LocalSetsTableReferences
                                        ._exercisePerformanceIdTable(db)
                                        .exercisePerformanceId,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$LocalSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSetsTable,
      LocalSet,
      $$LocalSetsTableFilterComposer,
      $$LocalSetsTableOrderingComposer,
      $$LocalSetsTableAnnotationComposer,
      $$LocalSetsTableCreateCompanionBuilder,
      $$LocalSetsTableUpdateCompanionBuilder,
      (LocalSet, $$LocalSetsTableReferences),
      LocalSet,
      PrefetchHooks Function({bool workoutId, bool exercisePerformanceId})
    >;
typedef $$PendingOperationsTableCreateCompanionBuilder =
    PendingOperationsCompanion Function({
      Value<int> id,
      required String workoutId,
      required int leaseEpoch,
      required int seq,
      required String opId,
      required String type,
      required String dataJson,
      required DateTime occurredAt,
      Value<String> deliveryState,
      Value<String?> resultJson,
      Value<String?> errorCode,
      Value<int> attempts,
      Value<DateTime?> nextAttemptAt,
    });
typedef $$PendingOperationsTableUpdateCompanionBuilder =
    PendingOperationsCompanion Function({
      Value<int> id,
      Value<String> workoutId,
      Value<int> leaseEpoch,
      Value<int> seq,
      Value<String> opId,
      Value<String> type,
      Value<String> dataJson,
      Value<DateTime> occurredAt,
      Value<String> deliveryState,
      Value<String?> resultJson,
      Value<String?> errorCode,
      Value<int> attempts,
      Value<DateTime?> nextAttemptAt,
    });

final class $$PendingOperationsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PendingOperationsTable,
          PendingOperation
        > {
  $$PendingOperationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalWorkoutsTable _workoutIdTable(_$AppDatabase db) =>
      db.localWorkouts.createAlias(
        $_aliasNameGenerator(
          db.pendingOperations.workoutId,
          db.localWorkouts.workoutId,
        ),
      );

  $$LocalWorkoutsTableProcessedTableManager get workoutId {
    final $_column = $_itemColumn<String>('workout_id')!;

    final manager = $$LocalWorkoutsTableTableManager(
      $_db,
      $_db.localWorkouts,
    ).filter((f) => f.workoutId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PendingOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get leaseEpoch => $composableBuilder(
    column: $table.leaseEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryState => $composableBuilder(
    column: $table.deliveryState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalWorkoutsTableFilterComposer get workoutId {
    final $$LocalWorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.localWorkouts,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalWorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.localWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get leaseEpoch => $composableBuilder(
    column: $table.leaseEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryState => $composableBuilder(
    column: $table.deliveryState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalWorkoutsTableOrderingComposer get workoutId {
    final $$LocalWorkoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.localWorkouts,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalWorkoutsTableOrderingComposer(
            $db: $db,
            $table: $db.localWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get leaseEpoch => $composableBuilder(
    column: $table.leaseEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get opId =>
      $composableBuilder(column: $table.opId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryState => $composableBuilder(
    column: $table.deliveryState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  $$LocalWorkoutsTableAnnotationComposer get workoutId {
    final $$LocalWorkoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.localWorkouts,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalWorkoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.localWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingOperationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingOperationsTable,
          PendingOperation,
          $$PendingOperationsTableFilterComposer,
          $$PendingOperationsTableOrderingComposer,
          $$PendingOperationsTableAnnotationComposer,
          $$PendingOperationsTableCreateCompanionBuilder,
          $$PendingOperationsTableUpdateCompanionBuilder,
          (PendingOperation, $$PendingOperationsTableReferences),
          PendingOperation,
          PrefetchHooks Function({bool workoutId})
        > {
  $$PendingOperationsTableTableManager(
    _$AppDatabase db,
    $PendingOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingOperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingOperationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> workoutId = const Value.absent(),
                Value<int> leaseEpoch = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> opId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String> deliveryState = const Value.absent(),
                Value<String?> resultJson = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
              }) => PendingOperationsCompanion(
                id: id,
                workoutId: workoutId,
                leaseEpoch: leaseEpoch,
                seq: seq,
                opId: opId,
                type: type,
                dataJson: dataJson,
                occurredAt: occurredAt,
                deliveryState: deliveryState,
                resultJson: resultJson,
                errorCode: errorCode,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String workoutId,
                required int leaseEpoch,
                required int seq,
                required String opId,
                required String type,
                required String dataJson,
                required DateTime occurredAt,
                Value<String> deliveryState = const Value.absent(),
                Value<String?> resultJson = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
              }) => PendingOperationsCompanion.insert(
                id: id,
                workoutId: workoutId,
                leaseEpoch: leaseEpoch,
                seq: seq,
                opId: opId,
                type: type,
                dataJson: dataJson,
                occurredAt: occurredAt,
                deliveryState: deliveryState,
                resultJson: resultJson,
                errorCode: errorCode,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PendingOperationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workoutId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workoutId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workoutId,
                                referencedTable:
                                    $$PendingOperationsTableReferences
                                        ._workoutIdTable(db),
                                referencedColumn:
                                    $$PendingOperationsTableReferences
                                        ._workoutIdTable(db)
                                        .workoutId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PendingOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingOperationsTable,
      PendingOperation,
      $$PendingOperationsTableFilterComposer,
      $$PendingOperationsTableOrderingComposer,
      $$PendingOperationsTableAnnotationComposer,
      $$PendingOperationsTableCreateCompanionBuilder,
      $$PendingOperationsTableUpdateCompanionBuilder,
      (PendingOperation, $$PendingOperationsTableReferences),
      PendingOperation,
      PrefetchHooks Function({bool workoutId})
    >;
typedef $$AtlasWorkspacesTableCreateCompanionBuilder =
    AtlasWorkspacesCompanion Function({
      required String workspaceId,
      required String kind,
      Value<String?> slug,
      required String title,
      Value<String> navigationJson,
      Value<double> scrollOffset,
      Value<bool> isCurrent,
      required DateTime openedAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AtlasWorkspacesTableUpdateCompanionBuilder =
    AtlasWorkspacesCompanion Function({
      Value<String> workspaceId,
      Value<String> kind,
      Value<String?> slug,
      Value<String> title,
      Value<String> navigationJson,
      Value<double> scrollOffset,
      Value<bool> isCurrent,
      Value<DateTime> openedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AtlasWorkspacesTableFilterComposer
    extends Composer<_$AppDatabase, $AtlasWorkspacesTable> {
  $$AtlasWorkspacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get navigationJson => $composableBuilder(
    column: $table.navigationJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get scrollOffset => $composableBuilder(
    column: $table.scrollOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCurrent => $composableBuilder(
    column: $table.isCurrent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AtlasWorkspacesTableOrderingComposer
    extends Composer<_$AppDatabase, $AtlasWorkspacesTable> {
  $$AtlasWorkspacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get navigationJson => $composableBuilder(
    column: $table.navigationJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get scrollOffset => $composableBuilder(
    column: $table.scrollOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCurrent => $composableBuilder(
    column: $table.isCurrent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AtlasWorkspacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AtlasWorkspacesTable> {
  $$AtlasWorkspacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get navigationJson => $composableBuilder(
    column: $table.navigationJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get scrollOffset => $composableBuilder(
    column: $table.scrollOffset,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCurrent =>
      $composableBuilder(column: $table.isCurrent, builder: (column) => column);

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AtlasWorkspacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AtlasWorkspacesTable,
          AtlasWorkspace,
          $$AtlasWorkspacesTableFilterComposer,
          $$AtlasWorkspacesTableOrderingComposer,
          $$AtlasWorkspacesTableAnnotationComposer,
          $$AtlasWorkspacesTableCreateCompanionBuilder,
          $$AtlasWorkspacesTableUpdateCompanionBuilder,
          (
            AtlasWorkspace,
            BaseReferences<
              _$AppDatabase,
              $AtlasWorkspacesTable,
              AtlasWorkspace
            >,
          ),
          AtlasWorkspace,
          PrefetchHooks Function()
        > {
  $$AtlasWorkspacesTableTableManager(
    _$AppDatabase db,
    $AtlasWorkspacesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AtlasWorkspacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AtlasWorkspacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AtlasWorkspacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> workspaceId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> slug = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> navigationJson = const Value.absent(),
                Value<double> scrollOffset = const Value.absent(),
                Value<bool> isCurrent = const Value.absent(),
                Value<DateTime> openedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AtlasWorkspacesCompanion(
                workspaceId: workspaceId,
                kind: kind,
                slug: slug,
                title: title,
                navigationJson: navigationJson,
                scrollOffset: scrollOffset,
                isCurrent: isCurrent,
                openedAt: openedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String workspaceId,
                required String kind,
                Value<String?> slug = const Value.absent(),
                required String title,
                Value<String> navigationJson = const Value.absent(),
                Value<double> scrollOffset = const Value.absent(),
                Value<bool> isCurrent = const Value.absent(),
                required DateTime openedAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AtlasWorkspacesCompanion.insert(
                workspaceId: workspaceId,
                kind: kind,
                slug: slug,
                title: title,
                navigationJson: navigationJson,
                scrollOffset: scrollOffset,
                isCurrent: isCurrent,
                openedAt: openedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AtlasWorkspacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AtlasWorkspacesTable,
      AtlasWorkspace,
      $$AtlasWorkspacesTableFilterComposer,
      $$AtlasWorkspacesTableOrderingComposer,
      $$AtlasWorkspacesTableAnnotationComposer,
      $$AtlasWorkspacesTableCreateCompanionBuilder,
      $$AtlasWorkspacesTableUpdateCompanionBuilder,
      (
        AtlasWorkspace,
        BaseReferences<_$AppDatabase, $AtlasWorkspacesTable, AtlasWorkspace>,
      ),
      AtlasWorkspace,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppKeyValuesTableTableManager get appKeyValues =>
      $$AppKeyValuesTableTableManager(_db, _db.appKeyValues);
  $$CachedDocumentsTableTableManager get cachedDocuments =>
      $$CachedDocumentsTableTableManager(_db, _db.cachedDocuments);
  $$LocalWorkoutsTableTableManager get localWorkouts =>
      $$LocalWorkoutsTableTableManager(_db, _db.localWorkouts);
  $$LocalExercisesTableTableManager get localExercises =>
      $$LocalExercisesTableTableManager(_db, _db.localExercises);
  $$LocalSetsTableTableManager get localSets =>
      $$LocalSetsTableTableManager(_db, _db.localSets);
  $$PendingOperationsTableTableManager get pendingOperations =>
      $$PendingOperationsTableTableManager(_db, _db.pendingOperations);
  $$AtlasWorkspacesTableTableManager get atlasWorkspaces =>
      $$AtlasWorkspacesTableTableManager(_db, _db.atlasWorkspaces);
}
