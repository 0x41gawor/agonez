part of 'focus_mode_screen.dart';

/// The plan's warm-up or stretching around the workout's exercises: its note
/// read as a checklist, one movement a line. Ticks stay on this phone.
class WorkoutRoutineScreen extends StatefulWidget {
  const WorkoutRoutineScreen({
    required this.workout,
    required this.kind,
    required this.groups,
    required this.progress,
    required this.actionLabel,
    required this.onProgressChanged,
    required this.onAction,
    required this.onMinimise,
    this.onSync,
    this.enableHaptics = true,
    this.now,
    super.key,
  });

  final FocusWorkoutViewModel workout;
  final RoutineKind kind;
  final List<RoutineGroup> groups;
  final RoutineProgress progress;

  /// What moving on does, such as starting the first exercise.
  final String actionLabel;
  final ValueChanged<RoutineProgress> onProgressChanged;

  /// Moves on, with the routine's ticks marked finished.
  final ValueChanged<RoutineProgress> onAction;
  final VoidCallback onMinimise;
  final VoidCallback? onSync;
  final bool enableHaptics;
  final DateTime Function()? now;

  @override
  State<WorkoutRoutineScreen> createState() => _WorkoutRoutineScreenState();
}

class _WorkoutRoutineScreenState extends State<WorkoutRoutineScreen> {
  late Set<int> _done = {...widget.progress.done};
  Timer? _ticker;

  DateTime get _now => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    // The elapsed time in the top bar runs from the workout's start.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggle(int index) {
    if (widget.enableHaptics) HapticFeedback.selectionClick();
    setState(() {
      _done = {..._done};
      if (!_done.remove(index)) _done.add(index);
    });
    widget.onProgressChanged(widget.progress.copyWith(done: _done));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final warmup = widget.kind == RoutineKind.warmup;
    // Each movement keeps its place in the whole routine, which is how its
    // tick is stored.
    var next = 0;
    final numbered = [
      for (final group in widget.groups)
        (group, [for (final item in group.items) (next++, item)]),
    ];
    final total = next;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onMinimise();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _FocusTopBar(
                workout: widget.workout,
                now: _now,
                onMinimise: widget.onMinimise,
                onSync: widget.onSync,
              ),
              Expanded(
                child: ListView(
                  key: const Key('routine-list'),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  children: [
                    AgonezEyebrow(
                      warmup
                          ? l10n.routineWarmupEyebrow
                          : l10n.routineStretchEyebrow,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      warmup
                          ? l10n.routineWarmupTitle
                          : l10n.routineStretchTitle,
                      style: AgonezTypography.of(context).headlineLarge,
                    ),
                    const SizedBox(height: 14),
                    _RoutineMeter(done: _done.length, total: total),
                    const SizedBox(height: 20),
                    for (final (group, items) in numbered) ...[
                      if (group.title != null) ...[
                        AgonezEyebrow(group.title!),
                        const SizedBox(height: 8),
                      ],
                      AgonezPanel(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (final (at, item) in items) ...[
                              if (at != items.first.$1)
                                const Divider(height: 1),
                              _RoutineItemRow(
                                key: Key('routine-item-$at'),
                                item: item,
                                done: _done.contains(at),
                                onTap: () => _toggle(at),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    Text(
                      l10n.routineNotRecorded,
                      style: AgonezTypography.of(context).bodySmall,
                    ),
                  ],
                ),
              ),
              _PinnedBar(
                child: AgonezPrimaryButton(
                  key: const Key('routine-action'),
                  label: widget.actionLabel,
                  onPressed: () => widget.onAction(
                    widget.progress.copyWith(done: _done, finished: true),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineMeter extends StatelessWidget {
  const _RoutineMeter({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.agonezColors;
    final complete = total > 0 && done >= total;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(2)),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: total == 0 ? 0 : done / total),
              duration: AgonezDurations.standard,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 4,
                backgroundColor: colors.lineSubtle,
                color: complete ? colors.success : colors.gold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          AppLocalizations.of(context).routineProgress(done, total),
          key: const Key('routine-progress'),
          style: AgonezTypography.of(context).labelSmall,
        ),
      ],
    );
  }
}

class _RoutineItemRow extends StatelessWidget {
  const _RoutineItemRow({
    required this.item,
    required this.done,
    required this.onTap,
    super.key,
  });

  final RoutineItem item;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.agonezColors;
    return Semantics(
      checked: done,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AgonezDurations.quick,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? colors.success : Colors.transparent,
                  border: Border.all(
                    color: done ? colors.success : colors.controlStrong,
                    width: 1.5,
                  ),
                ),
                child: done
                    ? Icon(Icons.check_rounded, size: 16, color: colors.ground)
                    : null,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AgonezTypography.bodyLarge.copyWith(
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                        color: done ? colors.textMuted : colors.textPrimary,
                      ),
                    ),
                    if (item.detail != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.detail!,
                        style: AgonezTypography.of(context).bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (item.dose != null) ...[
                const SizedBox(width: 12),
                Text(
                  item.dose!,
                  style: AgonezTypography.monoSmall.copyWith(
                    fontSize: 13,
                    color: done ? colors.textMuted : colors.prescriptionText,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
