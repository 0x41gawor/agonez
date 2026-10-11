import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

class AppKeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class CachedDocuments extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get etag => text().nullable()();
  TextColumn get json => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {cacheKey};
}

class LocalWorkouts extends Table {
  TextColumn get workoutId => text()();
  IntColumn get sessionId => integer()();
  IntColumn get planRunId => integer().nullable()();
  TextColumn get workoutUnitName => text()();
  TextColumn get lifecycle =>
      text().withDefault(const Constant('pending_start'))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  TextColumn get prescriptionJson => text()();
  TextColumn get startPayloadJson => text()();
  TextColumn get serverSnapshotJson => text().nullable()();
  TextColumn get etag => text().nullable()();
  IntColumn get leaseEpoch => integer().withDefault(const Constant(1))();
  IntColumn get appliedSeq => integer().withDefault(const Constant(0))();
  IntColumn get nextSeq => integer().withDefault(const Constant(1))();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  IntColumn get currentExercise => integer().withDefault(const Constant(0))();
  IntColumn get currentSet => integer().withDefault(const Constant(0))();
  TextColumn get cursorPhase => text().withDefault(const Constant('set'))();
  DateTimeColumn get restEndsAt => dateTime().nullable()();
  IntColumn get restDurationS => integer().nullable()();
  TextColumn get entryDraftJson => text().nullable()();
  TextColumn get workoutComment => text().nullable()();
  TextColumn get syncState => text().withDefault(const Constant('saving'))();
  TextColumn get syncErrorCode => text().nullable()();
  IntColumn get syncAttempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextSyncAt => dateTime().nullable()();
  TextColumn get finalizePayloadJson => text().nullable()();
  DateTimeColumn get finalizedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {workoutId};
}

