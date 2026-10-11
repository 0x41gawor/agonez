import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../atlas/widgets/anatomy_heatmap.dart';
import '../../design/design.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/hold_to_confirm.dart';
import '../../widgets/sync_status_pill.dart';
import 'focus_workout_models.dart';

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
          '${l10n.setRecordedSnackbar(set.ordinal)} · '
          '${_formatLoad(load)} × $reps @ RIR $rir',
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
        : l10n.setConfirm(set!.ordinal);
    final summary = enabled
        ? l10n.setConfirmSummary(
            _formatLoad(_draft.loadKg!),
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
    final l10n = AppLocalizations.of(context);
    await _showHoldFor(
      title: chosen.name,
      explanation: l10n.deviationReorderExplanation(chosen.plannedOrdinal),
      label: l10n.deviationHoldReorder,
      duration: const Duration(seconds: 1),
      action: () => widget.callbacks.onReorderExercise(chosen),
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
          title: l10n.deviationSkipSet(set.ordinal),
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
      ).noteSetTitle(widget.workout.currentSet?.ordinal ?? 1),
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
  skipExercise,
  substitute,
  addUnplanned,
  finish,
}

String _formatLoad(double value) {
  final fixed = value.toStringAsFixed(2);
  return fixed
      .replaceFirst(RegExp(r'\.00$'), '')
      .replaceFirst(RegExp(r'0$'), '');
}

String _formatDuration(Duration value) {
  final seconds = value.inSeconds.abs();
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}

class _FocusTopBar extends StatelessWidget {
  const _FocusTopBar({
    required this.workout,
    required this.now,
    required this.onMinimise,
    required this.onOutline,
    required this.onActions,
    required this.onSync,
  });

  final FocusWorkoutViewModel workout;
  final DateTime now;
  final VoidCallback onMinimise;
  final VoidCallback onOutline;
  final VoidCallback onActions;
  final VoidCallback? onSync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final elapsed = now.difference(workout.startedAt);
    return SizedBox(
      height: 54,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              key: const Key('focus-minimise'),
              tooltip: l10n.workoutMinimiseA11y,
              onPressed: onMinimise,
              icon: const Icon(Icons.keyboard_arrow_down),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.workoutUnitName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AgonezTypography.label.copyWith(
                      color: context.agonezColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    l10n.workoutElapsed(_formatDuration(elapsed)),
                    style: AgonezTypography.monoSmall,
                  ),
                ],
              ),
            ),
            SyncStatusPill(
              status: workout.syncStatus,
              label: workout.syncLabel,
              onPressed: onSync,
            ),
            IconButton(
              key: const Key('focus-outline'),
              tooltip: l10n.workoutOutline,
              onPressed: onOutline,
              icon: const Icon(Icons.format_list_bulleted_rounded, size: 21),
            ),
            IconButton(
              key: const Key('focus-actions'),
              tooltip: l10n.workoutActions,
              onPressed: onActions,
              icon: const Icon(Icons.more_horiz),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutProgress extends StatelessWidget {
  const _WorkoutProgress({required this.workout});

  final FocusWorkoutViewModel workout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.agonezColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.lineSubtle)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 5,
            child: Row(
              children: [
                for (var index = 0; index < workout.exercises.length; index++)
                  Expanded(
                    flex: math.max(1, workout.exercises[index].sets.length),
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index == workout.exercises.length - 1 ? 0 : 3,
                      ),
                      decoration: BoxDecoration(
                        color: _segmentColor(colors, workout, index),
                        borderRadius: BorderRadius.circular(3),
                        border: workout.exercises[index].isSkipped
                            ? Border.all(color: colors.caution)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AgonezEyebrow(
                l10n.workoutExerciseCounter(
                  workout.currentExerciseIndex + 1,
                  workout.exercises.length,
                ),
              ),
              AgonezEyebrow(
                l10n.workoutSetCounter(workout.resolvedSets, workout.totalSets),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _segmentColor(
    AgonezThemeColors colors,
    FocusWorkoutViewModel workout,
    int index,
  ) {
    final exercise = workout.exercises[index];
    if (exercise.isSkipped) return Colors.transparent;
    if (exercise.isComplete) return colors.success;
    if (index == workout.currentExerciseIndex) return colors.gold;
    return colors.line;
  }
}

class _SupersededBanner extends StatelessWidget {
  const _SupersededBanner({required this.readOnly, required this.onResumeHere});

  final bool readOnly;
  final Future<void> Function()? onResumeHere;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.agonezColors;
    return Container(
      width: double.infinity,
      color: colors.caution.withValues(alpha: 0.09),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      child: Row(
        children: [
          Icon(Icons.devices_other, size: 18, color: colors.caution),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.syncSuperseded,
              style: AgonezTypography.label.copyWith(color: colors.caution),
            ),
          ),
          if (readOnly && onResumeHere != null)
            TextButton(
              onPressed: onResumeHere,
              child: Text(l10n.syncResumeHere),
            ),
        ],
      ),
    );
  }
}

class _ExerciseHeader extends StatelessWidget {
  const _ExerciseHeader({required this.exercise, required this.onTap});

  final FocusExerciseViewModel exercise;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.agonezColors;
    final flags = <String>[
      if (exercise.mode == FocusExerciseMode.unplanned) l10n.workoutUnplanned,
      if (exercise.orderChanged) l10n.workoutOrderChanged,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgonezEyebrow(
          [exercise.roleLabel, ...flags].join(' · '),
          color: exercise.mode == FocusExerciseMode.unplanned
              ? colors.goldText
              : null,
        ),
        const SizedBox(height: 5),
        Semantics(
          button: onTap != null,
          label: '${exercise.name}, ${l10n.atlasQuickView}',
          child: InkWell(
            key: const Key('focus-exercise-name'),
            onTap: onTap,
            borderRadius: AgonezRadii.controlBorder,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      exercise.name,
                      style: AgonezTypography.exerciseTitle,
                    ),
                  ),
                  if (onTap != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.menu_book_outlined,
                        size: 21,
                        color: colors.goldText,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (exercise.mode == FocusExerciseMode.substituted) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: colors.caution, width: 2)),
              color: colors.caution.withValues(alpha: 0.06),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _LineageValue(
                    label: l10n.workoutPerformed,
                    value: exercise.name,
                  ),
                ),
                const Icon(Icons.arrow_back, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: _LineageValue(
                    label: l10n.workoutPrescribed,
                    value: exercise.prescribedName ?? exercise.name,
                  ),
                ),
              ],
            ),
          ),
        ] else if (exercise.variantLabel != null) ...[
          const SizedBox(height: 3),
          Text(exercise.variantLabel!, style: AgonezTypography.caption),
        ],
      ],
    );
  }
}

