import 'package:agonez/src/api/atlas_models.dart';
import 'package:agonez/src/atlas/widgets/exercise_image.dart';
import 'package:agonez/src/features/workout/focus_mode_screen.dart';
import 'package:agonez/src/features/workout/focus_workout_models.dart';
import 'package:agonez/src/l10n/generated/app_localizations.dart';
import 'package:agonez/src/widgets/sync_status_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/workout_fixtures.dart';

void main() {
  testWidgets('common set path is reps, RIR, confirm with prescribed load', (
    tester,
  ) async {
    FocusSetSubmission? submission;
    await _pumpFocus(
      tester,
      _workout(),
      _callbacks(
        onConfirmSet: (value) async {
          submission = value;
        },
      ),
    );

    expect(find.byKey(const Key('focus-confirm')), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp(r'^6 repetitions')));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel(RegExp(r'^2 RIR')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('focus-confirm')));
    await tester.pump();

    expect(submission, isNotNull);
    expect(submission!.loadKg, 80);
    expect(submission!.repetitions, 6);
    expect(submission!.rir, 2);
  });

  testWidgets('exercise name opens the Atlas quick view with its photo', (
    tester,
  ) async {
    await _pumpFocus(
      tester,
      _workout(atlasPeek: fixtureAtlasPeek),
      _callbacks(),
    );

    await tester.tap(find.byKey(const Key('focus-exercise-name')));
    // The anatomy map keeps a progress indicator running while its asset
    // loads, so let the sheet animation finish instead of settling.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Brace before descending.'), findsOneWidget);
    // The fixture slug has no bundled photo, so the image collapses to zero
    // height and the list reports it as offstage.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ExerciseImage &&
            widget.slug == fixtureAtlasPeek.exercise.slug,
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });

  group('changing the order', () {
    testWidgets('an untouched exercise gives its slot to the one done now', (
      tester,
    ) async {
      final doneNow = <String>[];
      await _pumpFocus(
        tester,
        _squatThenLegCurl(),
        _callbacks(onDoNow: (exercise) async => doneNow.add(exercise.id)),
      );

      await tester.tap(find.byKey(const Key('focus-outline')));
      await tester.pumpAndSettle();
      expect(find.text('Do next'), findsNothing);
      await tester.tap(find.text('Do now'));
      await tester.pumpAndSettle();

      expect(find.text('Postpone Barbell squat'), findsOneWidget);
      expect(
        find.textContaining(
          'Leg curl takes its place now. This exercise was planned #1 and '
          'moves to #2.',
        ),
        findsOneWidget,
      );
      await _hold(tester);
      expect(doneNow, ['leg-curl']);
    });

    testWidgets('a started exercise keeps its slot; others can go next', (
      tester,
    ) async {
      final movedNext = <String>[];
      await _pumpFocus(
        tester,
        _squatThenLegCurl(squatStarted: true),
        _callbacks(
          onReorderExercise: (exercise) async => movedNext.add(exercise.id),
          onDoNow: (_) async => fail('a started exercise cannot be postponed'),
        ),
      );

      await tester.tap(find.byKey(const Key('focus-outline')));
      await tester.pumpAndSettle();
      expect(find.text('Do now'), findsNothing);
      await tester.tap(find.text('Do next'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('The planned order puts it at #2.'),
        findsOneWidget,
      );
      await _hold(tester);
      expect(movedNext, ['leg-curl']);
    });

    testWidgets('postpone hands the slot to the next exercise', (tester) async {
      final doneNow = <String>[];
      await _pumpFocus(
        tester,
        _squatThenLegCurl(),
        _callbacks(onDoNow: (exercise) async => doneNow.add(exercise.id)),
      );

      await _openPostpone(tester);
      await tester.tap(find.byKey(const Key('focus-postpone')));
      await tester.pumpAndSettle();
      await _hold(tester);

      expect(doneNow, ['leg-curl']);
    });

    testWidgets('postpone is locked once a set is recorded', (tester) async {
      await _pumpFocus(
        tester,
        _squatThenLegCurl(squatStarted: true),
        _callbacks(),
      );

      await _openPostpone(tester);

      final tile = tester.widget<ListTile>(
        find.descendant(
          of: find.byKey(const Key('focus-postpone')),
          matching: find.byType(ListTile),
        ),
      );
      expect(tile.enabled, isFalse);
      expect(find.text('Only before its first set.'), findsOneWidget);
    });

    testWidgets('there is nothing to postpone behind the last exercise', (
      tester,
    ) async {
      await _pumpFocus(tester, _workout(), _callbacks());

      await tester.tap(find.byKey(const Key('focus-actions')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('focus-postpone')), findsNothing);
    });
  });
}

