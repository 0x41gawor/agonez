import 'package:agonez/src/api/context_models.dart';
import 'package:agonez/src/features/you/you_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/today_fixtures.dart';

void main() {
  late TodayHarness harness;

  setUp(() {
    harness = TodayHarness();
    final settings = harness.settings;
    when(() => settings.compoundRestSeconds).thenReturn(135);
    when(() => settings.accessoryRestSeconds).thenReturn(90);
    when(() => settings.restNotificationsEnabled).thenReturn(true);
    when(() => settings.restSoundEnabled).thenReturn(false);
    when(() => settings.themeMode).thenReturn(ThemeMode.light);
  });
  tearDown(() => harness.dispose());

  testWidgets('shows the plan run the athlete chose, not the first active', (
    tester,
  ) async {
    // Two runs are active on the server; the athlete follows the second.
    when(harness.repository.listPlanRuns).thenAnswer(
      (_) async => const [
        PlanRunCompact(
          id: 14,
          name: 'Real RUN',
          status: 'active',
          startsOn: '2026-10-26',
          endsOn: '2026-11-22',
          microcycleCount: 4,
          currentMicrocycleOrdinal: 1,
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
    harness.stubContext((_) => workoutContext());

    await tester.pumpWidget(harness.app(const YouScreen()));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('you-plan-run'))).data,
      'Filip Majka',
    );
    expect(find.text('Real RUN'), findsNothing);
  });
}
