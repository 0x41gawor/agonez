import 'package:agonez/src/api/agonez_api_client.dart';
import 'package:agonez/src/api/api_error.dart';
import 'package:agonez/src/data/mobile_repository.dart';
import 'package:agonez/src/storage/app_database.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
}
