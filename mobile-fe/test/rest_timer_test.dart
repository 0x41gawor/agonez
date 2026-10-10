import 'package:agonez/src/workout/rest_timer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rest state is derived from its wall-clock deadline', () {
    final timer = RestTimer(
      endsAt: DateTime.utc(2026, 10, 10, 17, 3),
      durationSeconds: 180,
    );

    expect(
      timer.remainingAt(DateTime.utc(2026, 10, 10, 17, 1)),
      const Duration(minutes: 2),
    );
    expect(timer.isCompleteAt(DateTime.utc(2026, 10, 10, 17, 3)), isTrue);
    expect(
      timer.overrunAt(DateTime.utc(2026, 10, 10, 17, 3, 14)),
      const Duration(seconds: 14),
    );
  });

  test('adjustment moves the durable deadline', () {
    final timer = RestTimer(
      endsAt: DateTime.utc(2026, 10, 10, 17, 3),
      durationSeconds: 180,
    ).adjusted(const Duration(seconds: 30));

    expect(timer.endsAt, DateTime.utc(2026, 10, 10, 17, 3, 30));
    expect(timer.durationSeconds, 210);
  });
}
