part of 'focus_mode_screen.dart';

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
    required this.onOpenRepKeypad,
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
  final VoidCallback onOpenRepKeypad;
  final ValueChanged<int> onRirChanged;
  final VoidCallback onSetNote;
  final VoidCallback onMoreData;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.agonezColors;
    final repValues = _repWindow(set.repMin, set.repMax);
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
                  '• ${l10n.divergenceLoad('${loadDelta > 0 ? '+' : ''}${formatLoad(loadDelta)}')}',
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
          target: switch (_repTarget(set)) {
            final target? => l10n.setTarget(target),
            null => null,
          },
        ),
        const SizedBox(height: 6),
        _SelectorRow(
          keyPrefix: 'focus-reps',
          values: [
            for (final value in repValues) _SelectorValue(value, '$value'),
            _SelectorValue(
              customRep ? draft.repetitions! : null,
              customRep ? '${draft.repetitions}' : l10n.setOther,
              opensKeypad: true,
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
            // The last button always opens the keypad, also once it shows
            // a count typed there, so that count can be corrected.
            if (value == null || !repValues.contains(value)) {
              onOpenRepKeypad();
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
          keyPrefix: 'focus-rir',
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
              label: l10n.noteSetTitle(set.number),
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

/// The five rep counts offered as buttons: the whole target range and one
/// below it when they fit, otherwise the range from its minimum. Any other
/// count is typed on the keypad.
List<int> _repWindow(int? repMin, int? repMax) {
  final min = repMin ?? 6;
  final max = math.max(min, repMax ?? min);
  final start = max - min + 1 <= 4 ? math.max(1, min - 1) : min;
  return List<int>.generate(5, (index) => start + index);
}

/// The set's rep target as shown, e.g. `6–8`; null without one.
String? _repTarget(FocusSetViewModel? set) => switch (set) {
  FocusSetViewModel(repMin: final min?, :final repMax) =>
    repMax == null || repMax == min ? '$min' : '$min–$repMax',
  _ => null,
};

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
            semanticLabel: l10n.setMinusLoadA11y(formatLoad(step)),
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
                  : l10n.setLoadValueA11y(formatLoad(value!)),
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
                          value == null ? '—' : '${formatLoad(value!)} kg',
                          style: AgonezTypography.inputNumberOf(context),
                        ),
                        Text(
                          l10n.setTapToType,
                          style: AgonezTypography.of(context).bodySmall,
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
            semanticLabel: l10n.setPlusLoadA11y(formatLoad(step)),
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
  const _SelectorValue(this.value, this.label, {this.opensKeypad = false});

  final int? value;
  final String label;

  /// Opens the keypad instead of choosing [value].
  final bool opensKeypad;
}

class _SelectorRow extends StatelessWidget {
  const _SelectorRow({
    required this.keyPrefix,
    required this.values,
    required this.selected,
    required this.enabled,
    required this.isTarget,
    required this.semanticLabel,
    required this.onChanged,
  });

  /// Names the row's buttons in keys, e.g. `focus-reps-8`.
  final String keyPrefix;
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
              keyPrefix: keyPrefix,
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
    required this.keyPrefix,
    required this.value,
    required this.selected,
    required this.target,
    required this.enabled,
    required this.semanticLabel,
    required this.onPressed,
  });

  final String keyPrefix;
  final _SelectorValue value;
  final bool selected;
  final bool target;
  final bool enabled;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.agonezColors;
    // A count typed on the keypad stays editable there.
    final edits = value.opensKeypad && value.value != null;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: semanticLabel,
      hint: value.opensKeypad
          ? AppLocalizations.of(context).setRepsKeypadA11y
          : null,
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
            key: Key('$keyPrefix-${value.value ?? 'other'}'),
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: Text(
                      value.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AgonezTypography.inputNumber.copyWith(
                        color: selected ? colors.ground : colors.textPrimary,
                        fontSize: value.label.length > 2 ? 12 : 19,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (edits)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(
                        Icons.edit_outlined,
                        size: 12,
                        color: selected ? colors.ground : colors.textSecondary,
                      ),
                    ),
                ],
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
              ? context.agonezColors.goldLine
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
