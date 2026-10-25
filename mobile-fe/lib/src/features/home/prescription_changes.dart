import 'package:flutter/foundation.dart';

import '../../api/prescription_models.dart';

/// A planned load that differs between two versions of a prescription.
@immutable
class LoadChange {
  const LoadChange({
    required this.exerciseName,
    required this.setIndex,
    required this.before,
    required this.after,
  });

  final String exerciseName;

  /// The set's position within its exercise, counting from 0.
  final int setIndex;
  final double? before;
  final double? after;
}

/// What changed between the prescription the athlete last saw and the
/// current one, typically after Post-Workout-Analysis updated it on
/// desktop.
///
/// Exercises are matched by their prescription id, which analysis keeps
/// stable, and sets by their position within the exercise, since promoting
/// plan-target rows to analysed ones may replace the set rows themselves.
@immutable
class PrescriptionChanges {
  const PrescriptionChanges({required this.loads, required this.other});

  factory PrescriptionChanges.between(
    WorkoutPrescription before,
    WorkoutPrescription after,
  ) {
    final previous = {
      for (final exercise in before.exercises)
        exercise.exercisePrescriptionId: exercise,
    };
    final loads = <LoadChange>[];
    var other = 0;
    for (final exercise in after.exercises) {
      final earlier = previous.remove(exercise.exercisePrescriptionId);
      if (earlier == null || earlier.exercise.id != exercise.exercise.id) {
        other++;
        continue;
      }
      final then = _ordered(earlier.sets);
      final now = _ordered(exercise.sets);
      for (var index = 0; index < now.length || index < then.length; index++) {
        if (index >= now.length || index >= then.length) {
          other++;
          continue;
        }
        final (a, b) = (then[index], now[index]);
        if (a.prescribedLoadKg != b.prescribedLoadKg) {
          loads.add(
            LoadChange(
              exerciseName: exercise.exercise.name,
              setIndex: index,
              before: a.prescribedLoadKg,
              after: b.prescribedLoadKg,
            ),
          );
        } else if (a.repMin != b.repMin ||
            a.repMax != b.repMax ||
            a.targetRir != b.targetRir) {
          other++;
        }
      }
    }
    // Exercises no longer prescribed.
    other += previous.length;
    return PrescriptionChanges(loads: loads, other: other);
  }

  final List<LoadChange> loads;

  /// Changes other than loads: exercises or sets added or removed, and
  /// changed rep ranges or RIR targets.
  final int other;

  bool get isEmpty => loads.isEmpty && other == 0;

  static List<PrescriptionSet> _ordered(List<PrescriptionSet> sets) =>
      [...sets]..sort((a, b) => a.ordinal.compareTo(b.ordinal));
}
