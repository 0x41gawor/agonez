import 'dart:async';
import 'dart:convert';

import 'package:agonez/src/api/prescription_models.dart';
import 'package:agonez/src/api/wire_enums.dart';
import 'package:agonez/src/features/workout/active_workout_focus_screen.dart';
import 'package:agonez/src/storage/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/today_fixtures.dart';
import '../../support/workout_fixtures.dart';

void main() {
  late TodayHarness harness;

  setUp(() => harness = TodayHarness());
  tearDown(() => harness.dispose());

  Widget focusApp() => harness.app(
    const SizedBox.shrink(),
    focus: const ActiveWorkoutFocusScreen(),
    initialLocation: '/focus',
  );

  testWidgets('waits for a just-started workout the stream has not shown', (
    tester,
  ) async {
    // The workout is in the database; the stream still reports none.
    harness.storedWorkout = startedLegs();

    await tester.pumpWidget(focusApp());
    // Enough frames for the stream's first value, a redirect and its route.
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Workout tab'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('leaves for the Workout tab when no workout is active', (
    tester,
  ) async {
    await tester.pumpWidget(focusApp());
    await tester.pumpAndSettle();

    expect(find.text('Workout tab'), findsOneWidget);
  });

  testWidgets('a summary already on its way is not overridden', (tester) async {
    // The workout finished and synced; the database read is still running.
    final read = Completer<LocalWorkout?>();
    when(harness.database.activeWorkout).thenAnswer((_) => read.future);
    await tester.pumpWidget(
      harness.app(
        const Scaffold(body: Text('Summary')),
        focus: const ActiveWorkoutFocusScreen(),
        initialLocation: '/focus',
      ),
    );
    await tester.pump();

    // The finish sends the athlete to the summary first.
    GoRouter.of(tester.element(find.byType(ActiveWorkoutFocusScreen))).go('/');
    await tester.pump();
    read.complete(null);
    await tester.pumpAndSettle();

    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('Workout tab'), findsNothing);
  });

  group('a running workout', () {
    PrescriptionSet planned(int ordinal, {String? loadSource}) =>
        PrescriptionSet(
          setPrescriptionId: 500 + ordinal,
          ordinal: ordinal,
          role: 'working',
          prescribedLoadKg: 24,
          repMin: 6,
          repMax: 8,
          targetRir: 2,
          comment: null,
          loadSource: loadSource,
        );
    PreviousSet lastTime(int ordinal, int reps) => PreviousSet(
      ordinal: ordinal,
      status: PerformedSetStatus.performed,
      loadKg: 24,
      repetitions: reps,
      rir: 2,
    );

    Future<void> openWorkout(
      WidgetTester tester, {
      String? loadSource = 'analysis',
    }) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      // Both the plan and last time number the sets from 0.
      final prescription = prescriptionWith(
        [
          planned(0, loadSource: loadSource),
          planned(1, loadSource: loadSource),
        ],
        history: ExerciseHistory(
          previousExposure: PreviousExposure(
            microcycleOrdinal: 1,
            performedOn: '2026-10-12',
            exercise: fixtureExercise,
            sets: [lastTime(0, 8), lastTime(1, 6)],
          ),
        ),
      );
      final workout = startedLegs().copyWith(
        prescriptionJson: jsonEncode(prescription.toJson()),
      );
      harness
        ..storedWorkout = workout
        ..streamWorkout(workout);
      when(() => harness.database.workoutExercises(any())).thenAnswer(
        (_) async => [
          LocalExercise(
            exercisePerformanceId: 'exercise-1',
            workoutId: workout.workoutId,
            exercisePrescriptionId:
                fixturePrescriptionExercise.exercisePrescriptionId,
            performedOrdinal: 0,
            mode: 'as_prescribed',
            serverRev: 0,
            localRev: 0,
            updatedAt: DateTime.utc(2026, 10, 19, 17),
          ),
        ],
      );
      await tester.pumpWidget(focusApp());
      for (var frame = 0; frame < 5; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('numbers sets from 1 by default', (tester) async {
      await openWorkout(tester);

      expect(find.text('1 · 24'), findsOneWidget);
      expect(find.text('2 · 24'), findsOneWidget);
      expect(find.text('PRESCRIBED · SET 1'), findsOneWidget);
    });

    testWidgets('numbers sets from 0 when the athlete chose so', (
      tester,
    ) async {
      harness.setNumberingStart = 0;
      await openWorkout(tester);

      expect(find.text('0 · 24'), findsOneWidget);
      expect(find.text('PRESCRIBED · SET 0'), findsOneWidget);
    });

    testWidgets('a load repeated from last session says so', (tester) async {
      await openWorkout(tester, loadSource: 'last_exposure');

      expect(find.text('Load from last session'), findsOneWidget);
    });

    testWidgets('an analysed load carries no such note', (tester) async {
      await openWorkout(tester);

      expect(find.text('Load from last session'), findsNothing);
    });

    testWidgets('last time shows the same set, not the next one', (
      tester,
    ) async {
      await openWorkout(tester);

      // The first set's previous performance was 24 × 8, not set two's 24 × 6.
      expect(find.text('24 × 8 @2'), findsOneWidget);
      expect(find.text('24 × 6 @2'), findsNothing);
    });
  });

  group('a workout of two exercises', () {
    setUpAll(() => registerFallbackValue(<String>[]));

    LocalExercise planned(
      String id,
      int prescriptionId,
      int ordinal, {
      String? comment,
    }) => LocalExercise(
      exercisePerformanceId: id,
      workoutId: startedLegs().workoutId,
      exercisePrescriptionId: prescriptionId,
      performedOrdinal: ordinal,
      mode: 'as_prescribed',
      comment: comment,
      serverRev: 0,
      localRev: 0,
      updatedAt: DateTime.utc(2026, 10, 26, 17),
    );

    Future<void> openWorkout(WidgetTester tester, {String? squatNote}) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final workout = startedLegs().copyWith(
        prescriptionJson: jsonEncode(twoExercisePrescription.toJson()),
      );
      harness
        ..storedWorkout = workout
        ..streamWorkout(workout);
      when(() => harness.database.workoutExercises(any())).thenAnswer(
        (_) async => [
          planned('squat', 222, 0, comment: squatNote),
          planned('leg-curl', 223, 1),
        ],
      );
      await tester.pumpWidget(focusApp());
      for (var frame = 0; frame < 5; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('doing the leg curl now postpones the squat to #2', (
      tester,
    ) async {
      when(
        () => harness.workoutRepository.startExerciseNow(
          workoutId: any(named: 'workoutId'),
          order: any(named: 'order'),
          exerciseIndex: any(named: 'exerciseIndex'),
        ),
      ).thenAnswer((_) async {});
      await openWorkout(tester);
      final workout = harness.storedWorkout!;

      await tester.tap(find.byKey(const Key('focus-outline')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Do now'));
      await tester.pumpAndSettle();
      // The plan numbers exercises from 0; the athlete reads them from 1.
      expect(
        find.textContaining('This exercise was planned #1 and moves to #2.'),
        findsOneWidget,
      );
      final hold = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('focus-hold-confirm'))),
      );
      await tester.pump(const Duration(milliseconds: 1050));
      await hold.up();
      await tester.pumpAndSettle();

      verify(
        () => harness.workoutRepository.startExerciseNow(
          workoutId: workout.workoutId,
          order: ['leg-curl', 'squat'],
          exerciseIndex: 0,
        ),
      ).called(1);
    });

    testWidgets('a note saved unchanged is not sent', (tester) async {
      await openWorkout(tester, squatNote: 'Seat on 6');

      await tester.tap(find.byKey(const Key('focus-actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Exercise note'));
      await tester.pumpAndSettle();
      expect(find.text('Seat on 6'), findsOneWidget);
      await tester.tap(find.text('Save note'));
      await tester.pumpAndSettle();

      verifyNever(
        () => harness.workoutRepository.setExerciseComment(
          workoutId: any(named: 'workoutId'),
          exercisePerformanceId: any(named: 'exercisePerformanceId'),
          exercisePrescriptionId: any(named: 'exercisePrescriptionId'),
          comment: any(named: 'comment'),
          ifRev: any(named: 'ifRev'),
        ),
      );
    });
  });
}