class _LineageValue extends StatelessWidget {
  const _LineageValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AgonezEyebrow(label, color: context.agonezColors.caution),
      const SizedBox(height: 3),
      Text(value, maxLines: 2, style: AgonezTypography.label),
    ],
  );
}

class _SetRail extends StatelessWidget {
  const _SetRail({
    required this.exercise,
    required this.currentSetId,
    required this.onTapRecorded,
  });

  final FocusExerciseViewModel exercise;
  final String? currentSetId;
  final ValueChanged<FocusSetViewModel>? onTapRecorded;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: exercise.sets.length,
      separatorBuilder: (_, _) => const SizedBox(width: 7),
      itemBuilder: (context, index) {
        final set = exercise.sets[index];
        return _SetPill(
          set: set,
          isCurrent: set.id == currentSetId,
          onTap: set.isRecorded && onTapRecorded != null
              ? () => onTapRecorded!(set)
              : null,
        );
      },
    ),
  );
}

class _SetPill extends StatelessWidget {
  const _SetPill({required this.set, required this.isCurrent, this.onTap});

  final FocusSetViewModel set;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.agonezColors;
    final label = set.isRecorded
        ? '✓ ${_formatLoad(set.loadKg ?? 0)}×${set.repetitions} @${set.rir}'
        : set.isSkipped
        ? l10n.workoutSkippedLabel
        : set.isExtra
        ? '${l10n.workoutExtraLabel} ${set.ordinal}'
        : '${set.ordinal} · ${set.prescribedLoadKg == null ? '—' : _formatLoad(set.prescribedLoadKg!)}';
    final borderColor = set.isSkipped
        ? colors.caution
        : isCurrent
        ? colors.gold
        : set.isExtra
        ? AgonezColors.goldLine
        : colors.control;
    final background = set.isRecorded
        ? colors.success.withValues(alpha: 0.12)
        : isCurrent
        ? colors.goldSoft
        : Colors.transparent;
    return Semantics(
      button: onTap != null,
      selected: isCurrent,
      label:
          '${l10n.workoutSetLabel(set.ordinal)}, $label'
          '${set.differsFromPrescription ? ', ${l10n.divergenceDiffersA11y}' : ''}',
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: StadiumBorder(
          side: BorderSide(color: borderColor, width: isCurrent ? 1.5 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Container(
            constraints: const BoxConstraints(minWidth: 52, minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AgonezTypography.monoSmall.copyWith(
                    color: set.isRecorded
                        ? colors.successText
                        : set.isSkipped
                        ? colors.caution
                        : isCurrent
                        ? colors.goldText
                        : colors.textSecondary,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (set.differsFromPrescription) ...[
                  const SizedBox(width: 5),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.caution,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({required this.exercise, required this.set});

  final FocusExerciseViewModel exercise;
  final FocusSetViewModel set;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.agonezColors;
    if (exercise.mode == FocusExerciseMode.unplanned || set.isExtra) {
      return AgonezPanel(
        backgroundColor: colors.alternative,
        borderColor: AgonezColors.goldLine,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AgonezEyebrow(
              set.isExtra
                  ? l10n.workoutExtraNotPrescribed
                  : l10n.workoutNoPrescriptionUnplanned,
              color: colors.goldText,
            ),
            const SizedBox(height: 8),
            Text(l10n.workoutRecordWhatYouDo, style: AgonezTypography.body),
          ],
        ),
      );
    }
    final load = set.prescribedLoadKg == null
        ? '— kg'
        : '${_formatLoad(set.prescribedLoadKg!)} kg';
    final reps = set.repMin == set.repMax
        ? '${set.repMin}'
        : '${set.repMin}–${set.repMax}';
    final rir = set.targetRir == null ? '—' : '${set.targetRir}';
    final previous = exercise.previousSet;
    return AgonezPanel(
      backgroundColor: colors.prescriptionBackground,
      borderColor: AgonezColors.prescriptionLine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AgonezEyebrow(
            l10n.workoutPrescribedSet(set.ordinal),
            color: colors.prescriptionText,
          ),
          const SizedBox(height: 8),
          Text(
            '$load × $reps @ RIR $rir',
            style: AgonezTypography.inputNumber.copyWith(
              color: colors.prescriptionText,
              fontSize: 23,
            ),
          ),
          if (exercise.mode == FocusExerciseMode.substituted) ...[
            const SizedBox(height: 6),
            Text(
              l10n.workoutPrescriptionWasFor(
                exercise.prescribedName ?? exercise.name,
              ),
              style: AgonezTypography.caption.copyWith(
                color: colors.prescriptionText,
              ),
            ),
          ],
          if (previous != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                AgonezEyebrow(
                  l10n.workoutLastExposure('MC${previous.microcycleOrdinal}'),
                  color: colors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${previous.loadKg == null ? '—' : _formatLoad(previous.loadKg!)} × '
                    '${previous.repetitions ?? '—'} @${previous.rir ?? '—'}',
                    style: AgonezTypography.monoSmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if ((set.prescriptionComment ?? exercise.prescriptionComment) !=
              null) ...[
            const SizedBox(height: 10),
            Text(
              set.prescriptionComment ?? exercise.prescriptionComment!,
              style: AgonezTypography.body.copyWith(
                color: colors.prescriptionText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RestCard extends StatelessWidget {
  const _RestCard({
    required this.endsAt,
    required this.durationSeconds,
    required this.now,
    required this.nextSet,
    required this.onMinus,
    required this.onPlus,
    required this.onEnd,
  });

  final DateTime endsAt;
  final int durationSeconds;
  final DateTime now;
  final FocusSetViewModel? nextSet;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.agonezColors;
    final remaining = endsAt.difference(now);
    final complete = remaining <= Duration.zero;
    final progress = durationSeconds <= 0
        ? 1.0
        : (1 - remaining.inMilliseconds / (durationSeconds * 1000)).clamp(
            0.0,
            1.0,
          );
    final clock = _formatDuration(remaining);
    final set = nextSet;
    final prescription = set == null
        ? null
        : '${set.prescribedLoadKg == null ? '—' : _formatLoad(set.prescribedLoadKg!)} kg × '
              '${set.repMin == set.repMax ? set.repMin : '${set.repMin}–${set.repMax}'} '
              '@ RIR ${set.targetRir ?? '—'}';
    return Semantics(
      container: true,
      liveRegion: complete,
      label: complete
          ? l10n.timerRestComplete(clock)
          : '${l10n.timerRest} $clock',
      child: AgonezPanel(
        backgroundColor: complete
            ? colors.success.withValues(alpha: 0.08)
            : colors.goldSoft,
        borderColor: complete ? colors.success : AgonezColors.goldLine,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AgonezEyebrow(
              complete ? l10n.timerRestComplete(clock) : l10n.timerRest,
              color: complete ? colors.successText : colors.goldText,
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Text(
                    complete ? '+$clock' : clock,
                    key: const Key('focus-rest-clock'),
                    style: AgonezTypography.clock.copyWith(
                      color: complete ? colors.successText : colors.goldText,
                    ),
                  ),
                ),
                _TimerButton(
                  label: '−30',
                  semanticLabel: l10n.timerMinus30,
                  onPressed: onMinus,
                ),
                const SizedBox(width: 6),
                _TimerButton(
                  label: '+30',
                  semanticLabel: l10n.timerPlus30,
                  onPressed: onPlus,
                ),
                const SizedBox(width: 6),
                _TimerButton(
                  label: '×',
                  semanticLabel: l10n.timerEnd,
                  onPressed: onEnd,
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 2,
              color: complete ? colors.success : colors.gold,
              backgroundColor: colors.line,
            ),
            if (set != null) ...[
              const SizedBox(height: 10),
              Text(
                l10n.timerUpNextSet(set.ordinal),
                style: AgonezTypography.caption,
              ),
              if (prescription != null)
                Text(
                  prescription,
                  style: AgonezTypography.monoSmall.copyWith(
                    color: colors.prescriptionText,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimerButton extends StatelessWidget {
  const _TimerButton({
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel,
    excludeSemantics: true,
    child: SizedBox.square(
      dimension: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
        child: Text(label, style: AgonezTypography.monoSmall),
      ),
    ),
  );
}

class _EntryZone extends StatelessWidget {
  const _EntryZone({
    required this.exercise,
    required this.set,
    required this.draft,
    required this.enabled,
    required this.enableHaptics,
    required this.onLoadChanged,
    required this.onOpenKeypad,
    required this.onRepsChanged,
    required this.onOpenRepGrid,
    required this.onRirChanged,
    required this.onSetNote,
    required this.onMoreData,
  });

  final FocusExerciseViewModel exercise;
  final FocusSetViewModel set;
  final FocusEntryDraft draft;
  final bool enabled;
  final bool enableHaptics;
  final ValueChanged<double> onLoadChanged;
  final VoidCallback onOpenKeypad;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback onOpenRepGrid;
  final ValueChanged<int> onRirChanged;
  final VoidCallback onSetNote;
  final VoidCallback onMoreData;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.agonezColors;
    final repStart = math.max(1, (set.repMin ?? 6) - 1);
    final repValues = List<int>.generate(5, (index) => repStart + index);
    final customRep =
        draft.repetitions != null && !repValues.contains(draft.repetitions);
    final loadDelta = set.prescribedLoadKg != null && draft.loadKg != null
        ? draft.loadKg! - set.prescribedLoadKg!
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ZoneLabel(label: l10n.setLoad),
        const SizedBox(height: 6),
        _LoadStepper(
          value: draft.loadKg,
          step: exercise.loadStepKg <= 0 ? 2.5 : exercise.loadStepKg,
          enabled: enabled,
          diverges: loadDelta != null && loadDelta.abs() > 0.001,
          enableHaptics: enableHaptics,
          onChanged: onLoadChanged,
          onOpenKeypad: onOpenKeypad,
        ),
        if (draft.carriedFromLastSet) ...[
          const SizedBox(height: 5),
          Text(
            '• ${l10n.setKeptFromLast}',
            style: AgonezTypography.caption.copyWith(color: colors.goldText),
          ),
        ] else if (loadDelta != null && loadDelta.abs() > 0.001) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Text(
                  '• ${l10n.divergenceLoad('${loadDelta > 0 ? '+' : ''}${_formatLoad(loadDelta)}')}',
                  style: AgonezTypography.caption.copyWith(
                    color: colors.caution,
                  ),
                ),
              ),
              TextButton(
                onPressed: enabled && set.prescribedLoadKg != null
                    ? () => onLoadChanged(set.prescribedLoadKg!)
                    : null,
                child: Text(l10n.setReset),
              ),
            ],
          ),
        ],
        const SizedBox(height: 11),
        _ZoneLabel(
          label: l10n.setReps,
          target: set.repMin == null
              ? null
              : l10n.setTarget(
                  set.repMin == set.repMax
                      ? '${set.repMin}'
                      : '${set.repMin}–${set.repMax}',
                ),
        ),
        const SizedBox(height: 6),
        _SelectorRow(
          values: [
            for (final value in repValues) _SelectorValue(value, '$value'),
            _SelectorValue(
              customRep ? draft.repetitions! : null,
              customRep ? '${draft.repetitions}' : l10n.setOther,
            ),
          ],
          selected: draft.repetitions,
          enabled: enabled,
          isTarget: (value) =>
              value != null &&
              set.repMin != null &&
              value >= set.repMin! &&
              value <= (set.repMax ?? set.repMin!),
          semanticLabel: (value, selected, target) => value == null
              ? l10n.setOther
              : l10n.setRepA11y(
                  value,
                  selected ? l10n.setSelectedA11y : l10n.setNotSelectedA11y,
                  target ? l10n.setWithinTargetA11y : l10n.setOutsideTargetA11y,
                ),
          onChanged: (value) {
            if (value == null) {
              onOpenRepGrid();
            } else {
              onRepsChanged(value);
            }
          },
        ),
        if (draft.repetitions != null && set.repMin != null) ...[
          _RepsDivergence(set: set, repetitions: draft.repetitions!),
        ],
        const SizedBox(height: 12),
        _ZoneLabel(
          label: l10n.setRir,
          target: set.targetRir == null
              ? null
              : l10n.setTarget('${set.targetRir}'),
        ),
        const SizedBox(height: 6),
        _SelectorRow(
          values: const [
            _SelectorValue(0, '0'),
            _SelectorValue(1, '1'),
            _SelectorValue(2, '2'),
            _SelectorValue(3, '3'),
            _SelectorValue(4, '4'),
            _SelectorValue(5, '5+'),
          ],
          selected: draft.rir,
          enabled: enabled,
          isTarget: (value) => value == set.targetRir,
          semanticLabel: (value, selected, target) =>
              '${value == 5 ? '5 plus' : value} RIR, '
              '${selected ? l10n.setSelectedA11y : l10n.setNotSelectedA11y}, '
              '${target ? l10n.setWithinTargetA11y : l10n.setOutsideTargetA11y}',
          onChanged: (value) {
            if (value != null) onRirChanged(value);
          },
        ),
        if (draft.rir != null &&
            set.targetRir != null &&
            draft.rir != set.targetRir) ...[
          const SizedBox(height: 5),
          Text(
            '• ${draft.rir! < set.targetRir! ? l10n.divergenceRirDeeper : l10n.divergenceRirLighter}',
            style: AgonezTypography.caption.copyWith(color: colors.caution),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _AuxChip(
              icon: Icons.notes_rounded,
              label: l10n.noteSetTitle(set.ordinal),
              selected: (draft.comment ?? '').isNotEmpty,
              onPressed: enabled ? onSetNote : null,
            ),
            _AuxChip(
              icon: Icons.monitor_heart_outlined,
              label: l10n.moreDataTitle,
              selected: draft.heartRateBpm != null,
              onPressed: enabled ? onMoreData : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _ZoneLabel extends StatelessWidget {
  const _ZoneLabel({required this.label, this.target});

  final String label;
  final String? target;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      AgonezEyebrow(label),
      if (target != null) ...[
        const Spacer(),
        Text(
          target!,
          style: AgonezTypography.monoSmall.copyWith(
            color: context.agonezColors.prescriptionText,
          ),
        ),
      ],
    ],
  );
}

class _LoadStepper extends StatelessWidget {
  const _LoadStepper({
    required this.value,
    required this.step,
    required this.enabled,
    required this.diverges,
    required this.enableHaptics,
    required this.onChanged,
    required this.onOpenKeypad,
  });

  final double? value;
  final double step;
  final bool enabled;
  final bool diverges;
  final bool enableHaptics;
  final ValueChanged<double> onChanged;
  final VoidCallback onOpenKeypad;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.agonezColors;
    return SizedBox(
      height: AgonezSizes.loadControlHeight,
      child: Row(
        children: [
          _RepeatButton(
            key: const Key('focus-load-minus'),
            icon: Icons.remove,
            semanticLabel: l10n.setMinusLoadA11y(_formatLoad(step)),
            enabled: enabled && value != null,
            enableHaptics: enableHaptics,
            onStep: () => onChanged(math.max(0, (value ?? 0) - step)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              button: true,
              enabled: enabled,
              label: value == null
                  ? l10n.setEnterLoad
                  : l10n.setLoadValueA11y(_formatLoad(value!)),
              excludeSemantics: true,
              child: Material(
                color: colors.sunk,
                shape: RoundedRectangleBorder(
                  borderRadius: AgonezRadii.controlBorder,
                  side: BorderSide(
                    color: diverges ? colors.caution : colors.control,
                    width: diverges ? 1.5 : 1,
                  ),
                ),
                child: InkWell(
                  key: const Key('focus-load-value'),
                  onTap: enabled ? onOpenKeypad : null,
                  borderRadius: AgonezRadii.controlBorder,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          value == null ? '—' : '${_formatLoad(value!)} kg',
                          style: AgonezTypography.inputNumber,
                        ),
                        Text(
                          l10n.setTapToType,
                          style: AgonezTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _RepeatButton(
            key: const Key('focus-load-plus'),
            icon: Icons.add,
            semanticLabel: l10n.setPlusLoadA11y(_formatLoad(step)),
            enabled: enabled,
            enableHaptics: enableHaptics,
            onStep: () => onChanged((value ?? 0) + step),
          ),
        ],
      ),
    );
  }
}

class _RepeatButton extends StatefulWidget {
  const _RepeatButton({
    required this.icon,
    required this.semanticLabel,
    required this.enabled,
    required this.enableHaptics,
    required this.onStep,
    super.key,
  });

  final IconData icon;
  final String semanticLabel;
  final bool enabled;
  final bool enableHaptics;
  final VoidCallback onStep;

  @override
  State<_RepeatButton> createState() => _RepeatButtonState();
}

class _RepeatButtonState extends State<_RepeatButton> {
  Timer? _delay;
  Timer? _repeat;
  bool _didRepeat = false;

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _start() {
    if (!widget.enabled) return;
    _didRepeat = false;
    _delay = Timer(const Duration(milliseconds: 400), () {
      _didRepeat = true;
      _step();
      _repeat = Timer.periodic(
        const Duration(milliseconds: 250),
        (_) => _step(),
      );
    });
  }

  void _step() {
    widget.onStep();
    if (widget.enableHaptics) HapticFeedback.selectionClick();
  }

  void _release() {
    if (!widget.enabled) return;
    if (!_didRepeat) _step();
    _stop();
  }

  void _stop() {
    _delay?.cancel();
    _repeat?.cancel();
    _delay = null;
    _repeat = null;
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: widget.enabled,
    label: widget.semanticLabel,
    onTap: widget.enabled ? _step : null,
    excludeSemantics: true,
    child: Opacity(
      opacity: widget.enabled ? 1 : 0.4,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.enabled ? (_) => _start() : null,
        onTapUp: widget.enabled ? (_) => _release() : null,
        onTapCancel: widget.enabled ? _stop : null,
        child: Container(
          width: AgonezSizes.loadControlWidth,
          height: AgonezSizes.loadControlHeight,
          decoration: BoxDecoration(
            color: context.agonezColors.raised,
            border: Border.all(color: context.agonezColors.controlStrong),
            borderRadius: AgonezRadii.controlBorder,
          ),
          child: Icon(widget.icon, size: 26),
        ),
      ),
    ),
  );
}

class _SelectorValue {
  const _SelectorValue(this.value, this.label);

  final int? value;
  final String label;
}

class _SelectorRow extends StatelessWidget {
  const _SelectorRow({
    required this.values,
    required this.selected,
    required this.enabled,
    required this.isTarget,
    required this.semanticLabel,
    required this.onChanged,
  });

  final List<_SelectorValue> values;
  final int? selected;
  final bool enabled;
  final bool Function(int? value) isTarget;
  final String Function(int? value, bool selected, bool target) semanticLabel;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    assert(values.length == 6);
    return Row(
      children: [
        for (var index = 0; index < values.length; index++) ...[
          if (index > 0) const SizedBox(width: 6),
          Expanded(
            child: _SelectorButton(
              value: values[index],
              selected: selected != null && selected == values[index].value,
              target: isTarget(values[index].value),
              enabled: enabled,
              semanticLabel: semanticLabel(
                values[index].value,
                selected != null && selected == values[index].value,
                isTarget(values[index].value),
              ),
              onPressed: () => onChanged(values[index].value),
            ),
          ),
        ],
      ],
    );
  }
}

class _SelectorButton extends StatelessWidget {
  const _SelectorButton({
    required this.value,
    required this.selected,
    required this.target,
    required this.enabled,
    required this.semanticLabel,
    required this.onPressed,
  });

  final _SelectorValue value;
  final bool selected;
  final bool target;
  final bool enabled;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.agonezColors;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Material(
          color: selected ? colors.textPrimary : colors.raised,
          shape: RoundedRectangleBorder(
            borderRadius: AgonezRadii.controlBorder,
            side: BorderSide(
              color: selected ? colors.textPrimary : colors.control,
            ),
          ),
          child: InkWell(
            key: value.value == null
                ? const Key('focus-selector-other')
                : Key('focus-selector-${value.value}'),
            onTap: enabled ? onPressed : null,
            borderRadius: AgonezRadii.controlBorder,
            child: Container(
              height: AgonezSizes.selector,
              alignment: Alignment.center,
              decoration: target
                  ? BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: colors.prescription,
                          width: 3,
                        ),
                      ),
                    )
                  : null,
              child: Text(
                value.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AgonezTypography.inputNumber.copyWith(
                  color: selected ? colors.ground : colors.textPrimary,
                  fontSize: value.label.length > 2 ? 12 : 19,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RepsDivergence extends StatelessWidget {
  const _RepsDivergence({required this.set, required this.repetitions});

  final FocusSetViewModel set;
  final int repetitions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final min = set.repMin!;
    final max = set.repMax ?? min;
    final message = repetitions < min
        ? l10n.divergenceRepsBelow(min - repetitions)
        : repetitions > max
        ? l10n.divergenceRepsAbove(repetitions - max)
        : null;
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text(
        '• $message',
        style: AgonezTypography.caption.copyWith(
          color: context.agonezColors.caution,
        ),
      ),
    );
  }
}

class _AuxChip extends StatelessWidget {
  const _AuxChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AgonezSizes.auxiliaryChipHeight,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: selected
            ? context.agonezColors.goldText
            : context.agonezColors.textSecondary,
        side: BorderSide(
          color: selected
              ? AgonezColors.goldLine
              : context.agonezColors.control,
        ),
        minimumSize: const Size(0, AgonezSizes.auxiliaryChipHeight),
        padding: const EdgeInsets.symmetric(horizontal: 11),
      ),
      icon: Icon(icon, size: 17),
      label: Text(label, maxLines: 1),
    ),
  );
}

class _ExerciseCompleteCard extends StatelessWidget {
  const _ExerciseCompleteCard({
    required this.exercise,
    required this.onExerciseNote,
    required this.onAddExtraSet,
  });

  final FocusExerciseViewModel exercise;
  final VoidCallback onExerciseNote;
  final VoidCallback onAddExtraSet;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.agonezColors;
    return AgonezPanel(
      borderColor: colors.success.withValues(alpha: 0.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: colors.successText, size: 20),
              const SizedBox(width: 8),
              Text(l10n.workoutExerciseComplete, style: AgonezTypography.title),
            ],
          ),
          const SizedBox(height: 12),
          for (final set in exercise.sets) ...[
            Row(
              children: [
                SizedBox(
                  width: 46,
                  child: Text(
                    set.isExtra
                        ? l10n.workoutExtraLabel
                        : l10n.workoutSetLabel(set.ordinal),
                    style: AgonezTypography.caption,
                  ),
                ),
                Expanded(
                  child: Text(
                    set.isSkipped
                        ? l10n.workoutSkippedLabel
                        : '${_formatLoad(set.loadKg ?? 0)} × ${set.repetitions} @${set.rir}',
                    style: AgonezTypography.monoSmall.copyWith(
                      color: set.isSkipped
                          ? colors.caution
                          : colors.textPrimary,
                    ),
                  ),
                ),
                if (!set.isExtra && set.prescribedLoadKg != null)
                  Text(
                    '${_formatLoad(set.prescribedLoadKg!)} × '
                    '${set.repMin == set.repMax ? set.repMin : '${set.repMin}–${set.repMax}'}',
                    style: AgonezTypography.monoSmall.copyWith(
                      color: colors.prescriptionText,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),
          ],
          const Divider(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onExerciseNote,
                  child: Text(l10n.noteExerciseTitle),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onAddExtraSet,
                  child: Text(l10n.deviationAddSet),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PinnedBar extends StatelessWidget {
  const _PinnedBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      16,
      9,
      16,
      MediaQuery.paddingOf(context).bottom + AgonezSizes.bottomSafeGap,
    ),
    decoration: BoxDecoration(
      color: context.agonezColors.ground,
      border: Border(top: BorderSide(color: context.agonezColors.line)),
    ),
    child: child,
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.body,
    this.eyebrow,
    this.footer,
    this.maxHeightFactor = 0.86,
  });

  final String title;
  final String? eyebrow;
  final Widget body;
  final Widget? footer;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AgonezSheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (eyebrow != null) ...[
                        AgonezEyebrow(eyebrow!),
                        const SizedBox(height: 4),
                      ],
                      Text(title, style: AgonezTypography.sheetTitle),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context).commonClose,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(),
          Flexible(child: body),
          if (footer != null) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: footer,
            ),
          ],
        ],
      ),
    ),
  );
}

class _OutlineSheet extends StatelessWidget {
  const _OutlineSheet({required this.workout});

  final FocusWorkoutViewModel workout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.agonezColors;
    return _SheetFrame(
      title: l10n.workoutOutlineTitle(workout.workoutUnitName),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        itemCount: workout.exercises.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final exercise = workout.exercises[index];
          final current = index == workout.currentExerciseIndex;
          final state = exercise.isSkipped
              ? l10n.workoutSkippedLabel
              : exercise.isComplete
              ? l10n.workoutExerciseComplete
              : current
              ? l10n.workspaceActive
              : l10n.workoutUpNext;
          return Semantics(
            selected: current,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: current ? colors.goldSoft : Colors.transparent,
                      border: Border.all(
                        color: current ? colors.gold : colors.control,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: AgonezTypography.monoSmall,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: AgonezTypography.label.copyWith(
                            color: exercise.isSkipped
                                ? colors.textMuted
                                : colors.textPrimary,
                            decoration: exercise.isSkipped
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$state · ${exercise.resolvedSetCount}/${exercise.sets.length}',
                          style: AgonezTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  if (index > workout.currentExerciseIndex &&
                      !exercise.isComplete)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(exercise),
                      child: Text(l10n.workoutDoNext),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActionsSheet extends StatelessWidget {
  const _ActionsSheet({required this.workout, required this.exercise});

  final FocusWorkoutViewModel workout;
  final FocusExerciseViewModel exercise;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canSubstitute =
        !exercise.hasRecordedSets &&
        exercise.mode == FocusExerciseMode.asPrescribed;
    final canSkipSet = workout.currentSet?.prescribedSetId != null;
    final canSkipExercise = exercise.exercisePrescriptionId != null;
    return _SheetFrame(
      title: l10n.workoutActions,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
        children: [
          if (exercise.atlasPeek != null)
            _ActionTile(
              icon: Icons.menu_book_outlined,
              label: l10n.atlasQuickView,
              onTap: () => Navigator.pop(context, _FocusAction.quickPeek),
            ),
          _ActionTile(
            icon: Icons.notes_rounded,
            label: l10n.noteSetTitle(workout.currentSet?.ordinal ?? 1),
            onTap: workout.currentSet == null
                ? null
                : () => Navigator.pop(context, _FocusAction.setNote),
          ),
          _ActionTile(
            icon: Icons.monitor_heart_outlined,
            label: l10n.moreDataTitle,
            onTap: workout.currentSet == null
                ? null
                : () => Navigator.pop(context, _FocusAction.moreData),
          ),
          _ActionTile(
            icon: Icons.comment_outlined,
            label: l10n.noteExerciseTitle,
            onTap: () => Navigator.pop(context, _FocusAction.exerciseNote),
          ),
          const Divider(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: AgonezEyebrow(l10n.deviationSectionTitle),
          ),
          _ActionTile(
            icon: Icons.skip_next_outlined,
            label: l10n.deviationSkipSet(workout.currentSet?.ordinal ?? 1),
            friction: 1,
            onTap: !canSkipSet
                ? null
                : () => Navigator.pop(context, _FocusAction.skipSet),
          ),
          _ActionTile(
            icon: Icons.add_box_outlined,
            label: l10n.deviationAddSet,
            friction: 1,
            onTap: () => Navigator.pop(context, _FocusAction.addSet),
          ),
          _ActionTile(
            icon: Icons.swap_horiz,
            label: l10n.deviationSubstitute,
            supporting: canSubstitute ? null : l10n.deviationSubstitutionLocked,
            friction: 2,
            onTap: canSubstitute
                ? () => Navigator.pop(context, _FocusAction.substitute)
                : null,
          ),
          _ActionTile(
            icon: Icons.remove_circle_outline,
            label: l10n.deviationSkipExercise(exercise.name),
            friction: 2,
            onTap: canSkipExercise
                ? () => Navigator.pop(context, _FocusAction.skipExercise)
                : null,
          ),
          _ActionTile(
            icon: Icons.playlist_add,
            label: l10n.deviationAddUnplanned,
            friction: 3,
            onTap: () => Navigator.pop(context, _FocusAction.addUnplanned),
          ),
          const Divider(height: 20),
          _ActionTile(
            icon: Icons.flag_outlined,
            label: l10n.workoutFinishWorkout,
            onTap: () => Navigator.pop(context, _FocusAction.finish),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.supporting,
    this.friction,
  });

  final IconData icon;
  final String label;
  final String? supporting;
  final int? friction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.agonezColors;
    final l10n = AppLocalizations.of(context);
    return ListTile(
      enabled: onTap != null,
      minTileHeight: 54,
      leading: Icon(icon, size: 21),
      title: Text(label, style: AgonezTypography.label),
      subtitle: supporting == null
          ? null
          : Text(supporting!, style: AgonezTypography.caption),
      trailing: friction == null
          ? const Icon(Icons.chevron_right, size: 19)
          : Semantics(
              label: l10n.deviationFrictionA11y(friction!),
              excludeSemantics: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List<Widget>.generate(
                  friction!,
                  (_) => Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(left: 3),
                    decoration: BoxDecoration(
                      color: colors.caution,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
      onTap: onTap,
    );
  }
}

class _HoldActionSheet extends StatelessWidget {
  const _HoldActionSheet({
    required this.title,
    required this.explanation,
    required this.label,
    required this.duration,
    required this.neutral,
    required this.enableHaptics,
  });

  final String title;
  final String explanation;
  final String label;
  final Duration duration;
  final bool neutral;
  final bool enableHaptics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final seconds = (duration.inMilliseconds / 1000).toStringAsFixed(1);
    return _SheetFrame(
      title: title,
      eyebrow: l10n.deviationSectionTitle,
      maxHeightFactor: 0.62,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Text(explanation, style: AgonezTypography.bodyLarge),
      ),
      footer: HoldToConfirm(
        key: const Key('focus-hold-confirm'),
        label: label,
        duration: duration,
        durationLabel: l10n.deviationHoldDuration(seconds),
        tone: neutral ? HoldToConfirmTone.neutral : HoldToConfirmTone.caution,
        enableHaptics: enableHaptics,
        accessibilityActionLabel: label,
        onConfirmed: () => Navigator.of(context).pop(true),
      ),
    );
  }
}

class _FinishSheet extends StatelessWidget {
  const _FinishSheet({
    required this.workout,
    required this.elapsed,
    required this.enableHaptics,
  });

  final FocusWorkoutViewModel workout;
  final Duration elapsed;
  final bool enableHaptics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final incomplete = workout.incompleteSetCount;
    final isIncomplete = incomplete > 0;
    final offline =
        workout.syncStatus == WorkoutSyncStatus.offline ||
        workout.syncStatus == WorkoutSyncStatus.failed;
    return _SheetFrame(
      title: isIncomplete
          ? l10n.finishIncompleteTitle(workout.incompleteExerciseCount)
          : l10n.finishTitle,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isIncomplete) ...[
              Text(
                l10n.finishIncompleteExplanation(incomplete),
                style: AgonezTypography.bodyLarge,
              ),
              const SizedBox(height: 16),
            ],
            _SummaryRow(
              label: l10n.finishSetsRecorded,
              value: '${workout.recordedSets} / ${workout.totalSets}',
            ),
            _SummaryRow(
              label: l10n.finishDuration,
              value: _formatDuration(elapsed),
            ),
            const SizedBox(height: 12),
            Text(
              offline ? l10n.finishOfflineHint : l10n.finishOnlineHint,
              style: AgonezTypography.caption.copyWith(
                color: offline
                    ? context.agonezColors.caution
                    : context.agonezColors.textMuted,
              ),
            ),
          ],
        ),
      ),
      footer: isIncomplete
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AgonezPrimaryButton(
                  label: l10n.finishContinueWorkout,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 9),
                HoldToConfirm(
                  key: const Key('focus-finish-hold'),
                  label: l10n.finishHoldAnyway,
                  duration: const Duration(milliseconds: 1400),
                  durationLabel: l10n.deviationHoldDuration('1.4'),
                  enableHaptics: enableHaptics,
                  onConfirmed: () => Navigator.of(context).pop(true),
                ),
              ],
            )
          : AgonezPrimaryButton(
              key: const Key('focus-finish-confirm'),
              label: l10n.workoutFinishWorkout,
              onPressed: () => Navigator.of(context).pop(false),
            ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(label, style: AgonezTypography.body)),
        Text(value, style: AgonezTypography.monoSmall),
      ],
    ),
  );
}

class _AtlasQuickPeekSheet extends StatelessWidget {
  const _AtlasQuickPeekSheet({
    required this.exercise,
    required this.onOpenFull,
  });

  final FocusExerciseViewModel exercise;
  final VoidCallback? onOpenFull;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final peek = exercise.atlasPeek!;
    final regions = <String, double>{
      for (final region in peek.bodyMap.regions)
        region.regionId: region.intensity,
    };
    final technique = <(String, String?)>[
      (l10n.atlasTechniqueSetup, peek.techniqueTldr.setup),
      (l10n.atlasTechniqueExecution, peek.techniqueTldr.execution),
      (l10n.atlasTechniqueFocus, peek.techniqueTldr.focus),
      (l10n.atlasTechniqueStopWhen, peek.techniqueTldr.stopWhen),
    ];
    return _SheetFrame(
      title: exercise.name,
      eyebrow: l10n.atlasQuickView,
      maxHeightFactor: 0.9,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          if ((peek.exercise.fullName ?? '').isNotEmpty)
            Text(peek.exercise.fullName!, style: AgonezTypography.body),
          const SizedBox(height: 14),
          for (final block in technique)
            if ((block.$2 ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AgonezEyebrow(block.$1),
                    const SizedBox(height: 4),
                    Text(block.$2!, style: AgonezTypography.bodyLarge),
                  ],
                ),
              ),
          const Divider(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 330;
              final map = AnatomyHeatmap(
                regionIntensities: regions,
                height: narrow ? 190 : 220,
                semanticsLabel: l10n.atlasSectionAnatomy,
              );
              final muscles = Column(
                children: [
                  for (final muscle in peek.musclesTop.take(4))
                    _MuscleExposureRow(
                      name: muscle.name,
                      etu: muscle.etuCm2,
                      share: muscle.capacityShare,
                    ),
                ],
              );
              if (narrow) {
                return Column(
                  children: [map, const SizedBox(height: 12), muscles],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: map),
                  const SizedBox(width: 12),
                  Expanded(child: muscles),
                ],
              );
            },
          ),
          if ((exercise.planNote ?? '').isNotEmpty) ...[
            const Divider(height: 24),
            AgonezEyebrow(l10n.atlasPlanNoteThisWorkout),
            const SizedBox(height: 5),
            Text(exercise.planNote!, style: AgonezTypography.body),
          ],
        ],
      ),
      footer: onOpenFull == null
          ? null
          : AgonezPrimaryButton(
              label: l10n.atlasOpenFull,
              onPressed: () {
                Navigator.of(context).pop();
                onOpenFull!();
              },
            ),
    );
  }
}

class _MuscleExposureRow extends StatelessWidget {
  const _MuscleExposureRow({
    required this.name,
    required this.etu,
    required this.share,
  });

