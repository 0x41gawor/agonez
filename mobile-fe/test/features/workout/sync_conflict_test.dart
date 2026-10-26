import 'package:agonez/src/features/workout/focus_workout_models.dart';
import 'package:agonez/src/features/workout/sync_conflict.dart';
import 'package:agonez/src/l10n/generated/app_localizations_en.dart';
import 'package:agonez/src/widgets/sync_status_pill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();
  final workout = FocusWorkoutViewModel(
    workoutId: 'workout-id',
    workoutUnitName: 'Legs',
    startedAt: DateTime.utc(2026, 10, 26, 17),
    exercises: const [
      FocusExerciseViewModel(
        id: 'extension',
        name: 'Leg extension',
        roleLabel: 'Isolation',
        plannedOrdinal: 3,
        performedOrdinal: 2,
        loadStepKg: 2.5,
        defaultRestSeconds: 90,
        sets: [
          FocusSetViewModel(
            id: 'extension-set-1',
            ordinal: 1,
            number: 2,
            status: FocusSetStatus.recorded,
          ),
        ],
      ),
    ],
    currentExerciseIndex: 0,
    currentSetIndex: 0,
    syncStatus: WorkoutSyncStatus.conflict,
    syncLabel: 'Conflict',
  );

  test('an exercise note reads as notes, not as the server row', () {
    final conflict = describeConflict(
      type: 'set_exercise_comment',
      data: const {
        'exercise_performance_id': 'extension',
        'exercise_prescription_id': 479,
        'comment': 'Seat on 6',
        'if_rev': 1,
      },
      serverState: const {
        'exercise_performance_id': 'extension',
        'exercise_prescription_id': 479,
        'performed_ordinal': 2,
        'mode': 'as_prescribed',
        'actual_exercise_id': 20,
        'comment': null,
        'rev': 5,
      },
      workout: workout,
      l10n: l10n,
    );

    expect(conflict.subject, 'Leg extension · Exercise note');
    expect(conflict.phone, 'Seat on 6');
    expect(conflict.server, 'No note');
  });

  test('a set reads as load, reps and RIR', () {
    final conflict = describeConflict(
      type: 'upsert_set',
      data: const {
        'set_performance_id': 'extension-set-1',
        'exercise_performance_id': 'extension',
        'load_kg': 17.5,
        'repetitions': 9,
        'rir': 4,
        'comment': 'knee ok',
      },
      // The server sends decimals as strings.
      serverState: const {
        'status': 'performed',
        'load_kg': '15.00',
        'repetitions': 9,
        'rir': 5,
        'comment': null,
        'rev': 2,
      },
      workout: workout,
      l10n: l10n,
    );

    expect(conflict.subject, 'Leg extension · Set 2');
    expect(conflict.phone, '17.5 kg × 9 @ RIR 4\nknee ok');
    expect(conflict.server, '15 kg × 9 @ RIR 5');
  });

  test('a set the server does not have reads as not recorded', () {
    final conflict = describeConflict(
      type: 'skip_set',
      data: const {
        'set_performance_id': 'extension-set-1',
        'exercise_performance_id': 'extension',
      },
      serverState: null,
      workout: workout,
      l10n: l10n,
    );

    expect(conflict.phone, 'Skipped');
    expect(conflict.server, 'Not recorded');
  });

  test('an unknown edit never shows raw data', () {
    final conflict = describeConflict(
      type: 'set_workout_comment',
      data: const {'comment': 'x'},
      serverState: const {'comment': 'y', 'rev': 3},
      workout: workout,
      l10n: l10n,
    );

    expect(conflict.subject, isNull);
    expect(conflict.phone, '—');
    expect(conflict.server, '—');
  });
}
