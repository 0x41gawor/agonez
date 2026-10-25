import 'package:agonez/src/app/app_providers.dart';
import 'package:agonez/src/app/navigation_shell.dart';
import 'package:agonez/src/design/design.dart';
import 'package:agonez/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/today_fixtures.dart';

void main() {
  late TodayHarness harness;

  setUp(() => harness = TodayHarness());
  tearDown(() => harness.dispose());

  Widget shell() => ProviderScope(
    overrides: [appRuntimeProvider.overrideWithValue(harness.runtime)],
    child: MaterialApp.router(
      theme: AgonezTheme.dark,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: GoRouter(
        initialLocation: '/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, _, navigationShell) =>
                AgonezNavigationShell(navigationShell: navigationShell),
            branches: [
              for (final path in ['/home', '/workout', '/atlas', '/you'])
                StatefulShellBranch(
                  routes: [
                    GoRoute(path: path, builder: (_, _) => const SizedBox()),
                  ],
                ),
            ],
          ),
        ],
      ),
    ),
  );

  String? workoutTabValue(WidgetTester tester) => tester
      .getSemantics(find.widgetWithText(NavigationDestination, 'Workout'))
      .value;

  testWidgets('the Workout tab says when a workout is running', (tester) async {
    await tester.pumpWidget(shell());
    await tester.pumpAndSettle();
    expect(workoutTabValue(tester), isEmpty);

    harness.streamWorkout(startedLegs());
    await tester.pumpAndSettle();

    expect(workoutTabValue(tester), 'active');
  });
}
