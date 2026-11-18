import 'dart:async';

import 'package:agonez/src/api/atlas_models.dart';
import 'package:agonez/src/atlas/widgets/exercise_image.dart';
import 'package:agonez/src/design/design.dart';
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

  group('the undo after a set', () {
    Future<void> confirmASet(WidgetTester tester) async {
      await tester.tap(find.bySemanticsLabel(RegExp(r'^6 repetitions')));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel(RegExp(r'^2 RIR')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('focus-confirm')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('is offered for a moment, not until dismissed', (tester) async {
      await _pumpFocus(
        tester,
        _workout(),
        _callbacks(onUndoSet: (_, _) async {}),
      );
      await confirmASet(tester);
      expect(find.text('Undo'), findsOneWidget);

      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();

      expect(find.text('Undo'), findsNothing);
    });

    testWidgets('does not follow the athlete off the screen', (tester) async {
      await _pumpFocus(
        tester,
        _workout(),
        _callbacks(onUndoSet: (_, _) async {}),
      );
      await confirmASet(tester);
      expect(find.text('Undo'), findsOneWidget);

      // Finishing replaces the workout with its summary.
      unawaited(
        tester
            .state<NavigatorState>(find.byType(Navigator))
            .pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Summary')),
              ),
            ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('Undo'), findsNothing);
    });
  });

  group('typing reps', () {
    Future<void> tapKeys(WidgetTester tester, String keys) async {
      for (final key in keys.split('')) {
        await tester.tap(find.byKey(Key('focus-rep-keypad-$key')));
        await tester.pump();
      }
    }

    String keypadValue(WidgetTester tester) => tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(const Key('focus-rep-keypad-value')),
            matching: find.byType(Text),
          ),
        )
        .data!;

    testWidgets('a count typed on the keypad can be corrected there', (
      tester,
    ) async {
      await _pumpFocus(tester, _workout(), _callbacks());

      await tester.tap(find.byKey(const Key('focus-reps-other')));
      await tester.pumpAndSettle();
      await tapKeys(tester, '12');
      await tester.tap(find.byKey(const Key('focus-rep-keypad-done')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('focus-reps-12')), findsOneWidget);

      // Tapping it again reopens the keypad with 12, which typing replaces.
      await tester.tap(find.byKey(const Key('focus-reps-12')));
      await tester.pumpAndSettle();
      expect(keypadValue(tester), '12');
      await tapKeys(tester, '13');
      expect(keypadValue(tester), '13');
      await tester.tap(find.byKey(const Key('focus-rep-keypad-done')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('focus-reps-13')), findsOneWidget);
      expect(find.byKey(const Key('focus-reps-12')), findsNothing);
    });

    testWidgets('the keypad takes no leading zero and no empty count', (
      tester,
    ) async {
      await _pumpFocus(tester, _workout(), _callbacks());

      await tester.tap(find.byKey(const Key('focus-reps-other')));
      await tester.pumpAndSettle();
      await tapKeys(tester, '0');

      expect(keypadValue(tester), '—');
      expect(
        tester
            .widget<AgonezPrimaryButton>(
              find.byKey(const Key('focus-rep-keypad-done')),
            )
            .onPressed,
        isNull,
      );

      await tapKeys(tester, '105');
      await tester.tap(find.byKey(const Key('focus-rep-keypad-backspace')));
      await tester.pump();
      expect(keypadValue(tester), '10');
    });

    testWidgets('the row covers the target, one below when it fits', (
      tester,
    ) async {
      await _pumpFocus(tester, _workout(repMin: 6, repMax: 8), _callbacks());
      for (final reps in [5, 6, 7, 8, 9]) {
        expect(find.byKey(Key('focus-reps-$reps')), findsOneWidget);
      }

      // 10–15 does not fit with one below: the row starts at the minimum.
      await _pumpFocus(tester, _workout(repMin: 10, repMax: 15), _callbacks());
      expect(find.byKey(const Key('focus-reps-9')), findsNothing);
      for (final reps in [10, 11, 12, 13, 14]) {
        expect(find.byKey(Key('focus-reps-$reps')), findsOneWidget);
      }
    });
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

  group('notes after an exercise', () {
    const squatSetup = FocusSetupNote(
      exerciseTrackId: 10,
      exerciseId: 18,
      text: 'Seat 2, K13',
    );

    Future<void> openOutline(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('focus-outline')));
      await tester.pumpAndSettle();
    }

    testWidgets('a finished exercise takes a note from the outline', (
      tester,
    ) async {
      FocusExerciseViewModel? noted;
      String? savedNote;
      await _pumpFocus(
        tester,
        _squatThenLegCurl(squatDone: true, squatSetup: squatSetup),
        _callbacks(
          onExerciseNoteChanged: (exercise, comment) async {
            noted = exercise;
            savedNote = comment;
          },
        ),
      );

      await openOutline(tester);
      await tester.tap(find.byKey(const Key('outline-note-squat')));
      await tester.pumpAndSettle();
      // The sheet names the exercise, which is no longer on screen.
      expect(find.textContaining('Barbell squat · '), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Knees caved on set 2');
      await tester.tap(find.text('Save note'));
      await tester.pumpAndSettle();

      expect(noted?.id, 'squat');
      expect(savedNote, 'Knees caved on set 2');
    });

    testWidgets('a finished exercise opens its setup from the outline', (
      tester,
    ) async {
      FocusExerciseViewModel? noted;
      String? savedText;
      await _pumpFocus(
        tester,
        _squatThenLegCurl(squatDone: true, squatSetup: squatSetup),
        _callbacks(
          onExerciseNoteChanged: (_, _) async {},
          onSetupNoteChanged: (exercise, text) async {
            noted = exercise;
            savedText = text;
          },
        ),
      );

      await openOutline(tester);
      await tester.tap(find.byKey(const Key('outline-setup-squat')));
      await tester.pumpAndSettle();
      expect(find.text('Seat 2, K13'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Seat 3, K13');
      await tester.tap(find.text('Save setup'));
      await tester.pumpAndSettle();

      expect(noted?.id, 'squat');
      expect(savedText, 'Seat 3, K13');
    });

    testWidgets('an exercise not finished offers no notes in the outline', (
      tester,
    ) async {
      await _pumpFocus(
        tester,
        _squatThenLegCurl(squatStarted: true, squatSetup: squatSetup),
        _callbacks(
          onExerciseNoteChanged: (_, _) async {},
          onSetupNoteChanged: (_, _) async {},
        ),
      );

      await openOutline(tester);

      // The squat is under way and the leg curl still ahead.
      expect(find.byKey(const Key('outline-note-squat')), findsNothing);
      expect(find.byKey(const Key('outline-setup-squat')), findsNothing);
      expect(find.byKey(const Key('outline-note-leg-curl')), findsNothing);
    });
  });

  group('my setup', () {
    const saved = FocusSetupNote(
      exerciseTrackId: 10,
      exerciseId: 18,
      text: 'Seat 2, K13',
    );

    testWidgets('opens the saved setup and saves an edit', (tester) async {
      String? savedText;
      await _pumpFocus(
        tester,
        _workout(setupNote: saved),
        _callbacks(onSetupNoteChanged: (_, text) async => savedText = text),
      );

      await tester.tap(find.byKey(const Key('focus-setup-note')));
      await tester.pumpAndSettle();
      expect(find.text('My setup'), findsOneWidget);
      expect(find.text('Seat 2, K13'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Seat 2, K14 ');
      await tester.tap(find.text('Save setup'));
      await tester.pumpAndSettle();

      expect(savedText, 'Seat 2, K14');
    });

    testWidgets('closing the setup without saving changes nothing', (
      tester,
    ) async {
      var calls = 0;
      await _pumpFocus(
        tester,
        _workout(setupNote: saved),
        _callbacks(onSetupNoteChanged: (_, _) async => calls++),
      );

      await tester.tap(find.byKey(const Key('focus-setup-note')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(195, 40));
      await tester.pumpAndSettle();

      expect(find.text('My setup'), findsNothing);
      expect(calls, 0);
    });

    testWidgets('an exercise without a slot has no setup', (tester) async {
      await _pumpFocus(
        tester,
        _workout(),
        _callbacks(onSetupNoteChanged: (_, _) async {}),
      );

      expect(find.byKey(const Key('focus-setup-note')), findsNothing);
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
  // A phone-sized view, so sheets sized from the screen height get a phone's.
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
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

FocusWorkoutViewModel _workout({
  AtlasPeek? atlasPeek,
  FocusSetupNote? setupNote,
  int repMin = 6,
  int repMax = 8,
}) => FocusWorkoutViewModel(
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
      setupNote: setupNote,
      sets: [
        FocusSetViewModel(
          id: 'set-id',
          ordinal: 1,
          number: 1,
          status: FocusSetStatus.planned,
          prescribedSetId: 477,
          prescribedLoadKg: 80,
          repMin: repMin,
          repMax: repMax,
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
/// With [squatDone], both squat sets are recorded and the leg curl is
/// current.
FocusWorkoutViewModel _squatThenLegCurl({
  bool squatStarted = false,
  bool squatDone = false,
  String? squatNote,
  FocusSetupNote? squatSetup,
}) {
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
        exerciseComment: squatNote,
        setupNote: squatSetup,
        sets: [
          squatSet(0, recorded: squatStarted || squatDone),
          squatSet(1, recorded: squatDone),
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
    currentExerciseIndex: squatDone ? 1 : 0,
    currentSetIndex: squatStarted && !squatDone ? 1 : 0,
    syncStatus: WorkoutSyncStatus.saved,
    syncLabel: 'Saved',
  );
}

FocusWorkoutCallbacks _callbacks({
  Future<void> Function(FocusSetSubmission)? onConfirmSet,
  Future<void> Function(FocusExerciseViewModel)? onReorderExercise,
  Future<void> Function(FocusExerciseViewModel)? onDoNow,
  Future<void> Function(FocusExerciseViewModel, FocusSetViewModel)? onUndoSet,
  Future<void> Function(FocusExerciseViewModel, String?)? onSetupNoteChanged,
  Future<void> Function(FocusExerciseViewModel, String?)? onExerciseNoteChanged,
}) => FocusWorkoutCallbacks(
  onMinimise: () {},
  onUndoSet: onUndoSet,
  onSetupNoteChanged: onSetupNoteChanged,
  onExerciseNoteChanged: onExerciseNoteChanged,
  onConfirmSet: onConfirmSet ?? (_) async {},
  onSkipSet: (_, _) async {},
  onAddExtraSet: (_) async {},
  onSkipExercise: (_) async {},
  onReorderExercise: onReorderExercise ?? (_) async {},
  onDoNow: onDoNow ?? (_) async {},
  onFinish: (_) async {},
);
