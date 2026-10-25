part of 'focus_mode_screen.dart';

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
        borderColor: colors.goldLine,
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
            Text(
              l10n.workoutRecordWhatYouDo,
              style: AgonezTypography.of(context).bodyMedium,
            ),
          ],
        ),
      );
    }
    final load = set.prescribedLoadKg == null
        ? '— kg'
        : '${formatLoad(set.prescribedLoadKg!)} kg';
    final reps = set.repMin == set.repMax
        ? '${set.repMin}'
        : '${set.repMin}–${set.repMax}';
    final rir = set.targetRir == null ? '—' : '${set.targetRir}';
    final previous = exercise.previousSet;
    return AgonezPanel(
      backgroundColor: colors.prescriptionBackground,
      borderColor: colors.prescriptionLine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AgonezEyebrow(
            l10n.workoutPrescribedSet(set.number),
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
                    '${previous.loadKg == null ? '—' : formatLoad(previous.loadKg!)} × '
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
        : '${set.prescribedLoadKg == null ? '—' : formatLoad(set.prescribedLoadKg!)} kg × '
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
        borderColor: complete ? colors.success : colors.goldLine,
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
                l10n.timerUpNextSet(set.number),
                style: AgonezTypography.of(context).bodySmall,
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
        child: Text(label, style: AgonezTypography.of(context).labelSmall),
      ),
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
              Text(
                l10n.workoutExerciseComplete,
                style: AgonezTypography.of(context).titleLarge,
              ),
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
                        : l10n.workoutSetLabel(set.number),
                    style: AgonezTypography.of(context).bodySmall,
                  ),
                ),
                Expanded(
                  child: Text(
                    set.isSkipped
                        ? l10n.workoutSkippedLabel
                        : '${formatLoad(set.loadKg ?? 0)} × ${set.repetitions} @${set.rir}',
                    style: AgonezTypography.monoSmall.copyWith(
                      color: set.isSkipped
                          ? colors.caution
                          : colors.textPrimary,
                    ),
                  ),
                ),
                if (!set.isExtra && set.prescribedLoadKg != null)
                  Text(
                    '${formatLoad(set.prescribedLoadKg!)} × '
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
