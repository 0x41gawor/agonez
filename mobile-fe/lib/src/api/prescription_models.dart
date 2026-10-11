import 'atlas_models.dart';
import 'json_support.dart';
import 'wire_enums.dart';

class PrescriptionSet {
  const PrescriptionSet({
    required this.setPrescriptionId,
    required this.ordinal,
    required this.role,
    required this.prescribedLoadKg,
    required this.repMin,
    required this.repMax,
    required this.targetRir,
    required this.comment,
  });

  factory PrescriptionSet.fromJson(JsonMap json) => PrescriptionSet(
    setPrescriptionId: asInt(
      requiredJson(json, 'set_prescription_id'),
      'set_prescription_id',
    ),
    ordinal: asInt(requiredJson(json, 'ordinal'), 'ordinal'),
    role: asString(requiredJson(json, 'role'), 'role'),
    prescribedLoadKg: asNullableDouble(
      requiredJson(json, 'prescribed_load_kg'),
      'prescribed_load_kg',
    ),
    repMin: asInt(requiredJson(json, 'rep_min'), 'rep_min'),
    repMax: asInt(requiredJson(json, 'rep_max'), 'rep_max'),
    targetRir: asNullableInt(requiredJson(json, 'target_rir'), 'target_rir'),
    comment: asNullableString(requiredJson(json, 'comment'), 'comment'),
  );

  final int setPrescriptionId;
  final int ordinal;
  final String role;
  final double? prescribedLoadKg;
  final int repMin;
  final int repMax;
  final int? targetRir;
  final String? comment;

  JsonMap toJson() => <String, Object?>{
    'set_prescription_id': setPrescriptionId,
    'ordinal': ordinal,
    'role': role,
    'prescribed_load_kg': prescribedLoadKg,
    'rep_min': repMin,
    'rep_max': repMax,
    'target_rir': targetRir,
    'comment': comment,
  };
}

class PrescriptionSlot {
  const PrescriptionSlot({required this.goal, required this.role});

  factory PrescriptionSlot.fromJson(JsonMap json) => PrescriptionSlot(
    goal: asNullableString(requiredJson(json, 'goal'), 'goal'),
    role: asString(requiredJson(json, 'role'), 'role'),
  );

  final String? goal;
  final String role;

  JsonMap toJson() => <String, Object?>{'goal': goal, 'role': role};
}

class PrescriptionAlternative {
  const PrescriptionAlternative({
    required this.exercise,
    required this.variantOrdinal,
    required this.atlasPeek,
    this.source = 'plan_variant',
  });

  factory PrescriptionAlternative.fromJson(JsonMap json) =>
      PrescriptionAlternative(
        exercise: ExerciseIdentity.fromJson(
          asJsonMap(requiredJson(json, 'exercise'), 'exercise'),
        ),
        source: asNullableString(json['source'], 'source') ?? 'plan_variant',
        variantOrdinal: asInt(
          requiredJson(json, 'variant_ordinal'),
          'variant_ordinal',
        ),
        atlasPeek: AtlasPeek.fromJson(
          asJsonMap(requiredJson(json, 'atlas_peek'), 'atlas_peek'),
        ),
      );

  final ExerciseIdentity exercise;
  final String source;
  final int variantOrdinal;
  final AtlasPeek atlasPeek;

  JsonMap toJson() => <String, Object?>{
    'exercise': exercise.toJson(),
    'source': source,
    'variant_ordinal': variantOrdinal,
    'atlas_peek': atlasPeek.toJson(),
  };
}

class PreviousSet {
  const PreviousSet({
    required this.ordinal,
    required this.status,
    required this.loadKg,
    required this.repetitions,
    required this.rir,
  });

  factory PreviousSet.fromJson(JsonMap json) => PreviousSet(
    ordinal: asInt(requiredJson(json, 'ordinal'), 'ordinal'),
    status: decodePerformedSetStatus(requiredJson(json, 'status')),
    loadKg: asNullableDouble(requiredJson(json, 'load_kg'), 'load_kg'),
    repetitions: asNullableInt(
      requiredJson(json, 'repetitions'),
      'repetitions',
    ),
    rir: asNullableInt(requiredJson(json, 'rir'), 'rir'),
  );

  final int ordinal;
  final PerformedSetStatus status;
  final double? loadKg;
  final int? repetitions;
  final int? rir;

