import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
part 'database.g.dart';

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

class LocalWorkouts extends Table {
  TextColumn get id => text()();
  IntColumn get sessionId => integer()();
  TextColumn get name => text()();
  TextColumn get prescriptionJson => text()();
  TextColumn get performanceJson => text().withDefault(const Constant('{}'))();
  TextColumn get startedAt => text()();
  TextColumn get status =>
      text().withDefault(const Constant('pending_start'))();
  IntColumn get leaseEpoch => integer().withDefault(const Constant(1))();
  IntColumn get appliedSeq => integer().withDefault(const Constant(0))();
  IntColumn get nextSeq => integer().withDefault(const Constant(1))();
  IntColumn get exerciseIndex => integer().withDefault(const Constant(0))();
  IntColumn get setIndex => integer().withDefault(const Constant(0))();
  TextColumn get restEndsAt => text().nullable()();
  TextColumn get finalizeJson => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class PendingOps extends Table {
  TextColumn get opId => text()();
  TextColumn get workoutId => text().references(LocalWorkouts, #id)();
  IntColumn get epoch => integer()();
  IntColumn get seq => integer()();
  TextColumn get type => text()();
  TextColumn get payloadJson => text()();
  TextColumn get at => text()();
  TextColumn get state => text().withDefault(const Constant('pending'))();
  TextColumn get errorCode => text().nullable()();
  @override
  Set<Column> get primaryKey => {opId};
  @override
  List<Set<Column>> get uniqueKeys => [
    {workoutId, epoch, seq},
  ];
}

class AtlasWorkspaces extends Table {
  TextColumn get slug => text()();
  TextColumn get title => text()();
  IntColumn get exerciseId => integer()();
  IntColumn get position => integer()();
  RealColumn get scrollOffset => real().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {slug};
}

@DriftDatabase(tables: [Settings, LocalWorkouts, PendingOps, AtlasWorkspaces])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);
  factory AppDatabase.open() => AppDatabase(_openConnection());
  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());
  @override
  int get schemaVersion => 1;

  Future<String?> setting(String key) async => (await (select(
    settings,
  )..where((t) => t.key.equals(key))).getSingleOrNull())?.value;
  Future<void> putSetting(String key, String value) => into(
    settings,
  ).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
  Future<LocalWorkout?> activeWorkout() =>
      (select(localWorkouts)
            ..where((t) => t.status.isNotIn(['finalized', 'pending_finalize']))
            ..limit(1))
          .getSingleOrNull();
  Stream<LocalWorkout?> watchActiveWorkout() =>
      (select(localWorkouts)
            ..where((t) => t.status.isNotIn(['finalized', 'pending_finalize']))
            ..limit(1))
          .watchSingleOrNull();

  Stream<LocalWorkout?> watchWorkout(String id) => (select(
    localWorkouts,
  )..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<LocalWorkout?> syncCandidate() =>
      (select(localWorkouts)
            ..where((t) => t.status.isNotIn(['finalized']))
            ..limit(1))
          .getSingleOrNull();
  Future<List<PendingOp>> pending(String workoutId) =>
      (select(pendingOps)
            ..where(
              (t) => t.workoutId.equals(workoutId) & t.state.equals('pending'),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
          .get();

  Future<int> unresolvedCount(String workoutId) async {
    final count = pendingOps.opId.count();
    final row =
        await (selectOnly(pendingOps)
              ..addColumns([count])
              ..where(
                pendingOps.workoutId.equals(workoutId) &
                    pendingOps.state.isIn(['conflict', 'rejected']),
              ))
            .getSingle();
    return row.read(count) ?? 0;
  }

  Future<List<PendingOp>> rejectedMissingExerciseRefs(String workoutId) =>
      (select(pendingOps)
            ..where(
              (t) =>
                  t.workoutId.equals(workoutId) &
                  t.state.equals('rejected') &
                  t.errorCode.equals('exercise_performance_not_found'),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
          .get();

  Future<int> enqueue(
    String workoutId,
    String opId,
    String type,
    Map<String, Object?> data,
  ) => transaction(() async {
    final workout = await (select(
      localWorkouts,
    )..where((t) => t.id.equals(workoutId))).getSingle();
    final seq = workout.nextSeq;
    await into(pendingOps).insert(
      PendingOpsCompanion.insert(
        opId: opId,
        workoutId: workoutId,
        epoch: workout.leaseEpoch,
        seq: seq,
        type: type,
        payloadJson: jsonEncode(data),
        at: DateTime.now().toUtc().toIso8601String(),
      ),
    );
    await (update(localWorkouts)..where((t) => t.id.equals(workoutId))).write(
      LocalWorkoutsCompanion(nextSeq: Value(seq + 1)),
    );
    return seq;
  });
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final dir = await getApplicationDocumentsDirectory();
  return NativeDatabase(File(p.join(dir.path, 'agonez.sqlite')));
});
