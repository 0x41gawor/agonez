import 'package:agonez/src/api/context_models.dart';
import 'package:agonez/src/features/home/done_today.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/today_fixtures.dart';

void main() {
  test('a completed planned session is today\'s, with what comes next', () {
    final done = DoneToday.of(
      doneTodayContext(
        days: const [
          MicrocycleDay(
            date: '2026-10-19',
            dayOrdinal: 1,
            sessionId: 41,
            workoutUnitName: 'LEGS',
            status: 'completed',
          ),
          MicrocycleDay(
            date: '2026-10-20',
            dayOrdinal: 2,
            sessionId: null,
            workoutUnitName: null,
            status: 'rest_day',
          ),
          MicrocycleDay(
            date: '2026-10-21',
            dayOrdinal: 3,
            sessionId: 42,
            workoutUnitName: 'Chest + Back',
            status: 'scheduled',
          ),
        ],
        recent: [_finished(41, 'LEGS', '2026-10-19')],
      ),
    )!;

    expect(done.workoutUnitName, 'LEGS');
    expect(done.result?.performedSets, 18);
    expect(done.next?.workoutUnitName, 'Chest + Back');
  });

  test('a unit trained off-schedule on a rest day counts too', () {
    final done = DoneToday.of(
      doneTodayContext(
        days: const [
          MicrocycleDay(
            date: '2026-10-19',
            dayOrdinal: 1,
            sessionId: null,
            workoutUnitName: null,
            status: 'rest_day',
          ),
        ],
        recent: [_finished(42, 'Chest + Back', '2026-10-19')],
      ),
    );

    expect(done?.workoutUnitName, 'Chest + Back');
  });

  test('the planned session is named even without its result', () {
    final done = DoneToday.of(
      doneTodayContext(
        days: const [
          MicrocycleDay(
            date: '2026-10-19',
            dayOrdinal: 1,
            sessionId: 41,
            workoutUnitName: 'LEGS',
            status: 'completed',
          ),
        ],
        recent: const [],
      ),
    );

    expect(done?.workoutUnitName, 'LEGS');
    expect(done?.result, isNull);
  });

  test('a day without training is not done', () {
    final done = DoneToday.of(
      doneTodayContext(
        days: const [
          MicrocycleDay(
            date: '2026-10-19',
            dayOrdinal: 1,
            sessionId: null,
            workoutUnitName: null,
            status: 'rest_day',
          ),
        ],
        recent: [_finished(40, 'Pull B', '2026-10-18')],
      ),
    );

    expect(done, isNull);
  });
}

/// Finished at noon UTC, which is the same calendar day in any time zone
/// the tests run in.
RecentWorkout _finished(int session, String name, String date) => RecentWorkout(
  sessionId: session,
  workoutUnitName: name,
  completedAt: DateTime.parse('${date}T12:00:00Z'),
  performedSets: 18,
  prescribedSets: 20,
  skippedSets: 2,
);
