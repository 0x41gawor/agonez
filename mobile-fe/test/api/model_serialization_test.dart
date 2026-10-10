import 'package:agonez/src/api/api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prescription keeps unresolved load separate and nullable', () {
    final set = PrescriptionSet.fromJson(<String, Object?>{
      'set_prescription_id': 880301,
      'ordinal': 0,
      'role': 'working',
      'prescribed_load_kg': null,
      'rep_min': 5,
      'rep_max': 7,
      'target_rir': null,
      'comment': null,
    });

    expect(set.prescribedLoadKg, isNull);
    expect(set.toJson()['prescribed_load_kg'], isNull);
  });

  test('Atlas peek accepts sparse TLDR and actual anatomy metadata', () {
    final peek = AtlasPeek.fromJson(<String, Object?>{
      'exercise': <String, Object?>{
        'id': 112,
        'slug': 'flat_bench_barbell_press',
        'name': 'Bench Press',
      },
      'tags': <Object?>['Chest'],
      'technique_tldr': <String, Object?>{'setup': 'Brace.'},
      'muscles_top': <Object?>[],
      'body_map': <String, Object?>{
        'asset': 'anatomy.svg',
        'asset_version': 'v1',
        'regions': <Object?>[
          <String, Object?>{'region_id': 'pec_major_l', 'intensity': 0.8},
        ],
      },
      'content_locale': 'en',
      'atlas_version': '0.1',
    });

    expect(peek.exercise.fullName, isNull);
    expect(peek.techniqueTldr.execution, isNull);
    expect(peek.bodyMap.asset, 'anatomy.svg');
    expect(peek.bodyMap.assetVersion, 'v1');
  });

  test('mobile API added mode does not leak database additional enum', () {
    final exercise = ExercisePerformance.fromJson(<String, Object?>{
      'exercise_performance_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'exercise_prescription_id': null,
      'performed_ordinal': 4,
      'mode': 'added',
      'actual_exercise': null,
      'comment': null,
      'rev': 1,
      'sets': <Object?>[],
    });

    expect(exercise.mode, ExercisePerformanceMode.added);
    expect(exercise.toJson()['mode'], 'added');
  });

  test('start and finalize requests serialize protocol defaults', () {
    final startedAt = DateTime.utc(2026, 10, 9, 15, 29, 11);
    final start = StartWorkout(
      workoutId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      sessionId: 414,
      prescriptionVersion: 'rx-414-deadbeef1234',
      startedAt: startedAt,
    );
    final finish = FinalizeWorkout(
      leaseEpoch: 1,
      finalSeq: 41,
      finishedAt: startedAt.add(const Duration(hours: 1)),
      acknowledgedIncomplete: true,
    );

    expect(start.toJson()['allow_missing_loads'], isFalse);
    expect(start.toJson()['off_schedule'], isNull);
    expect(finish.toJson()['unrecorded'], 'mark_not_performed');
    expect(finish.toJson()['acknowledged_incomplete'], isTrue);
  });

  test('error envelope preserves stable code and arbitrary details', () {
    final envelope = ApiErrorEnvelope.fromJson(<String, Object?>{
      'error': <String, Object?>{
        'code': 'seq_gap',
        'message': 'A sequence is missing',
        'details': <String, Object?>{'expected_seq': 8},
      },
    });

    expect(envelope.error.code, 'seq_gap');
    expect(envelope.error.details['expected_seq'], 8);
  });
}