Future<void> _openPostpone(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('focus-actions')));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byKey(const Key('focus-postpone')),
    100,
    scrollable: find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(Scrollable),
    ),
  );
}

Future<void> _hold(WidgetTester tester) async {
  final hold = await tester.startGesture(
    tester.getCenter(find.byKey(const Key('focus-hold-confirm'))),
  );
  await tester.pump(const Duration(milliseconds: 1050));
  await hold.up();
  await tester.pumpAndSettle();
}

Future<void> _pumpFocus(
  WidgetTester tester,
  FocusWorkoutViewModel workout,
  FocusWorkoutCallbacks callbacks,
) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: FocusModeScreen(
        workout: workout,
        callbacks: callbacks,
        now: () => DateTime.utc(2026, 10, 10, 17, 1),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

FocusWorkoutViewModel _workout({AtlasPeek? atlasPeek}) => FocusWorkoutViewModel(
  workoutId: 'workout-id',
  workoutUnitName: 'Legs',
  startedAt: DateTime.utc(2026, 10, 10, 17),
  exercises: [
    FocusExerciseViewModel(
      id: 'exercise-id',
      name: 'Barbell squat',
      roleLabel: 'Primary',
      plannedOrdinal: 1,
      performedOrdinal: 0,
      loadStepKg: 2.5,
      defaultRestSeconds: 180,
      atlasPeek: atlasPeek,
      sets: const [
        FocusSetViewModel(
          id: 'set-id',
          ordinal: 1,
          number: 1,
          status: FocusSetStatus.planned,
          prescribedSetId: 477,
          prescribedLoadKg: 80,
          repMin: 6,
          repMax: 8,
          targetRir: 2,
        ),
      ],
    ),
  ],
  currentExerciseIndex: 0,
  currentSetIndex: 0,
  syncStatus: WorkoutSyncStatus.saved,
  syncLabel: 'Saved',
);

/// Barbell squat planned first, leg curl second; the squat is current.
FocusWorkoutViewModel _squatThenLegCurl({bool squatStarted = false}) {
  FocusSetViewModel squatSet(int ordinal, {bool recorded = false}) =>
      FocusSetViewModel(
        id: 'squat-set-$ordinal',
        ordinal: ordinal,
        number: ordinal + 1,
        status: recorded ? FocusSetStatus.recorded : FocusSetStatus.planned,
        prescribedSetId: 477 + ordinal,
        prescribedLoadKg: 80,
        repMin: 6,
        repMax: 8,
        targetRir: 2,
        loadKg: recorded ? 80 : null,
        repetitions: recorded ? 7 : null,
        rir: recorded ? 2 : null,
      );
  return FocusWorkoutViewModel(
    workoutId: 'workout-id',
    workoutUnitName: 'Legs',
    startedAt: DateTime.utc(2026, 10, 10, 17),
    exercises: [
      FocusExerciseViewModel(
        id: 'squat',
        exercisePrescriptionId: 222,
        name: 'Barbell squat',
        roleLabel: 'Primary',
        plannedOrdinal: 1,
        performedOrdinal: 0,
        loadStepKg: 2.5,
        defaultRestSeconds: 180,
        sets: [
          squatSet(0, recorded: squatStarted),
          squatSet(1),
        ],
      ),
      const FocusExerciseViewModel(
        id: 'leg-curl',
        exercisePrescriptionId: 223,
        name: 'Leg curl',
        roleLabel: 'Isolation',
        plannedOrdinal: 2,
        performedOrdinal: 1,
        loadStepKg: 2.5,
        defaultRestSeconds: 90,
        sets: [
          FocusSetViewModel(
            id: 'leg-curl-set-0',
            ordinal: 0,
            number: 1,
            status: FocusSetStatus.planned,
            prescribedSetId: 600,
            prescribedLoadKg: 40,
            repMin: 10,
            repMax: 12,
            targetRir: 2,
          ),
        ],
      ),
    ],
    currentExerciseIndex: 0,
    currentSetIndex: squatStarted ? 1 : 0,
    syncStatus: WorkoutSyncStatus.saved,
    syncLabel: 'Saved',
  );
}

FocusWorkoutCallbacks _callbacks({
  Future<void> Function(FocusSetSubmission)? onConfirmSet,
  Future<void> Function(FocusExerciseViewModel)? onReorderExercise,
  Future<void> Function(FocusExerciseViewModel)? onDoNow,
}) => FocusWorkoutCallbacks(
  onMinimise: () {},
  onConfirmSet: onConfirmSet ?? (_) async {},
  onSkipSet: (_, _) async {},
  onAddExtraSet: (_) async {},
  onSkipExercise: (_) async {},
  onReorderExercise: onReorderExercise ?? (_) async {},
  onDoNow: onDoNow ?? (_) async {},
  onFinish: (_) async {},
);
