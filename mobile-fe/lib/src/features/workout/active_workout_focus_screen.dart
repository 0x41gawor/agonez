import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/atlas_models.dart';
import '../../api/conditional_response.dart';
import '../../api/prescription_models.dart';
import '../../api/wire_enums.dart';
import '../../api/workout_models.dart';
import '../../app/app_providers.dart';
import '../../app/app_runtime.dart';
import '../../design/design.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../storage/app_database.dart';
import '../../widgets/sync_status_pill.dart';
import 'focus_mode_screen.dart';
import 'focus_workout_models.dart';

/// Production route adapter for `/focus`.
///
/// The visual Focus widget stays independently testable while this layer maps
/// the frozen API prescription + Drift performance rows and wires local-first
/// repository operations.
class ActiveWorkoutFocusScreen extends ConsumerWidget {
  const ActiveWorkoutFocusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeWorkoutProvider);
    return active.when(
      loading: () => const _FocusLoading(),
      error: (_, _) => const _FocusLoadError(),
      data: (workout) {
        if (workout == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/workout');
          });
          return const _FocusLoading();
        }
        final exercises = ref.watch(
          workoutExercisesProvider(workout.workoutId),
        );
        final sets = ref.watch(workoutSetsProvider(workout.workoutId));
        if (exercises.hasError || sets.hasError) return const _FocusLoadError();
        final localExercises = exercises.value;
        final localSets = sets.value;
        if (localExercises == null || localSets == null) {
          return const _FocusLoading();
        }

        late final WorkoutPrescription prescription;
        try {
          prescription = WorkoutPrescription.fromJson(
            Map<String, Object?>.from(
              jsonDecode(workout.prescriptionJson) as Map,
            ),
          );
        } catch (_) {
          return const _FocusLoadError();
        }

        final viewModel = _mapWorkout(
          context,
          workout,
          prescription,
          localExercises,
          localSets,
        );
        final runtime = ref.watch(appRuntimeProvider);
        return FocusModeScreen(
          workout: viewModel,
          enableHaptics: runtime.settings.hapticsEnabled,
          callbacks: _callbacks(
            context,
            ref,
            runtime,
            workout,
            prescription,
            localExercises,
            viewModel,
          ),
        );
      },
    );
  }

  FocusWorkoutCallbacks _callbacks(
    BuildContext context,
    WidgetRef ref,
    AppRuntime runtime,
    LocalWorkout localWorkout,
    WorkoutPrescription prescription,
    List<LocalExercise> localExercises,
    FocusWorkoutViewModel model,
  ) {
    final repository = runtime.workoutRepository;
    final l10n = AppLocalizations.of(context);

    PrescriptionExercise? prescribedExercise(FocusExerciseViewModel exercise) {
      final id = exercise.exercisePrescriptionId;
      if (id == null) return null;
      return prescription.exercises
          .where((item) => item.exercisePrescriptionId == id)
          .firstOrNull;
    }

    LocalExercise localExercise(FocusExerciseViewModel exercise) =>
        localExercises.firstWhere(
          (item) => item.exercisePerformanceId == exercise.id,
        );

    Future<void> moveCursor({
      required int exerciseIndex,
      required int setIndex,
      required PositionPhase phase,
    }) async {
      final boundedExercise = exerciseIndex.clamp(
        0,
        model.exercises.length - 1,
      );
      final exercise = model.exercises[boundedExercise];
      await repository.setCursor(
        workoutId: model.workoutId,
        exercisePerformanceId: exercise.id,
        exerciseIndex: boundedExercise,
        setOrdinal: setIndex,
        phase: phase,
      );
    }

    return FocusWorkoutCallbacks(
      onMinimise: () => context.go('/home'),
      onConfirmSet: (submission) async {
        final exerciseIndex = model.currentExerciseIndex;
        final setIndex = model.currentSetIndex;
        final prescribed = prescribedExercise(submission.exercise);
        final nextSetIndex = setIndex + 1;
        final phase = nextSetIndex >= submission.exercise.sets.length
            ? PositionPhase.exerciseComplete
            : PositionPhase.set;
        if (prescribed == null) {
          await repository.confirmUnplannedSet(
            workoutId: model.workoutId,
            exercisePerformanceId: submission.exercise.id,
            ordinal: submission.set.ordinal,
            loadKg: submission.loadKg,
            repetitions: submission.repetitions,
            rir: submission.rir,
            setPerformanceId: submission.set.id.startsWith('draft:')
                ? null
                : submission.set.id,
            comment: submission.comment,
            heartRateBpm: submission.heartRateBpm,
            ifRev: submission.set.isRecorded
                ? submission.set.localRevision
                : null,
            restSeconds: submission.restDurationSeconds,
            performedAt: submission.performedAt,
          );
        } else {
          final prescribedSet = submission.set.prescribedSetId == null
              ? null
              : prescribed.sets
                    .where(
                      (item) =>
                          item.setPrescriptionId ==
                          submission.set.prescribedSetId,
                    )
                    .firstOrNull;
          await repository.confirmSet(
            workoutId: model.workoutId,
            exercise: prescribed,
            prescribedSet: prescribedSet,
            ordinal: submission.set.ordinal,
            loadKg: submission.loadKg,
            repetitions: submission.repetitions,
            rir: submission.rir,
            setPerformanceId:
                submission.set.prescribedSetId == null &&
                    !submission.set.id.startsWith('draft:')
                ? submission.set.id
                : null,
            comment: submission.comment,
            heartRateBpm: submission.heartRateBpm,
            ifRev: submission.set.isRecorded
                ? submission.set.localRevision
                : null,
            nextExerciseIndex: exerciseIndex,
            nextSetIndex: nextSetIndex,
            performedAt: submission.performedAt,
            restSeconds: submission.restDurationSeconds,
          );
        }
        await moveCursor(
          exerciseIndex: exerciseIndex,
          setIndex: nextSetIndex,
          phase: phase,
        );
        unawaited(
          _scheduleRestNotification(
            runtime,
            model,
            l10n,
            submission.performedAt.add(
              Duration(seconds: submission.restDurationSeconds),
            ),
            exerciseIndex,
            nextSetIndex,
          ),
        );
      },
      onDraftChanged: (draft) => runtime.database.setWorkoutCursor(
        workoutId: model.workoutId,
        exerciseIndex: model.currentExerciseIndex,
        setIndex: model.currentSetIndex,
        phase: localWorkout.cursorPhase,
        draftJson: jsonEncode(<String, Object?>{
          'load_kg': draft.loadKg,
          'repetitions': draft.repetitions,
          'rir': draft.rir,
          'comment': draft.comment,
          'heart_rate_bpm': draft.heartRateBpm,
          'carried_from_last_set': draft.carriedFromLastSet,
        }),
      ),
      onSkipSet: (exercise, set) async {
        final prescribed = prescribedExercise(exercise);
        if (prescribed == null || set.prescribedSetId == null) return;
        final prescribedSet = prescribed.sets.firstWhere(
          (item) => item.setPrescriptionId == set.prescribedSetId,
        );
        final next = model.currentSetIndex + 1;
        final phase = next >= exercise.sets.length
            ? PositionPhase.exerciseComplete
            : PositionPhase.set;
        await repository.skipSet(
          workoutId: model.workoutId,
          exercise: prescribed,
          set: prescribedSet,
          nextExerciseIndex: model.currentExerciseIndex,
          nextSetIndex: next,
        );
        await moveCursor(
          exerciseIndex: model.currentExerciseIndex,
          setIndex: next,
          phase: phase,
        );
      },
      onAddExtraSet: (exercise) => moveCursor(
        exerciseIndex: model.currentExerciseIndex,
        setIndex: exercise.sets.length,
        phase: PositionPhase.set,
      ),
      onSkipExercise: (exercise) async {
        final prescribed = prescribedExercise(exercise);
        if (prescribed == null) return;
        await repository.skipExercise(
          workoutId: model.workoutId,
          exercisePerformanceId: exercise.id,
          exercisePrescriptionId: prescribed.exercisePrescriptionId,
          ifRev: localExercise(exercise).localRev,
        );
        final next = math.min(
          model.currentExerciseIndex + 1,
          model.exercises.length - 1,
        );
        await moveCursor(
          exerciseIndex: next,
          setIndex: 0,
          phase: PositionPhase.set,
        );
        ref.invalidate(workoutExercisesProvider(model.workoutId));
      },
      onReorderExercise: (exercise) async {
        final order = model.exercises.map((item) => item.id).toList();
        order.remove(exercise.id);
        order.insert(
          math.min(model.currentExerciseIndex + 1, order.length),
          exercise.id,
        );
        await repository.reorderExercises(
          workoutId: model.workoutId,
          order: order,
        );
        ref.invalidate(workoutExercisesProvider(model.workoutId));
      },
      onCursorChanged: (exerciseIndex, setIndex) => moveCursor(
        exerciseIndex: exerciseIndex,
        setIndex: setIndex,
        phase: PositionPhase.set,
      ),
      onRestChanged: (endsAt, duration) async {
        await runtime.database.setRestTimer(
          workoutId: model.workoutId,
          endsAt: endsAt,
          durationSeconds: duration,
        );
        if (endsAt == null) {
          await runtime.notifications.cancel();
        } else {
          await _scheduleRestNotification(
            runtime,
            model,
            l10n,
            endsAt,
            model.currentExerciseIndex,
            model.currentSetIndex,
          );
        }
      },
      onUndoSet: (exercise, set) async {
        await repository.clearSet(
          workoutId: model.workoutId,
          setPerformanceId: set.id,
          ifRev: set.localRevision,
        );
        await runtime.notifications.cancel();
        await moveCursor(
          exerciseIndex: model.currentExerciseIndex,
          setIndex: math.max(0, set.ordinal - 1),
          phase: PositionPhase.set,
        );
      },
      onEditSet: (edit) async {
        final prescribed = prescribedExercise(edit.exercise);
        final currentRestEndsAt = model.restEndsAt;
        final currentRestDuration = model.restDurationSeconds;
        if (prescribed == null) {
          await repository.confirmUnplannedSet(
            workoutId: model.workoutId,
            exercisePerformanceId: edit.exercise.id,
            ordinal: edit.set.ordinal,
            loadKg: edit.loadKg,
            repetitions: edit.repetitions,
            rir: edit.rir,
            setPerformanceId: edit.set.id,
            comment: edit.comment,
            heartRateBpm: edit.heartRateBpm,
            ifRev: edit.set.localRevision,
            restSeconds: 0,
          );
        } else {
          final prescribedSet = edit.set.prescribedSetId == null
              ? null
              : prescribed.sets
                    .where(
                      (item) =>
                          item.setPrescriptionId == edit.set.prescribedSetId,
                    )
                    .firstOrNull;
          await repository.confirmSet(
            workoutId: model.workoutId,
            exercise: prescribed,
            prescribedSet: prescribedSet,
            ordinal: edit.set.ordinal,
            loadKg: edit.loadKg,
            repetitions: edit.repetitions,
            rir: edit.rir,
            setPerformanceId: edit.set.id,
            comment: edit.comment,
            heartRateBpm: edit.heartRateBpm,
            ifRev: edit.set.localRevision,
            nextExerciseIndex: model.currentExerciseIndex,
            nextSetIndex: model.currentSetIndex,
            restSeconds: 0,
          );
        }
        await runtime.database.setRestTimer(
          workoutId: model.workoutId,
          endsAt: currentRestEndsAt,
          durationSeconds: currentRestDuration,
        );
      },
      onExerciseNoteChanged: (exercise, comment) async {
        final local = localExercise(exercise);
        await repository.setExerciseComment(
          workoutId: model.workoutId,
          exercisePerformanceId: exercise.id,
          exercisePrescriptionId: exercise.exercisePrescriptionId,
          comment: comment,
          ifRev: local.localRev,
        );
        ref.invalidate(workoutExercisesProvider(model.workoutId));
      },
      pickSubstitute: (exercise) => _showExercisePicker(
        context,
        runtime,
        planRunId: localWorkout.planRunId,
        alternatives: prescribedExercise(exercise)?.alternatives,
      ),
      onSubstitute: (exercise, replacement) async {
        final prescribed = prescribedExercise(exercise);
        if (prescribed == null) return;
        await repository.substituteExercise(
          workoutId: model.workoutId,
          exercisePerformanceId: exercise.id,
          exercisePrescriptionId: prescribed.exercisePrescriptionId,
          actualExercise: ExerciseIdentity(
            id: replacement.exerciseId,
            slug: replacement.slug,
            name: replacement.name,
            fullName: replacement.fullName,
          ),
          source: replacement.planAlternative
              ? SubstitutionSource.planVariant
              : SubstitutionSource.atlas,
          variantOrdinal: replacement.variantOrdinal,
          ifRev: localExercise(exercise).localRev,
        );
        ref.invalidate(workoutExercisesProvider(model.workoutId));
      },
      pickUnplannedExercise: (exercise) => _showExercisePicker(
        context,
        runtime,
        planRunId: localWorkout.planRunId,
      ),
      onAddUnplannedExercise: (choice) async {
        final addedId = await repository.addUnplannedExercise(
          workoutId: model.workoutId,
          actualExercise: ExerciseIdentity(
            id: choice.exerciseId,
            slug: choice.slug,
            name: choice.name,
            fullName: choice.fullName,
          ),
          performedOrdinal: model.exercises.length,
        );
        final order = model.exercises.map((item) => item.id).toList();
        order.insert(
          math.min(model.currentExerciseIndex + 1, order.length),
          addedId,
        );
        await repository.reorderExercises(
          workoutId: model.workoutId,
          order: order,
        );
        ref.invalidate(workoutExercisesProvider(model.workoutId));
      },
      onOpenFullAtlas: () {
        final slug = model.currentExercise.slug;
        if (slug != null) {
          context.push('/atlas/article/${Uri.encodeComponent(slug)}');
        } else {
          context.go('/atlas');
        }
      },
      onSyncDetails: () =>
          unawaited(_showSyncSheet(context, runtime, localWorkout, model)),
      onResumeHere: () async {
        await runtime.workoutRecoveryRepository.claim(model.workoutId);
        runtime.syncEngine.kick();
        ref.invalidate(workoutExercisesProvider(model.workoutId));
      },
      onFinish: (acknowledgedIncomplete) async {
        await repository.finish(
          workoutId: model.workoutId,
          acknowledgedIncomplete: acknowledgedIncomplete,
        );
        await runtime.notifications.cancel();
        runtime.syncEngine.kick();
        if (context.mounted) context.go('/recorded/${model.workoutId}');
      },
    );
  }

  FocusWorkoutViewModel _mapWorkout(
    BuildContext context,
    LocalWorkout workout,
    WorkoutPrescription prescription,
    List<LocalExercise> localExercises,
    List<LocalSet> localSets,
  ) {
    final l10n = AppLocalizations.of(context);
    final ordered = [...localExercises]
      ..sort((a, b) => a.performedOrdinal.compareTo(b.performedOrdinal));
    final prescriptionById = <int, PrescriptionExercise>{
      for (final exercise in prescription.exercises)
        exercise.exercisePrescriptionId: exercise,
    };
    final exerciseModels = <FocusExerciseViewModel>[];
    for (var index = 0; index < ordered.length; index++) {
      final local = ordered[index];
      final prescribed = local.exercisePrescriptionId == null
          ? null
          : prescriptionById[local.exercisePrescriptionId!];
      final performanceSets =
          localSets
              .where(
                (set) =>
                    set.exercisePerformanceId == local.exercisePerformanceId,
              )
              .toList()
            ..sort((a, b) => a.ordinal.compareTo(b.ordinal));
      final actual = _decodeExercise(local.actualExerciseJson);
      final skippedExercise = local.mode == 'skipped';
      final sets = <FocusSetViewModel>[];
      if (prescribed != null) {
        for (final target in prescribed.sets) {
          final observed = performanceSets
              .where((set) => set.prescribedSetId == target.setPrescriptionId)
              .firstOrNull;
          sets.add(
            _mapSet(observed, target: target, forceSkipped: skippedExercise),
          );
        }
      }
      for (final observed in performanceSets.where(
        (set) => set.prescribedSetId == null,
      )) {
        sets.add(_mapSet(observed, extra: true));
      }
      final isCurrent = index == workout.currentExercise;
      if (prescribed == null && sets.isEmpty) {
        sets.add(
          FocusSetViewModel(
            id: 'draft:${local.exercisePerformanceId}:1',
            ordinal: 1,
            status: FocusSetStatus.planned,
            isExtra: true,
          ),
        );
      } else if (isCurrent &&
          workout.cursorPhase == 'set' &&
          workout.currentSet >= sets.length) {
        sets.add(
          FocusSetViewModel(
            id: 'draft:${local.exercisePerformanceId}:${sets.length + 1}',
            ordinal: sets.length + 1,
            status: FocusSetStatus.planned,
            isExtra: true,
          ),
        );
      }
      final previous = prescribed?.history.previousExposure;
      final previousOrdinal = workout.currentSet.clamp(0, sets.length - 1) + 1;
      final previousSet = previous?.sets
          .where((item) => item.ordinal == previousOrdinal)
          .firstOrNull;
      exerciseModels.add(
        FocusExerciseViewModel(
          id: local.exercisePerformanceId,
          exercisePrescriptionId: local.exercisePrescriptionId,
          exerciseId: actual?.id ?? prescribed?.exercise.id,
          slug: actual?.slug ?? prescribed?.exercise.slug,
          name:
              actual?.name ??
              prescribed?.exercise.name ??
              '#${local.actualExerciseId ?? local.exercisePerformanceId}',
          fullName: actual?.fullName ?? prescribed?.exercise.fullName,
          prescribedName: prescribed?.exercise.name,
          roleLabel: _roleLabel(l10n, prescribed?.slot.role),
          plannedOrdinal: prescribed?.ordinal ?? local.performedOrdinal + 1,
          performedOrdinal: local.performedOrdinal,
          mode: switch (local.mode) {
            'substituted' => FocusExerciseMode.substituted,
            'added' || 'unplanned' => FocusExerciseMode.unplanned,
            _ => FocusExerciseMode.asPrescribed,
          },
          variantLabel: prescribed?.variantLabel,
          planNote: prescribed?.planComment,
          prescriptionComment: prescribed?.prescriptionComment,
          exerciseComment: local.comment,
          loadStepKg: prescribed?.loadStepKg ?? 2.5,
          defaultRestSeconds: prescribed?.defaultRestS ?? 90,
          sets: sets,
          previousSet: previous == null || previousSet == null
              ? null
              : FocusPreviousSetViewModel(
                  microcycleOrdinal: previous.microcycleOrdinal,
                  loadKg: previousSet.loadKg,
                  repetitions: previousSet.repetitions,
                  rir: previousSet.rir,
                ),
          atlasPeek: prescribed?.atlasPeek,
          orderChanged:
              prescribed != null &&
              local.performedOrdinal != prescribed.ordinal,
        ),
      );
    }
    final exerciseIndex = workout.currentExercise
        .clamp(0, math.max(0, exerciseModels.length - 1))
        .toInt();
    final currentSets = exerciseModels[exerciseIndex].sets;
    final setIndex = workout.cursorPhase == 'exercise_complete'
        ? currentSets.length
        : workout.currentSet
              .clamp(0, math.max(0, currentSets.length - 1))
              .toInt();
    final pending = math.max(0, workout.nextSeq - workout.appliedSeq - 1);
    return FocusWorkoutViewModel(
      workoutId: workout.workoutId,
      workoutUnitName: workout.workoutUnitName,
      startedAt: workout.startedAt,
      exercises: exerciseModels,
      currentExerciseIndex: exerciseIndex,
      currentSetIndex: setIndex,
      syncStatus: _syncStatus(workout.syncState),
      syncLabel: _syncLabel(l10n, workout.syncState, pending),
      pendingOperationCount: pending,
      entryDraft: _decodeDraft(workout.entryDraftJson),
      restEndsAt: workout.restEndsAt,
      restDurationSeconds: workout.restDurationS,
      readOnly: workout.syncState == 'superseded',
    );
  }

  FocusSetViewModel _mapSet(
    LocalSet? observed, {
    PrescriptionSet? target,
    bool extra = false,
    bool forceSkipped = false,
  }) {
    final status = forceSkipped || observed?.status == 'skipped'
        ? FocusSetStatus.skipped
        : observed == null
        ? FocusSetStatus.planned
        : FocusSetStatus.recorded;
    return FocusSetViewModel(
      id:
          observed?.setPerformanceId ??
          'prescribed:${target!.setPrescriptionId}',
      ordinal: observed?.ordinal ?? target!.ordinal,
      status: status,
      prescribedSetId: target?.setPrescriptionId,
      prescribedLoadKg: target?.prescribedLoadKg,
      repMin: target?.repMin,
      repMax: target?.repMax,
      targetRir: target?.targetRir,
      prescriptionComment: target?.comment,
      loadKg: observed?.loadKg,
      repetitions: observed?.repetitions,
      rir: observed?.rir,
      comment: observed?.comment,
      heartRateBpm: observed?.heartRateBpm,
      localRevision: observed?.localRev ?? 0,
      isExtra: extra,
    );
  }

  ExerciseIdentity? _decodeExercise(String? json) {
    if (json == null) return null;
    try {
      return ExerciseIdentity.fromJson(
        Map<String, Object?>.from(jsonDecode(json) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  FocusEntryDraft? _decodeDraft(String? json) {
    if (json == null) return null;
    try {
      final value = Map<String, Object?>.from(jsonDecode(json) as Map);
      return FocusEntryDraft(
        loadKg: (value['load_kg'] as num?)?.toDouble(),
        repetitions: value['repetitions'] as int?,
        rir: value['rir'] as int?,
        comment: value['comment'] as String?,
        heartRateBpm: value['heart_rate_bpm'] as int?,
        carriedFromLastSet: value['carried_from_last_set'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  String _roleLabel(AppLocalizations l10n, String? role) => switch (role) {
    'primary_progressive' => l10n.workoutRolePrimaryProgressive,
    'secondary_compound' => l10n.workoutRoleSecondaryCompound,
    _ => l10n.workoutRoleIsolation,
  };

  WorkoutSyncStatus _syncStatus(String state) => switch (state) {
    'saving' => WorkoutSyncStatus.saving,
    'offline' => WorkoutSyncStatus.offline,
    'failed' || 'recovery_required' => WorkoutSyncStatus.failed,
    'conflict' => WorkoutSyncStatus.conflict,
    'superseded' => WorkoutSyncStatus.superseded,
    _ => WorkoutSyncStatus.saved,
  };

  String _syncLabel(AppLocalizations l10n, String state, int pending) =>
      switch (state) {
        'saving' => l10n.syncSaving,
        'offline' => l10n.syncOfflineCount(pending),
        'failed' || 'recovery_required' => l10n.syncFailed,
        'conflict' => l10n.syncConflict,
        'superseded' => l10n.syncSuperseded,
        _ => l10n.syncSaved,
      };
}

class _FocusLoading extends StatelessWidget {
  const _FocusLoading();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(child: Center(child: CircularProgressIndicator())),
  );
}

class _FocusLoadError extends StatelessWidget {
  const _FocusLoadError();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: AgonezInsets.card,
          child: Text(
            AppLocalizations.of(context).errorInvalidResponse,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}

Future<void> _scheduleRestNotification(
  AppRuntime runtime,
  FocusWorkoutViewModel workout,
  AppLocalizations l10n,
  DateTime endsAt,
  int exerciseIndex,
  int setIndex,
) async {
  if (!runtime.settings.restNotificationsEnabled) return;
  var targetExerciseIndex = exerciseIndex;
  var targetSetIndex = setIndex;
  if (targetExerciseIndex < workout.exercises.length &&
      targetSetIndex >= workout.exercises[targetExerciseIndex].sets.length) {
    targetExerciseIndex++;
    targetSetIndex = 0;
  }
  if (targetExerciseIndex >= workout.exercises.length) return;
  final exercise = workout.exercises[targetExerciseIndex];
  if (exercise.sets.isEmpty) return;
  final set = exercise.sets[targetSetIndex.clamp(0, exercise.sets.length - 1)];
  final load = set.prescribedLoadKg == null
      ? '— kg'
      : '${_notificationLoad(set.prescribedLoadKg!)} kg';
  final repetitions = set.repMin == set.repMax
      ? '${set.repMin ?? '—'}'
      : '${set.repMin ?? '—'}–${set.repMax ?? '—'}';
  final prescription = '$load × $repetitions @ RIR ${set.targetRir ?? '—'}';
  await runtime.notifications.schedule(
    endsAt: endsAt,
    exerciseName: exercise.name,
    setOrdinal: set.ordinal,
    prescription: prescription,
    title: l10n.timerNotificationTitle,
    body: l10n.timerNotificationBody(exercise.name, set.ordinal, prescription),
    playSound: runtime.settings.restSoundEnabled,
  );
}

String _notificationLoad(double value) {
  final result = value.toStringAsFixed(2);
  return result
      .replaceFirst(RegExp(r'\.00$'), '')
      .replaceFirst(RegExp(r'0$'), '');
}

Future<FocusExerciseChoice?> _showExercisePicker(
  BuildContext context,
  AppRuntime runtime, {
  int? planRunId,
  List<PrescriptionAlternative>? alternatives,
}) => showModalBottomSheet<FocusExerciseChoice>(
  context: context,
  isScrollControlled: true,
  builder: (context) => _AtlasExercisePickerSheet(
    runtime: runtime,
    planRunId: planRunId,
    alternatives: alternatives ?? const <PrescriptionAlternative>[],
  ),
);

class _AtlasExercisePickerSheet extends StatefulWidget {
  const _AtlasExercisePickerSheet({
    required this.runtime,
    required this.planRunId,
    required this.alternatives,
  });

  final AppRuntime runtime;
  final int? planRunId;
  final List<PrescriptionAlternative> alternatives;

  @override
  State<_AtlasExercisePickerSheet> createState() =>
      _AtlasExercisePickerSheetState();
}

class _AtlasExercisePickerSheetState extends State<_AtlasExercisePickerSheet> {
  Timer? _debounce;
  Future<AtlasSearchResponse>? _search;

  @override
  void initState() {
    super.initState();
    _searchAtlas('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _searchAtlas(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _search = widget.runtime.mobileRepository.searchAtlas(
          query: query.trim().isEmpty ? null : query.trim(),
          planRunId: widget.planRunId,
        );
      });
    });
  }

  FocusExerciseChoice _choiceFromAlternative(
    PrescriptionAlternative alternative,
  ) => FocusExerciseChoice(
    exerciseId: alternative.exercise.id,
    slug: alternative.exercise.slug,
    name: alternative.exercise.name,
    fullName: alternative.exercise.fullName,
    planAlternative: true,
    variantOrdinal: alternative.variantOrdinal,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          children: [
            const AgonezSheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.deviationSelectExercise,
                      style: AgonezTypography.sheetTitle,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.commonClose,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: TextField(
                autofocus: false,
                onChanged: _searchAtlas,
                decoration: InputDecoration(
                  hintText: l10n.deviationSearchAtlas,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                children: [
                  if (widget.alternatives.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 10, 8, 5),
                      child: AgonezEyebrow(l10n.deviationPlanAlternatives),
                    ),
                    for (final alternative in widget.alternatives)
                      _ExerciseChoiceTile(
                        choice: _choiceFromAlternative(alternative),
                      ),
                    const Divider(height: 22),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 5),
                    child: AgonezEyebrow(l10n.deviationSearchAtlas),
                  ),
                  FutureBuilder<AtlasSearchResponse>(
                    future: _search,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.all(28),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            l10n.errorNetworkUnavailable,
                            textAlign: TextAlign.center,
                            style: AgonezTypography.body,
                          ),
                        );
                      }
                      return Column(
                        children: [
                          for (final item in snapshot.requireData.items)
                            _ExerciseChoiceTile(
                              choice: FocusExerciseChoice(
                                exerciseId: item.id,
                                slug: item.slug,
                                name: item.name,
                                fullName: item.fullName,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseChoiceTile extends StatelessWidget {
  const _ExerciseChoiceTile({required this.choice});

  final FocusExerciseChoice choice;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 56,
    title: Text(choice.name, style: AgonezTypography.label),
    subtitle: choice.fullName == null
        ? null
        : Text(choice.fullName!, style: AgonezTypography.caption),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => Navigator.of(context).pop(choice),
  );
}

Future<void> _showSyncSheet(
  BuildContext context,
  AppRuntime runtime,
  LocalWorkout localWorkout,
  FocusWorkoutViewModel workout,
) async {
  final l10n = AppLocalizations.of(context);
  final blocking = await runtime.database.latestBlockingOperation(
    workout.workoutId,
  );
  if (!context.mounted) return;
  final result = blocking?.resultJson == null
      ? const <String, Object?>{}
      : Map<String, Object?>.from(jsonDecode(blocking!.resultJson!) as Map);
  final serverState = result['server_state'];
  final isConflict =
      localWorkout.syncState == 'conflict' &&
      blocking?.deliveryState == 'conflict';
  final isRejected =
      localWorkout.syncState == 'recovery_required' ||
      blocking?.deliveryState == 'rejected';
  final title = switch (workout.syncStatus) {
    WorkoutSyncStatus.saved => l10n.syncEverythingSaved,
    WorkoutSyncStatus.saving => l10n.syncSavingTitle,
    WorkoutSyncStatus.offline => l10n.syncOfflineTitle,
    WorkoutSyncStatus.failed => l10n.syncFailedTitle,
    WorkoutSyncStatus.conflict => l10n.syncConflictTitle,
    WorkoutSyncStatus.superseded => l10n.syncSuperseded,
  };
  await showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AgonezSheetHandle(),
            const SizedBox(height: 10),
            Text(title, style: AgonezTypography.sheetTitle),
            const SizedBox(height: 8),
            Text(
              isConflict
                  ? l10n.syncConflictExplanation
                  : isRejected
                  ? _rejectedExplanation(l10n, localWorkout.syncErrorCode)
                  : workout.syncStatus == WorkoutSyncStatus.superseded
                  ? l10n.syncSupersededExplanation
                  : l10n.syncLocalFirstExplanation,
              style: AgonezTypography.body,
            ),
            if (isConflict && blocking != null) ...[
              const SizedBox(height: 16),
              _ConflictValue(
                label: l10n.syncThisPhone,
                value: _compactConflictValue(jsonDecode(blocking.dataJson)),
              ),
              const SizedBox(height: 8),
              _ConflictValue(
                label: l10n.syncServer,
                value: _compactConflictValue(serverState),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.syncWaiting,
                    style: AgonezTypography.caption,
                  ),
                ),
                Text(
                  '${workout.pendingOperationCount}',
                  style: AgonezTypography.monoSmall,
                ),
              ],
            ),
            if (isConflict) ...[
              const SizedBox(height: 16),
              AgonezPrimaryButton(
                label: l10n.syncKeepPhone,
                onPressed: () async {
                  final retried = await runtime.database.retryLatestConflict(
                    workout.workoutId,
                  );
                  if (retried) runtime.syncEngine.kick();
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  final response = await runtime.api.getWorkout(
                    workout.workoutId,
                  );
                  if (response is ModifiedResponse<WorkoutSnapshot>) {
                    await runtime.database.resolveConflictsUsingServer(
                      workout.workoutId,
                    );
                    await runtime.workoutRecoveryRepository.importSnapshot(
                      response.value,
                    );
                    runtime.syncEngine.kick();
                  }
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: Text(l10n.syncUseServer),
              ),
            ] else if (localWorkout.syncState == 'failed' ||
                localWorkout.syncState == 'offline') ...[
              const SizedBox(height: 16),
              AgonezPrimaryButton(
                label: l10n.syncRetryNow,
                onPressed: () {
                  runtime.syncEngine.kick();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _ConflictValue extends StatelessWidget {
  const _ConflictValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => AgonezPanel(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgonezEyebrow(label),
        const SizedBox(height: 6),
        Text(value, style: AgonezTypography.monoSmall),
      ],
    ),
  );
}

String _compactConflictValue(Object? value) {
  if (value == null) return '—';
  if (value is Map) {
    const preferred = [
      'load_kg',
      'repetitions',
      'rir',
      'status',
      'comment',
      'actual_exercise',
      'order',
    ];
    final parts = <String>[];
    for (final key in preferred) {
      if (value.containsKey(key) && value[key] != null) {
        parts.add('$key: ${value[key]}');
      }
    }
    if (parts.isNotEmpty) return parts.join(' · ');
  }
  final encoded = value is String ? value : jsonEncode(value);
  return encoded.length <= 180 ? encoded : '${encoded.substring(0, 177)}…';
}

String _rejectedExplanation(AppLocalizations l10n, String? code) =>
    code == 'substitution_after_sets'
    ? l10n.errorSubstitutionAfterSets
    : l10n.errorRejectedOperation;
