import 'package:flutter/foundation.dart';

import '../../api/atlas_models.dart';
import '../../widgets/sync_status_pill.dart';

/// Presentation state for the immersive, active-workout workspace.
///
/// These models deliberately keep the frozen prescription and the observed
/// performance in separate fields. An adapter at the application boundary can
/// build them from Drift rows plus the frozen [WorkoutPrescription].
enum FocusSetStatus { planned, recorded, skipped }

enum FocusExerciseMode { asPrescribed, substituted, unplanned }

class FocusSetViewModel {
  const FocusSetViewModel({
    required this.id,
    required this.ordinal,
    required this.status,
    this.prescribedSetId,
    this.prescribedLoadKg,
    this.repMin,
    this.repMax,
    this.targetRir,
    this.prescriptionComment,
    this.loadKg,
    this.repetitions,
    this.rir,
    this.comment,
    this.heartRateBpm,
    this.localRevision = 0,
    this.isExtra = false,
  });

  final String id;
  final int ordinal;
  final FocusSetStatus status;
  final int? prescribedSetId;
  final double? prescribedLoadKg;
  final int? repMin;
  final int? repMax;
  final int? targetRir;
  final String? prescriptionComment;
  final double? loadKg;
  final int? repetitions;
  final int? rir;
  final String? comment;
  final int? heartRateBpm;
  final int localRevision;
  final bool isExtra;

  bool get isRecorded => status == FocusSetStatus.recorded;
  bool get isSkipped => status == FocusSetStatus.skipped;

  bool get differsFromPrescription {
    if (!isRecorded || isExtra) return false;
    final loadDiffers = prescribedLoadKg != null && loadKg != prescribedLoadKg;
    final repsDiffer =
        repetitions != null &&
        ((repMin != null && repetitions! < repMin!) ||
            (repMax != null && repetitions! > repMax!));
    final rirDiffers = targetRir != null && rir != targetRir;
    return loadDiffers || repsDiffer || rirDiffers;
  }
}

class FocusPreviousSetViewModel {
  const FocusPreviousSetViewModel({
    required this.microcycleOrdinal,
    this.loadKg,
    this.repetitions,
    this.rir,
  });

  final int microcycleOrdinal;
  final double? loadKg;
  final int? repetitions;
  final int? rir;
}

class FocusExerciseViewModel {
  const FocusExerciseViewModel({
    required this.id,
    required this.name,
    required this.roleLabel,
    required this.plannedOrdinal,
    required this.performedOrdinal,
    required this.loadStepKg,
    required this.defaultRestSeconds,
    required this.sets,
    this.mode = FocusExerciseMode.asPrescribed,
    this.exercisePrescriptionId,
    this.exerciseId,
    this.slug,
    this.fullName,
    this.prescribedName,
    this.variantLabel,
    this.planNote,
    this.prescriptionComment,
    this.exerciseComment,
    this.previousSet,
    this.atlasPeek,
    this.orderChanged = false,
  });

  final String id;
  final int? exercisePrescriptionId;
  final int? exerciseId;
  final String? slug;
  final String name;
  final String? fullName;
  final String roleLabel;
  final int plannedOrdinal;
  final int performedOrdinal;
  final FocusExerciseMode mode;
  final String? prescribedName;
  final String? variantLabel;
  final String? planNote;
  final String? prescriptionComment;
  final String? exerciseComment;
  final double loadStepKg;
  final int defaultRestSeconds;
  final List<FocusSetViewModel> sets;
  final FocusPreviousSetViewModel? previousSet;
  final AtlasPeek? atlasPeek;
  final bool orderChanged;

  int get recordedSetCount => sets.where((set) => set.isRecorded).length;
  int get resolvedSetCount =>
      sets.where((set) => set.isRecorded || set.isSkipped).length;
  bool get hasRecordedSets => recordedSetCount > 0;
  bool get isComplete => sets.isNotEmpty && resolvedSetCount == sets.length;
  bool get isSkipped => sets.isNotEmpty && sets.every((set) => set.isSkipped);
}

class FocusEntryDraft {
  const FocusEntryDraft({
    this.loadKg,
    this.repetitions,
    this.rir,
    this.comment,
    this.heartRateBpm,
    this.carriedFromLastSet = false,
  });

  final double? loadKg;
  final int? repetitions;
  final int? rir;
  final String? comment;
  final int? heartRateBpm;
  final bool carriedFromLastSet;

  FocusEntryDraft copyWith({
    double? loadKg,
    bool clearLoad = false,
    int? repetitions,
    bool clearRepetitions = false,
    int? rir,
    bool clearRir = false,
    String? comment,
    bool clearComment = false,
    int? heartRateBpm,
    bool clearHeartRate = false,
    bool? carriedFromLastSet,
  }) => FocusEntryDraft(
    loadKg: clearLoad ? null : loadKg ?? this.loadKg,
    repetitions: clearRepetitions ? null : repetitions ?? this.repetitions,
    rir: clearRir ? null : rir ?? this.rir,
    comment: clearComment ? null : comment ?? this.comment,
    heartRateBpm: clearHeartRate ? null : heartRateBpm ?? this.heartRateBpm,
    carriedFromLastSet: carriedFromLastSet ?? this.carriedFromLastSet,
  );
}

class FocusWorkoutViewModel {
  const FocusWorkoutViewModel({
    required this.workoutId,
    required this.workoutUnitName,
    required this.startedAt,
    required this.exercises,
    required this.currentExerciseIndex,
    required this.currentSetIndex,
    required this.syncStatus,
    required this.syncLabel,
    this.pendingOperationCount = 0,
    this.entryDraft,
    this.restEndsAt,
    this.restDurationSeconds,
    this.readOnly = false,
  });

