import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api/context_models.dart';
import '../../design/design.dart';
import '../../l10n/generated/app_localizations.dart';

/// How one day of the microcycle reads in [MicrocycleStrip].
enum MicrocycleDayState {
  rest,
  planned,
  today,
  inProgress,
  completed,
  missed,
  cancelled,
}

/// Maps a context day to its strip state.
///
/// `status` is the session status (`scheduled`, `in_progress`, `completed`,
/// `missed`, `cancelled`) or `rest_day` for a day without a session. A
/// status the app does not know yet reads as planned.
MicrocycleDayState microcycleDayState(
  MicrocycleDay day, {
  required bool isToday,
}) {
  if (day.sessionId == null || day.status == 'rest_day') {
    return MicrocycleDayState.rest;
  }
  return switch (day.status) {
    'completed' => MicrocycleDayState.completed,
    'in_progress' => MicrocycleDayState.inProgress,
    'missed' => MicrocycleDayState.missed,
    'cancelled' => MicrocycleDayState.cancelled,
    _ => isToday ? MicrocycleDayState.today : MicrocycleDayState.planned,
  };
}

/// The current microcycle as one row of day cells: weekday, workout-unit (or
/// rest) and a status pip, with today outlined in gold. Microcycles too long
/// for the row scroll sideways instead of squeezing their cells.
class MicrocycleStrip extends StatelessWidget {
  const MicrocycleStrip({required this.contextValue, super.key});

  final MobileContext contextValue;

  static const _gap = 5.0;
  static const _minCellWidth = 42.0;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final current =
        contextValue.today?.microcycle?.ordinal ??
        contextValue.planRun?.currentMicrocycleOrdinal ??
        0;
    final total = contextValue.planRun?.microcycleCount ?? 0;
    final todayDate = contextValue.today?.date;
    final cells = [
      for (final day in contextValue.microcycleDays)
        _DayCell(day: day, isToday: day.date == todayDate),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgonezEyebrow(strings.homeMicrocycle(current, total)),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final width =
                (constraints.maxWidth - _gap * (cells.length - 1)) /
                cells.length;
            if (width >= _minCellWidth) {
              return Row(
                children: [
                  for (final (index, cell) in cells.indexed) ...[
                    if (index > 0) const SizedBox(width: _gap),
                    Expanded(child: cell),
                  ],
                ],
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (index, cell) in cells.indexed) ...[
                    if (index > 0) const SizedBox(width: _gap),
                    SizedBox(width: _minCellWidth, child: cell),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.isToday});

  final MicrocycleDay day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = context.agonezColors;
    final language = Localizations.localeOf(context).languageCode;
    final date = DateTime.tryParse(day.date);
    final state = microcycleDayState(day, isToday: isToday);
    final name = day.workoutUnitName ?? strings.homeDayRest;
    final status = switch (state) {
      MicrocycleDayState.rest => null,
      MicrocycleDayState.planned => strings.homeDayPlanned,
      MicrocycleDayState.today => strings.homeDayToday,
      MicrocycleDayState.inProgress => strings.homeDayInProgress,
      MicrocycleDayState.completed => strings.homeDayCompleted,
      MicrocycleDayState.missed => strings.homeDayMissed,
      MicrocycleDayState.cancelled => strings.homeDayCancelled,
    };
    return Semantics(
      label: [
        if (date != null) DateFormat.EEEE(language).format(date),
        name,
        ?status,
        if (isToday && state != MicrocycleDayState.today) strings.homeDayToday,
      ].join(', '),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(2, 7, 2, 8),
        decoration: BoxDecoration(
          color: isToday
              ? Color.alphaBlend(
                  colors.goldLine.withValues(alpha: .2),
                  colors.alternative,
                )
              : colors.alternative,
          border: Border.all(color: isToday ? colors.gold : colors.line),
          borderRadius: AgonezRadii.controlBorder,
        ),
        child: Column(
          children: [
            Text(
              date == null ? '' : _shortWeekday(date, language),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: AgonezTypography.eyebrow.copyWith(
                fontSize: 9.5,
                letterSpacing: .76,
                color: colors.textDim,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox.square(
              dimension: 12,
              child: CustomPaint(painter: _StatusPip.of(state, colors)),
            ),
          ],
        ),
      ),
    );
  }

  /// `TUE`, or `WT` in Polish, whose abbreviations end with a period.
  static String _shortWeekday(DateTime date, String language) {
    final label = DateFormat.E(language).format(date).toUpperCase();
    return label.endsWith('.') ? label.substring(0, label.length - 1) : label;
  }
}

/// The 12 × 12 status mark: a short dash for rest, otherwise a rounded
/// square that is filled when the day was trained or is being trained,
/// dashed gold when it is due today and crossed when it was missed or
/// cancelled.
class _StatusPip extends CustomPainter {
  const _StatusPip({
    required this.border,
    this.fill,
    this.dashed = false,
    this.cross,
    this.dash = false,
  });

  factory _StatusPip.of(
    MicrocycleDayState state,
    AgonezThemeColors colors,
  ) => switch (state) {
    MicrocycleDayState.rest => _StatusPip(border: colors.textGhost, dash: true),
    MicrocycleDayState.planned => _StatusPip(border: colors.textGhost),
    MicrocycleDayState.today => _StatusPip(border: colors.gold, dashed: true),
    MicrocycleDayState.inProgress => _StatusPip(
      border: colors.goldText,
      fill: colors.gold,
    ),
    MicrocycleDayState.completed => _StatusPip(
      border: colors.success,
      fill: colors.success,
    ),
    MicrocycleDayState.missed => _StatusPip(
      border: colors.error,
      cross: colors.error,
    ),
    MicrocycleDayState.cancelled => _StatusPip(
      border: colors.textGhost,
      cross: colors.textGhost,
    ),
  };

  final Color border;
  final Color? fill;
  final bool dashed;
  final Color? cross;

  /// Rest days draw only a horizontal dash through the middle.
  final bool dash;

  static const _stroke = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = border;
    if (dash) {
      final y = size.height / 2;
      canvas.drawLine(
        Offset(size.width / 2 - 5, y),
        Offset(size.width / 2 + 5, y),
        line..strokeWidth = 2,
      );
      return;
    }
    final box = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(_stroke / 2),
      const Radius.circular(3),
    );
    if (fill case final fill?) {
      canvas.drawRRect(box, Paint()..color = fill);
    }
    if (dashed) {
      for (final metric in (Path()..addRRect(box)).computeMetrics()) {
        for (var start = 0.0; start < metric.length; start += 5) {
          canvas.drawPath(
            metric.extractPath(start, math.min(start + 3, metric.length)),
            line..strokeCap = StrokeCap.butt,
          );
        }
      }
    } else {
      canvas.drawRRect(box, line);
    }
    if (cross case final cross?) {
      final inset = size.width * .32;
      final far = size.width - inset;
      line.color = cross;
      canvas
        ..drawLine(Offset(inset, inset), Offset(far, far), line)
        ..drawLine(Offset(far, inset), Offset(inset, far), line);
    }
  }

  @override
  bool shouldRepaint(_StatusPip old) =>
      border != old.border ||
      fill != old.fill ||
      dashed != old.dashed ||
      cross != old.cross ||
      dash != old.dash;
}
