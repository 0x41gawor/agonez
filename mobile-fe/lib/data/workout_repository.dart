import 'dart:convert';
import 'package:drift/drift.dart';
import '../domain/ids.dart';
import '../domain/models.dart';
import 'api.dart';
import 'database.dart';

class WorkoutRepository {
  WorkoutRepository(this.db, this.api);
  final AppDatabase db;
  final MobileApi api;

  Future<String> start(
    Prescription prescription, {
    bool allowMissingLoads = false,
  }) async {
    final id = AgonezIds.workout();
    final now = DateTime.now().toUtc().toIso8601String();
    await db
        .into(db.localWorkouts)
        .insert(
          LocalWorkoutsCompanion.insert(
            id: id,
            sessionId: prescription.sessionId,
            name: prescription.name,
            prescriptionJson: prescription.encode(),
            startedAt: now,
          ),
        );
    try {
      final snapshot = await api.start({
        'workout_id': id,
        'session_id': prescription.sessionId,
        'prescription_version': prescription.version,
        'started_at': now,
        'allow_missing_loads': allowMissingLoads,
        'off_schedule': null,
      });
      await _applySnapshot(id, snapshot);
    } catch (_) {
      /* Durable pending_start is intentional. */
    }
    return id;
  }

  Future<String> resumeServer(Json summary, {required bool claimLease}) async {
    final id = summary['workout_id'] as String;
    Json snapshot;
    if (claimLease) {
      snapshot = await api.claim(id, {
        'device_id': await db.setting('device_id'),
        'observed_applied_seq': summary['applied_seq'] as int,
      });
    } else {
      snapshot = await api.snapshot(id);
    }
    final prescription = Prescription(
      Map<String, dynamic>.from(snapshot['prescription'] as Map),
    );
    final performance = Map<String, dynamic>.from(
      snapshot['performance'] as Map? ?? const {},
    );
    final hint = snapshot['position_hint'] as Map?;
    final cursor = _resumeCursor(prescription, performance);
    await db
        .into(db.localWorkouts)
        .insertOnConflictUpdate(
          LocalWorkoutsCompanion.insert(
            id: id,
            sessionId: snapshot['session_id'] as int,
            name: prescription.name,
            prescriptionJson: prescription.encode(),
            performanceJson: Value(jsonEncode(performance)),
            startedAt: snapshot['started_at'] as String,
            status: const Value('active'),
            leaseEpoch: Value((snapshot['lease'] as Map)['epoch'] as int),
            appliedSeq: Value(snapshot['applied_seq'] as int),
            nextSeq: Value((snapshot['applied_seq'] as int) + 1),
            exerciseIndex: Value(cursor.$1),
            setIndex: Value(hint?['set_ordinal'] as int? ?? cursor.$2),
          ),
        );
    return id;
  }

  Future<void> confirmSet({
    required LocalWorkout workout,
    required Json exercise,
    required Json set,
    required double load,
    required int repetitions,
    required int rir,
    String? comment,
    int? heartRate,
  }) async {
    final exerciseId = AgonezIds.prescribedExercise(
      workout.id,
      exercise['exercise_prescription_id'] as int,
    );
    final setId = AgonezIds.prescribedSet(
      workout.id,
      set['set_prescription_id'] as int,
    );
    final performedAt = DateTime.now().toUtc().toIso8601String();
    await db.transaction(() async {
      final tree = workout.performanceJson.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(workout.performanceJson) as Json;
      (tree['sets'] ??= <String, dynamic>{})[setId] = {
        'load_kg': load,
        'repetitions': repetitions,
        'rir': rir,
        'status': 'performed',
      };
      final nextSet = workout.setIndex + 1;
      final sets = (exercise['sets'] as List).length;
      await (db.update(
        db.localWorkouts,
      )..where((t) => t.id.equals(workout.id))).write(
        LocalWorkoutsCompanion(
          performanceJson: Value(jsonEncode(tree)),
          setIndex: Value(nextSet >= sets ? 0 : nextSet),
          exerciseIndex: Value(
            nextSet >= sets ? workout.exerciseIndex + 1 : workout.exerciseIndex,
          ),
          restEndsAt: Value(
            DateTime.now()
                .add(
                  Duration(seconds: exercise['default_rest_s'] as int? ?? 90),
                )
                .toUtc()
                .toIso8601String(),
          ),
        ),
      );
      await db.enqueue(workout.id, AgonezIds.operation(), 'upsert_set', {
        'set_performance_id': setId,
        'exercise_performance_id': exerciseId,
        'prescribed_set_id': set['set_prescription_id'],
        'ordinal': set['ordinal'],
        'status': 'performed',
        'load_kg': load,
        'repetitions': repetitions,
        'rir': rir,
        'comment': comment,
        'heart_rate_bpm': heartRate,
        'performed_at': performedAt,
      });
    });
  }

  Future<void> structural(LocalWorkout workout, String type, Json data) =>
      db.enqueue(workout.id, AgonezIds.operation(), type, data);
  Future<void> queueFinalize(LocalWorkout workout, bool acknowledged) =>
      (db.update(
        db.localWorkouts,
      )..where((t) => t.id.equals(workout.id))).write(
        LocalWorkoutsCompanion(
          status: const Value('pending_finalize'),
          finalizeJson: Value(
            jsonEncode({
              'lease_epoch': workout.leaseEpoch,
              'final_seq': workout.nextSeq - 1,
              'finished_at': DateTime.now().toUtc().toIso8601String(),
              'unrecorded': 'mark_not_performed',
              'acknowledged_incomplete': acknowledged,
            }),
          ),
        ),
      );

  Future<void> _applySnapshot(String id, Json j) =>
      (db.update(db.localWorkouts)..where((t) => t.id.equals(id))).write(
        LocalWorkoutsCompanion(
          status: Value(j['status'] == 'completed' ? 'finalized' : 'active'),
          leaseEpoch: Value((j['lease'] as Map?)?['epoch'] as int? ?? 1),
          appliedSeq: Value(j['applied_seq'] as int? ?? 0),
        ),
      );
}

(int, int) _resumeCursor(Prescription prescription, Json performance) {
  final recorded = <int>{};
  for (final exercise in (performance['exercises'] as List? ?? const [])) {
    for (final set in ((exercise as Map)['sets'] as List? ?? const [])) {
      final id = (set as Map)['prescribed_set_id'] as int?;
      if (id != null) recorded.add(id);
    }
  }
  for (
    var exerciseIndex = 0;
    exerciseIndex < prescription.exercises.length;
    exerciseIndex++
  ) {
    final sets = (prescription.exercises[exerciseIndex]['sets'] as List)
        .cast<Map>();
    for (var setIndex = 0; setIndex < sets.length; setIndex++) {
      if (!recorded.contains(sets[setIndex]['set_prescription_id'])) {
        return (exerciseIndex, setIndex);
      }
    }
  }
  return (prescription.exercises.length, 0);
}
