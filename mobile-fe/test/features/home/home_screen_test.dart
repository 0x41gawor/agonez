import 'dart:async';

import 'package:agonez/src/api/context_models.dart';
import 'package:agonez/src/api/prescription_models.dart';
import 'package:agonez/src/api/prescription_preview.dart';
import 'package:agonez/src/api/wire_enums.dart';
import 'package:agonez/src/data/mobile_repository.dart';
import 'package:agonez/src/features/home/home_screen.dart';
import 'package:agonez/src/features/home/today_overview.dart';
import 'package:agonez/src/features/home/workout_unit_picker.dart';
import 'package:agonez/src/app/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/today_fixtures.dart';
import '../../support/workout_fixtures.dart';

void main() {
  late TodayHarness harness;

  setUpAll(() => registerFallbackValue(fixturePrescription));
  setUp(() => harness = TodayHarness());
  tearDown(() => harness.dispose());

  testWidgets('context refresh redraws the newly selected plan run', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    harness.selectedPlanRunId = 1;
    harness.stubContext(
      (planRunId) => planRunId == 2 ? workoutContext() : restDayContext(),
    );

    await tester.pumpWidget(harness.app(const HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('REST DAY'), findsOneWidget);
    expect(find.text('LEGS'), findsNothing);

    harness.selectedPlanRunId = 2;
    harness.contextRefreshes.add(1);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('LEGS'), findsOneWidget);
    expect(find.text('REST DAY'), findsNothing);
  });

  testWidgets('today lists its exercises and other units open a picker', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    harness.stubContext(
      (_) => workoutContext(
        alternatives: [missedPushA],
        microcycleDays: [legsDay],
        recent: [recentPushA],
      ),
    );

    await tester.pumpWidget(harness.app(const HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Barbell squat'), findsOneWidget);
    expect(find.text('1 × 6–8'), findsOneWidget);
    // Home also shows where the plan run stands.
    expect(find.text('MICROCYCLE 1 / 8'), findsOneWidget);
    expect(find.text('RECENT'), findsOneWidget);
    // The locked list of other units is gone; a picker link replaces it.
    expect(find.byIcon(Icons.lock_clock_outlined), findsNothing);
    expect(find.text('Push A'), findsOneWidget); // the recent row only

    await tester.tap(find.text('Train another workout-unit…'));
    await tester.pumpAndSettle();

    expect(find.text('Choose workout-unit'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(WorkoutUnitPickerSheet),
        matching: find.text('Push A'),
      ),
      findsOneWidget,
    );
    expect(find.text('Start LEGS'), findsOneWidget);
  });

  testWidgets('a newly selected run hides the old session until it loads', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final demoContext = Completer<MobileContext>();
    harness.stubContext(
      (planRunId) => planRunId == 1 ? demoContext.future : workoutContext(),
    );
    when(harness.repository.listPlanRuns).thenAnswer(
      (_) async => const [
        PlanRunCompact(
          id: 1,
          name: 'Execution Demo',
          status: 'active',
          startsOn: '2026-10-19',
          endsOn: '2026-12-13',
          microcycleCount: 8,
          currentMicrocycleOrdinal: 1,
        ),
      ],
    );
    when(() => harness.repository.selectPlanRun(1)).thenAnswer((_) async {
      harness.selectedPlanRunId = 1;
    });

    await tester.pumpWidget(harness.app(const HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('LEGS'), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-plan-run')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Execution Demo'));
    await tester.pumpAndSettle();

    // The old run's session is not left startable while the new one loads.
    expect(find.byType(TodaySkeleton), findsOneWidget);
    expect(find.text('LEGS'), findsNothing);
    expect(find.text('Start workout'), findsNothing);
    // The header already names the chosen run.
    expect(find.text('Execution Demo'), findsOneWidget);
    expect(find.text('Filip Majka'), findsNothing);

    demoContext.complete(restDayContext());
    await tester.pumpAndSettle();

    expect(find.text('REST DAY'), findsOneWidget);
  });

  testWidgets('a finished day says so instead of calling it a rest day', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    harness.stubContext(
      (_) => doneTodayContext(
        days: const [
          MicrocycleDay(
            date: '2026-10-19',
            dayOrdinal: 1,
            sessionId: 41,
            workoutUnitName: 'LEGS',
            status: 'completed',
          ),
          MicrocycleDay(
            date: '2026-10-20',
            dayOrdinal: 2,
            sessionId: 42,
            workoutUnitName: 'Chest + Back',
            status: 'scheduled',
          ),
        ],
        recent: [
          RecentWorkout(
            sessionId: 41,
            workoutUnitName: 'LEGS',
            completedAt: DateTime.utc(2026, 10, 19, 12),
            performedSets: 18,
            prescribedSets: 20,
            skippedSets: 2,
          ),
        ],
      ),
    );

    await tester.pumpWidget(harness.app(const HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('DONE FOR TODAY'), findsOneWidget);
    expect(find.textContaining('18 of 20 sets · finished'), findsOneWidget);
    expect(find.text('Chest + Back · tomorrow'), findsOneWidget);
    expect(find.text('REST DAY'), findsNothing);
  });

  testWidgets('a newer prescription than the one last seen is flagged', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    harness.stubContext((_) => workoutContext());
    PrescriptionSet set(int ordinal, double load) => PrescriptionSet(
      setPrescriptionId: 500 + ordinal,
      ordinal: ordinal,
      role: 'working',
      prescribedLoadKg: load,
      repMin: 6,
      repMax: 8,
      targetRir: 2,
      comment: null,
    );
    // The card last showed rx-40; analysis has since produced rx-41.
    when(
      () => harness.repository.loadPrescription(41, preferCache: true),
    ).thenAnswer(
      (_) async => LoadedValue(
        value: prescriptionWith([
          set(0, 80),
          set(1, 80),
          set(2, 65),
        ], version: 'rx-40'),
        fromCache: true,
      ),
    );
    when(() => harness.repository.loadPrescription(41)).thenAnswer(
      (_) async => LoadedValue(
        value: prescriptionWith([
          set(0, 80),
          set(1, 82.5),
          set(2, 67.5),
        ], version: 'rx-41'),
        fromCache: false,
      ),
    );

    await tester.pumpWidget(harness.app(const HomeScreen()));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        'Prescription changed: Barbell squat, set 2 · 80 → 82.5 kg (+1 more). '
        'The new version will be used.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a partly analysed session says how much is analysed', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    harness.stubContext(
      (_) => workoutContext(
        readiness: const PrescriptionReadiness(
          readiness: PrescriptionReadinessStatus.missing,
          exerciseCount: 4,
          setCount: 8,
          expectedExerciseCount: 8,
          expectedSetCount: 11,
        ),
      ),
    );

    await tester.pumpWidget(harness.app(const HomeScreen()));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Post-Workout-Analysis covers 4 of 8 exercises. The rest start from '
        'plan targets.',
      ),
      findsOneWidget,
    );
    expect(find.text('Start with plan targets'), findsOneWidget);
  });

  group('a session that is not ready', () {
    MobileContext partlyAnalysed() => workoutContext(
      readiness: const PrescriptionReadiness(
        readiness: PrescriptionReadinessStatus.missing,
        exerciseCount: 1,
        setCount: 3,
        expectedExerciseCount: 3,
        expectedSetCount: 8,
      ),
    );
    PreviewSet previewSet(double? load, String? source) => PreviewSet(
      role: 'working',
      repMin: 8,
      repMax: 10,
      loadKg: load,
      loadSource: source,
    );

    testWidgets('lists every exercise it would be prescribed', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      harness.stubContext((_) => partlyAnalysed());
      when(() => harness.repository.previewFallbackPrescription(41)).thenAnswer(
        (_) async => PrescriptionPreview(
          exercises: [
            PreviewExercise(
              ordinal: 0,
              name: 'Bench Press',
              generated: false,
              sets: [for (var i = 0; i < 3; i++) previewSet(68, 'analysis')],
            ),
            PreviewExercise(
              ordinal: 1,
              name: 'Cable Lateral Raise',
              generated: true,
              sets: [
                for (var i = 0; i < 2; i++) previewSet(19, 'last_exposure'),
              ],
            ),
            PreviewExercise(
              ordinal: 2,
              name: 'Barbell Curl',
              generated: true,
              sets: [for (var i = 0; i < 3; i++) previewSet(null, null)],
            ),
          ],
        ),
      );

      await tester.pumpWidget(harness.app(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Cable Lateral Raise'), findsOneWidget);
      expect(find.text('loads from last session'), findsOneWidget);
      expect(find.text('Barbell Curl'), findsOneWidget);
      expect(find.text('no loads yet'), findsOneWidget);
      // Listing is read-only; the plan targets are prepared only on Start.
      verifyNever(() => harness.repository.prepareFallbackPrescription(any()));
    });

    testWidgets('falls back to what the server holds without a preview', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      harness.stubContext((_) => partlyAnalysed());
      when(
        () => harness.repository.previewFallbackPrescription(41),
      ).thenThrow(StateError('offline'));

      await tester.pumpWidget(harness.app(const HomeScreen()));
      await tester.pumpAndSettle();

      // The analysed part, from the ordinary prescription read.
      expect(find.text('Barbell squat'), findsOneWidget);
    });
  });

  testWidgets('without a plan run the card offers to choose one', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    harness.selectedPlanRunId = null;
    harness.stubContext(
      (_) => MobileContext(
        generatedAt: DateTime.utc(2026, 10, 19, 8),
        contextVersion: 'none',
        planRun: null,
        selectionRequired: true,
        today: null,
        microcycleDays: const [],
        expectedSession: null,
        alternatives: const [],
        fallbacks: const [],
        activeWorkout: null,
        recent: const [],
      ),
    );
    when(harness.repository.listPlanRuns).thenAnswer(
      (_) async => const [
        PlanRunCompact(
          id: 2,
          name: 'Filip Majka',
          status: 'active',
          startsOn: '2026-10-19',
          endsOn: '2026-12-13',
          microcycleCount: 8,
          currentMicrocycleOrdinal: 1,
        ),
      ],
    );
    when(() => harness.repository.selectPlanRun(2)).thenAnswer((_) async {});

    await tester.pumpWidget(harness.app(const HomeScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Choose plan run'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filip Majka'));
    await tester.pumpAndSettle();

    verify(() => harness.repository.selectPlanRun(2)).called(1);
  });

  testWidgets('the header names the run the server settled on', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // Whatever is chosen, the server answers with Filip Majka, as it does
    // when the chosen run was deleted in the meantime.
    harness.stubContext((_) => workoutContext());
    when(harness.repository.listPlanRuns).thenAnswer(
      (_) async => const [
        PlanRunCompact(
          id: 1,
          name: 'Execution Demo',
          status: 'active',
          startsOn: '2026-09-01',
          endsOn: '2026-10-26',
          microcycleCount: 8,
          currentMicrocycleOrdinal: 8,
        ),
      ],
    );
    when(() => harness.repository.selectPlanRun(1)).thenAnswer((_) async {});

    await tester.pumpWidget(harness.app(const HomeScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-plan-run')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Execution Demo'));
    await tester.pumpAndSettle();

    final chip = find.byKey(const Key('home-plan-run'));
    expect(
      find.descendant(of: chip, matching: find.text('Filip Majka')),
      findsOneWidget,
    );
  });

  testWidgets('the header names the run and the sheet marks it', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    harness.stubContext((_) => workoutContext());
    when(harness.repository.listPlanRuns).thenAnswer(
      (_) async => const [
        PlanRunCompact(
          id: 1,
          name: 'Execution Demo',
          status: 'active',
          startsOn: '2026-09-01',
          endsOn: '2026-10-26',
          microcycleCount: 8,
          currentMicrocycleOrdinal: 8,
        ),
        PlanRunCompact(
          id: 2,
          name: 'Filip Majka',
          status: 'active',
          startsOn: '2026-10-19',
          endsOn: '2026-12-13',
          microcycleCount: 8,
          currentMicrocycleOrdinal: 1,
        ),
      ],
    );

    await tester.pumpWidget(harness.app(const HomeScreen()));
    await tester.pumpAndSettle();

    final chip = find.byKey(const Key('home-plan-run'));
    expect(
      find.descendant(of: chip, matching: find.text('Filip Majka')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: chip, matching: find.text('MC 1/8')),
      findsOneWidget,
    );

    await tester.tap(chip);
    await tester.pumpAndSettle();

    ListTile row(String name) => tester.widget<ListTile>(
      find.ancestor(
        of: find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text(name),
        ),
        matching: find.byType(ListTile),
      ),
    );
    expect(row('Filip Majka').selected, isTrue);
    expect(row('Execution Demo').selected, isFalse);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );

    // Choosing the current run again changes nothing.
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Filip Majka'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    verifyNever(() => harness.repository.selectPlanRun(any()));
  });

  testWidgets('a session without a prescription starts from plan targets', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    harness.stubContext((_) => workoutContext(prescribed: false));
    // The preview reads the prescription and is refused, as on the server.
    when(
      () => harness.repository.loadPrescription(
        any(),
        preferCache: any(named: 'preferCache'),
      ),
    ).thenThrow(StateError('prescription_missing'));
    when(() => harness.repository.prepareFallbackPrescription(41)).thenAnswer(
      (_) async => LoadedValue(value: fixturePrescription, fromCache: false),
    );
    when(
      () => harness.workoutRepository.start(
        prescription: any(named: 'prescription'),
        planRunId: any(named: 'planRunId'),
        allowMissingLoads: any(named: 'allowMissingLoads'),
      ),
    ).thenAnswer((_) async => 'workout-1');

    await tester.pumpWidget(harness.app(const HomeScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start with plan targets'));
    await tester.pumpAndSettle();

    verify(() => harness.repository.prepareFallbackPrescription(41)).called(1);
    verify(
      () => harness.workoutRepository.start(
        prescription: fixturePrescription,
        planRunId: 2,
        allowMissingLoads: true,
      ),
    ).called(1);
    expect(find.text('Focus'), findsOneWidget);
  });

  testWidgets('a start goes straight into the workout', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    harness.stubContext((_) => workoutContext());
    final started = Completer<String>();
    when(
      () => harness.workoutRepository.start(
        prescription: any(named: 'prescription'),
        planRunId: any(named: 'planRunId'),
        allowMissingLoads: any(named: 'allowMissingLoads'),
      ),
    ).thenAnswer((_) {
      // The new row reaches the database, and Home, before start returns.
      harness.streamWorkout(startedLegs());
      return started.future;
    });

    await tester.pumpWidget(harness.app(const HomeScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start workout'));
    await tester.pump();
    await tester.pump();

    // Home keeps the start card, still in progress, rather than flashing
    // its resume card on the way into the workout.
    expect(find.text('Resume workout'), findsNothing);
    expect(find.text('Start workout'), findsOneWidget);

    started.complete('workout-1');
    await tester.pump();
    // Mid-transition, Home leaves exactly as it was.
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 30));
      expect(find.text('Resume workout', skipOffstage: false), findsNothing);
    }
    await tester.pumpAndSettle();

    expect(find.text('Focus'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.text('Focus')),
    );
    expect(container.read(workoutLaunchProvider), isFalse);

    // Back on Home, the running workout is offered to resume.
    GoRouter.of(tester.element(find.text('Focus'))).go('/');
    await tester.pumpAndSettle();
    expect(find.text('Resume workout'), findsOneWidget);
  });

  testWidgets('the workout opens once the new workout can be shown', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    harness.stubContext((_) => workoutContext());
    // The start returns before the active-workout stream reports it.
    when(
      () => harness.workoutRepository.start(
        prescription: any(named: 'prescription'),
        planRunId: any(named: 'planRunId'),
        allowMissingLoads: any(named: 'allowMissingLoads'),
      ),
    ).thenAnswer((_) async => 'workout-1');

    await tester.pumpWidget(harness.app(const HomeScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start workout'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Focus'), findsNothing);

    harness.streamWorkout(startedLegs());
    // Promptly, well before the two-second fallback.
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Focus'), findsOneWidget);
  });
}
