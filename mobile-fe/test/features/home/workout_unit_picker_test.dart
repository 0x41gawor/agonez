import 'package:agonez/src/api/api_error.dart';
import 'package:agonez/src/api/context_models.dart';
import 'package:agonez/src/api/wire_enums.dart';
import 'package:agonez/src/design/design.dart';
import 'package:agonez/src/features/home/workout_unit_picker.dart';
import 'package:agonez/src/l10n/generated/app_localizations.dart';
import 'package:agonez/src/widgets/hold_to_confirm.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('units run in calendar order with fallbacks last', () {
    final units = pickerUnits(_context());

    expect(units.map((unit) => (unit.name, unit.kind)), [
      ('Legs', PickerUnitKind.done),
      ('Push A', PickerUnitKind.offSchedule),
      ('Pull B', PickerUnitKind.today),
      ('Push B', PickerUnitKind.offSchedule),
    ]);
    expect(initialPickerIndex(units), 2);
    expect(units[0].session, isNull);
    expect(units[1].session?.sessionId, 36);
  });

  test('a rest day opens on the first unit that can be started', () {
    final units = pickerUnits(_context(today: false));

    expect(units[initialPickerIndex(units)].name, 'Push A');
  });

  testWidgets('today starts like the Home button', (tester) async {
    var startedToday = 0;
    await _pump(
      tester,
      onStartToday: () => startedToday++,
      startOffSchedule: (_) async {},
    );

    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text("Today's scheduled workout."), findsOneWidget);
    await tester.tap(find.text('Start Pull B'));
    expect(startedToday, 1);
  });

  testWidgets('another unit needs a hold and shows a refusal in place', (
    tester,
  ) async {
    final started = <int>[];
    await _pump(
      tester,
      onStartToday: () {},
      startOffSchedule: (session) async {
        started.add(session.sessionId);
        throw _offScheduleRefused();
      },
    );

    await _selectRowAbove(tester);
    expect(find.textContaining("Push A isn't scheduled for today."), findsOne);
    expect(find.textContaining('MISSED'), findsOneWidget);
    // A plain tap is not enough for an off-schedule start.
    await tester.tap(find.byType(HoldToConfirm));
    await tester.pump(AgonezDurations.holdReset);
    expect(started, isEmpty);

    await _hold(tester);

    expect(started, [36]);
    expect(
      find.text('Off-schedule workout execution is not available yet.'),
      findsOneWidget,
    );
    expect(find.byType(WorkoutUnitPickerSheet), findsOneWidget);
  });

  testWidgets('changing the unit never moves the wheel or resizes the sheet', (
    tester,
  ) async {
    await _pump(
      tester,
      onStartToday: () {},
      startOffSchedule: (_) async => throw _offScheduleRefused(),
    );
    Rect wheel() => tester.getRect(find.byType(CupertinoPicker));
    Rect sheet() => tester.getRect(find.byType(WorkoutUnitPickerSheet));
    final wheelAtToday = wheel();
    final sheetAtToday = sheet();

    // Today's one-line hint becomes the multi-line explanation box.
    await _selectRowAbove(tester);
    expect(wheel(), wheelAtToday);
    expect(sheet(), sheetAtToday);

    // A refusal takes the explanation's place.
    await _hold(tester);
    expect(
      find.text('Off-schedule workout execution is not available yet.'),
      findsOneWidget,
    );
    expect(wheel(), wheelAtToday);
    expect(sheet(), sheetAtToday);

    await tester.drag(find.byType(CupertinoPicker), const Offset(0, -48));
    await tester.pumpAndSettle();
    expect(find.text("Today's scheduled workout."), findsOneWidget);
    expect(wheel(), wheelAtToday);
    expect(sheet(), sheetAtToday);
  });

  testWidgets('an accepted off-schedule start closes the sheet', (
    tester,
  ) async {
    bool? result;
    await _pump(
      tester,
      onStartToday: () {},
      startOffSchedule: (_) async {},
      onClosed: (value) => result = value,
    );

    await _selectRowAbove(tester);
    await _hold(tester);
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.byType(WorkoutUnitPickerSheet), findsNothing);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required VoidCallback onStartToday,
  required Future<void> Function(SessionSummary) startOffSchedule,
  ValueChanged<bool?>? onClosed,
}) async {
  await tester.binding.setSurfaceSize(const Size(412, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AgonezTheme.dark,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                final value = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => WorkoutUnitPickerSheet(
                    units: pickerUnits(_context()),
                    enableHaptics: false,
                    onStartToday: onStartToday,
                    startOffSchedule: startOffSchedule,
                  ),
                );
                onClosed?.call(value);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// Scrolls the wheel one row up, from today's Pull B to the missed Push A.
Future<void> _selectRowAbove(WidgetTester tester) async {
  await tester.drag(find.byType(CupertinoPicker), const Offset(0, 48));
  await tester.pumpAndSettle();
}

Future<void> _hold(WidgetTester tester) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byType(HoldToConfirm)),
  );
  await tester.pump(const Duration(milliseconds: 1050));
  await gesture.up();
  await tester.pump();
  await tester.pump();
}

AgonezApiException _offScheduleRefused() => AgonezApiException(
  statusCode: 422,
  error: const ApiErrorBody(
    code: 'off_schedule_not_supported',
    message: 'Off-schedule starts are not supported',
    details: {},
  ),
  responseData: null,
  cause: DioException(
    requestOptions: RequestOptions(path: '/api/v1/mobile/workouts'),
    type: DioExceptionType.badResponse,
  ),
);

SessionSummary _session(
  int id,
  String name,
  String date, {
  SessionRelation? relation,
  String status = 'scheduled',
}) => SessionSummary(
  sessionId: id,
  workoutUnitName: name,
  workoutTrackId: id,
  scheduledOn: date,
  status: status,
  prescription: const PrescriptionReadiness(
    readiness: PrescriptionReadinessStatus.missing,
  ),
  relation: relation,
);

MobileContext _context({bool today = true}) => MobileContext(
  generatedAt: DateTime.utc(2026, 10, 24, 8),
  contextVersion: 'ctx',
  planRun: null,
  selectionRequired: false,
  today: const TodayPosition(date: '2026-10-24', microcycle: null),
  microcycleDays: const [
    MicrocycleDay(
      date: '2026-10-19',
      dayOrdinal: 1,
      sessionId: 35,
      workoutUnitName: 'Legs',
      status: 'completed',
    ),
    MicrocycleDay(
      date: '2026-10-20',
      dayOrdinal: 2,
      sessionId: 36,
      workoutUnitName: 'Push A',
      status: 'missed',
    ),
  ],
  expectedSession: today ? _session(40, 'Pull B', '2026-10-24') : null,
  // Deliberately out of order: the picker sorts by date.
  alternatives: [
    _session(
      41,
      'Push B',
      '2026-10-25',
      relation: SessionRelation.laterInMicrocycle,
    ),
    _session(
      36,
      'Push A',
      '2026-10-20',
      relation: SessionRelation.earlierMissed,
      status: 'missed',
    ),
  ],
  fallbacks: const [],
  activeWorkout: null,
  recent: const [],
);
