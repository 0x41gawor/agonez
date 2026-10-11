import 'package:agonez/src/api/api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const opId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  const setId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  const exerciseId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
  final at = DateTime.utc(2026, 10, 9, 16, 30);

  test('all ten operations serialize and deserialize by discriminator', () {
    final operations = <WorkoutOperation>[
      UpsertSetOperation(
        opId: opId,
        seq: 1,
        at: at,
        data: UpsertSetData(
          setPerformanceId: setId,
          exercisePerformanceId: exerciseId,
          exercisePrescriptionId: 51,
          prescribedSetId: 81,
          ordinal: 0,
          loadKg: 67.5,
          repetitions: 7,
          rir: 1,
          comment: 'Clean pause',
          heartRateBpm: 145,
          performedAt: at,
        ),
      ),
      SkipSetOperation(
        opId: opId,
        seq: 2,
        at: at,
        data: SkipSetData(
          setPerformanceId: setId,
          exercisePerformanceId: exerciseId,
          exercisePrescriptionId: 51,
          prescribedSetId: 82,
          ordinal: 1,
        ),
      ),
      ClearSetOperation(
        opId: opId,
        seq: 3,
        at: at,
        data: ClearSetData(setPerformanceId: setId, ifRev: 1),
      ),
      SetExerciseCommentOperation(
        opId: opId,
        seq: 4,
        at: at,
        data: SetExerciseCommentData(
          exercisePerformanceId: exerciseId,
          exercisePrescriptionId: 51,
          comment: null,
        ),
      ),
      SkipExerciseOperation(
        opId: opId,
        seq: 5,
        at: at,
        data: SkipExerciseData(
          exercisePerformanceId: exerciseId,
          exercisePrescriptionId: 51,
          comment: 'Machine unavailable',
        ),
      ),
      SubstituteExerciseOperation(
        opId: opId,
        seq: 6,
        at: at,
        data: SubstituteExerciseData(
          exercisePerformanceId: exerciseId,
          exercisePrescriptionId: 51,
          actualExerciseId: 140,
          source: SubstitutionSource.planVariant,
          variantOrdinal: 2,
        ),
      ),
      AddUnplannedExerciseOperation(
        opId: opId,
        seq: 7,
        at: at,
        data: AddUnplannedExerciseData(
          exercisePerformanceId: exerciseId,
          actualExerciseId: 160,
          performedOrdinal: 6,
        ),
      ),
      ReorderExercisesOperation(
        opId: opId,
        seq: 8,
        at: at,
        data: ReorderExercisesData(order: const <String>[exerciseId]),
      ),
      SetCursorOperation(
        opId: opId,
        seq: 9,
        at: at,
        data: SetCursorData(
          exercisePerformanceId: exerciseId,
          setOrdinal: 2,
          phase: PositionPhase.exerciseComplete,
        ),
      ),
      SetWorkoutCommentOperation(
        opId: opId,
        seq: 10,
        at: at,
        data: SetWorkoutCommentData(comment: 'Strong session'),
      ),
    ];
    final batch = OperationBatch(leaseEpoch: 1, baseSeq: 0, ops: operations);

    final json = batch.toJson();
    final decoded = OperationBatch.fromJson(json);

    expect(
      (json['ops']! as List<Object?>).map(
        (item) => (item! as Map<String, Object?>)['type'],
      ),
      <String>[
        'upsert_set',
        'skip_set',
        'clear_set',
        'set_exercise_comment',
        'skip_exercise',
        'substitute_exercise',
        'add_unplanned_exercise',
        'reorder_exercises',
        'set_cursor',
        'set_workout_comment',
      ],
    );
    expect(decoded.ops[0], isA<UpsertSetOperation>());
    expect(decoded.ops[1], isA<SkipSetOperation>());
    expect(decoded.ops[2], isA<ClearSetOperation>());
    expect(decoded.ops[3], isA<SetExerciseCommentOperation>());
    expect(decoded.ops[4], isA<SkipExerciseOperation>());
    expect(decoded.ops[5], isA<SubstituteExerciseOperation>());
    expect(decoded.ops[6], isA<AddUnplannedExerciseOperation>());
    expect(decoded.ops[7], isA<ReorderExercisesOperation>());
    expect(decoded.ops[8], isA<SetCursorOperation>());
    expect(decoded.ops[9], isA<SetWorkoutCommentOperation>());
  });

  test('additional set is an upsert with a null prescription reference', () {
    final data = UpsertSetData(
      setPerformanceId: setId,
      exercisePerformanceId: exerciseId,
      ordinal: 3,
      repetitions: 8,
      performedAt: at,
    );

    expect(data.toJson()['prescribed_set_id'], isNull);
    expect(data.toJson()['status'], 'performed');
  });

  test('batch rejects sequence gaps before transport', () {
    expect(
      () => OperationBatch(
        leaseEpoch: 1,
        baseSeq: 4,
        ops: <WorkoutOperation>[
          ClearSetOperation(
            opId: opId,
            seq: 6,
            at: at,
            data: ClearSetData(setPerformanceId: setId),
          ),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('reorder rejects duplicate identities', () {
    expect(
      () => ReorderExercisesData(order: const <String>[exerciseId, exerciseId]),
      throwsArgumentError,
    );
  });

  test(
    'duplicate is acknowledged while conflict and rejection stay consumed',
    () {
      final duplicate = OperationResult.fromJson(<String, Object?>{
        'seq': 1,
        'op_id': opId,
        'status': 'duplicate',
      });
      final conflict = OperationResult.fromJson(<String, Object?>{
        'seq': 2,
        'op_id': opId,
        'status': 'conflict',
        'entity_rev': 4,
        'server_state': <String, Object?>{'rev': 4},
      });

      expect(duplicate.isAcknowledged, isTrue);
      expect(conflict.isAcknowledged, isFalse);
      expect(conflict.isConsumed, isTrue);
      expect(conflict.serverState, <String, Object?>{'rev': 4});
    },
  );
}