  final String workoutId;
  final String workoutUnitName;
  final DateTime startedAt;
  final List<FocusExerciseViewModel> exercises;
  final int currentExerciseIndex;
  final int currentSetIndex;
  final WorkoutSyncStatus syncStatus;
  final String syncLabel;
  final int pendingOperationCount;
  final FocusEntryDraft? entryDraft;
  final DateTime? restEndsAt;
  final int? restDurationSeconds;
  final bool readOnly;

  FocusExerciseViewModel get currentExercise =>
      exercises[currentExerciseIndex.clamp(0, exercises.length - 1)];

  FocusSetViewModel? get currentSet {
    final sets = currentExercise.sets;
    if (sets.isEmpty || currentSetIndex < 0 || currentSetIndex >= sets.length) {
      return null;
    }
    return sets[currentSetIndex];
  }

  int get totalSets =>
      exercises.fold(0, (total, exercise) => total + exercise.sets.length);
  int get resolvedSets =>
      exercises.fold(0, (total, exercise) => total + exercise.resolvedSetCount);
  int get recordedSets =>
      exercises.fold(0, (total, exercise) => total + exercise.recordedSetCount);
  int get incompleteSetCount => exercises.fold(
    0,
    (total, exercise) =>
        total +
        exercise.sets
            .where((set) => set.status == FocusSetStatus.planned)
            .length,
  );
  int get incompleteExerciseCount =>
      exercises.where((exercise) => !exercise.isComplete).length;
}

class FocusExerciseChoice {
  const FocusExerciseChoice({
    required this.exerciseId,
    required this.slug,
    required this.name,
    this.fullName,
    this.planAlternative = false,
    this.variantOrdinal,
  });

  final int exerciseId;
  final String slug;
  final String name;
  final String? fullName;
  final bool planAlternative;
  final int? variantOrdinal;
}

class FocusSetSubmission {
  const FocusSetSubmission({
    required this.workoutId,
    required this.exercise,
    required this.set,
    required this.loadKg,
    required this.repetitions,
    required this.rir,
    required this.performedAt,
    required this.restDurationSeconds,
    this.comment,
    this.heartRateBpm,
  });

  final String workoutId;
  final FocusExerciseViewModel exercise;
  final FocusSetViewModel set;
  final double loadKg;
  final int repetitions;
  final int rir;
  final String? comment;
  final int? heartRateBpm;
  final DateTime performedAt;
  final int restDurationSeconds;
}

class FocusSetEdit {
  const FocusSetEdit({
    required this.exercise,
    required this.set,
    required this.loadKg,
    required this.repetitions,
    required this.rir,
    this.comment,
    this.heartRateBpm,
  });

  final FocusExerciseViewModel exercise;
  final FocusSetViewModel set;
  final double loadKg;
  final int repetitions;
  final int rir;
  final String? comment;
  final int? heartRateBpm;
}

typedef FocusExercisePicker =
    Future<FocusExerciseChoice?> Function(FocusExerciseViewModel exercise);

/// Side-effect boundary for Focus Mode.
///
/// [onConfirmSet] must complete after the set and its operation have been
/// committed locally. It must never wait for the network.
class FocusWorkoutCallbacks {
  const FocusWorkoutCallbacks({
    required this.onMinimise,
    required this.onConfirmSet,
    required this.onSkipSet,
    required this.onAddExtraSet,
    required this.onSkipExercise,
    required this.onReorderExercise,
    required this.onFinish,
    this.onCursorChanged,
    this.onDraftChanged,
    this.onRestChanged,
    this.onUndoSet,
    this.onEditSet,
    this.onExerciseNoteChanged,
    this.pickSubstitute,
    this.onSubstitute,
    this.pickUnplannedExercise,
    this.onAddUnplannedExercise,
    this.onOpenFullAtlas,
    this.onSyncDetails,
    this.onResumeHere,
  });

  final VoidCallback onMinimise;
  final Future<void> Function(FocusSetSubmission submission) onConfirmSet;
  final Future<void> Function(
    FocusExerciseViewModel exercise,
    FocusSetViewModel set,
  )
  onSkipSet;
  final Future<void> Function(FocusExerciseViewModel exercise) onAddExtraSet;
  final Future<void> Function(FocusExerciseViewModel exercise) onSkipExercise;
  final Future<void> Function(FocusExerciseViewModel exercise)
  onReorderExercise;
  final Future<void> Function(bool acknowledgedIncomplete) onFinish;
  final Future<void> Function(int exerciseIndex, int setIndex)? onCursorChanged;
  final Future<void> Function(FocusEntryDraft draft)? onDraftChanged;
  final Future<void> Function(DateTime? endsAt, int? durationSeconds)?
  onRestChanged;
  final Future<void> Function(
    FocusExerciseViewModel exercise,
    FocusSetViewModel set,
  )?
  onUndoSet;
  final Future<void> Function(FocusSetEdit edit)? onEditSet;
  final Future<void> Function(FocusExerciseViewModel exercise, String? comment)?
  onExerciseNoteChanged;
  final FocusExercisePicker? pickSubstitute;
  final Future<void> Function(
    FocusExerciseViewModel exercise,
    FocusExerciseChoice replacement,
  )?
  onSubstitute;
  final FocusExercisePicker? pickUnplannedExercise;
  final Future<void> Function(FocusExerciseChoice exercise)?
  onAddUnplannedExercise;
  final VoidCallback? onOpenFullAtlas;
  final VoidCallback? onSyncDetails;
  final Future<void> Function()? onResumeHere;
}