  final String name;
  final double etu;
  final double? share;

  @override
  Widget build(BuildContext context) {
    final colors = context.agonezColors;
    final normalized = (share ?? 0).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AgonezTypography.caption,
                ),
              ),
              Text(etu.toStringAsFixed(1), style: AgonezTypography.monoSmall),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: normalized,
              minHeight: 3,
              color: colors.muscleHeat,
              backgroundColor: colors.line,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteSheet extends StatefulWidget {
  const _NoteSheet({
    required this.title,
    required this.hint,
    required this.initialValue,
    required this.suggestions,
    this.supportingText,
  });

  final String title;
  final String hint;
  final String? initialValue;
  final List<String> suggestions;
  final String? supportingText;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _append(String suggestion) {
    final current = _controller.text.trim();
    _controller.text = current.isEmpty ? suggestion : '$current. $suggestion';
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _SheetFrame(
        title: widget.title,
        maxHeightFactor: 0.74,
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.supportingText != null) ...[
                Text(widget.supportingText!, style: AgonezTypography.caption),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 5,
                maxLength: 1000,
                decoration: InputDecoration(hintText: widget.hint),
              ),
              if (widget.suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final suggestion in widget.suggestions)
                      ActionChip(
                        label: Text(suggestion),
                        onPressed: () => _append(suggestion),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        footer: AgonezPrimaryButton(
          label: l10n.noteSave,
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
        ),
      ),
    );
  }
}

