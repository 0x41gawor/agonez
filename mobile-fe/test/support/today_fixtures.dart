import 'dart:async';

import 'package:agonez/src/api/agonez_api_client.dart';
import 'package:agonez/src/api/context_models.dart';
import 'package:agonez/src/api/wire_enums.dart';
import 'package:agonez/src/app/app_providers.dart';
import 'package:agonez/src/app/app_runtime.dart';
import 'package:agonez/src/data/mobile_repository.dart';
import 'package:agonez/src/features/workout/end_workout_launch.dart';
import 'package:agonez/src/design/design.dart';
import 'package:agonez/src/l10n/generated/app_localizations.dart';
import 'package:agonez/src/settings/app_settings_controller.dart';
import 'package:agonez/src/storage/app_database.dart';
import 'package:agonez/src/workout/workout_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'workout_fixtures.dart';

class MockAppRuntime extends Mock implements AppRuntime {}

class MockMobileRepository extends Mock implements MobileRepository {}

class MockAppDatabase extends Mock implements AppDatabase {}

class MockAppSettingsController extends Mock implements AppSettingsController {}

class MockWorkoutRepository extends Mock implements WorkoutRepository {}

class MockApiClient extends Mock implements AgonezApiClient {}

/// A runtime for screens built on today's context: no active workout, plan
/// run 2 selected and [fixturePrescription] behind every session. Tests
/// stub the context themselves through [stubContext].
class TodayHarness {
  TodayHarness() {
    when(() => runtime.mobileRepository).thenReturn(repository);
    when(() => runtime.database).thenReturn(database);
    when(() => runtime.workoutRepository).thenReturn(workoutRepository);
    when(() => runtime.api).thenReturn(api);
    when(() => runtime.settings).thenReturn(settings);
    when(() => runtime.contextRefreshes).thenReturn(contextRefreshes);
    when(() => settings.locale).thenReturn(const Locale('en'));
    when(() => settings.hapticsEnabled).thenReturn(false);
    when(() => database.watchActiveWorkout()).thenAnswer((_) async* {
      yield _streamedWorkout;
      yield* _activeWorkouts.stream;
    });
    when(database.activeWorkout).thenAnswer((_) async => storedWorkout);
    when(
      () => database.workoutExercises(any()),
    ).thenAnswer((_) async => const <LocalExercise>[]);
    when(
      () => database.watchWorkoutSets(any()),
    ).thenAnswer((_) => Stream.value(const <LocalSet>[]));
    when(
      repository.selectedPlanRunId,
    ).thenAnswer((_) async => selectedPlanRunId);
    when(
      () => repository.loadPrescription(
        any(),
        preferCache: any(named: 'preferCache'),
      ),
    ).thenAnswer(
      (_) async => LoadedValue(value: fixturePrescription, fromCache: false),
    );
  }

  final runtime = MockAppRuntime();
  final repository = MockMobileRepository();
  final database = MockAppDatabase();
  final settings = MockAppSettingsController();
  final workoutRepository = MockWorkoutRepository();
  final api = MockApiClient();
  final contextRefreshes = StreamController<int>.broadcast();
  int? selectedPlanRunId = 2;

  final _activeWorkouts = StreamController<LocalWorkout?>.broadcast();
  LocalWorkout? _streamedWorkout;

  /// What a direct database read of the active workout returns. The
  /// active-workout stream follows [streamWorkout] instead, so a test can
  /// let the stream lag behind the database.
  LocalWorkout? storedWorkout;

  /// Makes the active-workout stream report [workout].
  void streamWorkout(LocalWorkout? workout) {
    _streamedWorkout = workout;
    _activeWorkouts.add(workout);
  }

  /// Answers context loads with [build] for the selected plan run, read
  /// from [selectedPlanRunId] at load time.
  void stubContext(FutureOr<MobileContext> Function(int? planRunId) build) {
    when(
      () => repository.loadSelectedContext(locale: any(named: 'locale')),
    ).thenAnswer(
      (_) async =>
          LoadedValue(value: await build(selectedPlanRunId), fromCache: false),
    );
  }

  /// The app with [home] at `/`. `/focus` shows [focus], by default a
  /// placeholder titled Focus that ends a workout launch like the real
  /// workout screen, and `/workout` a placeholder titled Workout tab.
  Widget app(
    Widget home, {
    Widget focus = const EndWorkoutLaunchWhenShown(
      child: Scaffold(body: Text('Focus')),
    ),
    String initialLocation = '/',
  }) => ProviderScope(
    overrides: [appRuntimeProvider.overrideWithValue(runtime)],
    child: MaterialApp.router(
      theme: AgonezTheme.dark,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router(home, focus, initialLocation),
    ),
  );

  /// The app's routing in small: tabs in a stateful shell and the workout
  /// on the root navigator, so opening it replaces the shell, which leaves
  /// with an exit transition while the workout appears beneath it.
  static GoRouter _router(Widget home, Widget focus, String initialLocation) {
    final rootNavigator = GlobalKey<NavigatorState>();
    return GoRouter(
      navigatorKey: rootNavigator,
      initialLocation: initialLocation,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => shell,
          branches: [
            StatefulShellBranch(
              routes: [GoRoute(path: '/', builder: (_, _) => home)],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/workout',
                  builder: (_, _) => const Scaffold(body: Text('Workout tab')),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/focus',
          parentNavigatorKey: rootNavigator,
          builder: (_, _) => focus,
        ),
      ],
    );
  }

