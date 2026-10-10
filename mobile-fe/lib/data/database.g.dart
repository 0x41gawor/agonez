// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
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
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
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
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _performanceJsonMeta = const VerificationMeta(
    'performanceJson',
  );
  @override
  late final GeneratedColumn<String> performanceJson = GeneratedColumn<String>(
    'performance_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<String> startedAt = GeneratedColumn<String>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending_start'),
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
  static const VerificationMeta _exerciseIndexMeta = const VerificationMeta(
    'exerciseIndex',
  );
  @override
  late final GeneratedColumn<int> exerciseIndex = GeneratedColumn<int>(
    'exercise_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _setIndexMeta = const VerificationMeta(
    'setIndex',
  );
  @override
  late final GeneratedColumn<int> setIndex = GeneratedColumn<int>(
    'set_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _restEndsAtMeta = const VerificationMeta(
    'restEndsAt',
  );
  @override
  late final GeneratedColumn<String> restEndsAt = GeneratedColumn<String>(
    'rest_ends_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finalizeJsonMeta = const VerificationMeta(
    'finalizeJson',
  );
  @override
  late final GeneratedColumn<String> finalizeJson = GeneratedColumn<String>(
    'finalize_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    name,
    prescriptionJson,
    performanceJson,
    startedAt,
    status,
    leaseEpoch,
    appliedSeq,
    nextSeq,
    exerciseIndex,
    setIndex,
    restEndsAt,
    finalizeJson,
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
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
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
    if (data.containsKey('performance_json')) {
      context.handle(
        _performanceJsonMeta,
        performanceJson.isAcceptableOrUnknown(
          data['performance_json']!,
          _performanceJsonMeta,
        ),
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
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
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
    if (data.containsKey('exercise_index')) {
      context.handle(
        _exerciseIndexMeta,
        exerciseIndex.isAcceptableOrUnknown(
          data['exercise_index']!,
          _exerciseIndexMeta,
        ),
      );
    }
    if (data.containsKey('set_index')) {
      context.handle(
        _setIndexMeta,
        setIndex.isAcceptableOrUnknown(data['set_index']!, _setIndexMeta),
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
    if (data.containsKey('finalize_json')) {
      context.handle(
        _finalizeJsonMeta,
        finalizeJson.isAcceptableOrUnknown(
          data['finalize_json']!,
          _finalizeJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalWorkout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalWorkout(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      prescriptionJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prescription_json'],
      )!,
      performanceJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}performance_json'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}started_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
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
      exerciseIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_index'],
      )!,
      setIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_index'],
      )!,
      restEndsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rest_ends_at'],
      ),
      finalizeJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}finalize_json'],
      ),
    );
  }

  @override
  $LocalWorkoutsTable createAlias(String alias) {
    return $LocalWorkoutsTable(attachedDatabase, alias);
  }
}

class LocalWorkout extends DataClass implements Insertable<LocalWorkout> {
  final String id;
  final int sessionId;
  final String name;
  final String prescriptionJson;
  final String performanceJson;
  final String startedAt;
  final String status;
  final int leaseEpoch;
  final int appliedSeq;
  final int nextSeq;
  final int exerciseIndex;
  final int setIndex;
  final String? restEndsAt;
  final String? finalizeJson;
  const LocalWorkout({
    required this.id,
    required this.sessionId,
    required this.name,
    required this.prescriptionJson,
    required this.performanceJson,
    required this.startedAt,
    required this.status,
    required this.leaseEpoch,
    required this.appliedSeq,
    required this.nextSeq,
    required this.exerciseIndex,
    required this.setIndex,
    this.restEndsAt,
    this.finalizeJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['name'] = Variable<String>(name);
    map['prescription_json'] = Variable<String>(prescriptionJson);
    map['performance_json'] = Variable<String>(performanceJson);
    map['started_at'] = Variable<String>(startedAt);
    map['status'] = Variable<String>(status);
    map['lease_epoch'] = Variable<int>(leaseEpoch);
    map['applied_seq'] = Variable<int>(appliedSeq);
    map['next_seq'] = Variable<int>(nextSeq);
    map['exercise_index'] = Variable<int>(exerciseIndex);
    map['set_index'] = Variable<int>(setIndex);
    if (!nullToAbsent || restEndsAt != null) {
      map['rest_ends_at'] = Variable<String>(restEndsAt);
    }
    if (!nullToAbsent || finalizeJson != null) {
      map['finalize_json'] = Variable<String>(finalizeJson);
    }
    return map;
  }

  LocalWorkoutsCompanion toCompanion(bool nullToAbsent) {
    return LocalWorkoutsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      name: Value(name),
      prescriptionJson: Value(prescriptionJson),
      performanceJson: Value(performanceJson),
      startedAt: Value(startedAt),
      status: Value(status),
      leaseEpoch: Value(leaseEpoch),
      appliedSeq: Value(appliedSeq),
      nextSeq: Value(nextSeq),
      exerciseIndex: Value(exerciseIndex),
      setIndex: Value(setIndex),
      restEndsAt: restEndsAt == null && nullToAbsent
          ? const Value.absent()
          : Value(restEndsAt),
      finalizeJson: finalizeJson == null && nullToAbsent
          ? const Value.absent()
          : Value(finalizeJson),
    );
  }