  JsonMap toJson() => <String, Object?>{
    'ordinal': ordinal,
    'status': status.wireName,
    'load_kg': loadKg,
    'repetitions': repetitions,
    'rir': rir,
  };
}

class PreviousExposure {
  const PreviousExposure({
    required this.microcycleOrdinal,
    required this.performedOn,
    required this.exercise,
    required this.sets,
  });

  factory PreviousExposure.fromJson(JsonMap json) => PreviousExposure(
    microcycleOrdinal: asInt(
      requiredJson(json, 'microcycle_ordinal'),
      'microcycle_ordinal',
    ),
    performedOn: asString(requiredJson(json, 'performed_on'), 'performed_on'),
    exercise: ExerciseIdentity.fromJson(
      asJsonMap(requiredJson(json, 'exercise'), 'exercise'),
    ),
    sets: decodeList(
      requiredJson(json, 'sets'),
      (value) => PreviousSet.fromJson(asJsonMap(value, 'sets[]')),
      'sets',
    ),
  );

  final int microcycleOrdinal;
  final String performedOn;
  final ExerciseIdentity exercise;
  final List<PreviousSet> sets;

  JsonMap toJson() => <String, Object?>{
    'microcycle_ordinal': microcycleOrdinal,
    'performed_on': performedOn,
    'exercise': exercise.toJson(),
    'sets': sets.map((item) => item.toJson()).toList(growable: false),
  };
}

class ExerciseHistory {
  const ExerciseHistory({required this.previousExposure});

  factory ExerciseHistory.fromJson(JsonMap json) => ExerciseHistory(
    previousExposure: requiredJson(json, 'previous_exposure') == null
        ? null
        : PreviousExposure.fromJson(
            asJsonMap(json['previous_exposure'], 'previous_exposure'),
          ),
  );

  final PreviousExposure? previousExposure;

  JsonMap toJson() => <String, Object?>{
    'previous_exposure': previousExposure?.toJson(),
  };
}

class PrescriptionExercise {
  const PrescriptionExercise({
    required this.exercisePrescriptionId,
    required this.ordinal,
    required this.exerciseTrackId,
    required this.slot,
    required this.exercise,
    required this.variantLabel,
    required this.planComment,
    required this.prescriptionComment,
    required this.loadStepKg,
    required this.defaultRestS,
    required this.sets,
    required this.alternatives,
    required this.history,
    required this.atlasPeek,
  });

  factory PrescriptionExercise.fromJson(JsonMap json) => PrescriptionExercise(
    exercisePrescriptionId: asInt(
      requiredJson(json, 'exercise_prescription_id'),
      'exercise_prescription_id',
    ),
    ordinal: asInt(requiredJson(json, 'ordinal'), 'ordinal'),
    exerciseTrackId: asInt(
      requiredJson(json, 'exercise_track_id'),
      'exercise_track_id',
    ),
    slot: PrescriptionSlot.fromJson(
      asJsonMap(requiredJson(json, 'slot'), 'slot'),
    ),
    exercise: ExerciseIdentity.fromJson(
      asJsonMap(requiredJson(json, 'exercise'), 'exercise'),
    ),
    variantLabel: asNullableString(
      requiredJson(json, 'variant_label'),
      'variant_label',
    ),
    planComment: asNullableString(
      requiredJson(json, 'plan_comment'),
      'plan_comment',
    ),
    prescriptionComment: asNullableString(
      requiredJson(json, 'prescription_comment'),
      'prescription_comment',
    ),
    loadStepKg: asDouble(requiredJson(json, 'load_step_kg'), 'load_step_kg'),
    defaultRestS: asInt(requiredJson(json, 'default_rest_s'), 'default_rest_s'),
    sets: decodeList(
      requiredJson(json, 'sets'),
      (value) => PrescriptionSet.fromJson(asJsonMap(value, 'sets[]')),
      'sets',
    ),
    alternatives: decodeList(
      requiredJson(json, 'alternatives'),
      (value) =>
          PrescriptionAlternative.fromJson(asJsonMap(value, 'alternatives[]')),
      'alternatives',
    ),
    history: ExerciseHistory.fromJson(
      asJsonMap(requiredJson(json, 'history'), 'history'),
    ),
    atlasPeek: AtlasPeek.fromJson(
      asJsonMap(requiredJson(json, 'atlas_peek'), 'atlas_peek'),
    ),
  );

