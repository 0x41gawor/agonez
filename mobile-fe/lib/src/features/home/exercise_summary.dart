import 'package:flutter/foundation.dart';

import '../../api/prescription_models.dart';

/// One exercise of a prescription as the Today card lists it: sets × rep
/// range, for example `3 × 6–8`.
///
/// Loads are left to the workout itself, where each set shows its load next
/// to the previous performance; Home is a glance at what is coming.
@immutable
class ExerciseSummary {
  const ExerciseSummary({
    required this.ordinal,
    required this.name,
    required this.sets,
    required this.repMin,
    required this.repMax,
  });

  /// Counts every prescribed set, matching the card's set total. The rep
  /// range comes from the working sets, so a ramp-up set never widens it.
  factory ExerciseSummary.of(PrescriptionExercise exercise) {
    final working = exercise.sets
        .where((set) => set.role != 'rampup')
        .toList(growable: false);
    final shaping = working.isEmpty ? exercise.sets : working;
    return ExerciseSummary(
      ordinal: exercise.ordinal,
      name: exercise.exercise.name,
      sets: exercise.sets.length,
      repMin: shaping.isEmpty
          ? 0
          : shaping.map((set) => set.repMin).reduce((a, b) => a < b ? a : b),
      repMax: shaping.isEmpty
          ? 0
          : shaping.map((set) => set.repMax).reduce((a, b) => a > b ? a : b),
    );
  }

  final int ordinal;
  final String name;
  final int sets;
  final int repMin;
  final int repMax;

  /// `3 × 6–8`, or `3 × 5` for a single rep target; null when the exercise
  /// is prescribed without any sets.
  String? get prescriptionLabel {
    if (sets == 0) return null;
    final reps = repMin == repMax ? '$repMin' : '$repMin–$repMax';
    return '$sets × $reps';
  }
}
