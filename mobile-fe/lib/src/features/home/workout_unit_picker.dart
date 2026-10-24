import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api/context_models.dart';
import '../../api/wire_enums.dart';
import '../../design/design.dart';
import '../../errors/user_error_mapper.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/hold_to_confirm.dart';

enum PickerUnitKind { done, today, offSchedule, fallback }

/// A workout-unit row of the "Train another workout-unit" wheel.
@immutable
class PickerUnit {
  const PickerUnit({
    required this.name,
    required this.kind,
    this.date,
    this.session,
  });

  final String name;
  final PickerUnitKind kind;

  /// The scheduled or completed day (`yyyy-MM-dd`); null for fallbacks.
  final String? date;

  /// The session to start; null for units that cannot be started.
  final SessionSummary? session;
}

/// The units the picker offers, in calendar order: units already trained in
/// this microcycle, today's unit and the other scheduled units, followed by
/// fallbacks. The order shows where an off-schedule choice sits in the week.
List<PickerUnit> pickerUnits(MobileContext context) {
  final dated = <PickerUnit>[
    for (final day in context.microcycleDays)
      if (day.status == 'completed' && day.workoutUnitName != null)
        PickerUnit(
          name: day.workoutUnitName!,
          kind: PickerUnitKind.done,
          date: day.date,
        ),
    if (context.expectedSession case final today?)
      PickerUnit(
        name: today.workoutUnitName,
        kind: PickerUnitKind.today,
        date: today.scheduledOn,
        session: today,
      ),
    for (final session in context.alternatives)
      PickerUnit(
        name: session.workoutUnitName,
        kind: PickerUnitKind.offSchedule,
        date: session.scheduledOn,
        session: session,
      ),
  ];
  dated.sort((a, b) {
    final byDate = a.date!.compareTo(b.date!);
    return byDate != 0 ? byDate : a.kind.index.compareTo(b.kind.index);
  });
  return [
    ...dated,
    // Reserved by the API; always empty in v1.
    for (final fallback in context.fallbacks)
      if (fallback['workout_unit_name'] case final String name)
        PickerUnit(name: name, kind: PickerUnitKind.fallback),
  ];
}

/// Whether the picker has anything besides today's unit to offer.
bool hasOtherWorkoutUnits(MobileContext context) =>
    context.alternatives.isNotEmpty || context.fallbacks.isNotEmpty;

/// The wheel starts on today's unit, or else on the first unit that can be
/// started.
int initialPickerIndex(List<PickerUnit> units) {
  final today = units.indexWhere((unit) => unit.kind == PickerUnitKind.today);
  if (today >= 0) return today;
  final startable = units.indexWhere((unit) => unit.session != null);
  return startable >= 0 ? startable : 0;
}

/// "Choose workout-unit": a Cupertino wheel of this microcycle's units.
///
/// Today's unit starts like the Home button. Any other unit is an
/// off-schedule start: the athlete holds to confirm, and the start waits for
/// the server, which owns the scheduling rules and may refuse it. The sheet
/// stays open on failure and closes with `true` once a workout has started.
class WorkoutUnitPickerSheet extends StatefulWidget {
  const WorkoutUnitPickerSheet({
    required this.units,
    required this.onStartToday,
    required this.startOffSchedule,
    this.enableHaptics = true,
    super.key,
  });

  final List<PickerUnit> units;
  final VoidCallback onStartToday;
  final Future<void> Function(SessionSummary session) startOffSchedule;
  final bool enableHaptics;

  @override
  State<WorkoutUnitPickerSheet> createState() => _WorkoutUnitPickerSheetState();
}

class _WorkoutUnitPickerSheetState extends State<WorkoutUnitPickerSheet> {
  late int _index = initialPickerIndex(widget.units);
  late final FixedExtentScrollController _wheel = FixedExtentScrollController(
    initialItem: _index,
  );
  bool _starting = false;
  String? _error;

  @override
  void dispose() {
    _wheel.dispose();
    super.dispose();
  }

  Future<void> _startOffSchedule(SessionSummary session) async {
    final strings = AppLocalizations.of(context);
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      await widget.startOffSchedule(session);
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (mounted) setState(() => _error = userFacingError(error, strings));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Widget _explanation(PickerUnit unit) {
    final strings = AppLocalizations.of(context);
    final hint = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: context.agonezColors.textMuted);
    return switch (unit.kind) {
      PickerUnitKind.today => Text(strings.pickerTodayExplanation, style: hint),
      PickerUnitKind.done => Text(strings.pickerDoneExplanation, style: hint),
      PickerUnitKind.offSchedule => _WhyBox(
        lead: strings.pickerNotScheduledToday(unit.name),
        body: strings.pickerOffScheduleRules,
      ),
      PickerUnitKind.fallback => _WhyBox(body: strings.pickerFallbackFuture),
    };
  }

