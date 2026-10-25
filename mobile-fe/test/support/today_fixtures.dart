import 'dart:async';

import 'package:agonez/src/api/context_models.dart';
import 'package:agonez/src/api/wire_enums.dart';
import 'package:agonez/src/app/app_providers.dart';
import 'package:agonez/src/app/app_runtime.dart';
import 'package:agonez/src/data/mobile_repository.dart';
import 'package:agonez/src/design/design.dart';
import 'package:agonez/src/l10n/generated/app_localizations.dart';
import 'package:agonez/src/settings/app_settings_controller.dart';
import 'package:agonez/src/storage/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'workout_fixtures.dart';

class MockAppRuntime extends Mock implements AppRuntime {}

class MockMobileRepository extends Mock implements MobileRepository {}

class MockAppDatabase extends Mock implements AppDatabase {}

class MockAppSettingsController extends Mock implements AppSettingsController {}

/// A runtime for screens built on today's context: no active workout, plan
/// run 2 selected and [fixturePrescription] behind every session. Tests
/// stub `loadContext` themselves through [stubContext].
class TodayHarness {
  TodayHarness() {
    when(() => runtime.mobileRepository).thenReturn(repository);
    when(() => runtime.database).thenReturn(database);
    when(() => runtime.settings).thenReturn(settings);
    when(() => runtime.contextRefreshes).thenReturn(contextRefreshes);
    when(() => settings.locale).thenReturn(const Locale('en'));
    when(() => settings.hapticsEnabled).thenReturn(false);
    when(
      () => database.watchActiveWorkout(),
    ).thenAnswer((_) => Stream<LocalWorkout?>.value(null));
    when(database.activeWorkout).thenAnswer((_) async => null);
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
  final contextRefreshes = StreamController<int>.broadcast();
  int? selectedPlanRunId = 2;

  /// Answers context loads with [build] for the requested plan run.
  void stubContext(FutureOr<MobileContext> Function(int? planRunId) build) {
    when(
      () => repository.loadContext(
        planRunId: any(named: 'planRunId'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer(
      (invocation) async => LoadedValue(
        value: await build(invocation.namedArguments[#planRunId] as int?),
        fromCache: false,
      ),
    );
  }

  Widget app(Widget home) => ProviderScope(
    overrides: [appRuntimeProvider.overrideWithValue(runtime)],
    child: MaterialApp(
      theme: AgonezTheme.dark,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );

  Future<void> dispose() => contextRefreshes.close();
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

/// Plan run 2 with LEGS, a ready session, expected today.
MobileContext workoutContext({
  List<SessionSummary> alternatives = const [],
  List<MicrocycleDay> microcycleDays = const [],
  List<RecentWorkout> recent = const [],
}) => MobileContext(
  generatedAt: DateTime.utc(2026, 10, 19, 8, 1),
  contextVersion: 'run-2',
  planRun: contextPlanRun(id: 2, name: 'Filip Majka'),
  selectionRequired: false,
  today: const TodayPosition(date: '2026-10-19', microcycle: null),
  microcycleDays: microcycleDays,
  expectedSession: const SessionSummary(
    sessionId: 41,
    workoutUnitName: 'LEGS',
    workoutTrackId: 5,
    scheduledOn: '2026-10-19',
    status: 'scheduled',
    prescription: PrescriptionReadiness(
      readiness: PrescriptionReadinessStatus.ready,
      prescriptionVersion: 'rx-41',
      exerciseCount: 7,
      setCount: 20,
      estimatedDurationMin: 90,
    ),
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
