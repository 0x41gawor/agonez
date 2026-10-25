import 'package:agonez/src/api/api.dart';
import 'package:agonez/src/data/mobile_repository.dart';
import 'package:agonez/src/features/home/home_screen.dart';
import 'package:agonez/src/widgets/hold_to_confirm.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/today_fixtures.dart';
import '../../support/workout_fixtures.dart';

void main() {
  late TodayHarness harness;

  setUpAll(() {
    registerFallbackValue(fixturePrescription);
    registerFallbackValue(
      const OffSchedule(acknowledged: true, selectedFrom: 'picker'),
    );
    registerFallbackValue((StartWorkout _) async => throw UnimplementedError());
  });
  setUp(() => harness = TodayHarness());
  tearDown(() => harness.dispose());

  Future<void> chooseAndHold(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(harness.app(const HomeScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Train another workout-unit…'));
    await tester.pumpAndSettle();
    // One row up from today's LEGS: the earlier, off-schedule unit.
    await tester.drag(find.byType(CupertinoPicker), const Offset(0, 48));
    await tester.pumpAndSettle();
    final hold = await tester.startGesture(
      tester.getCenter(find.byType(HoldToConfirm)),
    );
    await tester.pump(const Duration(milliseconds: 1050));
    await hold.up();
    await tester.pumpAndSettle();
  }

  When<Future<String>> whenStartsOffSchedule() => when(
    () => harness.workoutRepository.startAfterServerAccepts(
      prescription: any(named: 'prescription'),
      send: any(named: 'send'),
      planRunId: any(named: 'planRunId'),
      allowMissingLoads: any(named: 'allowMissingLoads'),
      offSchedule: any(named: 'offSchedule'),
    ),
  );

  testWidgets('another unit starts as its next exposure', (tester) async {
    harness.stubContext((_) => workoutContext(alternatives: [missedPushA]));
    when(() => harness.repository.prepareFallbackPrescription(36)).thenAnswer(
      (_) async => LoadedValue(value: fixturePrescription, fromCache: false),
    );
    whenStartsOffSchedule().thenAnswer((_) async {
      harness.streamWorkout(startedLegs());
      return 'workout-1';
    });

    await chooseAndHold(tester);

    expect(find.text('Focus'), findsOneWidget);
    // Push A has no prescription yet, so it starts from plan targets.
    verify(() => harness.repository.prepareFallbackPrescription(36)).called(1);
    final call = verify(
      () => harness.workoutRepository.startAfterServerAccepts(
        prescription: any(named: 'prescription'),
        send: any(named: 'send'),
        planRunId: 2,
        allowMissingLoads: true,
        offSchedule: captureAny(named: 'offSchedule'),
      ),
    )..called(1);
    final offSchedule = call.captured.single as OffSchedule;
    expect(offSchedule.mode, OffScheduleMode.nextTrackExposure);
    expect(offSchedule.acknowledged, isTrue);
    expect(offSchedule.selectedFrom, 'picker');
    expect(offSchedule.expectedSessionId, 41);
  });

  testWidgets('a refusal from an outdated list refreshes Home', (tester) async {
    harness.stubContext((_) => workoutContext(alternatives: [missedPushA]));
    when(() => harness.repository.prepareFallbackPrescription(36)).thenAnswer(
      (_) async => LoadedValue(value: fixturePrescription, fromCache: false),
    );
    whenStartsOffSchedule().thenThrow(_refusal('not_next_track_exposure'));

    await chooseAndHold(tester);

    expect(
      find.text(
        'An earlier session of this workout-unit is still pending. Close the '
        'list and start that one first.',
      ),
      findsOneWidget,
    );
    expect(find.text('Focus'), findsNothing);
    verify(
      () =>
          harness.repository.loadSelectedContext(locale: any(named: 'locale')),
    ).called(2);
  });

  testWidgets('an incomplete prescription is completed and started again', (
    tester,
  ) async {
    // Ready by the context's counts, yet the start finds plan slots missing.
    const partlyAnalyzed = SessionSummary(
      sessionId: 37,
      workoutUnitName: 'Pull A',
      workoutTrackId: 2,
      scheduledOn: '2026-10-18',
      status: 'missed',
      prescription: PrescriptionReadiness(
        readiness: PrescriptionReadinessStatus.ready,
        prescriptionVersion: 'rx-37',
        exerciseCount: 3,
        setCount: 9,
      ),
      relation: SessionRelation.earlierMissed,
    );
    harness.stubContext((_) => workoutContext(alternatives: [partlyAnalyzed]));
    when(() => harness.repository.prepareFallbackPrescription(37)).thenAnswer(
      (_) async => LoadedValue(value: fixturePrescription, fromCache: false),
    );
    var attempts = 0;
    whenStartsOffSchedule().thenAnswer((_) async {
      if (++attempts == 1) throw _refusal('prescription_incomplete');
      harness.streamWorkout(startedLegs());
      return 'workout-1';
    });

    await chooseAndHold(tester);

    expect(attempts, 2);
    verify(() => harness.repository.prepareFallbackPrescription(37)).called(1);
    expect(find.text('Focus'), findsOneWidget);
  });
}

AgonezApiException _refusal(String code) => AgonezApiException(
  statusCode: 422,
  error: ApiErrorBody(code: code, message: code, details: const {}),
  responseData: null,
  cause: DioException(
    requestOptions: RequestOptions(path: '/api/v1/mobile/workouts'),
    type: DioExceptionType.badResponse,
  ),
);