  factory LocalWorkout.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalWorkout(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      name: serializer.fromJson<String>(json['name']),
      prescriptionJson: serializer.fromJson<String>(json['prescriptionJson']),
      performanceJson: serializer.fromJson<String>(json['performanceJson']),
      startedAt: serializer.fromJson<String>(json['startedAt']),
      status: serializer.fromJson<String>(json['status']),
      leaseEpoch: serializer.fromJson<int>(json['leaseEpoch']),
      appliedSeq: serializer.fromJson<int>(json['appliedSeq']),
      nextSeq: serializer.fromJson<int>(json['nextSeq']),
      exerciseIndex: serializer.fromJson<int>(json['exerciseIndex']),
      setIndex: serializer.fromJson<int>(json['setIndex']),
      restEndsAt: serializer.fromJson<String?>(json['restEndsAt']),
      finalizeJson: serializer.fromJson<String?>(json['finalizeJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'name': serializer.toJson<String>(name),
      'prescriptionJson': serializer.toJson<String>(prescriptionJson),
      'performanceJson': serializer.toJson<String>(performanceJson),
      'startedAt': serializer.toJson<String>(startedAt),
      'status': serializer.toJson<String>(status),
      'leaseEpoch': serializer.toJson<int>(leaseEpoch),
      'appliedSeq': serializer.toJson<int>(appliedSeq),
      'nextSeq': serializer.toJson<int>(nextSeq),
      'exerciseIndex': serializer.toJson<int>(exerciseIndex),
      'setIndex': serializer.toJson<int>(setIndex),
      'restEndsAt': serializer.toJson<String?>(restEndsAt),
      'finalizeJson': serializer.toJson<String?>(finalizeJson),
    };
  }

  LocalWorkout copyWith({
    String? id,
    int? sessionId,
    String? name,
    String? prescriptionJson,
    String? performanceJson,
    String? startedAt,
    String? status,
    int? leaseEpoch,
    int? appliedSeq,
    int? nextSeq,
    int? exerciseIndex,
    int? setIndex,
    Value<String?> restEndsAt = const Value.absent(),
    Value<String?> finalizeJson = const Value.absent(),
  }) => LocalWorkout(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    name: name ?? this.name,
    prescriptionJson: prescriptionJson ?? this.prescriptionJson,
    performanceJson: performanceJson ?? this.performanceJson,
    startedAt: startedAt ?? this.startedAt,
    status: status ?? this.status,
    leaseEpoch: leaseEpoch ?? this.leaseEpoch,
    appliedSeq: appliedSeq ?? this.appliedSeq,
    nextSeq: nextSeq ?? this.nextSeq,
    exerciseIndex: exerciseIndex ?? this.exerciseIndex,
    setIndex: setIndex ?? this.setIndex,
    restEndsAt: restEndsAt.present ? restEndsAt.value : this.restEndsAt,
    finalizeJson: finalizeJson.present ? finalizeJson.value : this.finalizeJson,
  );
  LocalWorkout copyWithCompanion(LocalWorkoutsCompanion data) {
    return LocalWorkout(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      name: data.name.present ? data.name.value : this.name,
      prescriptionJson: data.prescriptionJson.present
          ? data.prescriptionJson.value
          : this.prescriptionJson,
      performanceJson: data.performanceJson.present
          ? data.performanceJson.value
          : this.performanceJson,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      status: data.status.present ? data.status.value : this.status,
      leaseEpoch: data.leaseEpoch.present
          ? data.leaseEpoch.value
          : this.leaseEpoch,
      appliedSeq: data.appliedSeq.present
          ? data.appliedSeq.value
          : this.appliedSeq,
      nextSeq: data.nextSeq.present ? data.nextSeq.value : this.nextSeq,
      exerciseIndex: data.exerciseIndex.present
          ? data.exerciseIndex.value
          : this.exerciseIndex,
      setIndex: data.setIndex.present ? data.setIndex.value : this.setIndex,
      restEndsAt: data.restEndsAt.present
          ? data.restEndsAt.value
          : this.restEndsAt,
      finalizeJson: data.finalizeJson.present
          ? data.finalizeJson.value
          : this.finalizeJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalWorkout(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('name: $name, ')
          ..write('prescriptionJson: $prescriptionJson, ')
          ..write('performanceJson: $performanceJson, ')
          ..write('startedAt: $startedAt, ')
          ..write('status: $status, ')
          ..write('leaseEpoch: $leaseEpoch, ')
          ..write('appliedSeq: $appliedSeq, ')
          ..write('nextSeq: $nextSeq, ')
          ..write('exerciseIndex: $exerciseIndex, ')
          ..write('setIndex: $setIndex, ')
          ..write('restEndsAt: $restEndsAt, ')
          ..write('finalizeJson: $finalizeJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    name,
    prescriptionJson,
    performanceJson,
    startedAt,
    status,
    leaseEpoch,
    appliedSeq,
    nextSeq,
    exerciseIndex,
    setIndex,
    restEndsAt,
    finalizeJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalWorkout &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.name == this.name &&
          other.prescriptionJson == this.prescriptionJson &&
          other.performanceJson == this.performanceJson &&
          other.startedAt == this.startedAt &&
          other.status == this.status &&
          other.leaseEpoch == this.leaseEpoch &&
          other.appliedSeq == this.appliedSeq &&
          other.nextSeq == this.nextSeq &&
          other.exerciseIndex == this.exerciseIndex &&
          other.setIndex == this.setIndex &&
          other.restEndsAt == this.restEndsAt &&
          other.finalizeJson == this.finalizeJson);
}

class LocalWorkoutsCompanion extends UpdateCompanion<LocalWorkout> {
  final Value<String> id;
  final Value<int> sessionId;
  final Value<String> name;
  final Value<String> prescriptionJson;
  final Value<String> performanceJson;
  final Value<String> startedAt;
  final Value<String> status;
  final Value<int> leaseEpoch;
  final Value<int> appliedSeq;
  final Value<int> nextSeq;
  final Value<int> exerciseIndex;
  final Value<int> setIndex;
  final Value<String?> restEndsAt;
  final Value<String?> finalizeJson;
  final Value<int> rowid;
  const LocalWorkoutsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.name = const Value.absent(),
    this.prescriptionJson = const Value.absent(),
    this.performanceJson = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.leaseEpoch = const Value.absent(),
    this.appliedSeq = const Value.absent(),
    this.nextSeq = const Value.absent(),
    this.exerciseIndex = const Value.absent(),
    this.setIndex = const Value.absent(),
    this.restEndsAt = const Value.absent(),
    this.finalizeJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalWorkoutsCompanion.insert({
    required String id,
    required int sessionId,
    required String name,
    required String prescriptionJson,
    this.performanceJson = const Value.absent(),
    required String startedAt,
    this.status = const Value.absent(),
    this.leaseEpoch = const Value.absent(),
    this.appliedSeq = const Value.absent(),
    this.nextSeq = const Value.absent(),
    this.exerciseIndex = const Value.absent(),
    this.setIndex = const Value.absent(),
    this.restEndsAt = const Value.absent(),
    this.finalizeJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       name = Value(name),
       prescriptionJson = Value(prescriptionJson),
       startedAt = Value(startedAt);
  static Insertable<LocalWorkout> custom({
    Expression<String>? id,
    Expression<int>? sessionId,
    Expression<String>? name,
    Expression<String>? prescriptionJson,
    Expression<String>? performanceJson,
    Expression<String>? startedAt,
    Expression<String>? status,
    Expression<int>? leaseEpoch,
    Expression<int>? appliedSeq,
    Expression<int>? nextSeq,
    Expression<int>? exerciseIndex,
    Expression<int>? setIndex,
    Expression<String>? restEndsAt,
    Expression<String>? finalizeJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (name != null) 'name': name,
      if (prescriptionJson != null) 'prescription_json': prescriptionJson,
      if (performanceJson != null) 'performance_json': performanceJson,
      if (startedAt != null) 'started_at': startedAt,
      if (status != null) 'status': status,
      if (leaseEpoch != null) 'lease_epoch': leaseEpoch,
      if (appliedSeq != null) 'applied_seq': appliedSeq,
      if (nextSeq != null) 'next_seq': nextSeq,
      if (exerciseIndex != null) 'exercise_index': exerciseIndex,
      if (setIndex != null) 'set_index': setIndex,
      if (restEndsAt != null) 'rest_ends_at': restEndsAt,
      if (finalizeJson != null) 'finalize_json': finalizeJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalWorkoutsCompanion copyWith({
    Value<String>? id,
    Value<int>? sessionId,
    Value<String>? name,
    Value<String>? prescriptionJson,
    Value<String>? performanceJson,
    Value<String>? startedAt,
    Value<String>? status,
    Value<int>? leaseEpoch,
    Value<int>? appliedSeq,
    Value<int>? nextSeq,
    Value<int>? exerciseIndex,
    Value<int>? setIndex,
    Value<String?>? restEndsAt,
    Value<String?>? finalizeJson,
    Value<int>? rowid,
  }) {
    return LocalWorkoutsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      name: name ?? this.name,
      prescriptionJson: prescriptionJson ?? this.prescriptionJson,
      performanceJson: performanceJson ?? this.performanceJson,
      startedAt: startedAt ?? this.startedAt,
      status: status ?? this.status,
      leaseEpoch: leaseEpoch ?? this.leaseEpoch,
      appliedSeq: appliedSeq ?? this.appliedSeq,
      nextSeq: nextSeq ?? this.nextSeq,
      exerciseIndex: exerciseIndex ?? this.exerciseIndex,
      setIndex: setIndex ?? this.setIndex,
      restEndsAt: restEndsAt ?? this.restEndsAt,
      finalizeJson: finalizeJson ?? this.finalizeJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (prescriptionJson.present) {
      map['prescription_json'] = Variable<String>(prescriptionJson.value);
    }
    if (performanceJson.present) {
      map['performance_json'] = Variable<String>(performanceJson.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<String>(startedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
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
    if (exerciseIndex.present) {
      map['exercise_index'] = Variable<int>(exerciseIndex.value);
    }
    if (setIndex.present) {
      map['set_index'] = Variable<int>(setIndex.value);
    }
    if (restEndsAt.present) {
      map['rest_ends_at'] = Variable<String>(restEndsAt.value);
    }
    if (finalizeJson.present) {
      map['finalize_json'] = Variable<String>(finalizeJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalWorkoutsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('name: $name, ')
          ..write('prescriptionJson: $prescriptionJson, ')
          ..write('performanceJson: $performanceJson, ')
          ..write('startedAt: $startedAt, ')
          ..write('status: $status, ')
          ..write('leaseEpoch: $leaseEpoch, ')
          ..write('appliedSeq: $appliedSeq, ')
          ..write('nextSeq: $nextSeq, ')
          ..write('exerciseIndex: $exerciseIndex, ')
          ..write('setIndex: $setIndex, ')
          ..write('restEndsAt: $restEndsAt, ')
          ..write('finalizeJson: $finalizeJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingOpsTable extends PendingOps
    with TableInfo<$PendingOpsTable, PendingOp> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingOpsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _opIdMeta = const VerificationMeta('opId');
  @override
  late final GeneratedColumn<String> opId = GeneratedColumn<String>(
    'op_id',
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
      'REFERENCES local_workouts (id)',
    ),
  );
  static const VerificationMeta _epochMeta = const VerificationMeta('epoch');
  @override
  late final GeneratedColumn<int> epoch = GeneratedColumn<int>(
    'epoch',
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<String> at = GeneratedColumn<String>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
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
  @override
  List<GeneratedColumn> get $columns => [
    opId,
    workoutId,
    epoch,
    seq,
    type,
    payloadJson,
    at,
    state,
    errorCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_ops';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingOp> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('op_id')) {
      context.handle(
        _opIdMeta,
        opId.isAcceptableOrUnknown(data['op_id']!, _opIdMeta),
      );
    } else if (isInserting) {
      context.missing(_opIdMeta);
    }
    if (data.containsKey('workout_id')) {
      context.handle(
        _workoutIdMeta,
        workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('epoch')) {
      context.handle(
        _epochMeta,
        epoch.isAcceptableOrUnknown(data['epoch']!, _epochMeta),
      );
    } else if (isInserting) {
      context.missing(_epochMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {opId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {workoutId, epoch, seq},
  ];
  @override
  PendingOp map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingOp(
      opId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_id'],
      )!,
      workoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_id'],
      )!,
      epoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}epoch'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}at'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
    );
  }

  @override
  $PendingOpsTable createAlias(String alias) {
    return $PendingOpsTable(attachedDatabase, alias);
  }
}

class PendingOp extends DataClass implements Insertable<PendingOp> {
  final String opId;
  final String workoutId;
  final int epoch;
  final int seq;
  final String type;
  final String payloadJson;
  final String at;
  final String state;
  final String? errorCode;
  const PendingOp({
    required this.opId,
    required this.workoutId,
    required this.epoch,
    required this.seq,
    required this.type,
    required this.payloadJson,
    required this.at,
    required this.state,
    this.errorCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['op_id'] = Variable<String>(opId);
    map['workout_id'] = Variable<String>(workoutId);
    map['epoch'] = Variable<int>(epoch);
    map['seq'] = Variable<int>(seq);
    map['type'] = Variable<String>(type);
    map['payload_json'] = Variable<String>(payloadJson);
    map['at'] = Variable<String>(at);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    return map;
  }

  PendingOpsCompanion toCompanion(bool nullToAbsent) {
    return PendingOpsCompanion(
      opId: Value(opId),
      workoutId: Value(workoutId),
      epoch: Value(epoch),
      seq: Value(seq),
      type: Value(type),
      payloadJson: Value(payloadJson),
      at: Value(at),
      state: Value(state),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
    );
  }

  factory PendingOp.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingOp(
      opId: serializer.fromJson<String>(json['opId']),
      workoutId: serializer.fromJson<String>(json['workoutId']),
      epoch: serializer.fromJson<int>(json['epoch']),
      seq: serializer.fromJson<int>(json['seq']),
      type: serializer.fromJson<String>(json['type']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      at: serializer.fromJson<String>(json['at']),
      state: serializer.fromJson<String>(json['state']),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'opId': serializer.toJson<String>(opId),
      'workoutId': serializer.toJson<String>(workoutId),
      'epoch': serializer.toJson<int>(epoch),
      'seq': serializer.toJson<int>(seq),
      'type': serializer.toJson<String>(type),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'at': serializer.toJson<String>(at),
      'state': serializer.toJson<String>(state),
      'errorCode': serializer.toJson<String?>(errorCode),
    };
  }

  PendingOp copyWith({
    String? opId,
    String? workoutId,
    int? epoch,
    int? seq,
    String? type,
    String? payloadJson,
    String? at,
    String? state,
    Value<String?> errorCode = const Value.absent(),
  }) => PendingOp(
    opId: opId ?? this.opId,
    workoutId: workoutId ?? this.workoutId,
    epoch: epoch ?? this.epoch,
    seq: seq ?? this.seq,
    type: type ?? this.type,
    payloadJson: payloadJson ?? this.payloadJson,
    at: at ?? this.at,
    state: state ?? this.state,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
  );
  PendingOp copyWithCompanion(PendingOpsCompanion data) {
    return PendingOp(
      opId: data.opId.present ? data.opId.value : this.opId,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      epoch: data.epoch.present ? data.epoch.value : this.epoch,
      seq: data.seq.present ? data.seq.value : this.seq,
      type: data.type.present ? data.type.value : this.type,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      at: data.at.present ? data.at.value : this.at,
      state: data.state.present ? data.state.value : this.state,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingOp(')
          ..write('opId: $opId, ')
          ..write('workoutId: $workoutId, ')
          ..write('epoch: $epoch, ')
          ..write('seq: $seq, ')
          ..write('type: $type, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('at: $at, ')
          ..write('state: $state, ')
          ..write('errorCode: $errorCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    opId,
    workoutId,
    epoch,
    seq,
    type,
    payloadJson,
    at,
    state,
    errorCode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingOp &&
          other.opId == this.opId &&
          other.workoutId == this.workoutId &&
          other.epoch == this.epoch &&
          other.seq == this.seq &&
          other.type == this.type &&
          other.payloadJson == this.payloadJson &&
          other.at == this.at &&
          other.state == this.state &&
          other.errorCode == this.errorCode);
}

class PendingOpsCompanion extends UpdateCompanion<PendingOp> {
  final Value<String> opId;
  final Value<String> workoutId;
  final Value<int> epoch;
  final Value<int> seq;
  final Value<String> type;
  final Value<String> payloadJson;
  final Value<String> at;
  final Value<String> state;
  final Value<String?> errorCode;
  final Value<int> rowid;
  const PendingOpsCompanion({
    this.opId = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.epoch = const Value.absent(),
    this.seq = const Value.absent(),
    this.type = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.at = const Value.absent(),
    this.state = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingOpsCompanion.insert({
    required String opId,
    required String workoutId,
    required int epoch,
    required int seq,
    required String type,
    required String payloadJson,
    required String at,
    this.state = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : opId = Value(opId),
       workoutId = Value(workoutId),
       epoch = Value(epoch),
       seq = Value(seq),
       type = Value(type),
       payloadJson = Value(payloadJson),
       at = Value(at);
  static Insertable<PendingOp> custom({
    Expression<String>? opId,
    Expression<String>? workoutId,
    Expression<int>? epoch,
    Expression<int>? seq,
    Expression<String>? type,
    Expression<String>? payloadJson,
    Expression<String>? at,
    Expression<String>? state,
    Expression<String>? errorCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (opId != null) 'op_id': opId,
      if (workoutId != null) 'workout_id': workoutId,
      if (epoch != null) 'epoch': epoch,
      if (seq != null) 'seq': seq,
      if (type != null) 'type': type,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (at != null) 'at': at,
      if (state != null) 'state': state,
      if (errorCode != null) 'error_code': errorCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingOpsCompanion copyWith({
    Value<String>? opId,
    Value<String>? workoutId,
    Value<int>? epoch,
    Value<int>? seq,
    Value<String>? type,
    Value<String>? payloadJson,
    Value<String>? at,
    Value<String>? state,
    Value<String?>? errorCode,
    Value<int>? rowid,
  }) {
    return PendingOpsCompanion(
      opId: opId ?? this.opId,
      workoutId: workoutId ?? this.workoutId,
      epoch: epoch ?? this.epoch,
      seq: seq ?? this.seq,
      type: type ?? this.type,
      payloadJson: payloadJson ?? this.payloadJson,
      at: at ?? this.at,
      state: state ?? this.state,
      errorCode: errorCode ?? this.errorCode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (opId.present) {
      map['op_id'] = Variable<String>(opId.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<String>(workoutId.value);
    }
    if (epoch.present) {
      map['epoch'] = Variable<int>(epoch.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (at.present) {
      map['at'] = Variable<String>(at.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingOpsCompanion(')
          ..write('opId: $opId, ')
          ..write('workoutId: $workoutId, ')
          ..write('epoch: $epoch, ')
          ..write('seq: $seq, ')
          ..write('type: $type, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('at: $at, ')
          ..write('state: $state, ')
          ..write('errorCode: $errorCode, ')
          ..write('rowid: $rowid')
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
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    slug,
    title,
    exerciseId,
    position,
    scrollOffset,
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
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {slug};
  @override
  AtlasWorkspace map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AtlasWorkspace(
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      scrollOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}scroll_offset'],
      )!,
    );
  }

  @override
  $AtlasWorkspacesTable createAlias(String alias) {
    return $AtlasWorkspacesTable(attachedDatabase, alias);
  }
}

class AtlasWorkspace extends DataClass implements Insertable<AtlasWorkspace> {
  final String slug;
  final String title;
  final int exerciseId;
  final int position;
  final double scrollOffset;
  const AtlasWorkspace({
    required this.slug,
    required this.title,
    required this.exerciseId,
    required this.position,
    required this.scrollOffset,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['slug'] = Variable<String>(slug);
    map['title'] = Variable<String>(title);
    map['exercise_id'] = Variable<int>(exerciseId);
    map['position'] = Variable<int>(position);
    map['scroll_offset'] = Variable<double>(scrollOffset);
    return map;
  }

  AtlasWorkspacesCompanion toCompanion(bool nullToAbsent) {
    return AtlasWorkspacesCompanion(
      slug: Value(slug),
      title: Value(title),
      exerciseId: Value(exerciseId),
      position: Value(position),
      scrollOffset: Value(scrollOffset),
    );
  }

  factory AtlasWorkspace.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AtlasWorkspace(
      slug: serializer.fromJson<String>(json['slug']),
      title: serializer.fromJson<String>(json['title']),
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      position: serializer.fromJson<int>(json['position']),
      scrollOffset: serializer.fromJson<double>(json['scrollOffset']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'slug': serializer.toJson<String>(slug),
      'title': serializer.toJson<String>(title),
      'exerciseId': serializer.toJson<int>(exerciseId),
      'position': serializer.toJson<int>(position),
      'scrollOffset': serializer.toJson<double>(scrollOffset),
    };
  }

  AtlasWorkspace copyWith({
    String? slug,
    String? title,
    int? exerciseId,
    int? position,
    double? scrollOffset,
  }) => AtlasWorkspace(
    slug: slug ?? this.slug,
    title: title ?? this.title,
    exerciseId: exerciseId ?? this.exerciseId,
    position: position ?? this.position,
    scrollOffset: scrollOffset ?? this.scrollOffset,
  );
  AtlasWorkspace copyWithCompanion(AtlasWorkspacesCompanion data) {
    return AtlasWorkspace(
      slug: data.slug.present ? data.slug.value : this.slug,
      title: data.title.present ? data.title.value : this.title,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      position: data.position.present ? data.position.value : this.position,
      scrollOffset: data.scrollOffset.present
          ? data.scrollOffset.value
          : this.scrollOffset,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AtlasWorkspace(')
          ..write('slug: $slug, ')
          ..write('title: $title, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('scrollOffset: $scrollOffset')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(slug, title, exerciseId, position, scrollOffset);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AtlasWorkspace &&
          other.slug == this.slug &&
          other.title == this.title &&
          other.exerciseId == this.exerciseId &&
          other.position == this.position &&
          other.scrollOffset == this.scrollOffset);
}

class AtlasWorkspacesCompanion extends UpdateCompanion<AtlasWorkspace> {
  final Value<String> slug;
  final Value<String> title;
  final Value<int> exerciseId;
  final Value<int> position;
  final Value<double> scrollOffset;
  final Value<int> rowid;
  const AtlasWorkspacesCompanion({
    this.slug = const Value.absent(),
    this.title = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.position = const Value.absent(),
    this.scrollOffset = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AtlasWorkspacesCompanion.insert({
    required String slug,
    required String title,
    required int exerciseId,
    required int position,
    this.scrollOffset = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : slug = Value(slug),
       title = Value(title),
       exerciseId = Value(exerciseId),
       position = Value(position);
  static Insertable<AtlasWorkspace> custom({
    Expression<String>? slug,
    Expression<String>? title,
    Expression<int>? exerciseId,
    Expression<int>? position,
    Expression<double>? scrollOffset,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (slug != null) 'slug': slug,
      if (title != null) 'title': title,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (position != null) 'position': position,
      if (scrollOffset != null) 'scroll_offset': scrollOffset,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AtlasWorkspacesCompanion copyWith({
    Value<String>? slug,
    Value<String>? title,
    Value<int>? exerciseId,
    Value<int>? position,
    Value<double>? scrollOffset,
    Value<int>? rowid,
  }) {
    return AtlasWorkspacesCompanion(
      slug: slug ?? this.slug,
      title: title ?? this.title,
      exerciseId: exerciseId ?? this.exerciseId,
      position: position ?? this.position,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (scrollOffset.present) {
      map['scroll_offset'] = Variable<double>(scrollOffset.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AtlasWorkspacesCompanion(')
          ..write('slug: $slug, ')
          ..write('title: $title, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('scrollOffset: $scrollOffset, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $LocalWorkoutsTable localWorkouts = $LocalWorkoutsTable(this);
  late final $PendingOpsTable pendingOps = $PendingOpsTable(this);
  late final $AtlasWorkspacesTable atlasWorkspaces = $AtlasWorkspacesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settings,
    localWorkouts,
    pendingOps,
    atlasWorkspaces,
  ];
}

typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
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
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
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
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
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
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$LocalWorkoutsTableCreateCompanionBuilder =
    LocalWorkoutsCompanion Function({
      required String id,
      required int sessionId,
      required String name,
      required String prescriptionJson,
      Value<String> performanceJson,
      required String startedAt,
      Value<String> status,
      Value<int> leaseEpoch,
      Value<int> appliedSeq,
      Value<int> nextSeq,
      Value<int> exerciseIndex,
      Value<int> setIndex,
      Value<String?> restEndsAt,
      Value<String?> finalizeJson,
      Value<int> rowid,
    });
typedef $$LocalWorkoutsTableUpdateCompanionBuilder =
    LocalWorkoutsCompanion Function({
      Value<String> id,
      Value<int> sessionId,
      Value<String> name,
      Value<String> prescriptionJson,
      Value<String> performanceJson,
      Value<String> startedAt,
      Value<String> status,
      Value<int> leaseEpoch,
      Value<int> appliedSeq,
      Value<int> nextSeq,
      Value<int> exerciseIndex,
      Value<int> setIndex,
      Value<String?> restEndsAt,
      Value<String?> finalizeJson,
      Value<int> rowid,
    });

final class $$LocalWorkoutsTableReferences
    extends BaseReferences<_$AppDatabase, $LocalWorkoutsTable, LocalWorkout> {
  $$LocalWorkoutsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$PendingOpsTable, List<PendingOp>>
  _pendingOpsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pendingOps,
    aliasName: $_aliasNameGenerator(
      db.localWorkouts.id,
      db.pendingOps.workoutId,
    ),
  );

  $$PendingOpsTableProcessedTableManager get pendingOpsRefs {
    final manager = $$PendingOpsTableTableManager(
      $_db,
      $_db.pendingOps,
    ).filter((f) => f.workoutId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_pendingOpsRefsTable($_db));
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
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prescriptionJson => $composableBuilder(
    column: $table.prescriptionJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get performanceJson => $composableBuilder(
    column: $table.performanceJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
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

  ColumnFilters<int> get exerciseIndex => $composableBuilder(
    column: $table.exerciseIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get restEndsAt => $composableBuilder(
    column: $table.restEndsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finalizeJson => $composableBuilder(
    column: $table.finalizeJson,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> pendingOpsRefs(
    Expression<bool> Function($$PendingOpsTableFilterComposer f) f,
  ) {
    final $$PendingOpsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pendingOps,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingOpsTableFilterComposer(
            $db: $db,
            $table: $db.pendingOps,
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
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prescriptionJson => $composableBuilder(
    column: $table.prescriptionJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get performanceJson => $composableBuilder(
    column: $table.performanceJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
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

  ColumnOrderings<int> get exerciseIndex => $composableBuilder(
    column: $table.exerciseIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get restEndsAt => $composableBuilder(
    column: $table.restEndsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finalizeJson => $composableBuilder(
    column: $table.finalizeJson,
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
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get prescriptionJson => $composableBuilder(
    column: $table.prescriptionJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get performanceJson => $composableBuilder(
    column: $table.performanceJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

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

  GeneratedColumn<int> get exerciseIndex => $composableBuilder(
    column: $table.exerciseIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get setIndex =>
      $composableBuilder(column: $table.setIndex, builder: (column) => column);

  GeneratedColumn<String> get restEndsAt => $composableBuilder(
    column: $table.restEndsAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get finalizeJson => $composableBuilder(
    column: $table.finalizeJson,
    builder: (column) => column,
  );

  Expression<T> pendingOpsRefs<T extends Object>(
    Expression<T> Function($$PendingOpsTableAnnotationComposer a) f,
  ) {
    final $$PendingOpsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pendingOps,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingOpsTableAnnotationComposer(
            $db: $db,
            $table: $db.pendingOps,
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
          PrefetchHooks Function({bool pendingOpsRefs})
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
                Value<String> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> prescriptionJson = const Value.absent(),
                Value<String> performanceJson = const Value.absent(),
                Value<String> startedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> leaseEpoch = const Value.absent(),
                Value<int> appliedSeq = const Value.absent(),
                Value<int> nextSeq = const Value.absent(),
                Value<int> exerciseIndex = const Value.absent(),
                Value<int> setIndex = const Value.absent(),
                Value<String?> restEndsAt = const Value.absent(),
                Value<String?> finalizeJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalWorkoutsCompanion(
                id: id,
                sessionId: sessionId,
                name: name,
                prescriptionJson: prescriptionJson,
                performanceJson: performanceJson,
                startedAt: startedAt,
                status: status,
                leaseEpoch: leaseEpoch,
                appliedSeq: appliedSeq,
                nextSeq: nextSeq,
                exerciseIndex: exerciseIndex,
                setIndex: setIndex,
                restEndsAt: restEndsAt,
                finalizeJson: finalizeJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int sessionId,
                required String name,
                required String prescriptionJson,
                Value<String> performanceJson = const Value.absent(),
                required String startedAt,
                Value<String> status = const Value.absent(),
                Value<int> leaseEpoch = const Value.absent(),
                Value<int> appliedSeq = const Value.absent(),
                Value<int> nextSeq = const Value.absent(),
                Value<int> exerciseIndex = const Value.absent(),
                Value<int> setIndex = const Value.absent(),
                Value<String?> restEndsAt = const Value.absent(),
                Value<String?> finalizeJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalWorkoutsCompanion.insert(
                id: id,
                sessionId: sessionId,
                name: name,
                prescriptionJson: prescriptionJson,
                performanceJson: performanceJson,
                startedAt: startedAt,
                status: status,
                leaseEpoch: leaseEpoch,
                appliedSeq: appliedSeq,
                nextSeq: nextSeq,
                exerciseIndex: exerciseIndex,
                setIndex: setIndex,
                restEndsAt: restEndsAt,
                finalizeJson: finalizeJson,
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
          prefetchHooksCallback: ({pendingOpsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (pendingOpsRefs) db.pendingOps],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (pendingOpsRefs)
                    await $_getPrefetchedData<
                      LocalWorkout,
                      $LocalWorkoutsTable,
                      PendingOp
                    >(
                      currentTable: table,
                      referencedTable: $$LocalWorkoutsTableReferences
                          ._pendingOpsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LocalWorkoutsTableReferences(
                            db,
                            table,
                            p0,
                          ).pendingOpsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.workoutId == item.id),
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
      PrefetchHooks Function({bool pendingOpsRefs})
    >;
typedef $$PendingOpsTableCreateCompanionBuilder =
    PendingOpsCompanion Function({
      required String opId,
      required String workoutId,
      required int epoch,
      required int seq,
      required String type,
      required String payloadJson,
      required String at,
      Value<String> state,
      Value<String?> errorCode,
      Value<int> rowid,
    });
typedef $$PendingOpsTableUpdateCompanionBuilder =
    PendingOpsCompanion Function({
      Value<String> opId,
      Value<String> workoutId,
      Value<int> epoch,
      Value<int> seq,
      Value<String> type,
      Value<String> payloadJson,
      Value<String> at,
      Value<String> state,
      Value<String?> errorCode,
      Value<int> rowid,
    });

final class $$PendingOpsTableReferences
    extends BaseReferences<_$AppDatabase, $PendingOpsTable, PendingOp> {
  $$PendingOpsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LocalWorkoutsTable _workoutIdTable(_$AppDatabase db) =>
      db.localWorkouts.createAlias(
        $_aliasNameGenerator(db.pendingOps.workoutId, db.localWorkouts.id),
      );

  $$LocalWorkoutsTableProcessedTableManager get workoutId {
    final $_column = $_itemColumn<String>('workout_id')!;

    final manager = $$LocalWorkoutsTableTableManager(
      $_db,
      $_db.localWorkouts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PendingOpsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingOpsTable> {
  $$PendingOpsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get epoch => $composableBuilder(
    column: $table.epoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalWorkoutsTableFilterComposer get workoutId {
    final $$LocalWorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.localWorkouts,
      getReferencedColumn: (t) => t.id,
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

class $$PendingOpsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingOpsTable> {
  $$PendingOpsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get epoch => $composableBuilder(
    column: $table.epoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalWorkoutsTableOrderingComposer get workoutId {
    final $$LocalWorkoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.localWorkouts,
      getReferencedColumn: (t) => t.id,
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

class $$PendingOpsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingOpsTable> {
  $$PendingOpsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get opId =>
      $composableBuilder(column: $table.opId, builder: (column) => column);

  GeneratedColumn<int> get epoch =>
      $composableBuilder(column: $table.epoch, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);

  $$LocalWorkoutsTableAnnotationComposer get workoutId {
    final $$LocalWorkoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.localWorkouts,
      getReferencedColumn: (t) => t.id,
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

class $$PendingOpsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingOpsTable,
          PendingOp,
          $$PendingOpsTableFilterComposer,
          $$PendingOpsTableOrderingComposer,
          $$PendingOpsTableAnnotationComposer,
          $$PendingOpsTableCreateCompanionBuilder,
          $$PendingOpsTableUpdateCompanionBuilder,
          (PendingOp, $$PendingOpsTableReferences),
          PendingOp,
          PrefetchHooks Function({bool workoutId})
        > {
  $$PendingOpsTableTableManager(_$AppDatabase db, $PendingOpsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingOpsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingOpsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingOpsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> opId = const Value.absent(),
                Value<String> workoutId = const Value.absent(),
                Value<int> epoch = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> at = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingOpsCompanion(
                opId: opId,
                workoutId: workoutId,
                epoch: epoch,
                seq: seq,
                type: type,
                payloadJson: payloadJson,
                at: at,
                state: state,
                errorCode: errorCode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String opId,
                required String workoutId,
                required int epoch,
                required int seq,
                required String type,
                required String payloadJson,
                required String at,
                Value<String> state = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingOpsCompanion.insert(
                opId: opId,
                workoutId: workoutId,
                epoch: epoch,
                seq: seq,
                type: type,
                payloadJson: payloadJson,
                at: at,
                state: state,
                errorCode: errorCode,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PendingOpsTableReferences(db, table, e),
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
                                referencedTable: $$PendingOpsTableReferences
                                    ._workoutIdTable(db),
                                referencedColumn: $$PendingOpsTableReferences
                                    ._workoutIdTable(db)
                                    .id,
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

typedef $$PendingOpsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingOpsTable,
      PendingOp,
      $$PendingOpsTableFilterComposer,
      $$PendingOpsTableOrderingComposer,
      $$PendingOpsTableAnnotationComposer,
      $$PendingOpsTableCreateCompanionBuilder,
      $$PendingOpsTableUpdateCompanionBuilder,
      (PendingOp, $$PendingOpsTableReferences),
      PendingOp,
      PrefetchHooks Function({bool workoutId})
    >;
typedef $$AtlasWorkspacesTableCreateCompanionBuilder =
    AtlasWorkspacesCompanion Function({
      required String slug,
      required String title,
      required int exerciseId,
      required int position,
      Value<double> scrollOffset,
      Value<int> rowid,
    });
typedef $$AtlasWorkspacesTableUpdateCompanionBuilder =
    AtlasWorkspacesCompanion Function({
      Value<String> slug,
      Value<String> title,
      Value<int> exerciseId,
      Value<int> position,
      Value<double> scrollOffset,
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
  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get scrollOffset => $composableBuilder(
    column: $table.scrollOffset,
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
  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get scrollOffset => $composableBuilder(
    column: $table.scrollOffset,
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
  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<double> get scrollOffset => $composableBuilder(
    column: $table.scrollOffset,
    builder: (column) => column,
  );
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
                Value<String> slug = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> exerciseId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<double> scrollOffset = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AtlasWorkspacesCompanion(
                slug: slug,
                title: title,
                exerciseId: exerciseId,
                position: position,
                scrollOffset: scrollOffset,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String slug,
                required String title,
                required int exerciseId,
                required int position,
                Value<double> scrollOffset = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AtlasWorkspacesCompanion.insert(
                slug: slug,
                title: title,
                exerciseId: exerciseId,
                position: position,
                scrollOffset: scrollOffset,
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
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$LocalWorkoutsTableTableManager get localWorkouts =>
      $$LocalWorkoutsTableTableManager(_db, _db.localWorkouts);
  $$PendingOpsTableTableManager get pendingOps =>
      $$PendingOpsTableTableManager(_db, _db.pendingOps);
  $$AtlasWorkspacesTableTableManager get atlasWorkspaces =>
      $$AtlasWorkspacesTableTableManager(_db, _db.atlasWorkspaces);
}
