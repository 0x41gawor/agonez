import 'package:agonez/src/features/home/home_screen.dart';
import 'package:agonez/src/features/home/workout_unit_picker.dart';
import 'package:agonez/src/features/workout/workout_tab_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/today_fixtures.dart';

void main() {
  late TodayHarness harness;

  setUp(() {
    harness = TodayHarness()
      ..stubContext(
        (_) => workoutContext(
          alternatives: [missedPushA],
          microcycleDays: [legsDay],
          recent: [recentPushA],
        ),
      );
  });
  tearDown(() => harness.dispose());

  testWidgets('without a workout it offers today and other units only', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(harness.app(const WorkoutTabScreen()));
    await tester.pumpAndSettle();

    expect(find.text('LEGS'), findsOneWidget);
    expect(find.text('Start workout'), findsOneWidget);
    expect(find.text('Barbell squat'), findsOneWidget);
    expect(find.text('1 × 6–8'), findsOneWidget);
    // Where the plan run stands stays on Home.
    expect(find.text('MICROCYCLE 1 / 8'), findsNothing);
    expect(find.text('RECENT'), findsNothing);
    expect(find.text('Push A'), findsNothing);
    expect(
      find.text('Trends and Post-Workout-Analysis live on desktop.'),
      findsNothing,
    );

    await tester.tap(find.text('Train another workout-unit…'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(WorkoutUnitPickerSheet),
        matching: find.text('Push A'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Home and the Workout tab share one context load', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      harness.app(
        const Column(
          children: [
            Expanded(child: HomeScreen()),
            Expanded(child: WorkoutTabScreen()),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Start workout'), findsNWidgets(2));
    verify(
      () => harness.repository.loadSelectedContext(locale: 'en'),
    ).called(1);
  });
}
