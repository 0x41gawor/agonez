import 'package:agonez/src/api/context_models.dart';
import 'package:agonez/src/design/design.dart';
import 'package:agonez/src/features/home/microcycle_strip.dart';
import 'package:agonez/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/today_fixtures.dart';

void main() {
  test('maps session statuses to day states', () {
    MicrocycleDayState state(
      String status, {
      int? session = 1,
      bool today = false,
    }) => microcycleDayState(
      _day('2026-10-16', session, 'Push A', status),
      isToday: today,
    );

    expect(state('completed'), MicrocycleDayState.completed);
    expect(state('in_progress'), MicrocycleDayState.inProgress);
    expect(state('missed'), MicrocycleDayState.missed);
    expect(state('cancelled'), MicrocycleDayState.cancelled);
    expect(state('scheduled'), MicrocycleDayState.planned);
    expect(state('scheduled', today: true), MicrocycleDayState.today);
    expect(state('rest_day', session: null), MicrocycleDayState.rest);
    // A status added on the server later must not break the strip.
    expect(state('postponed'), MicrocycleDayState.planned);
  });

  testWidgets('a week reads as weekday, unit and status per day', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host(_context(_week), locale: const Locale('en')));

    expect(find.text('MICROCYCLE 7 / 8'), findsOneWidget);
    expect(find.text('TUE'), findsOneWidget);
    expect(find.text('Rest'), findsNWidgets(2));
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.bySemanticsLabel('Tuesday, Pull A, done'), findsOneWidget);
    expect(find.bySemanticsLabel('Thursday, Rest'), findsOneWidget);
    expect(find.bySemanticsLabel('Friday, Push A, today'), findsOneWidget);
    expect(find.bySemanticsLabel('Saturday, Push B, planned'), findsOneWidget);
    expect(find.bySemanticsLabel('Sunday, Pull B, missed'), findsOneWidget);
  });

  testWidgets('Polish weekdays drop the abbreviation period', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host(_context(_week), locale: const Locale('pl')));

    expect(find.text('WT'), findsOneWidget);
    expect(find.text('NIEDZ'), findsOneWidget);
    expect(find.text('Wolne'), findsNWidgets(2));
  });

  testWidgets('a long microcycle opens on today', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // Fourteen days, 4–17 Oct; the fixture's today, 16 Oct, is the 13th.
    final days = [
      for (var day = 4; day <= 17; day++)
        _day(
          '2026-10-${day.toString().padLeft(2, '0')}',
          day,
          'Upper',
          'scheduled',
        ),
    ];

    await tester.pumpWidget(_host(_context(days), locale: const Locale('en')));

    final today = tester.getRect(find.bySemanticsLabel('Friday, Upper, today'));
    expect(today.left, greaterThanOrEqualTo(0));
    expect(today.right, lessThanOrEqualTo(390));
  });

  testWidgets('a long microcycle scrolls instead of squeezing its days', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final days = [
      for (var index = 0; index < 12; index++)
        _day('2026-10-${13 + index}', 50 + index, 'Upper Express', 'scheduled'),
    ];

    await tester.pumpWidget(_host(_context(days), locale: const Locale('en')));

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}

final _week = [
  _day('2026-10-13', 1, 'Pull A', 'completed'),
  _day('2026-10-14', 2, 'Legs', 'completed'),
  _day('2026-10-15', null, null, 'rest_day'),
  _day('2026-10-16', 3, 'Push A', 'scheduled'),
  _day('2026-10-17', 4, 'Push B', 'scheduled'),
  _day('2026-10-18', 5, 'Pull B', 'missed'),
  _day('2026-10-19', null, null, 'rest_day'),
];

MicrocycleDay _day(String date, int? session, String? unit, String status) =>
    MicrocycleDay(
      date: date,
      dayOrdinal: 1,
      sessionId: session,
      workoutUnitName: unit,
      status: status,
    );

MobileContext _context(List<MicrocycleDay> days) => MobileContext(
  generatedAt: DateTime.utc(2026, 10, 16, 8),
  contextVersion: 'ctx',
  planRun: contextPlanRun(id: 1, name: 'Execution Demo'),
  selectionRequired: false,
  today: const TodayPosition(
    date: '2026-10-16',
    microcycle: TodayMicrocycle(
      id: 7,
      ordinal: 7,
      dayOrdinal: 4,
      classification: 'normal',
    ),
  ),
  microcycleDays: days,
  expectedSession: null,
  alternatives: const [],
  fallbacks: const [],
  activeWorkout: null,
  recent: const [],
);

Widget _host(MobileContext value, {required Locale locale}) => MaterialApp(
  theme: AgonezTheme.light,
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: MicrocycleStrip(contextValue: value),
    ),
  ),
);
