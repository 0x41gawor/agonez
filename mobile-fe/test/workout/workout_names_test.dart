import 'dart:convert';

import 'package:agonez/src/api/atlas_models.dart';
import 'package:agonez/src/api/prescription_models.dart';
import 'package:agonez/src/api/wire_enums.dart';
import 'package:agonez/src/storage/app_database.dart';
import 'package:agonez/src/workout/workout_names.dart';
import 'package:agonez/src/workout/workout_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/today_fixtures.dart';
import '../support/workout_fixtures.dart';

void main() {
  late AppDatabase database;
  late MockApiClient api;
  late WorkoutRepository workouts;
  late WorkoutNames names;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    api = MockApiClient();
    workouts = WorkoutRepository(database: database);
    names = WorkoutNames(database: database, api: api);
  });

  tearDown(() => database.close());

  Future<String> startIn(String language) => workouts.start(
    prescription: _legsIn(language),
    startedAt: DateTime.utc(2026, 10, 27, 18),
  );

  Future<Map<String, Object?>> frozen(String workoutId) async =>
      jsonDecode(
            (await database.watchWorkout(workoutId).first)!.prescriptionJson,
          )
          as Map<String, Object?>;

  test('a workout started in Polish follows the app into English', () async {
    final workoutId = await startIn('pl');
    final before = await frozen(workoutId);
    when(() => api.getPrescription(28)).thenAnswer((_) async => _legsIn('en'));

    expect(await names.localize(workoutId, 'en'), isTrue);

    final after = await frozen(workoutId);
    final exercises = after['exercises']! as List<Object?>;
    expect(
      exercises.map((item) => ((item! as Map)['exercise'] as Map)['name']),
      ['Barbell squat (en)', 'Leg curl (en)'],
    );
    expect(
      exercises.map(
        (item) => ((item! as Map)['atlas_peek'] as Map)['content_locale'],
      ),
      ['en', 'en'],
    );
    // Only display text changed: targets are exactly as frozen.
    for (final (index, item) in exercises.indexed) {
      expect(
        (item! as Map)['sets'],
        ((before['exercises']! as List)[index] as Map)['sets'],
      );
    }
    final local = await database.workoutExercises(workoutId);
    expect(
      local.map(
        (exercise) => (jsonDecode(exercise.actualExerciseJson!) as Map)['name'],
      ),
      containsAll(['Barbell squat (en)', 'Leg curl (en)']),
    );

    // Once in English, it stays there without asking again.
    expect(await names.localize(workoutId, 'en'), isFalse);
    verify(() => api.getPrescription(28)).called(1);
  });

  test('names already in the app language need no request', () async {
    final workoutId = await startIn('en');

    expect(await names.localize(workoutId, 'en'), isFalse);
    verifyNever(() => api.getPrescription(any()));
  });

  test('offline, the names stay and the next call tries again', () async {
    final workoutId = await startIn('pl');
    when(() => api.getPrescription(28)).thenThrow(Exception('offline'));

    expect(await names.localize(workoutId, 'en'), isFalse);
    expect(
      ((await frozen(workoutId))['exercises']! as List).first,
      containsPair('exercise', containsPair('name', 'Barbell squat (pl)')),
    );

    when(() => api.getPrescription(28)).thenAnswer((_) async => _legsIn('en'));
    expect(await names.localize(workoutId, 'en'), isTrue);
  });

  test('a substitute from the Atlas is renamed through its peek', () async {
    final workoutId = await startIn('pl');
    final legCurl = (await database.workoutExercises(
      workoutId,
    )).firstWhere((exercise) => exercise.exercisePrescriptionId == 223);
    await workouts.substituteExercise(
      workoutId: workoutId,
      exercisePerformanceId: legCurl.exercisePerformanceId,
      exercisePrescriptionId: 223,
      actualExercise: const ExerciseIdentity(
        id: 77,
        slug: 'nordic_curl',
        name: 'Uginanie nordyckie',
      ),
      source: SubstitutionSource.atlas,
    );
    when(() => api.getPrescription(28)).thenAnswer((_) async => _legsIn('en'));
    when(() => api.getAtlasPeek(77)).thenAnswer(
      (_) async => AtlasPeek(
        exercise: const ExerciseIdentity(
          id: 77,
          slug: 'nordic_curl',
          name: 'Nordic curl',
        ),
        tags: fixtureAtlasPeek.tags,
        techniqueTldr: fixtureAtlasPeek.techniqueTldr,
        musclesTop: fixtureAtlasPeek.musclesTop,
        bodyMap: fixtureAtlasPeek.bodyMap,
        contentLocale: 'en',
        atlasVersion: fixtureAtlasPeek.atlasVersion,
      ),
    );

    await names.localize(workoutId, 'en');

    final substituted = (await database.workoutExercises(
      workoutId,
    )).firstWhere((exercise) => exercise.exercisePrescriptionId == 223);
    expect(
      (jsonDecode(substituted.actualExerciseJson!) as Map)['name'],
      'Nordic curl',
    );
  });
}

/// [twoExercisePrescription] as the server answers in [language].
WorkoutPrescription _legsIn(String language) {
  final json =
      jsonDecode(jsonEncode(twoExercisePrescription.toJson()))
          as Map<String, Object?>;
  for (final exercise in json['exercises']! as List<Object?>) {
    final entry = exercise! as Map<String, Object?>;
    final identity = entry['exercise']! as Map<String, Object?>;
    identity['name'] = '${identity['name']} ($language)';
    (entry['atlas_peek']! as Map<String, Object?>)['content_locale'] = language;
  }
  return WorkoutPrescription.fromJson(json);
}
