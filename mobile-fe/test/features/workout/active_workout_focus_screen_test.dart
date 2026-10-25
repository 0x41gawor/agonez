import 'dart:async';

import 'package:agonez/src/features/workout/active_workout_focus_screen.dart';
import 'package:agonez/src/storage/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

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
}
