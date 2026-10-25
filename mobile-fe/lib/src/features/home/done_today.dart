import 'package:flutter/foundation.dart';

import '../../api/context_models.dart';

/// Today's finished training, for the card that takes the rest-day card's
/// place once nothing is left to start today.
///
/// The context drops a session from `expected_session` as soon as it is
/// completed, so without this Home would call the day a rest day. Training
/// counts when today's planned session is completed or a workout was
/// completed today, which also covers a unit trained off-schedule on a rest
/// day.
@immutable
class DoneToday {
  const DoneToday({required this.workoutUnitName, this.result, this.next});

  final String workoutUnitName;

  /// The finished workout's sets and finish time; null when the context's
  /// short recent list does not include it.
  final RecentWorkout? result;

  /// The next planned session of this microcycle, if any.
  final MicrocycleDay? next;

  static DoneToday? of(MobileContext context) {
    final today = context.today?.date;
    if (today == null) return null;
    final planned = context.microcycleDays
        .where(
          (day) =>
              day.date == today &&
              day.status == 'completed' &&
              day.workoutUnitName != null,
        )
        .firstOrNull;
    final finishedToday =
        context.recent
            .where((workout) => _localDate(workout.completedAt) == today)
            .toList()
          ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    // Today's planned session if it is among them, else the latest.
    final result =
        finishedToday
            .where((workout) => workout.sessionId == planned?.sessionId)
            .firstOrNull ??
        finishedToday.firstOrNull;
    final name = result?.workoutUnitName ?? planned?.workoutUnitName;
    if (name == null) return null;
    return DoneToday(
      workoutUnitName: name,
      result: result,
      next: context.microcycleDays
          .where(
            (day) =>
                day.date.compareTo(today) > 0 &&
                day.sessionId != null &&
                day.status == 'scheduled',
          )
          .firstOrNull,
    );
  }

  static String _localDate(DateTime moment) {
    final local = moment.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}
