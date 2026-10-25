import 'dart:convert';

import 'package:agonez/src/api/agonez_api_client.dart';
import 'package:agonez/src/api/api_error.dart';
import 'package:agonez/src/api/conditional_response.dart';
import 'package:agonez/src/api/context_models.dart';
import 'package:agonez/src/data/mobile_repository.dart';
import 'package:agonez/src/storage/app_database.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/today_fixtures.dart';
import '../support/workout_fixtures.dart';

class _MockApiClient extends Mock implements AgonezApiClient {}

void main() {
  late AppDatabase database;
  late _MockApiClient api;
  late MobileRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    api = _MockApiClient();
    repository = MobileRepository(database: database, api: api);
  });
  tearDown(() => database.close());

  test(
    'a prepared plan-target prescription is cached for the session',
    () async {
      when(
        () => api.prepareFallbackPrescription(1),
      ).thenAnswer((_) async => fixturePrescription);

      final prepared = await repository.prepareFallbackPrescription(1);
      final cached = await repository.loadPrescription(1, preferCache: true);

      expect(prepared.fromCache, isFalse);
      expect(
        prepared.value.prescriptionVersion,
        fixturePrescription.prescriptionVersion,
      );
      expect(cached.fromCache, isTrue);
      expect(
        cached.value.prescriptionVersion,
        fixturePrescription.prescriptionVersion,
      );
      verifyNever(() => api.getPrescription(any()));
    },
  );

  test('offline, an earlier prepared copy is used', () async {
    when(
      () => api.prepareFallbackPrescription(1),
    ).thenAnswer((_) async => fixturePrescription);
    await repository.prepareFallbackPrescription(1);
    when(() => api.prepareFallbackPrescription(1)).thenThrow(
      AgonezApiException(
        statusCode: null,
        error: null,
        responseData: null,
        cause: DioException(requestOptions: RequestOptions()),
      ),
    );

    final offline = await repository.prepareFallbackPrescription(1);

    expect(offline.offline, isTrue);
    expect(
      offline.value.prescriptionVersion,
      fixturePrescription.prescriptionVersion,
    );
  });

  group('context', () {
    Future<void> cacheContext(String key, MobileContext value) =>
        database.putCachedDocument(
          key: key,
          json: jsonEncode(value.toJson()),
          etag: 'etag-cached',
        );

    test(
      "a deleted selected run is forgotten for the server's choice",
      () async {
        await repository.selectPlanRun(5);
        await cacheContext('context:5:today:en', restDayContext());
        when(
          () => api.getContext(planRunId: 5, etag: any(named: 'etag')),
        ).thenThrow(_apiError(404, 'plan_run_not_found'));
        when(() => api.getContext(etag: any(named: 'etag'))).thenAnswer(
          (_) async =>
              ModifiedResponse(value: workoutContext(), etag: 'etag-auto'),
        );

        final loaded = await repository.loadSelectedContext(locale: 'en');

        expect(loaded.offline, isFalse);
        expect(loaded.value.planRun?.name, 'Filip Majka');
        expect(await repository.selectedPlanRunId(), isNull);
        expect(await database.cachedDocument('context:5:today:en'), isNull);
      },
    );

    test('a refusal is not hidden behind a cached copy', () async {
      await repository.selectPlanRun(2);
      await cacheContext('context:2:today:en', workoutContext());
      when(
        () => api.getContext(planRunId: 2, etag: any(named: 'etag')),
      ).thenThrow(_apiError(422, 'request_validation'));

      await expectLater(
        repository.loadSelectedContext(locale: 'en'),
        throwsA(isA<AgonezApiException>()),
      );
    });

    test('an unreachable server falls back to the cached copy', () async {
      await repository.selectPlanRun(2);
      await cacheContext('context:2:today:en', workoutContext());
      for (final status in [null, 503]) {
        when(
          () => api.getContext(planRunId: 2, etag: any(named: 'etag')),
        ).thenThrow(_apiError(status, null));

        final loaded = await repository.loadSelectedContext(locale: 'en');

        expect(loaded.offline, isTrue, reason: 'status $status');
        expect(loaded.value.planRun?.name, 'Filip Majka');
      }
    });
  });

  test('a refused prescription is not replaced by a cached one', () async {
    when(
      () => api.prepareFallbackPrescription(1),
    ).thenAnswer((_) async => fixturePrescription);
    await repository.prepareFallbackPrescription(1);
    when(
      () => api.getPrescription(1),
    ).thenThrow(_apiError(404, 'session_not_found'));

    await expectLater(
      repository.loadPrescription(1),
      throwsA(isA<AgonezApiException>()),
    );
  });
}

AgonezApiException _apiError(int? status, String? code) => AgonezApiException(
  statusCode: status,
  error: code == null
      ? null
      : ApiErrorBody(code: code, message: code, details: const {}),
  responseData: null,
  cause: DioException(requestOptions: RequestOptions()),
);
