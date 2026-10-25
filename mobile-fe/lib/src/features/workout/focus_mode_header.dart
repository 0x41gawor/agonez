part of 'focus_mode_screen.dart';

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
                    style: AgonezTypography.of(context).labelSmall,
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
                      style: AgonezTypography.of(context).headlineLarge,
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
          Text(
            exercise.variantLabel!,
            style: AgonezTypography.of(context).bodySmall,
          ),
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
      Text(value, maxLines: 2, style: AgonezTypography.of(context).labelMedium),
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
        ? '✓ ${formatLoad(set.loadKg ?? 0)}×${set.repetitions} @${set.rir}'
        : set.isSkipped
        ? l10n.workoutSkippedLabel
        : set.isExtra
        ? '${l10n.workoutExtraLabel} ${set.ordinal}'
        : '${set.ordinal} · ${set.prescribedLoadKg == null ? '—' : formatLoad(set.prescribedLoadKg!)}';
    final borderColor = set.isSkipped
        ? colors.caution
        : isCurrent
        ? colors.gold
        : set.isExtra
        ? colors.goldLine
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