class _MoreDataSheet extends StatefulWidget {
  const _MoreDataSheet({required this.selected});

  final int? selected;

  @override
  State<_MoreDataSheet> createState() => _MoreDataSheetState();
}

class _MoreDataSheetState extends State<_MoreDataSheet> {
  int? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SheetFrame(
      title: l10n.moreDataTitle,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AgonezEyebrow(l10n.moreDataHeartRate),
            const SizedBox(height: 9),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in const [
                  90,
                  100,
                  110,
                  120,
                  130,
                  140,
                  150,
                  160,
                ])
                  ChoiceChip(
                    label: Text('$value'),
                    selected: _selected == value,
                    onSelected: (_) => setState(() => _selected = value),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(l10n.moreDataFutureSensor, style: AgonezTypography.caption),
          ],
        ),
      ),
      footer: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop<int?>(null),
            child: Text(l10n.commonCancel),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(_selected),
              child: Text(l10n.commonDone),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadKeypadSheet extends StatefulWidget {
  const _LoadKeypadSheet({this.current, this.prescribed, this.previous});

  final double? current;
  final double? prescribed;
  final double? previous;

  @override
  State<_LoadKeypadSheet> createState() => _LoadKeypadSheetState();
}

class _LoadKeypadSheetState extends State<_LoadKeypadSheet> {
  late String _value;