  Future<void> dispose() async {
    await contextRefreshes.close();
    // A paused listener would hold this close open; nothing awaits it.
    unawaited(_activeWorkouts.close());
  }
}

const missedPushA = SessionSummary(
  sessionId: 36,
  workoutUnitName: 'Push A',
  workoutTrackId: 1,
  scheduledOn: '2026-10-17',
  status: 'missed',
  prescription: PrescriptionReadiness(
    readiness: PrescriptionReadinessStatus.missing,
  ),
  relation: SessionRelation.earlierMissed,
);

MobileContext restDayContext() => MobileContext(
  generatedAt: DateTime.utc(2026, 10, 19, 8),
  contextVersion: 'run-1',
  planRun: contextPlanRun(id: 1, name: 'Execution Demo'),
  selectionRequired: false,
  today: const TodayPosition(date: '2026-10-19', microcycle: null),
  microcycleDays: const [],
  expectedSession: null,
  alternatives: const [],
  fallbacks: const [],
  activeWorkout: null,
  recent: const [],
);

/// Plan run 2 on 2026-10-19 with nothing left to start today.
MobileContext doneTodayContext({
  required List<MicrocycleDay> days,
  required List<RecentWorkout> recent,
}) => MobileContext(
  generatedAt: DateTime.utc(2026, 10, 19, 18),
  contextVersion: 'run-2-done',
  planRun: contextPlanRun(id: 2, name: 'Filip Majka'),
  selectionRequired: false,
  today: const TodayPosition(date: '2026-10-19', microcycle: null),
  microcycleDays: days,
  expectedSession: null,
  alternatives: const [],
  fallbacks: const [],
  activeWorkout: null,
  recent: recent,
);

/// Plan run 2 with LEGS expected today, prescribed unless [prescribed] is
/// false.
MobileContext workoutContext({
  List<SessionSummary> alternatives = const [],
  List<MicrocycleDay> microcycleDays = const [],
  List<RecentWorkout> recent = const [],
  bool prescribed = true,
  PrescriptionReadiness? readiness,
}) => MobileContext(
  generatedAt: DateTime.utc(2026, 10, 19, 8, 1),
  contextVersion: 'run-2',
  planRun: contextPlanRun(id: 2, name: 'Filip Majka'),
  selectionRequired: false,
  today: const TodayPosition(date: '2026-10-19', microcycle: null),
  microcycleDays: microcycleDays,
  expectedSession: SessionSummary(
    sessionId: 41,
    workoutUnitName: 'LEGS',
    workoutTrackId: 5,
    scheduledOn: '2026-10-19',
    status: 'scheduled',
    prescription:
        readiness ??
        (prescribed
            ? const PrescriptionReadiness(
                readiness: PrescriptionReadinessStatus.ready,
                prescriptionVersion: 'rx-41',
                exerciseCount: 7,
                setCount: 20,
                estimatedDurationMin: 90,
              )
            : const PrescriptionReadiness(
                readiness: PrescriptionReadinessStatus.missing,
                exerciseCount: 0,
                setCount: 0,
              )),
  ),
  alternatives: alternatives,
  fallbacks: const [],
  activeWorkout: null,
  recent: recent,
);

const legsDay = MicrocycleDay(
  date: '2026-10-19',
  dayOrdinal: 1,
  sessionId: 41,
  workoutUnitName: 'LEGS',
  status: 'scheduled',
);

final recentPushA = RecentWorkout(
  sessionId: 35,
  workoutUnitName: 'Push A',
  completedAt: DateTime.utc(2026, 10, 17, 18),
  performedSets: 18,
  prescribedSets: 20,
  skippedSets: 2,
);

ContextPlanRun contextPlanRun({required int id, required String name}) =>
    ContextPlanRun(
      id: id,
      name: name,
      status: 'active',
      startsOn: '2026-10-19',
      endsOn: '2026-12-13',
      microcycleCount: 8,
      currentMicrocycleOrdinal: 1,
      planName: name,
      microcycleDurationDays: 7,
    );

/// A just-started local workout for LEGS (session 41).
LocalWorkout startedLegs() => LocalWorkout(
  workoutId: 'workout-1',
  sessionId: 41,
  planRunId: 2,
  workoutUnitName: 'LEGS',
  lifecycle: 'pending_start',
  startedAt: DateTime.utc(2026, 10, 19, 17),
  prescriptionJson: '{}',
  startPayloadJson: '{}',
  leaseEpoch: 1,
  appliedSeq: 0,
  nextSeq: 1,
  revision: 0,
  currentExercise: 0,
  currentSet: 0,
  cursorPhase: 'set',
  syncState: 'saving',
  syncAttempts: 0,
  updatedAt: DateTime.utc(2026, 10, 19, 17),
);
