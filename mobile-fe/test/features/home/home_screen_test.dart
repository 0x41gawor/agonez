import 'dart:async';

import 'package:agonez/src/api/context_models.dart';
import 'package:agonez/src/features/home/home_screen.dart';
import 'package:agonez/src/features/home/today_overview.dart';
import 'package:agonez/src/features/home/workout_unit_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/today_fixtures.dart';

void main() {
  late TodayHarness harness;

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

    await tester.tap(find.byIcon(Icons.layers_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Execution Demo'));
    await tester.pumpAndSettle();

    // The old run's session is not left startable while the new one loads.
    expect(find.byType(TodaySkeleton), findsOneWidget);
    expect(find.text('LEGS'), findsNothing);
    expect(find.text('Start workout'), findsNothing);

    demoContext.complete(restDayContext());
    await tester.pumpAndSettle();

    expect(find.text('REST DAY'), findsOneWidget);
  });
}