  final int exercisePrescriptionId;
  final int ordinal;
  final int exerciseTrackId;
  final PrescriptionSlot slot;
  final ExerciseIdentity exercise;
  final String? variantLabel;
  final String? planComment;
  final String? prescriptionComment;
  final double loadStepKg;
  final int defaultRestS;
  final List<PrescriptionSet> sets;
  final List<PrescriptionAlternative> alternatives;
  final ExerciseHistory history;
  final AtlasPeek atlasPeek;

  JsonMap toJson() => <String, Object?>{
    'exercise_prescription_id': exercisePrescriptionId,
    'ordinal': ordinal,
    'exercise_track_id': exerciseTrackId,
    'slot': slot.toJson(),
    'exercise': exercise.toJson(),
    'variant_label': variantLabel,
    'plan_comment': planComment,
    'prescription_comment': prescriptionComment,
    'load_step_kg': loadStepKg,
    'default_rest_s': defaultRestS,
    'sets': sets.map((item) => item.toJson()).toList(growable: false),
    'alternatives': alternatives
        .map((item) => item.toJson())
        .toList(growable: false),
    'history': history.toJson(),
    'atlas_peek': atlasPeek.toJson(),
  };
}

class PrescriptionMicrocycle {
  const PrescriptionMicrocycle({
    required this.ordinal,
    required this.classification,
  });

  factory PrescriptionMicrocycle.fromJson(JsonMap json) =>
      PrescriptionMicrocycle(
        ordinal: asInt(requiredJson(json, 'ordinal'), 'ordinal'),
        classification: decodeMicrocycleClassification(
          requiredJson(json, 'classification'),
        ),
      );

  final int ordinal;
  final PrescriptionMicrocycleClassification classification;

  JsonMap toJson() => <String, Object?>{
    'ordinal': ordinal,
    'classification': classification.wireName,
  };
}

class WorkoutPrescription {
  const WorkoutPrescription({
    required this.sessionId,
    required this.prescriptionId,
    required this.prescriptionVersion,
    required this.workoutUnitName,
    required this.workoutTrackId,
    required this.microcycle,
    required this.planComment,
    required this.prescriptionComment,
    required this.exercises,
  });

  factory WorkoutPrescription.fromJson(JsonMap json) => WorkoutPrescription(
    sessionId: asInt(requiredJson(json, 'session_id'), 'session_id'),
    prescriptionId: asInt(
      requiredJson(json, 'prescription_id'),
      'prescription_id',
    ),
    prescriptionVersion: asString(
      requiredJson(json, 'prescription_version'),
      'prescription_version',
    ),
    workoutUnitName: asString(
      requiredJson(json, 'workout_unit_name'),
      'workout_unit_name',
    ),
    workoutTrackId: asInt(
      requiredJson(json, 'workout_track_id'),
      'workout_track_id',
    ),
    microcycle: PrescriptionMicrocycle.fromJson(
      asJsonMap(requiredJson(json, 'microcycle'), 'microcycle'),
    ),
    planComment: asNullableString(
      requiredJson(json, 'plan_comment'),
      'plan_comment',
    ),
    prescriptionComment: asNullableString(
      requiredJson(json, 'prescription_comment'),
      'prescription_comment',
    ),
    exercises: decodeList(
      requiredJson(json, 'exercises'),
      (value) => PrescriptionExercise.fromJson(asJsonMap(value, 'exercises[]')),
      'exercises',
    ),
  );

  final int sessionId;
  final int prescriptionId;
  final String prescriptionVersion;
  final String workoutUnitName;
  final int workoutTrackId;
  final PrescriptionMicrocycle microcycle;
  final String? planComment;
  final String? prescriptionComment;
  final List<PrescriptionExercise> exercises;

  JsonMap toJson() => <String, Object?>{
    'session_id': sessionId,
    'prescription_id': prescriptionId,
    'prescription_version': prescriptionVersion,
    'workout_unit_name': workoutUnitName,
    'workout_track_id': workoutTrackId,
    'microcycle': microcycle.toJson(),
    'plan_comment': planComment,
    'prescription_comment': prescriptionComment,
    'exercises': exercises.map((item) => item.toJson()).toList(growable: false),
  };
}
