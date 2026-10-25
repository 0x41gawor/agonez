import 'package:agonez/src/features/workout/active_workout_focus_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/today_fixtures.dart';

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
}
