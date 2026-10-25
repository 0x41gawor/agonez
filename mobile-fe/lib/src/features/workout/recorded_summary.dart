import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../api/atlas_models.dart';
import '../../api/prescription_models.dart';
import '../../storage/app_database.dart';

/// How an exercise of a finished workout departed from its prescription.
enum RecordedTag {
  substituted,
  unplanned,
  skipped,
  incomplete,
  reordered,
  note,
}

/// One exercise of a finished workout, as the summary lists it.
@immutable
class RecordedExercise {
  const RecordedExercise({
    required this.name,
    required this.sets,
    required this.tags,
  });

  /// The exercise actually performed: the substitute or unplanned exercise
  /// where there is one.
  final String name;

  /// Performed sets in order, as load and repetitions.
  final List<({double? loadKg, int? repetitions})> sets;

  /// In display order; empty for an exercise done as prescribed.
  final List<RecordedTag> tags;
}

/// The finished workout's exercises in the order they were performed.
///
/// An exercise counts as reordered only when it left the planned order
/// itself: the planned exercises keep their longest run that still follows
/// the prescription, and only those outside it are tagged. Doing #5 second
/// therefore tags that one exercise, not the three it was moved past.
List<RecordedExercise> recordedExercises({
  required WorkoutPrescription? prescription,
  required List<LocalExercise> exercises,
  required List<LocalSet> sets,
}) {
  final planned = <int, PrescriptionExercise>{
    for (final exercise in prescription?.exercises ?? const [])
      exercise.exercisePrescriptionId: exercise,
  };
  final plannedOrder = <int, int>{
    for (final (index, exercise)
        in (prescription?.exercises ?? const <PrescriptionExercise>[]).indexed)
      exercise.exercisePrescriptionId: index,
  };
  final performedOrder = [...exercises]
    ..sort((a, b) => a.performedOrdinal.compareTo(b.performedOrdinal));
  final moved = _outOfOrder([
    for (final exercise in performedOrder)
      if (plannedOrder[exercise.exercisePrescriptionId] case final position?)
        (exercise.exercisePerformanceId, position),
  ]);

  return [
    for (final exercise in performedOrder)
      _recorded(
        exercise,
        prescribed: planned[exercise.exercisePrescriptionId],
        sets:
            sets
                .where(
                  (set) =>
                      set.exercisePerformanceId ==
                      exercise.exercisePerformanceId,
                )
                .toList()
              ..sort((a, b) => a.ordinal.compareTo(b.ordinal)),
        reordered: moved.contains(exercise.exercisePerformanceId),
      ),
  ];
}

RecordedExercise _recorded(
  LocalExercise exercise, {
  required PrescriptionExercise? prescribed,
  required List<LocalSet> sets,
  required bool reordered,
}) {
  final performed = [
    for (final set in sets)
      if (set.status == 'performed')
        (loadKg: set.loadKg, repetitions: set.repetitions),
  ];
  final unplanned =
      exercise.exercisePrescriptionId == null || exercise.mode == 'added';
  final skipped = exercise.mode == 'skipped';
  final incomplete =
      !unplanned &&
      !skipped &&
      (exercise.mode == 'not_performed' ||
          performed.length < (prescribed?.sets.length ?? 0));
  final noted =
      (exercise.comment?.trim().isNotEmpty ?? false) ||
      sets.any((set) => set.comment?.trim().isNotEmpty ?? false);
  return RecordedExercise(
    name:
        _actualName(exercise.actualExerciseJson) ??
        prescribed?.exercise.name ??
        '—',
    sets: performed,
    tags: [
      if (exercise.mode == 'substituted') RecordedTag.substituted,
      if (unplanned) RecordedTag.unplanned,
      if (skipped) RecordedTag.skipped,
      if (incomplete) RecordedTag.incomplete,
      if (reordered) RecordedTag.reordered,
      if (noted) RecordedTag.note,
    ],
  );
}

String? _actualName(String? json) {
  if (json == null) return null;
  try {
    return ExerciseIdentity.fromJson(
      Map<String, Object?>.from(jsonDecode(json) as Map),
    ).name;
  } on Object {
    return null;
  }
}

/// Ids of the entries outside one longest run of increasing planned
/// positions, i.e. the fewest exercises whose moves explain the order.
Set<String> _outOfOrder(List<(String id, int position)> performed) {
  if (performed.isEmpty) return const {};
  // Longest increasing subsequence; the lists are a handful of exercises.
  final length = List.filled(performed.length, 1);
  final previous = List.filled(performed.length, -1);
  for (var i = 0; i < performed.length; i++) {
    for (var j = 0; j < i; j++) {
      if (performed[j].$2 < performed[i].$2 && length[j] + 1 > length[i]) {
        length[i] = length[j] + 1;
        previous[i] = j;
      }
    }
  }
  var end = 0;
  for (var i = 1; i < performed.length; i++) {
    if (length[i] > length[end]) end = i;
  }
  final kept = <String>{};
  for (var i = end; i >= 0; i = previous[i]) {
    kept.add(performed[i].$1);
  }
  return {
    for (final (id, _) in performed)
      if (!kept.contains(id)) id,
  };
}