  Widget _footer(PickerUnit unit) {
    final strings = AppLocalizations.of(context);
    return switch (unit.kind) {
      PickerUnitKind.today => AgonezPrimaryButton(
        label: strings.pickerStart(unit.name),
        icon: const Icon(Icons.play_arrow_rounded),
        onPressed: widget.onStartToday,
      ),
      PickerUnitKind.offSchedule => HoldToConfirm(
        key: ValueKey('picker-hold-${unit.session!.sessionId}'),
        label: strings.pickerStartInstead(unit.name),
        duration: const Duration(milliseconds: 1000),
        durationLabel: strings.deviationHoldDuration('1.0'),
        enabled: !_starting,
        enableHaptics: widget.enableHaptics,
        onConfirmed: () => _startOffSchedule(unit.session!),
      ),
      PickerUnitKind.done => AgonezPrimaryButton(
        label: strings.pickerStart(unit.name),
        onPressed: null,
      ),
      PickerUnitKind.fallback => AgonezPrimaryButton(
        label: strings.pickerFallbackLater,
        onPressed: null,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: AgonezInsets.sheetBody,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AgonezSheetHandle(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AgonezEyebrow(strings.pickerAdvanced),
                      const SizedBox(height: 4),
                      Text(strings.pickerTitle, style: textTheme.headlineSmall),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: strings.commonClose,
                  onPressed: _starting ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _UnitWheel(
              units: widget.units,
              selected: _index,
              controller: _wheel,
              onSelected: (index) => setState(() {
                _index = index;
                _error = null;
              }),
            ),
            const SizedBox(height: 12),
            // Every unit's explanation and footer are laid out and only the
            // selected one is shown. Each slot takes its tallest variant's
            // height, so changing the selection never resizes the sheet or
            // moves the wheel.
            IndexedStack(
              index: _error == null ? _index : widget.units.length,
              children: [
                for (final unit in widget.units) _explanation(unit),
                _ErrorBox(message: _error ?? ''),
              ],
            ),
            const SizedBox(height: 16),
            IndexedStack(
              index: _index,
              children: [for (final unit in widget.units) _footer(unit)],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitWheel extends StatelessWidget {
  const _UnitWheel({
    required this.units,
    required this.selected,
    required this.controller,
    required this.onSelected,
  });

  final List<PickerUnit> units;
  final int selected;
  final FixedExtentScrollController controller;
  final ValueChanged<int> onSelected;

  static const _rowHeight = 48.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.agonezColors;
    return Container(
      height: _rowHeight * 5,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.sunk,
        border: Border.all(color: colors.line),
        borderRadius: AgonezRadii.cardBorder,
      ),
      child: Stack(
        children: [
          // The picker paints its selection overlay above the rows, which
          // would dim the selected one; the highlight sits behind instead.
          Center(
            child: Container(
              height: _rowHeight,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: colors.raised,
                border: Border.all(color: colors.controlStrong),
                borderRadius: AgonezRadii.controlBorder,
              ),
            ),
          ),
          CupertinoPicker(
            scrollController: controller,
            itemExtent: _rowHeight,
            backgroundColor: Colors.transparent,
            squeeze: 1.15,
            onSelectedItemChanged: onSelected,
            selectionOverlay: const SizedBox.shrink(),
            children: [
              for (final (index, unit) in units.indexed)
                _UnitRow(unit: unit, selected: index == selected),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({required this.unit, required this.selected});

  final PickerUnit unit;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = context.agonezColors;
    final language = Localizations.localeOf(context).languageCode;
    String day(String iso) =>
        DateFormat('EEE d MMM', language).format(DateTime.parse(iso));
    final when = switch (unit.kind) {
      PickerUnitKind.today => strings.pickerToday,
      PickerUnitKind.done => strings.pickerDoneOn(day(unit.date!)),
      PickerUnitKind.offSchedule =>
        unit.session?.relation == SessionRelation.earlierMissed
            ? strings.pickerMissedOn(day(unit.date!))
            : day(unit.date!),
      PickerUnitKind.fallback => strings.pickerFallback,
    };
    final muted =
        unit.kind == PickerUnitKind.done ||
        unit.kind == PickerUnitKind.fallback;
    final nameStyle = TextStyle(
      fontSize: 17,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      color: selected
          ? colors.textPrimary
          : muted
          ? colors.textDim
          : colors.textMuted,
    );
    final name = Text(
      unit.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: nameStyle,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: unit.kind == PickerUnitKind.fallback
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.textGhost),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: name,
                    )
                  : name,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            when.toUpperCase(),
            style: AgonezTypography.eyebrow.copyWith(
              fontSize: 11,
              color: unit.kind == PickerUnitKind.today
                  ? colors.gold
                  : colors.textDim,
            ),
          ),
        ],
      ),
    );
  }
}

/// A refused start, shown in the explanation's place.
class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.agonezColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: .08),
        border: Border.all(color: colors.error.withValues(alpha: .45)),
        borderRadius: AgonezRadii.buttonBorder,
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
      ),
    );
  }
}

/// The caution box explaining why a choice is not a normal start.
class _WhyBox extends StatelessWidget {
  const _WhyBox({required this.body, this.lead});

  final String? lead;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.agonezColors;
    final style = Theme.of(context).textTheme.bodyMedium;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.caution.withValues(alpha: .08),
        border: Border.all(color: colors.caution.withValues(alpha: .45)),
        borderRadius: AgonezRadii.buttonBorder,
      ),
      child: Text.rich(
        TextSpan(
          children: [
            if (lead != null)
              TextSpan(
                text: '$lead ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            TextSpan(text: body),
          ],
        ),
        style: style?.copyWith(height: 1.45),
      ),
    );
  }
}
