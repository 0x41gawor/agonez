part of 'focus_mode_screen.dart';

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
                      Text(
                        title,
                        style: AgonezTypography.of(context).headlineMedium,
                      ),
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
                      style: AgonezTypography.of(context).labelSmall,
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
                          style: AgonezTypography.of(context).bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (index > workout.currentExerciseIndex &&
                      !exercise.isComplete)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(exercise),
                      child: Text(
                        workout.canPostponeCurrent
                            ? l10n.workoutDoNow
                            : l10n.workoutDoNext,
                      ),
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
    final postponeReplacement = workout.postponeReplacement;
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
            label: l10n.noteSetTitle(workout.currentSet?.number ?? 1),
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
            label: l10n.deviationSkipSet(workout.currentSet?.number ?? 1),
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
          if (postponeReplacement != null)
            _ActionTile(
              key: const Key('focus-postpone'),
              icon: Icons.low_priority,
              label: l10n.deviationPostpone(exercise.name),
              supporting: workout.canPostponeCurrent
                  ? null
                  : l10n.deviationPostponeLocked,
              friction: 1,
              onTap: workout.canPostponeCurrent
                  ? () => Navigator.pop(context, _FocusAction.postpone)
                  : null,
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
    super.key,
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
      title: Text(label, style: AgonezTypography.of(context).labelMedium),
      subtitle: supporting == null
          ? null
          : Text(supporting!, style: AgonezTypography.of(context).bodySmall),
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
        child: Text(explanation, style: AgonezTypography.of(context).bodyLarge),
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
                style: AgonezTypography.of(context).bodyLarge,
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
        Expanded(
          child: Text(label, style: AgonezTypography.of(context).bodyMedium),
        ),
        Text(value, style: AgonezTypography.of(context).labelSmall),
      ],
    ),
  );
}