  @override
  void initState() {
    super.initState();
    _value = widget.current == null ? '' : _formatLoad(widget.current!);
  }

  void _press(String value) {
    setState(() {
      if (value == 'backspace') {
        if (_value.isNotEmpty) _value = _value.substring(0, _value.length - 1);
      } else if (value == '.') {
        if (!_value.contains('.')) _value = _value.isEmpty ? '0.' : '$_value.';
      } else if (_value.length < 7) {
        final decimal = _value.indexOf('.');
        if (decimal < 0 || _value.length - decimal <= 2) {
          _value = _value == '0' ? value : '$_value$value';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parsed = double.tryParse(_value);
    return _SheetFrame(
      title: l10n.setLoad,
      maxHeightFactor: 0.84,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          children: [
            Container(
              height: 64,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.agonezColors.sunk,
                borderRadius: AgonezRadii.controlBorder,
                border: Border.all(color: context.agonezColors.control),
              ),
              child: Text(
                _value.isEmpty ? '— kg' : '$_value kg',
                style: AgonezTypography.inputNumber,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                if (widget.prescribed != null)
                  ActionChip(
                    label: Text(
                      '${l10n.workoutPrescribed} ${_formatLoad(widget.prescribed!)}',
                    ),
                    onPressed: () => setState(
                      () => _value = _formatLoad(widget.prescribed!),
                    ),
                  ),
                if (widget.previous != null)
                  ActionChip(
                    label: Text(
                      '${l10n.workoutLastExposure('')} ${_formatLoad(widget.previous!)}',
                    ),
                    onPressed: () =>
                        setState(() => _value = _formatLoad(widget.previous!)),
                  ),
                if (widget.current != null)
                  ActionChip(
                    label: Text(
                      '${l10n.setLoad} ${_formatLoad(widget.current!)}',
                    ),
                    onPressed: () =>
                        setState(() => _value = _formatLoad(widget.current!)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1.7,
              mainAxisSpacing: 7,
              crossAxisSpacing: 7,
              children: [
                for (final key in const [
                  '1',
                  '2',
                  '3',
                  '4',
                  '5',
                  '6',
                  '7',
                  '8',
                  '9',
                  '.',
                  '0',
                  'backspace',
                ])
                  OutlinedButton(
                    key: Key('focus-keypad-$key'),
                    onPressed: () => _press(key),
                    child: key == 'backspace'
                        ? const Icon(Icons.backspace_outlined, size: 20)
                        : Text(key, style: AgonezTypography.inputNumber),
                  ),
              ],
            ),
          ],
        ),
      ),
      footer: AgonezPrimaryButton(
        label: l10n.commonDone,
        onPressed: parsed == null || parsed < 0
            ? null
            : () => Navigator.of(context).pop(parsed),
      ),
    );
  }
}

class _RepGridSheet extends StatelessWidget {
  const _RepGridSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SheetFrame(
      title: l10n.setReps,
      maxHeightFactor: 0.76,
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 7,
          crossAxisSpacing: 7,
          childAspectRatio: 1,
        ),
        itemCount: 30,
        itemBuilder: (context, index) {
          final value = index + 1;
          return OutlinedButton(
            key: Key('focus-rep-grid-$value'),
            onPressed: () => Navigator.of(context).pop(value),
            style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
            child: Text('$value', style: AgonezTypography.inputNumber),
          );
        },
      ),
    );
  }
}

class _EditSetSheet extends StatefulWidget {
  const _EditSetSheet({required this.exercise, required this.set});

