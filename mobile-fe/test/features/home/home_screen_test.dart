import 'dart:async';

import 'package:agonez/src/api/context_models.dart';
import 'package:agonez/src/api/wire_enums.dart';
import 'package:agonez/src/app/app_providers.dart';
import 'package:agonez/src/app/app_runtime.dart';
import 'package:agonez/src/data/mobile_repository.dart';
import 'package:agonez/src/design/design.dart';
import 'package:agonez/src/features/home/home_screen.dart';
import 'package:agonez/src/l10n/generated/app_localizations.dart';
import 'package:agonez/src/settings/app_settings_controller.dart';
import 'package:agonez/src/storage/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/workout_fixtures.dart';

class _MockAppRuntime extends Mock implements AppRuntime {}

class _MockMobileRepository extends Mock implements MobileRepository {}

class _MockAppDatabase extends Mock implements AppDatabase {}

class _MockAppSettingsController extends Mock
    implements AppSettingsController {}

void main() {
  testWidgets('context refresh redraws the newly selected plan run', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final runtime = _MockAppRuntime();
    final repository = _MockMobileRepository();
    final database = _MockAppDatabase();
    final settings = _MockAppSettingsController();
    final contextRefreshes = StreamController<int>.broadcast();
    addTearDown(contextRefreshes.close);
    var selectedPlanRunId = 1;

    when(() => runtime.mobileRepository).thenReturn(repository);
    when(() => runtime.database).thenReturn(database);
    when(() => runtime.settings).thenReturn(settings);
    when(() => runtime.contextRefreshes).thenReturn(contextRefreshes);
    when(() => settings.locale).thenReturn(const Locale('en'));
    when(() => settings.hapticsEnabled).thenReturn(false);
    _stubPrescriptionPreview(repository);
    when(
      () => database.watchActiveWorkout(),
    ).thenAnswer((_) => Stream<LocalWorkout?>.value(null));
    when(
      repository.selectedPlanRunId,
    ).thenAnswer((_) async => selectedPlanRunId);
    when(
      () => repository.loadContext(
        planRunId: any(named: 'planRunId'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((invocation) async {
      final planRunId = invocation.namedArguments[#planRunId] as int?;
      return LoadedValue(
        value: planRunId == 2 ? _workoutContext() : _restDayContext(),
        fromCache: false,
      );
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appRuntimeProvider.overrideWithValue(runtime)],
        child: MaterialApp(
          theme: AgonezTheme.dark,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('REST DAY'), findsOneWidget);
    expect(find.text('LEGS'), findsNothing);

    selectedPlanRunId = 2;
    contextRefreshes.add(1);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('LEGS'), findsOneWidget);
    expect(find.text('REST DAY'), findsNothing);
  });

  testWidgets('today lists its exercises and other units open a picker', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final runtime = _MockAppRuntime();
    final repository = _MockMobileRepository();
    final database = _MockAppDatabase();
    final settings = _MockAppSettingsController();
    final contextRefreshes = StreamController<int>.broadcast();
    addTearDown(contextRefreshes.close);
    when(() => runtime.mobileRepository).thenReturn(repository);
    when(() => runtime.database).thenReturn(database);
    when(() => runtime.settings).thenReturn(settings);
    when(() => runtime.contextRefreshes).thenReturn(contextRefreshes);
    when(() => settings.locale).thenReturn(const Locale('en'));
    when(() => settings.hapticsEnabled).thenReturn(false);
    when(
      () => database.watchActiveWorkout(),
    ).thenAnswer((_) => Stream<LocalWorkout?>.value(null));
    when(repository.selectedPlanRunId).thenAnswer((_) async => 2);
    when(
      () => repository.loadContext(
        planRunId: any(named: 'planRunId'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer(
      (_) async => LoadedValue(
        value: _workoutContext(alternatives: [_missedPushA]),
        fromCache: false,
      ),
    );
    _stubPrescriptionPreview(repository);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appRuntimeProvider.overrideWithValue(runtime)],
        child: MaterialApp(
          theme: AgonezTheme.dark,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Barbell squat'), findsOneWidget);
    expect(find.text('1 × 6–8'), findsOneWidget);
    // The locked list of other units is gone; a picker link replaces it.
    expect(find.byIcon(Icons.lock_clock_outlined), findsNothing);
    expect(find.text('Push A'), findsNothing);

    await tester.tap(find.text('Train another workout-unit…'));
    await tester.pumpAndSettle();

    expect(find.text('Choose workout-unit'), findsOneWidget);
    expect(find.text('Push A'), findsOneWidget);
    expect(find.text('Start LEGS'), findsOneWidget);
  });
}

const _missedPushA = SessionSummary(
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

void _stubPrescriptionPreview(_MockMobileRepository repository) {
  when(
    () => repository.loadPrescription(
      any(),
      preferCache: any(named: 'preferCache'),
    ),
  ).thenAnswer(
    (_) async => LoadedValue(value: fixturePrescription, fromCache: false),
  );
}

MobileContext _restDayContext() => MobileContext(
  generatedAt: DateTime.utc(2026, 10, 19, 8),
  contextVersion: 'run-1',
  planRun: _planRun(id: 1, name: 'Execution Demo'),
  selectionRequired: false,
  today: const TodayPosition(date: '2026-10-19', microcycle: null),
  microcycleDays: const [],
  expectedSession: null,
  alternatives: const [],
  fallbacks: const [],
  activeWorkout: null,
  recent: const [],
);

MobileContext _workoutContext({List<SessionSummary> alternatives = const []}) =>
    MobileContext(
      generatedAt: DateTime.utc(2026, 10, 19, 8, 1),
      contextVersion: 'run-2',
      planRun: _planRun(id: 2, name: 'Filip Majka'),
      selectionRequired: false,
      today: const TodayPosition(date: '2026-10-19', microcycle: null),
      microcycleDays: const [],
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
      recent: const [],
    );

ContextPlanRun _planRun({required int id, required String name}) =>
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
