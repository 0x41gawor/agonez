import 'dart:convert';

import 'package:drift/drift.dart';

import '../api/agonez_api_client.dart';
import '../api/atlas_models.dart';
import '../storage/app_database.dart';

/// Keeps a workout's exercise names in the app's language.
///
/// A workout freezes its prescription when it starts, names included, in
/// the language the app had then. Without this, switching language
/// mid-workout would leave its exercises in the old one.
class WorkoutNames {
  WorkoutNames({required AppDatabase database, required AgonezApiClient api})
    : _database = database,
      _api = api;

  final AppDatabase _database;
  final AgonezApiClient _api;

  /// Rewrites [workoutId]'s exercise names, full names and Atlas peeks in
  /// [language], the language the API answers in. Only display text
  /// changes; ids, targets and recorded sets stay as they were frozen.
  ///
  /// Returns whether anything was rewritten. A failed request changes
  /// nothing, so the next call tries again.
  Future<bool> localize(String workoutId, String language) async {
    if (await _database.workoutNamesLanguage(workoutId) == language) {
      return false;
    }
    final workout = await _database.watchWorkout(workoutId).first;
    if (workout == null) return false;
    if (_frozenIn(workout.prescriptionJson) == language) {
      await _database.rememberWorkoutNamesLanguage(workoutId, language);
      return false;
    }

    final names = <int, ExerciseIdentity>{};
    final peeks = <int, AtlasPeek>{};
    try {
      final source = await _api.getPrescription(workout.sessionId);
      for (final exercise in source.exercises) {
        names[exercise.exercise.id] = exercise.exercise;
        peeks[exercise.exercise.id] = exercise.atlasPeek;
        for (final alternative in exercise.alternatives) {
          names[alternative.exercise.id] = alternative.exercise;
          peeks[alternative.exercise.id] = alternative.atlasPeek;
        }
      }
    } on Exception {
      return false;
    }
    // Substitutes and additions picked from the Atlas, outside the plan.
    for (final exercise in await _database.workoutExercises(workoutId)) {
      final id = exercise.actualExerciseId;
      if (id == null || names.containsKey(id)) continue;
      try {
        final peek = await _api.getAtlasPeek(id);
        names[id] = peek.exercise;
        peeks[id] = peek;
      } on Exception {
        // It keeps the name it has.
      }
    }

    return _database.transaction(() async {
      // Read again: the workout may have changed while the names loaded.
      final current = await _database.watchWorkout(workoutId).first;
      if (current == null) return false;
      var changed = false;

      final frozen =
          jsonDecode(current.prescriptionJson) as Map<String, Object?>;
      for (final exercise in frozen['exercises']! as List<Object?>) {
        final entry = exercise! as Map<String, Object?>;
        _relabel(entry, names, peeks);
        for (final alternative
            in entry['alternatives'] as List<Object?>? ?? const []) {
          _relabel(alternative! as Map<String, Object?>, names, peeks);
        }
      }
      final prescriptionJson = jsonEncode(frozen);
      if (prescriptionJson != current.prescriptionJson) {
        changed = true;
        await (_database.update(
          _database.localWorkouts,
        )..where((row) => row.workoutId.equals(workoutId))).write(
          LocalWorkoutsCompanion(prescriptionJson: Value(prescriptionJson)),
        );
      }

      for (final exercise in await _database.workoutExercises(workoutId)) {
        final localized = names[exercise.actualExerciseId];
        if (localized == null) continue;
        final actualJson = jsonEncode(localized.toJson());
        if (actualJson == exercise.actualExerciseJson) continue;
        changed = true;
        await (_database.update(_database.localExercises)..where(
              (row) => row.exercisePerformanceId.equals(
                exercise.exercisePerformanceId,
              ),
            ))
            .write(
              LocalExercisesCompanion(actualExerciseJson: Value(actualJson)),
            );
      }

      await _database.rememberWorkoutNamesLanguage(workoutId, language);
      return changed;
    });
  }

  /// The language the server answered in when the prescription was frozen,
  /// as its Atlas peeks state it; null when they don't agree on one.
  String? _frozenIn(String prescriptionJson) {
    final languages = <Object?>{};
    try {
      final frozen = jsonDecode(prescriptionJson) as Map<String, Object?>;
      for (final exercise in frozen['exercises']! as List<Object?>) {
        final peek = (exercise! as Map<String, Object?>)['atlas_peek'];
        if (peek is Map) languages.add(peek['content_locale']);
      }
    } on Object {
      return null;
    }
    return languages.length == 1 ? languages.single as String? : null;
  }

  void _relabel(
    Map<String, Object?> entry,
    Map<int, ExerciseIdentity> names,
    Map<int, AtlasPeek> peeks,
  ) {
    final exercise = entry['exercise'];
    final id = exercise is Map ? exercise['id'] : null;
    if (names[id] case final name?) entry['exercise'] = name.toJson();
    if (peeks[id] case final peek?) entry['atlas_peek'] = peek.toJson();
  }
}
