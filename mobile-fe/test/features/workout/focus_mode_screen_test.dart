import 'package:agonez/src/features/workout/focus_mode_screen.dart';
import 'package:agonez/src/features/workout/focus_workout_models.dart';
import 'package:agonez/src/l10n/generated/app_localizations.dart';
import 'package:agonez/src/widgets/sync_status_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('common set path is reps, RIR, confirm with prescribed load', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    FocusSetSubmission? submission;
    final workout = FocusWorkoutViewModel(
      workoutId: 'workout-id',
      workoutUnitName: 'Legs',
      startedAt: DateTime.utc(2026, 10, 10, 17),
      exercises: const [
        FocusExerciseViewModel(
          id: 'exercise-id',
          name: 'Barbell squat',
          roleLabel: 'Primary',
          plannedOrdinal: 1,
          performedOrdinal: 0,
          loadStepKg: 2.5,
          defaultRestSeconds: 180,
          sets: [
            FocusSetViewModel(
              id: 'set-id',
              ordinal: 1,
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
    final callbacks = FocusWorkoutCallbacks(
      onMinimise: () {},
      onConfirmSet: (value) async {
        submission = value;
      },
      onSkipSet: (_, _) async {},
      onAddExtraSet: (_) async {},
      onSkipExercise: (_) async {},
      onReorderExercise: (_) async {},
      onFinish: (_) async {},
    );
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
}