  final FocusExerciseViewModel exercise;
  final FocusSetViewModel set;

  @override
  State<_EditSetSheet> createState() => _EditSetSheetState();
}

class _EditSetSheetState extends State<_EditSetSheet> {
  late double _load;
  late int _reps;
  late int _rir;

  @override
  void initState() {
    super.initState();
    _load = widget.set.loadKg ?? widget.set.prescribedLoadKg ?? 0;
    _reps = widget.set.repetitions ?? widget.set.repMin ?? 1;
    _rir = widget.set.rir ?? widget.set.targetRir ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repStart = math.max(1, _reps - 2);
    return _SheetFrame(
      title: l10n.setEditTitle(widget.set.ordinal),
      eyebrow: l10n.setEditingNormal,
      maxHeightFactor: 0.88,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ZoneLabel(label: l10n.setLoad),
            const SizedBox(height: 6),
            _LoadStepper(
              value: _load,
              step: widget.exercise.loadStepKg,
              enabled: true,
              diverges:
                  widget.set.prescribedLoadKg != null &&
                  _load != widget.set.prescribedLoadKg,
              enableHaptics: false,
              onChanged: (value) => setState(() => _load = value),
              onOpenKeypad: () async {
                final value = await showModalBottomSheet<double>(
                  context: context,
                  builder: (context) => _LoadKeypadSheet(
                    current: _load,
                    prescribed: widget.set.prescribedLoadKg,
                    previous: null,
                  ),
                );
                if (mounted && value != null) setState(() => _load = value);
              },
            ),
            const SizedBox(height: 12),
            _ZoneLabel(label: l10n.setReps),
            const SizedBox(height: 6),
            _SelectorRow(
              values: [
                for (var value = repStart; value < repStart + 5; value++)
                  _SelectorValue(value, '$value'),
                const _SelectorValue(null, '…'),
              ],
              selected: _reps,
              enabled: true,
              isTarget: (value) =>
                  value != null &&
                  widget.set.repMin != null &&
                  value >= widget.set.repMin! &&
                  value <= (widget.set.repMax ?? widget.set.repMin!),
              semanticLabel: (value, selected, target) =>
                  '${value ?? l10n.setOther}',
              onChanged: (value) async {
                if (value != null) {
                  setState(() => _reps = value);
                  return;
                }
                final picked = await showModalBottomSheet<int>(
                  context: context,
                  builder: (_) => const _RepGridSheet(),
                );
                if (mounted && picked != null) setState(() => _reps = picked);
              },
            ),
            const SizedBox(height: 12),
            _ZoneLabel(label: l10n.setRir),
            const SizedBox(height: 6),
            _SelectorRow(
              values: const [
                _SelectorValue(0, '0'),
                _SelectorValue(1, '1'),
                _SelectorValue(2, '2'),
                _SelectorValue(3, '3'),
                _SelectorValue(4, '4'),
                _SelectorValue(5, '5+'),
              ],
              selected: _rir,
              enabled: true,
              isTarget: (value) => value == widget.set.targetRir,
              semanticLabel: (value, selected, target) => '$value RIR',
              onChanged: (value) {
                if (value != null) setState(() => _rir = value);
              },
            ),
          ],
        ),
      ),
      footer: AgonezPrimaryButton(
        label: l10n.setSave(widget.set.ordinal),
        onPressed: () => Navigator.of(context).pop(
          FocusSetEdit(
            exercise: widget.exercise,
            set: widget.set,
            loadKg: _load,
            repetitions: _reps,
            rir: _rir,
            comment: widget.set.comment,
            heartRateBpm: widget.set.heartRateBpm,
          ),
        ),
      ),
    );
  }
}
