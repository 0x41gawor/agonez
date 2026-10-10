class RestTimer {
  const RestTimer({required this.endsAt, required this.durationSeconds});

  final DateTime endsAt;
  final int durationSeconds;

  Duration remainingAt(DateTime now) => endsAt.difference(now);

  bool isCompleteAt(DateTime now) => !endsAt.isAfter(now);

  Duration overrunAt(DateTime now) =>
      isCompleteAt(now) ? now.difference(endsAt) : Duration.zero;

  RestTimer adjusted(Duration delta) => RestTimer(
    endsAt: endsAt.add(delta),
    durationSeconds: (durationSeconds + delta.inSeconds).clamp(0, 86400),
  );
}