class LocalExercises extends Table {
  TextColumn get exercisePerformanceId => text()();
  TextColumn get workoutId => text().references(LocalWorkouts, #workoutId)();
  IntColumn get exercisePrescriptionId => integer().nullable()();
  IntColumn get prescribedExerciseId => integer().nullable()();
  IntColumn get actualExerciseId => integer().nullable()();
  TextColumn get actualExerciseJson => text().nullable()();
  IntColumn get performedOrdinal => integer()();
  TextColumn get mode => text().withDefault(const Constant('as_prescribed'))();
  TextColumn get comment => text().nullable()();
  IntColumn get serverRev => integer().withDefault(const Constant(0))();
  IntColumn get localRev => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {exercisePerformanceId};
}

class LocalSets extends Table {
  TextColumn get setPerformanceId => text()();
  TextColumn get workoutId => text().references(LocalWorkouts, #workoutId)();
  TextColumn get exercisePerformanceId =>
      text().references(LocalExercises, #exercisePerformanceId)();
  IntColumn get exercisePrescriptionId => integer().nullable()();
  IntColumn get prescribedSetId => integer().nullable()();
  IntColumn get ordinal => integer()();
  TextColumn get status => text()();
  RealColumn get loadKg => real().nullable()();
  IntColumn get repetitions => integer().nullable()();
  IntColumn get rir => integer().nullable()();
  TextColumn get comment => text().nullable()();
  IntColumn get heartRateBpm => integer().nullable()();
  DateTimeColumn get performedAt => dateTime().nullable()();
  IntColumn get serverRev => integer().withDefault(const Constant(0))();
  IntColumn get localRev => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {setPerformanceId};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {workoutId, exercisePerformanceId, ordinal},
  ];
}

class PendingOperations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get workoutId => text().references(LocalWorkouts, #workoutId)();
  IntColumn get leaseEpoch => integer()();
  IntColumn get seq => integer()();
  TextColumn get opId => text().unique()();
  TextColumn get type => text()();
  TextColumn get dataJson => text()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get deliveryState =>
      text().withDefault(const Constant('queued'))();
  TextColumn get resultJson => text().nullable()();
  TextColumn get errorCode => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {workoutId, leaseEpoch, seq},
  ];
}

class AtlasWorkspaces extends Table {
  TextColumn get workspaceId => text()();
  TextColumn get kind => text()();
  TextColumn get slug => text().nullable()();
  TextColumn get title => text()();
  TextColumn get navigationJson => text().withDefault(const Constant('[]'))();
  RealColumn get scrollOffset => real().withDefault(const Constant(0))();
  BoolColumn get isCurrent => boolean().withDefault(const Constant(false))();
  DateTimeColumn get openedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {workspaceId};
}

@DriftDatabase(
  tables: [
    AppKeyValues,
    CachedDocuments,
    LocalWorkouts,
    LocalExercises,
    LocalSets,
    PendingOperations,
    AtlasWorkspaces,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'agonez'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 3) await _upgradePrototypeSchema(migrator);
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
    },
  );

  Future<void> _upgradePrototypeSchema(Migrator migrator) async {
    final workoutColumns = await _tableColumns('local_workouts');
    final atlasColumns = await _tableColumns('atlas_workspaces');
    final legacyWorkoutSchema =
        workoutColumns.contains('id') && !workoutColumns.contains('workout_id');
    final legacyAtlasSchema =
        atlasColumns.contains('position') &&
        !atlasColumns.contains('workspace_id');

    final settingsRows = await _rawRowsIfPresent(
      'settings',
      'SELECT "key", "value" FROM "settings"',
    );
    final workoutRows = legacyWorkoutSchema
        ? await _rawRowsIfPresent(
            'local_workouts',
            'SELECT * FROM "local_workouts"',
          )
        : const <Map<String, Object?>>[];
    final operationRows = legacyWorkoutSchema
        ? await _rawRowsIfPresent(
            'pending_ops',
            'SELECT * FROM "pending_ops" ORDER BY "epoch", "seq"',
          )
        : const <Map<String, Object?>>[];
    final workspaceRows = legacyAtlasSchema
        ? await _rawRowsIfPresent(
            'atlas_workspaces',
            'SELECT * FROM "atlas_workspaces" ORDER BY "position"',
          )
        : const <Map<String, Object?>>[];

    if (legacyWorkoutSchema) {
      // Version-one prototypes used the same table name for a different
      // shape. Remove children first so the replacement foreign keys target
      // the new workout_id primary key.
      await customStatement('DROP TABLE IF EXISTS "pending_operations"');
      await customStatement('DROP TABLE IF EXISTS "local_sets"');
      await customStatement('DROP TABLE IF EXISTS "local_exercises"');
      await customStatement('DROP TABLE IF EXISTS "pending_ops"');
      await customStatement('DROP TABLE IF EXISTS "local_workouts"');
    }
    if (legacyAtlasSchema) {
      await customStatement('DROP TABLE IF EXISTS "atlas_workspaces"');
    }

    // This also repairs a versioned-but-empty database left by an interrupted
    // early debug build. Drift emits CREATE TABLE IF NOT EXISTS statements.
    await migrator.createAll();

    final now = DateTime.now().toUtc();
    for (final row in settingsRows) {
      final key = row['key'] as String?;
      final value = row['value'] as String?;
      if (key == null || value == null) continue;
      await into(appKeyValues).insertOnConflictUpdate(
        AppKeyValuesCompanion.insert(key: key, value: value, updatedAt: now),
      );
    }

    if (legacyWorkoutSchema) {
      for (final row in workoutRows) {
        await _restorePrototypeWorkout(row, now);
      }
      for (final row in operationRows) {
        await _restorePrototypeOperation(row);
      }
    }

    if (legacyAtlasSchema) {
      for (final row in workspaceRows) {
        await _restorePrototypeWorkspace(row, now);
      }
    }

    if (settingsRows.isNotEmpty) {
      await customStatement('DROP TABLE IF EXISTS "settings"');
    }
  }

  Future<Set<String>> _tableColumns(String table) async {
    if (!await _tableExists(table)) return const <String>{};
    final safeTable = table.replaceAll('"', '""');
    final rows = await customSelect('PRAGMA table_info("$safeTable")').get();
    return rows.map((row) => row.data['name']).whereType<String>().toSet();
  }

  Future<bool> _tableExists(String table) async {
    final rows = await customSelect(
      'SELECT 1 FROM sqlite_master '
      'WHERE type = \'table\' AND name = ? LIMIT 1',
      variables: <Variable<Object>>[Variable<String>(table)],
    ).get();
    return rows.isNotEmpty;
  }

  Future<List<Map<String, Object?>>> _rawRowsIfPresent(
    String table,
    String sql,
  ) async {
    if (!await _tableExists(table)) return const <Map<String, Object?>>[];
    return (await customSelect(sql).get())
        .map((row) => Map<String, Object?>.from(row.data))
        .toList(growable: false);
  }

  Future<void> _restorePrototypeWorkout(
    Map<String, Object?> row,
    DateTime fallbackTime,
  ) async {
    final workoutId = row['id'] as String?;
    final name = row['name'] as String?;
    final prescriptionJson = row['prescription_json'] as String?;
    if (workoutId == null || name == null || prescriptionJson == null) return;

    final sessionId = _legacyInt(row['session_id']);
    if (sessionId == null || sessionId < 1) return;
    final startedAt = _legacyDate(row['started_at']) ?? fallbackTime;
    final restEndsAt = _legacyDate(row['rest_ends_at']);
    final status = row['status'] as String? ?? 'pending_start';
    final lifecycle = switch (status) {
      'finalized' || 'completed' => 'completed',
      'finalize_pending' => 'pending_finalize',
      'active' || 'pending_start' || 'pending_finalize' => status,
      _ => 'pending_start',
    };
    final prescription = _legacyJsonMap(prescriptionJson);
    final prescriptionVersion =
        prescription?['prescription_version'] as String? ?? 'legacy';
    final finalizeJson = row['finalize_json'] as String?;
    final finalize = _legacyJsonMap(finalizeJson);
    final finishedAt = _legacyDate(finalize?['finished_at']);
    final performance = _legacyJsonMap(row['performance_json'] as String?);

    await into(localWorkouts).insert(
      LocalWorkoutsCompanion.insert(
        workoutId: workoutId,
        sessionId: sessionId,
        workoutUnitName: name,
        lifecycle: Value(lifecycle),
        startedAt: startedAt,
        finishedAt: Value(finishedAt),
        prescriptionJson: prescriptionJson,
        startPayloadJson: jsonEncode(<String, Object?>{
          'workout_id': workoutId,
          'session_id': sessionId,
          'prescription_version': prescriptionVersion,
          'started_at': startedAt.toIso8601String(),
          'allow_missing_loads': false,
          'off_schedule': null,
        }),
        leaseEpoch: Value(_legacyInt(row['lease_epoch']) ?? 1),
        appliedSeq: Value(_legacyInt(row['applied_seq']) ?? 0),
        nextSeq: Value(_legacyInt(row['next_seq']) ?? 1),
        currentExercise: Value(_legacyInt(row['exercise_index']) ?? 0),
        currentSet: Value(_legacyInt(row['set_index']) ?? 0),
        restEndsAt: Value(restEndsAt),
        finalizePayloadJson: Value(finalizeJson),
        finalizedAt: Value(lifecycle == 'completed' ? finishedAt : null),
        syncState: Value(lifecycle == 'completed' ? 'saved' : 'offline'),
        updatedAt: fallbackTime,
      ),
      mode: InsertMode.insertOrIgnore,
    );

    final exercises = prescription?['exercises'];
    if (exercises is! List) return;
    final performedSets = switch (performance?['sets']) {
      final Map values => values.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      _ => const <String, Object?>{},
    };
    const uuid = Uuid();
    for (final (index, rawExercise) in exercises.indexed) {
      if (rawExercise is! Map) continue;
      final exercise = rawExercise.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final exercisePrescriptionId = _legacyInt(
        exercise['exercise_prescription_id'],
      );
      if (exercisePrescriptionId == null) continue;
      final exerciseIdentity = switch (exercise['exercise']) {
        final Map value => value.map(
          (key, item) => MapEntry(key.toString(), item),
        ),
        _ => const <String, Object?>{},
      };
      final exercisePerformanceId = uuid.v5(
        workoutId,
        'ex:$exercisePrescriptionId',
      );
      await into(localExercises).insert(
        LocalExercisesCompanion.insert(
          exercisePerformanceId: exercisePerformanceId,
          workoutId: workoutId,
          exercisePrescriptionId: Value(exercisePrescriptionId),
          prescribedExerciseId: Value(_legacyInt(exerciseIdentity['id'])),
          performedOrdinal: _legacyInt(exercise['ordinal']) ?? index,
          updatedAt: fallbackTime,
        ),
        mode: InsertMode.insertOrIgnore,
      );

      final sets = exercise['sets'];
      if (sets is! List) continue;
      for (final (setIndex, rawSet) in sets.indexed) {
        if (rawSet is! Map) continue;
        final prescribedSet = rawSet.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        final prescribedSetId = _legacyInt(
          prescribedSet['set_prescription_id'],
        );
        if (prescribedSetId == null) continue;
        final setPerformanceId = uuid.v5(workoutId, 'set:$prescribedSetId');
        final rawPerformance = performedSets[setPerformanceId];
        if (rawPerformance is! Map) continue;
        final set = rawPerformance.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        await into(localSets).insert(
          LocalSetsCompanion.insert(
            setPerformanceId: setPerformanceId,
            workoutId: workoutId,
            exercisePerformanceId: exercisePerformanceId,
            exercisePrescriptionId: Value(exercisePrescriptionId),
            prescribedSetId: Value(prescribedSetId),
            ordinal: _legacyInt(prescribedSet['ordinal']) ?? setIndex,
            status: set['status'] as String? ?? 'performed',
            loadKg: Value(_legacyDouble(set['load_kg'])),
            repetitions: Value(_legacyInt(set['repetitions'])),
            rir: Value(_legacyInt(set['rir'])),
            updatedAt: fallbackTime,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    }
  }

  Future<void> _restorePrototypeOperation(Map<String, Object?> row) async {
    final opId = row['op_id'] as String?;
    final workoutId = row['workout_id'] as String?;
    final type = row['type'] as String?;
    final dataJson = row['payload_json'] as String?;
    if (opId == null || workoutId == null || type == null || dataJson == null) {
      return;
    }
    final workout =
        await (select(localWorkouts)
              ..where((candidate) => candidate.workoutId.equals(workoutId)))
            .getSingleOrNull();
    if (workout == null) return;
    await into(pendingOperations).insert(
      PendingOperationsCompanion.insert(
        workoutId: workoutId,
        leaseEpoch: _legacyInt(row['epoch']) ?? workout.leaseEpoch,
        seq: _legacyInt(row['seq']) ?? workout.nextSeq,
        opId: opId,
        type: type,
        dataJson: dataJson,
        occurredAt: _legacyDate(row['at']) ?? workout.updatedAt,
        deliveryState: Value(
          row['state'] == 'pending' ? 'queued' : 'acknowledged',
        ),
        errorCode: Value(row['error_code'] as String?),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> _restorePrototypeWorkspace(
    Map<String, Object?> row,
    DateTime fallbackTime,
  ) async {
    final slug = row['slug'] as String?;
    final title = row['title'] as String?;
    if (slug == null || slug.isEmpty || title == null) return;
    // The current mobile Atlas has full exercise articles. Old muscle tabs had
    // no equivalent backend article route and are intentionally not restored.
    if (slug.startsWith('muscle:')) return;
    final exerciseId = _legacyInt(row['exercise_id']) ?? 0;
    final position = _legacyInt(row['position']) ?? 0;
    const uuid = Uuid();
    await into(atlasWorkspaces).insert(
      AtlasWorkspacesCompanion.insert(
        workspaceId: uuid.v5(
          '00000000-0000-0000-0000-000000000000',
          'legacy-atlas:$slug',
        ),
        kind: 'exercise',
        slug: Value(slug),
        title: title,
        navigationJson: Value(
          jsonEncode(<Map<String, Object?>>[
            <String, Object?>{
              'kind': 'exercise',
              'exercise_id': exerciseId,
              'slug': slug,
              'title': title,
            },
          ]),
        ),
        scrollOffset: Value(_legacyDouble(row['scroll_offset']) ?? 0),
        isCurrent: const Value(false),
        openedAt: fallbackTime.add(Duration(milliseconds: position)),
        updatedAt: fallbackTime.add(Duration(milliseconds: position)),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Map<String, Object?>? _legacyJsonMap(String? source) {
    if (source == null) return null;
    try {
      final value = jsonDecode(source);
      if (value is Map) {
        return value.map((key, item) => MapEntry(key.toString(), item));
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  DateTime? _legacyDate(Object? value) => switch (value) {
    final DateTime date => date.toUtc(),
    final String text => DateTime.tryParse(text)?.toUtc(),
    final int seconds => DateTime.fromMillisecondsSinceEpoch(
      seconds * 1000,
      isUtc: true,
    ),
    _ => null,
  };

  int? _legacyInt(Object? value) => switch (value) {
    final int number => number,
    final num number => number.toInt(),
    final String text => int.tryParse(text),
    _ => null,
  };

  double? _legacyDouble(Object? value) => switch (value) {
    final double number => number,
    final num number => number.toDouble(),
    final String text => double.tryParse(text),
    _ => null,
  };

  Future<String> installationId() async {
    final existing = await (select(
      appKeyValues,
    )..where((row) => row.key.equals('device_id'))).getSingleOrNull();
    if (existing != null) return existing.value;

    final value = const Uuid().v4();
    await into(appKeyValues).insert(
      AppKeyValuesCompanion.insert(
        key: 'device_id',
        value: value,
        updatedAt: DateTime.now().toUtc(),
      ),
      mode: InsertMode.insertOrIgnore,
    );
    return (await (select(
      appKeyValues,
    )..where((row) => row.key.equals('device_id'))).getSingle()).value;
  }

  Future<String?> readSetting(String key) async => (await (select(
    appKeyValues,
  )..where((row) => row.key.equals(key))).getSingleOrNull())?.value;

  Future<void> writeSetting(String key, String value) =>
      into(appKeyValues).insertOnConflictUpdate(
        AppKeyValuesCompanion.insert(
          key: key,
          value: value,
          updatedAt: DateTime.now().toUtc(),
        ),
      );

  Future<CachedDocument?> cachedDocument(String key) => (select(
    cachedDocuments,
  )..where((row) => row.cacheKey.equals(key))).getSingleOrNull();

  Future<void> putCachedDocument({
    required String key,
    required String json,
    String? etag,
  }) => into(cachedDocuments).insertOnConflictUpdate(
    CachedDocumentsCompanion.insert(
      cacheKey: key,
      json: json,
      etag: Value(etag),
      updatedAt: DateTime.now().toUtc(),
    ),
  );

  Selectable<LocalWorkout> activeWorkoutQuery() => select(localWorkouts)
    ..where((row) => row.lifecycle.isNotIn(['completed', 'abandoned']))
    ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])
    ..limit(1);

  Future<LocalWorkout?> activeWorkout() =>
      activeWorkoutQuery().getSingleOrNull();

  Stream<LocalWorkout?> watchActiveWorkout() =>
      activeWorkoutQuery().watchSingleOrNull();

  Stream<LocalWorkout?> watchWorkout(String workoutId) =>
      (select(localWorkouts)
            ..where((row) => row.workoutId.equals(workoutId))
            ..limit(1))
          .watchSingleOrNull();

  Future<void> createLocalWorkout({
    required LocalWorkoutsCompanion workout,
    required Iterable<LocalExercisesCompanion> exercises,
  }) => transaction(() async {
    final active = await activeWorkout();
    if (active != null && active.workoutId != workout.workoutId.value) {
      throw StateError('Only one local workout may be active');
    }
    await into(localWorkouts).insert(workout, mode: InsertMode.insertOrIgnore);
    await batch((batch) {
      batch.insertAll(
        localExercises,
        exercises.toList(growable: false),
        mode: InsertMode.insertOrIgnore,
      );
    });
  });

  Future<PendingOperation> enqueueOperation({
    required String workoutId,
    required String type,
    required Map<String, Object?> data,
    DateTime? occurredAt,
    String? operationId,
  }) => transaction(() async {
    final workout = await (select(
      localWorkouts,
    )..where((row) => row.workoutId.equals(workoutId))).getSingle();
    final now = (occurredAt ?? DateTime.now()).toUtc();
    final opId = operationId ?? const Uuid().v4();
    final id = await into(pendingOperations).insert(
      PendingOperationsCompanion.insert(
        workoutId: workoutId,
        leaseEpoch: workout.leaseEpoch,
        seq: workout.nextSeq,
        opId: opId,
        type: type,
        dataJson: jsonEncode(data),
        occurredAt: now,
      ),
    );
    await (update(
      localWorkouts,
    )..where((row) => row.workoutId.equals(workoutId))).write(
      LocalWorkoutsCompanion(
        nextSeq: Value(workout.nextSeq + 1),
        syncState: const Value('saving'),
        syncErrorCode: const Value(null),
        updatedAt: Value(now),
      ),
    );
    return (select(
      pendingOperations,
    )..where((row) => row.id.equals(id))).getSingle();
  });

  Future<PendingOperation> recordSetAndEnqueue({
    required String workoutId,
    required LocalSetsCompanion set,
    String operationType = 'upsert_set',
    required Map<String, Object?> operationData,
    DateTime? restEndsAt,
    int? restDurationS,
    int? nextExerciseIndex,
    int? nextSetIndex,
  }) => transaction(() async {
    await into(localSets).insertOnConflictUpdate(set);
    if (restEndsAt != null ||
        restDurationS != null ||
        nextExerciseIndex != null ||
        nextSetIndex != null) {
      await (update(
        localWorkouts,
      )..where((row) => row.workoutId.equals(workoutId))).write(
        LocalWorkoutsCompanion(
          restEndsAt: Value(restEndsAt?.toUtc()),
          restDurationS: Value(restDurationS),
          currentExercise: nextExerciseIndex == null
              ? const Value.absent()
              : Value(nextExerciseIndex),
          currentSet: nextSetIndex == null
              ? const Value.absent()
              : Value(nextSetIndex),
          entryDraftJson: const Value(null),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
    }
    return enqueueOperation(
      workoutId: workoutId,
      type: operationType,
      data: operationData,
      occurredAt: set.performedAt.present ? set.performedAt.value : null,
    );
  });

  Future<PendingOperation> deleteSetAndEnqueue({
    required String workoutId,
    required String setPerformanceId,
    required Map<String, Object?> operationData,
  }) => transaction(() async {
    await (delete(
      localSets,
    )..where((row) => row.setPerformanceId.equals(setPerformanceId))).go();
    return enqueueOperation(
      workoutId: workoutId,
      type: 'clear_set',
      data: operationData,
    );
  });

  Future<PendingOperation> updateExerciseAndEnqueue({
    required String workoutId,
    required String exercisePerformanceId,
    required LocalExercisesCompanion updateValue,
    required String operationType,
    required Map<String, Object?> operationData,
  }) => transaction(() async {
    await (update(localExercises)..where(
          (row) => row.exercisePerformanceId.equals(exercisePerformanceId),
        ))
        .write(updateValue);
    return enqueueOperation(
      workoutId: workoutId,
      type: operationType,
      data: operationData,
    );
  });

  Future<List<PendingOperation>> deliverableOperations(
    String workoutId, {
    int limit = 200,
  }) async {
    final workout = await (select(
      localWorkouts,
    )..where((row) => row.workoutId.equals(workoutId))).getSingle();
    return (select(pendingOperations)
          ..where(
            (row) =>
                row.workoutId.equals(workoutId) &
                row.leaseEpoch.equals(workout.leaseEpoch) &
                row.seq.isBiggerThanValue(workout.appliedSeq) &
                row.deliveryState.isIn(['queued', 'in_flight']),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.seq)])
          ..limit(limit))
        .get();
  }

  Future<List<LocalExercise>> workoutExercises(String workoutId) =>
      (select(localExercises)
            ..where((row) => row.workoutId.equals(workoutId))
            ..orderBy([(row) => OrderingTerm.asc(row.performedOrdinal)]))
          .get();

  Future<List<LocalSet>> workoutSets(String workoutId) =>
      (select(localSets)
            ..where((row) => row.workoutId.equals(workoutId))
            ..orderBy([
              (row) => OrderingTerm.asc(row.exercisePerformanceId),
              (row) => OrderingTerm.asc(row.ordinal),
            ]))
          .get();

  Stream<List<LocalSet>> watchWorkoutSets(String workoutId) =>
      (select(localSets)
            ..where((row) => row.workoutId.equals(workoutId))
            ..orderBy([
              (row) => OrderingTerm.asc(row.exercisePerformanceId),
              (row) => OrderingTerm.asc(row.ordinal),
            ]))
          .watch();

  Future<void> markStartAcknowledged({
    required String workoutId,
    required int leaseEpoch,
    required int appliedSeq,
    required int revision,
    required Map<String, Object?> snapshot,
    String? etag,
  }) => transaction(() async {
    final current = await (select(
      localWorkouts,
    )..where((row) => row.workoutId.equals(workoutId))).getSingle();
    await (update(
      localWorkouts,
    )..where((row) => row.workoutId.equals(workoutId))).write(
      LocalWorkoutsCompanion(
        lifecycle: Value(
          current.lifecycle == 'pending_finalize'
              ? 'pending_finalize'
              : 'active',
        ),
        leaseEpoch: Value(leaseEpoch),
        appliedSeq: Value(appliedSeq),
        revision: Value(revision),
        serverSnapshotJson: Value(jsonEncode(snapshot)),
        etag: Value(etag),
        syncState: const Value('saving'),
        syncErrorCode: const Value(null),
        syncAttempts: const Value(0),
        nextSyncAt: const Value(null),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  });

  Future<void> markSyncIssue({
    required String workoutId,
    required String state,
    String? errorCode,
    int? attempts,
    DateTime? nextAttemptAt,
  }) => (update(localWorkouts)..where((row) => row.workoutId.equals(workoutId)))
      .write(
        LocalWorkoutsCompanion(
          syncState: Value(state),
          syncErrorCode: Value(errorCode),
          syncAttempts: attempts == null
              ? const Value.absent()
              : Value(attempts),
          nextSyncAt: Value(nextAttemptAt?.toUtc()),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );

  Future<void> reconcileExpectedSequence({
    required String workoutId,
    required int expectedSeq,
  }) => transaction(() async {
    final workout = await (select(
      localWorkouts,
    )..where((row) => row.workoutId.equals(workoutId))).getSingle();
    final acknowledgedThrough = expectedSeq - 1;

    // A seq_gap with a later expected sequence means the server has already
    // consumed those commands (usually a response was lost). Retire them
    // locally so they cannot block finalization or be replayed.
    await (update(pendingOperations)..where(
          (row) =>
              row.workoutId.equals(workoutId) &
              row.leaseEpoch.equals(workout.leaseEpoch) &
              row.seq.isSmallerOrEqualValue(acknowledgedThrough) &
              row.deliveryState.isIn(['queued', 'in_flight']),
        ))
        .write(
          const PendingOperationsCompanion(
            deliveryState: Value('acknowledged'),
            errorCode: Value('server_already_applied'),
          ),
        );
    await (update(
      localWorkouts,
    )..where((row) => row.workoutId.equals(workoutId))).write(
      LocalWorkoutsCompanion(
        appliedSeq: Value(acknowledgedThrough),
        syncState: const Value('saving'),
        syncErrorCode: const Value(null),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  });

  Future<void> acceptClaimedSnapshot({
    required String workoutId,
    required int leaseEpoch,
    required int appliedSeq,
    required int revision,
    required Map<String, Object?> snapshot,
  }) => (update(localWorkouts)..where((row) => row.workoutId.equals(workoutId)))
      .write(
        LocalWorkoutsCompanion(
          lifecycle: const Value('active'),
          leaseEpoch: Value(leaseEpoch),
          appliedSeq: Value(appliedSeq),
          nextSeq: Value(appliedSeq + 1),
          revision: Value(revision),
          serverSnapshotJson: Value(jsonEncode(snapshot)),
          syncState: const Value('saved'),
          syncErrorCode: const Value(null),
          syncAttempts: const Value(0),
          nextSyncAt: const Value(null),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );

  Future<void> storeServerSnapshot({
    required String workoutId,
    required Map<String, Object?> snapshot,
    String? etag,
  }) => (update(localWorkouts)..where((row) => row.workoutId.equals(workoutId)))
      .write(
        LocalWorkoutsCompanion(
          serverSnapshotJson: Value(jsonEncode(snapshot)),
          etag: Value(etag),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );

  Future<int> pendingOperationCount(String workoutId) async {
    final workout = await (select(
      localWorkouts,
    )..where((row) => row.workoutId.equals(workoutId))).getSingleOrNull();
    if (workout == null) return 0;
    final count = pendingOperations.id.count();
    final query = selectOnly(pendingOperations)
      ..addColumns([count])
      ..where(
        pendingOperations.workoutId.equals(workoutId) &
            pendingOperations.leaseEpoch.equals(workout.leaseEpoch) &
            pendingOperations.seq.isBiggerThanValue(workout.appliedSeq) &
            pendingOperations.deliveryState.isIn(['queued', 'in_flight']),
      );
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<PendingOperation?> latestBlockingOperation(String workoutId) async {
    final workout = await (select(
      localWorkouts,
    )..where((row) => row.workoutId.equals(workoutId))).getSingleOrNull();
    if (workout == null) return null;
    return (select(pendingOperations)
          ..where(
            (row) =>
                row.workoutId.equals(workoutId) &
                row.leaseEpoch.equals(workout.leaseEpoch) &
                row.deliveryState.isIn(['conflict', 'rejected']),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.seq)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<bool> retryLatestConflict(String workoutId) => transaction(() async {
    final workout = await (select(
      localWorkouts,
    )..where((row) => row.workoutId.equals(workoutId))).getSingle();
    final conflict =
        await (select(pendingOperations)
              ..where(
                (row) =>
                    row.workoutId.equals(workoutId) &
                    row.leaseEpoch.equals(workout.leaseEpoch) &
                    row.deliveryState.equals('conflict'),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.seq)])
              ..limit(1))
            .getSingleOrNull();
    if (conflict == null) return false;

    final data = Map<String, Object?>.from(
      jsonDecode(conflict.dataJson) as Map,
    );
    final result = conflict.resultJson == null
        ? const <String, Object?>{}
        : Map<String, Object?>.from(jsonDecode(conflict.resultJson!) as Map);
    final serverState = result['server_state'];
    final entityRevision =
        result['entity_rev'] as int? ??
        (serverState is Map ? serverState['rev'] as int? : null);
    data['if_rev'] = entityRevision;
    final now = DateTime.now().toUtc();

    await (update(
      pendingOperations,
    )..where((row) => row.id.equals(conflict.id))).write(
      const PendingOperationsCompanion(
        deliveryState: Value('resolved_keep_phone'),
      ),
    );
    await into(pendingOperations).insert(
      PendingOperationsCompanion.insert(
        workoutId: workoutId,
        leaseEpoch: workout.leaseEpoch,
        seq: workout.nextSeq,
        opId: const Uuid().v4(),
        type: conflict.type,
        dataJson: jsonEncode(data),
        occurredAt: now,
      ),
    );
    if (entityRevision != null) {
      await _storeEntityRevision(
        operationType: conflict.type,
        data: data,
        serverRevision: entityRevision,
        localRevision: entityRevision + 1,
      );
    }
    await (update(
      localWorkouts,
    )..where((row) => row.workoutId.equals(workoutId))).write(
      LocalWorkoutsCompanion(
        nextSeq: Value(workout.nextSeq + 1),
        syncState: const Value('saving'),
        syncErrorCode: const Value(null),
        updatedAt: Value(now),
      ),
    );
    return true;
  });

  Future<void> resolveConflictsUsingServer(String workoutId) =>
      transaction(() async {
        final workout = await (select(
          localWorkouts,
        )..where((row) => row.workoutId.equals(workoutId))).getSingle();
        await (update(pendingOperations)..where(
              (row) =>
                  row.workoutId.equals(workoutId) &
                  row.leaseEpoch.equals(workout.leaseEpoch) &
                  row.deliveryState.equals('conflict'),
            ))
            .write(
              const PendingOperationsCompanion(
                deliveryState: Value('resolved_use_server'),
              ),
            );
      });

  Future<void> acknowledgeOperations({
    required String workoutId,
    required int leaseEpoch,
    required int appliedSeq,
    required int revision,
    required Map<int, Map<String, Object?>> resultsBySeq,
  }) => transaction(() async {
    // applied_seq is authoritative even when an individual result was omitted
    // from a retry response. All consumed operations through it are retired.
    await (update(pendingOperations)..where(
          (row) =>
              row.workoutId.equals(workoutId) &
              row.leaseEpoch.equals(leaseEpoch) &
              row.seq.isSmallerOrEqualValue(appliedSeq) &
              row.deliveryState.isIn(['queued', 'in_flight']),
        ))
        .write(
          const PendingOperationsCompanion(
            deliveryState: Value('acknowledged'),
          ),
        );

    String? blockingState;
    String? blockingErrorCode;
    for (final entry in resultsBySeq.entries) {
      final status = entry.value['status'] as String? ?? 'applied';
      final operation =
          await (select(pendingOperations)..where(
                (row) =>
                    row.workoutId.equals(workoutId) &
                    row.leaseEpoch.equals(leaseEpoch) &
                    row.seq.equals(entry.key),
              ))
              .getSingleOrNull();
      final resultError = entry.value['error'];
      final errorCode = resultError is Map<String, Object?>
          ? resultError['code'] as String?
          : null;
      if (status == 'conflict') {
        blockingState = 'conflict';
        blockingErrorCode ??= errorCode ?? 'operation_conflict';
      } else if (status == 'rejected' && blockingState != 'conflict') {
        blockingState = 'recovery_required';
        blockingErrorCode ??= errorCode ?? 'operation_rejected';
      }
      await (update(pendingOperations)..where(
            (row) =>
                row.workoutId.equals(workoutId) &
                row.leaseEpoch.equals(leaseEpoch) &
                row.seq.equals(entry.key),
          ))
          .write(
            PendingOperationsCompanion(
              deliveryState: Value(switch (status) {
                'conflict' => 'conflict',
                'rejected' => 'rejected',
                _ => 'acknowledged',
              }),
              resultJson: Value(jsonEncode(entry.value)),
              errorCode: Value(errorCode),
            ),
          );
      final entityRevision = entry.value['entity_rev'];
      if (operation != null &&
          (status == 'applied' || status == 'duplicate') &&
          entityRevision is int) {
        await _storeEntityRevision(
          operationType: operation.type,
          data: Map<String, Object?>.from(
            jsonDecode(operation.dataJson) as Map,
          ),
          serverRevision: entityRevision,
        );
      }
    }
    final existingBlocks =
        await (select(pendingOperations)..where(
              (row) =>
                  row.workoutId.equals(workoutId) &
                  row.leaseEpoch.equals(leaseEpoch) &
                  row.deliveryState.isIn(['conflict', 'rejected']),
            ))
            .get();
    if (existingBlocks.any(
      (operation) => operation.deliveryState == 'conflict',
    )) {
      blockingState = 'conflict';
      blockingErrorCode ??= existingBlocks
          .where((operation) => operation.deliveryState == 'conflict')
          .first
          .errorCode;
    } else if (existingBlocks.isNotEmpty && blockingState == null) {
      blockingState = 'recovery_required';
      blockingErrorCode ??= existingBlocks.first.errorCode;
    }
    final unresolved = await pendingOperationCount(workoutId);
    await (update(
      localWorkouts,
    )..where((row) => row.workoutId.equals(workoutId))).write(
      LocalWorkoutsCompanion(
        appliedSeq: Value(appliedSeq),
        revision: Value(revision),
        syncState: Value(
          blockingState ?? (unresolved == 0 ? 'saved' : 'saving'),
        ),
        syncErrorCode: Value(blockingErrorCode),
        syncAttempts: const Value(0),
        nextSyncAt: const Value(null),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  });

  Future<void> _storeEntityRevision({
    required String operationType,
    required Map<String, Object?> data,
    required int serverRevision,
    int? localRevision,
  }) async {
    if (operationType == 'upsert_set' || operationType == 'skip_set') {
      final id = data['set_performance_id'];
      if (id is! String) return;
      await (update(
        localSets,
      )..where((row) => row.setPerformanceId.equals(id))).write(
        LocalSetsCompanion(
          serverRev: Value(serverRevision),
          localRev: localRevision == null
              ? const Value.absent()
              : Value(localRevision),
        ),
      );
      return;
    }
    if (operationType == 'set_exercise_comment' ||
        operationType == 'skip_exercise' ||
        operationType == 'substitute_exercise' ||
        operationType == 'add_unplanned_exercise') {
      final id = data['exercise_performance_id'];
      if (id is! String) return;
      await (update(
        localExercises,
      )..where((row) => row.exercisePerformanceId.equals(id))).write(
        LocalExercisesCompanion(
          serverRev: Value(serverRevision),
          localRev: localRevision == null
              ? const Value.absent()
              : Value(localRevision),
        ),
      );
    }
  }

  Future<void> setWorkoutCursor({
    required String workoutId,
    required int exerciseIndex,
    required int setIndex,
    required String phase,
    String? draftJson,
  }) => (update(localWorkouts)..where((row) => row.workoutId.equals(workoutId)))
      .write(
        LocalWorkoutsCompanion(
          currentExercise: Value(exerciseIndex),
          currentSet: Value(setIndex),
          cursorPhase: Value(phase),
          entryDraftJson: Value(draftJson),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );

  Future<void> setRestTimer({
    required String workoutId,
    DateTime? endsAt,
    int? durationSeconds,
  }) => (update(localWorkouts)..where((row) => row.workoutId.equals(workoutId)))
      .write(
        LocalWorkoutsCompanion(
          restEndsAt: Value(endsAt?.toUtc()),
          restDurationS: Value(durationSeconds),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );

  Future<void> queueFinalize({
    required String workoutId,
    required Map<String, Object?> payload,
    required DateTime finishedAt,
  }) => (update(localWorkouts)..where((row) => row.workoutId.equals(workoutId)))
      .write(
        LocalWorkoutsCompanion(
          lifecycle: const Value('pending_finalize'),
          finalizePayloadJson: Value(jsonEncode(payload)),
          finishedAt: Value(finishedAt.toUtc()),
          restEndsAt: const Value(null),
          restDurationS: const Value(null),
          syncState: const Value('saving'),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );

  Future<void> markCompleted({
    required String workoutId,
    required DateTime finishedAt,
    required Map<String, Object?> response,
  }) => (update(localWorkouts)..where((row) => row.workoutId.equals(workoutId)))
      .write(
        LocalWorkoutsCompanion(
          lifecycle: const Value('completed'),
          finalizedAt: Value(finishedAt.toUtc()),
          serverSnapshotJson: Value(jsonEncode(response)),
          syncState: const Value('saved'),
          syncErrorCode: const Value(null),
          restEndsAt: const Value(null),
          restDurationS: const Value(null),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );

  Future<void> replaceAtlasWorkspaces(
    List<AtlasWorkspacesCompanion> workspaces,
  ) => transaction(() async {
    await delete(atlasWorkspaces).go();
    if (workspaces.isNotEmpty) {
      await batch((batch) => batch.insertAll(atlasWorkspaces, workspaces));
    }
  });
}
