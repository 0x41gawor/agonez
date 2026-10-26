import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../atlas/widgets/anatomy_heatmap.dart';
import '../../atlas/widgets/exercise_image.dart';
import '../../design/design.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/hold_to_confirm.dart';
import '../../widgets/sync_status_pill.dart';
import '../../workout/load_format.dart';
import 'focus_workout_models.dart';

part 'focus_mode_header.dart';
part 'focus_mode_cards.dart';
part 'focus_mode_entry.dart';
part 'focus_mode_sheets.dart';
part 'focus_mode_atlas_peek.dart';
part 'focus_mode_entry_sheets.dart';

/// The full-screen workout workspace.
///
/// It owns only ephemeral entry interaction. Confirmed facts cross
/// [FocusWorkoutCallbacks], whose implementation persists them locally before
/// completing. Network state is deliberately absent from the input path.
class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({
    required this.workout,
    required this.callbacks,
    this.enableHaptics = true,
    this.now,
    super.key,
  });

  final FocusWorkoutViewModel workout;
  final FocusWorkoutCallbacks callbacks;
  final bool enableHaptics;
  final DateTime Function()? now;

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen>
    with WidgetsBindingObserver {
  late FocusEntryDraft _draft;
  late String _cursorIdentity;
  Timer? _ticker;
  DateTime? _restEndsAt;
  int? _restDurationSeconds;
  bool _restCompletionAnnounced = false;
  bool _submitting = false;

  DateTime get _now => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cursorIdentity = _identityFor(widget.workout);
    _draft = _initialDraft(widget.workout);
    _restEndsAt = widget.workout.restEndsAt;
    _restDurationSeconds = widget.workout.restDurationSeconds;
    _restCompletionAnnounced =
        _restEndsAt == null || !_now.isBefore(_restEndsAt!);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final endsAt = _restEndsAt;
      if (endsAt != null &&
          !_restCompletionAnnounced &&
          !_now.isBefore(endsAt)) {
        _restCompletionAnnounced = true;
        if (widget.enableHaptics) HapticFeedback.mediumImpact();
      }
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant FocusModeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final identity = _identityFor(widget.workout);
    if (oldWidget.workout.workoutId != widget.workout.workoutId ||
        identity != _cursorIdentity) {
      _cursorIdentity = identity;
      _draft = _initialDraft(widget.workout);
    }
    if (widget.workout.restEndsAt != oldWidget.workout.restEndsAt ||
        widget.workout.restDurationSeconds !=
            oldWidget.workout.restDurationSeconds) {
      _restEndsAt = widget.workout.restEndsAt;
      _restDurationSeconds = widget.workout.restDurationSeconds;
      _restCompletionAnnounced =
          _restEndsAt == null || !_now.isBefore(_restEndsAt!);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  String _identityFor(FocusWorkoutViewModel workout) {
    if (workout.exercises.isEmpty) return '${workout.workoutId}:empty';
    final exercise = workout.currentExercise;
    final set = workout.currentSet;
    return '${workout.workoutId}:${exercise.id}:${set?.id ?? 'complete'}';
  }

  FocusEntryDraft _initialDraft(FocusWorkoutViewModel workout) {
    final restored = workout.entryDraft;
    if (restored != null) return restored;
    if (workout.exercises.isEmpty || workout.currentSet == null) {
      return const FocusEntryDraft();
    }

    final exercise = workout.currentExercise;
    final set = workout.currentSet!;
    double? load = set.prescribedLoadKg;
    var carried = false;
    final currentIndex = exercise.sets.indexWhere((item) => item.id == set.id);
    final prior = exercise.sets
        .take(math.max(0, currentIndex))
        .where((item) => item.isRecorded && item.loadKg != null)
        .toList(growable: false);
    final previous = prior.isEmpty ? null : prior.last;

    if (exercise.mode == FocusExerciseMode.unplanned || set.isExtra) {
      load = previous?.loadKg ?? exercise.previousSet?.loadKg;
    } else if (previous != null &&
        previous.prescribedLoadKg == set.prescribedLoadKg &&
        previous.loadKg != previous.prescribedLoadKg) {
      load = previous.loadKg;
      carried = true;
    }
    return FocusEntryDraft(loadKg: load, carriedFromLastSet: carried);
  }

  Future<void> _confirmSet() async {
    final exercise = widget.workout.currentExercise;
    final set = widget.workout.currentSet;
    final load = _draft.loadKg;
    final reps = _draft.repetitions;
    final rir = _draft.rir;
    if (set == null || load == null || reps == null || rir == null) return;

    setState(() => _submitting = true);
    try {
      await widget.callbacks.onConfirmSet(
        FocusSetSubmission(
          workoutId: widget.workout.workoutId,
          exercise: exercise,
          set: set,
          loadKg: load,
          repetitions: reps,
          rir: rir,
          comment: _draft.comment,
          heartRateBpm: _draft.heartRateBpm,
          performedAt: _now.toUtc(),
          restDurationSeconds: exercise.defaultRestSeconds,
        ),
      );
      if (!mounted) return;
      if (widget.enableHaptics) HapticFeedback.lightImpact();
      final restDuration = exercise.defaultRestSeconds;
      setState(() {
        _restDurationSeconds = restDuration;
        _restEndsAt = _now.add(Duration(seconds: restDuration));
        _draft = FocusEntryDraft(loadKg: load, carriedFromLastSet: true);
      });
      _showRecordedSnackBar(exercise, set, load, reps, rir);
    } catch (_) {
      if (mounted) _showFailure();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showRecordedSnackBar(
    FocusExerciseViewModel exercise,
    FocusSetViewModel set,
    double load,
    int reps,
    int rir,
  ) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: AgonezDurations.snackbarUndo,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 76),
        content: Text(
          '${l10n.setRecordedSnackbar(set.number)} · '
          '${formatLoad(load)} × $reps @ RIR $rir',
        ),
        action: widget.callbacks.onUndoSet == null
            ? null
            : SnackBarAction(
                label: l10n.setUndo,
                onPressed: () async {
                  try {
                    await widget.callbacks.onUndoSet!(exercise, set);
                  } catch (_) {
                    if (mounted) _showFailure();
                  }
                },
              ),
      ),
    );
  }

  void _showFailure() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.errorGenericBody)));
  }

  void _updateDraft(FocusEntryDraft value) {
    setState(() => _draft = value);
    unawaited(widget.callbacks.onDraftChanged?.call(value));
  }

  Future<void> _adjustRest(int seconds) async {
    final current = _restEndsAt;
    if (current == null) return;
    final duration = math.max(10, (_restDurationSeconds ?? 0) + seconds);
    final endsAt = current.add(Duration(seconds: seconds));
    setState(() {
      _restEndsAt = endsAt;
      _restDurationSeconds = duration;
      _restCompletionAnnounced = !_now.isBefore(endsAt);
    });
    try {
      await widget.callbacks.onRestChanged?.call(endsAt, duration);
    } catch (_) {
      if (mounted) _showFailure();
    }
  }

  Future<void> _endRest() async {
    setState(() {
      _restEndsAt = null;
      _restDurationSeconds = null;
      _restCompletionAnnounced = true;
    });
    try {
      await widget.callbacks.onRestChanged?.call(null, null);
    } catch (_) {
      if (mounted) _showFailure();
    }
  }

  @override
  Widget build(BuildContext context) {
    final workout = widget.workout;
    if (workout.exercises.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: IconButton(
              onPressed: widget.callbacks.onMinimise,
              icon: const Icon(Icons.keyboard_arrow_down),
            ),
          ),
        ),
      );
    }
    final exercise = workout.currentExercise;
    final set = workout.currentSet;
    final exerciseComplete = exercise.isComplete || set == null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.callbacks.onMinimise();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _FocusTopBar(
                workout: workout,
                now: _now,
                onMinimise: widget.callbacks.onMinimise,
                onOutline: _showOutline,
                onActions: _showActions,
                onSync: widget.callbacks.onSyncDetails,
              ),
              _WorkoutProgress(workout: workout),
              if (workout.syncStatus == WorkoutSyncStatus.superseded)
                _SupersededBanner(
                  readOnly: workout.readOnly,
                  onResumeHere: widget.callbacks.onResumeHere,
                ),
              Expanded(
                child: SingleChildScrollView(
                  key: const Key('focus-scroll-body'),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ExerciseHeader(
                        exercise: exercise,
                        onTap: exercise.atlasPeek == null
                            ? null
                            : _showQuickPeek,
                      ),
                      const SizedBox(height: 12),
                      _SetRail(
                        exercise: exercise,
                        currentSetId: set?.id,
                        onTapRecorded: widget.callbacks.onEditSet == null
                            ? null
                            : _showEditSet,
                      ),
                      const SizedBox(height: 12),
                      if (_restEndsAt != null)
                        _RestCard(
                          endsAt: _restEndsAt!,
                          durationSeconds: _restDurationSeconds ?? 0,
                          now: _now,
                          nextSet: set,
                          onMinus: () => _adjustRest(-30),
                          onPlus: () => _adjustRest(30),
                          onEnd: _endRest,
                        )
                      else if (!exerciseComplete)
                        _PrescriptionCard(exercise: exercise, set: set),
                      const SizedBox(height: 14),
                      if (exerciseComplete)
                        _ExerciseCompleteCard(
                          exercise: exercise,
                          onExerciseNote: _showExerciseNote,
                          onAddExtraSet: () => _showHoldFor(
                            title: AppLocalizations.of(context).deviationAddSet,
                            explanation: AppLocalizations.of(
                              context,
                            ).deviationAddSetExplanation,
                            label: AppLocalizations.of(
                              context,
                            ).deviationHoldAddSet,
                            duration: const Duration(milliseconds: 600),
                            neutral: true,
                            action: () =>
                                widget.callbacks.onAddExtraSet(exercise),
                          ),
                        )
                      else
                        _EntryZone(
                          exercise: exercise,
                          set: set,
                          draft: _draft,
                          enabled: !workout.readOnly && !_submitting,
                          enableHaptics: widget.enableHaptics,
                          onLoadChanged: (value) => _updateDraft(
                            _draft.copyWith(
                              loadKg: value,
                              carriedFromLastSet: false,
                            ),
                          ),
                          onOpenKeypad: _openLoadKeypad,
                          onRepsChanged: (value) =>
                              _updateDraft(_draft.copyWith(repetitions: value)),
                          onOpenRepGrid: _openRepGrid,
                          onRirChanged: (value) =>
                              _updateDraft(_draft.copyWith(rir: value)),
                          onSetNote: _showSetNote,
                          onMoreData: _showMoreData,
                        ),
                    ],
                  ),
                ),
              ),
              _buildPinnedAction(exercise, set, exerciseComplete),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinnedAction(
    FocusExerciseViewModel exercise,
    FocusSetViewModel? set,
    bool exerciseComplete,
  ) {
    final l10n = AppLocalizations.of(context);
    if (widget.workout.readOnly) {
      return _PinnedBar(
        child: AgonezPrimaryButton(
          label: l10n.syncResumeHere,
          onPressed: widget.callbacks.onResumeHere == null
              ? null
              : () => widget.callbacks.onResumeHere!(),
        ),
      );
    }
    if (exerciseComplete) {
      final nextIndex = widget.workout.currentExerciseIndex + 1;
      final hasNext = nextIndex < widget.workout.exercises.length;
      return _PinnedBar(
        child: AgonezPrimaryButton(
          key: const Key('focus-next-primary'),
          label: hasNext
              ? l10n.workoutStartNext(widget.workout.exercises[nextIndex].name)
              : l10n.workoutFinishWorkout,
          onPressed: hasNext
              ? () => widget.callbacks.onCursorChanged?.call(nextIndex, 0)
              : _showFinish,
        ),
      );
    }

    final missingLoad = _draft.loadKg == null;
    final missingObservation = _draft.repetitions == null || _draft.rir == null;
    final enabled =
        !missingLoad && !missingObservation && !_submitting && set != null;
    final label = missingLoad
        ? l10n.setEnterLoad
        : missingObservation
        ? l10n.setSelectRepsRir
        : l10n.setConfirm(set!.number);
    final summary = enabled
        ? l10n.setConfirmSummary(
            formatLoad(_draft.loadKg!),
            _draft.repetitions!,
            _draft.rir == 5 ? '5+' : '${_draft.rir}',
            _formatDuration(Duration(seconds: exercise.defaultRestSeconds)),
          )
        : null;
    return _PinnedBar(
      child: AgonezPrimaryButton(
        key: const Key('focus-confirm'),
        label: _submitting ? l10n.syncSaving : label,
        supportingText: summary,
        onPressed: enabled ? _confirmSet : null,
      ),
    );
  }

  Future<void> _showOutline() async {
    final chosen = await showModalBottomSheet<FocusExerciseViewModel>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _OutlineSheet(workout: widget.workout),
    );
    if (!mounted || chosen == null) return;
    if (widget.workout.canPostponeCurrent) {
      await _showPostpone(chosen);
      return;
    }
    final l10n = AppLocalizations.of(context);
    await _showHoldFor(
      title: chosen.name,
      explanation: l10n.deviationReorderExplanation(chosen.plannedOrdinal),
      label: l10n.deviationHoldReorder,
      duration: const Duration(seconds: 1),
      action: () => widget.callbacks.onReorderExercise(chosen),
    );
  }

  /// Postpones the untouched current exercise so [replacement] can start
  /// now. The current one comes right after it, as close to its planned
  /// place as possible: a primary lift done last is done tired.
  Future<void> _showPostpone(FocusExerciseViewModel replacement) async {
    final l10n = AppLocalizations.of(context);
    final current = widget.workout.currentExercise;
    final position = widget.workout.currentExerciseIndex + 2;
    await _showHoldFor(
      title: l10n.deviationPostpone(current.name),
      explanation: current.exercisePrescriptionId == null
          ? l10n.deviationPostponeUnplannedExplanation(
              replacement.name,
              position,
            )
          : l10n.deviationPostponeExplanation(
              replacement.name,
              current.plannedOrdinal,
              position,
            ),
      label: l10n.deviationHoldPostpone,
      duration: const Duration(seconds: 1),
      action: () => widget.callbacks.onDoNow(replacement),
    );
  }

  Future<void> _showActions() async {
    final action = await showModalBottomSheet<_FocusAction>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ActionsSheet(
        workout: widget.workout,
        exercise: widget.workout.currentExercise,
      ),
    );
    if (!mounted || action == null) return;
    final l10n = AppLocalizations.of(context);
    final exercise = widget.workout.currentExercise;
    final set = widget.workout.currentSet;
    switch (action) {
      case _FocusAction.quickPeek:
        await _showQuickPeek();
      case _FocusAction.setNote:
        await _showSetNote();
      case _FocusAction.moreData:
        await _showMoreData();
      case _FocusAction.exerciseNote:
        await _showExerciseNote();
      case _FocusAction.skipSet:
        if (set == null) return;
        await _showHoldFor(
          title: l10n.deviationSkipSet(set.number),
          explanation: l10n.deviationSkipSetExplanation,
          label: l10n.deviationHoldSkipSet,
          duration: const Duration(milliseconds: 600),
          neutral: true,
          action: () => widget.callbacks.onSkipSet(exercise, set),
        );
      case _FocusAction.addSet:
        await _showHoldFor(
          title: l10n.deviationAddSet,
          explanation: l10n.deviationAddSetExplanation,
          label: l10n.deviationHoldAddSet,
          duration: const Duration(milliseconds: 600),
          neutral: true,
          action: () => widget.callbacks.onAddExtraSet(exercise),
        );
      case _FocusAction.postpone:
        final replacement = widget.workout.postponeReplacement;
        if (replacement == null) return;
        await _showPostpone(replacement);
      case _FocusAction.skipExercise:
        await _showHoldFor(
          title: l10n.deviationSkipExercise(exercise.name),
          explanation: l10n.deviationSkipExerciseExplanation,
          label: l10n.deviationHoldSkipExercise,
          duration: const Duration(milliseconds: 1200),
          action: () => widget.callbacks.onSkipExercise(exercise),
        );
      case _FocusAction.substitute:
        await _pickAndSubstitute(exercise);
      case _FocusAction.addUnplanned:
        await _pickAndAddExercise(exercise);
      case _FocusAction.finish:
        await _showFinish();
    }
  }

  Future<void> _pickAndSubstitute(FocusExerciseViewModel exercise) async {
    final picker = widget.callbacks.pickSubstitute;
    final apply = widget.callbacks.onSubstitute;
    if (picker == null || apply == null) return;
    final choice = await picker(exercise);
    if (!mounted || choice == null) return;
    final l10n = AppLocalizations.of(context);
    await _showHoldFor(
      title: l10n.deviationSubstitute,
      explanation:
          '${l10n.deviationSubstituteExplanation}\n\n'
          '${l10n.workoutPrescribed}: ${exercise.name}\n'
          '${l10n.workoutPerformed}: ${choice.name}',
      label: l10n.deviationHoldSubstitute,
      duration: const Duration(milliseconds: 1200),
      action: () => apply(exercise, choice),
    );
  }

  Future<void> _pickAndAddExercise(FocusExerciseViewModel exercise) async {
    final picker = widget.callbacks.pickUnplannedExercise;
    final apply = widget.callbacks.onAddUnplannedExercise;
    if (picker == null || apply == null) return;
    final choice = await picker(exercise);
    if (!mounted || choice == null) return;
    final l10n = AppLocalizations.of(context);
    await _showHoldFor(
      title: l10n.deviationAddUnplanned,
      explanation: l10n.deviationAddUnplannedExplanation(
        choice.name,
        widget.workout.workoutUnitName,
      ),
      label: l10n.deviationHoldAddUnplanned,
      duration: const Duration(milliseconds: 1400),
      action: () => apply(choice),
    );
  }

  Future<void> _showHoldFor({
    required String title,
    required String explanation,
    required String label,
    required Duration duration,
    required Future<void> Function() action,
    bool neutral = false,
  }) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      builder: (context) => _HoldActionSheet(
        title: title,
        explanation: explanation,
        label: label,
        duration: duration,
        neutral: neutral,
        enableHaptics: widget.enableHaptics,
      ),
    );
    if (!mounted || confirmed != true) return;
    try {
      await action();
    } catch (_) {
      if (mounted) _showFailure();
    }
  }

  Future<void> _showFinish() async {
    final acknowledged = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FinishSheet(
        workout: widget.workout,
        elapsed: _now.difference(widget.workout.startedAt),
        enableHaptics: widget.enableHaptics,
      ),
    );
    if (!mounted || acknowledged == null) return;
    try {
      await widget.callbacks.onFinish(acknowledged);
    } catch (_) {
      if (mounted) _showFailure();
    }
  }

  Future<void> _showQuickPeek() async {
    final peek = widget.workout.currentExercise.atlasPeek;
    if (peek == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AtlasQuickPeekSheet(
        exercise: widget.workout.currentExercise,
        onOpenFull: widget.callbacks.onOpenFullAtlas,
      ),
    );
  }

  Future<void> _showSetNote() async {
    final value = await _showNoteSheet(
      title: AppLocalizations.of(
        context,
      ).noteSetTitle(widget.workout.currentSet?.number ?? 1),
      hint: AppLocalizations.of(context).noteSetPlaceholder,
      initialValue: _draft.comment,
      suggestions: _noteSuggestions,
    );
    if (!mounted || value == null) return;
    _updateDraft(
      value.isEmpty
          ? _draft.copyWith(clearComment: true)
          : _draft.copyWith(comment: value),
    );
  }

  Future<void> _showExerciseNote() async {
    final exercise = widget.workout.currentExercise;
    final value = await _showNoteSheet(
      title: AppLocalizations.of(context).noteExerciseTitle,
      hint: AppLocalizations.of(context).noteExercisePlaceholder,
      initialValue: exercise.exerciseComment,
      suggestions: const [],
      supportingText: AppLocalizations.of(context).noteExposureOnlyHint,
    );
    if (!mounted || value == null) return;
    try {
      await widget.callbacks.onExerciseNoteChanged?.call(
        exercise,
        value.isEmpty ? null : value,
      );
    } catch (_) {
      if (mounted) _showFailure();
    }
  }

  List<String> get _noteSuggestions {
    final l10n = AppLocalizations.of(context);
    return [
      l10n.noteSuggestionGripSlipped,
      l10n.noteSuggestionElbowsFlared,
      l10n.noteSuggestionReducedLoad,
      l10n.noteSuggestionPain,
      l10n.noteSuggestionEquipment,
      l10n.noteSuggestionSpotter,
    ];
  }

  Future<String?> _showNoteSheet({
    required String title,
    required String hint,
    required String? initialValue,
    required List<String> suggestions,
    String? supportingText,
  }) => showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _NoteSheet(
      title: title,
      hint: hint,
      initialValue: initialValue,
      suggestions: suggestions,
      supportingText: supportingText,
    ),
  );

  Future<void> _showMoreData() async {
    final selected = await showModalBottomSheet<int?>(
      context: context,
      builder: (context) => _MoreDataSheet(selected: _draft.heartRateBpm),
    );
    if (!mounted) return;
    _updateDraft(
      selected == null
          ? _draft.copyWith(clearHeartRate: true)
          : _draft.copyWith(heartRateBpm: selected),
    );
  }

  Future<void> _openLoadKeypad() async {
    final exercise = widget.workout.currentExercise;
    final set = widget.workout.currentSet;
    final value = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _LoadKeypadSheet(
        current: _draft.loadKg,
        prescribed: set?.prescribedLoadKg,
        previous: exercise.previousSet?.loadKg,
      ),
    );
    if (!mounted || value == null) return;
    _updateDraft(_draft.copyWith(loadKg: value, carriedFromLastSet: false));
  }

  Future<void> _openRepGrid() async {
    final value = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => const _RepGridSheet(),
    );
    if (!mounted || value == null) return;
    _updateDraft(_draft.copyWith(repetitions: value));
  }

  Future<void> _showEditSet(FocusSetViewModel set) async {
    final edit = await showModalBottomSheet<FocusSetEdit>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _EditSetSheet(exercise: widget.workout.currentExercise, set: set),
    );
    if (!mounted || edit == null) return;
    try {
      await widget.callbacks.onEditSet?.call(edit);
    } catch (_) {
      if (mounted) _showFailure();
    }
  }
}

enum _FocusAction {
  quickPeek,
  setNote,
  moreData,
  exerciseNote,
  skipSet,
  addSet,
  postpone,
  skipExercise,
  substitute,
  addUnplanned,
  finish,
}

String _formatDuration(Duration value) {
  final seconds = value.inSeconds.abs();
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}
