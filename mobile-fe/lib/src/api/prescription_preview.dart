import 'package:flutter/foundation.dart';

import 'json_support.dart';

/// The complete prescription a not-ready session would get, from
/// `GET /sessions/{id}/prescription/fallback`: analysed exercises as they
/// are, plus the plan's other exercises with loads inherited from the last
/// exposure.
///
/// For display only. The server writes nothing for it, so generated rows
/// have no ids and the preview has no version; a start always prepares the
/// prescription with the `POST` first.
@immutable
class PrescriptionPreview {
  const PrescriptionPreview({required this.exercises});

  factory PrescriptionPreview.fromJson(JsonMap json) => PrescriptionPreview(
    exercises: decodeList(
      requiredJson(json, 'exercises'),
      (value) => PreviewExercise.fromJson(asJsonMap(value, 'exercises[]')),
      'exercises',
    )..sort((a, b) => a.ordinal.compareTo(b.ordinal)),
  );

  /// In prescription order.
  final List<PreviewExercise> exercises;
}

@immutable
class PreviewExercise {
  const PreviewExercise({
    required this.ordinal,
    required this.name,
    required this.generated,
    required this.sets,
  });

  factory PreviewExercise.fromJson(JsonMap json) => PreviewExercise(
    ordinal: asInt(requiredJson(json, 'ordinal'), 'ordinal'),
    name: asString(
      requiredJson(
        asJsonMap(requiredJson(json, 'exercise'), 'exercise'),
        'name',
      ),
      'exercise.name',
    ),
    generated: json['source'] == 'plan_fallback',
    sets: decodeList(
      requiredJson(json, 'sets'),
      (value) => PreviewSet.fromJson(asJsonMap(value, 'sets[]')),
      'sets',
    ),
  );

  final int ordinal;
  final String name;

  /// Completed from the plan rather than analysed (`source: plan_fallback`).
  final bool generated;
  final List<PreviewSet> sets;
}

@immutable
class PreviewSet {
  const PreviewSet({
    required this.role,
    required this.repMin,
    required this.repMax,
    required this.loadKg,
    required this.loadSource,
  });

  factory PreviewSet.fromJson(JsonMap json) => PreviewSet(
    role: asString(requiredJson(json, 'role'), 'role'),
    repMin: asInt(requiredJson(json, 'rep_min'), 'rep_min'),
    repMax: asInt(requiredJson(json, 'rep_max'), 'rep_max'),
    loadKg: asNullableDouble(json['prescribed_load_kg'], 'prescribed_load_kg'),
    loadSource: asNullableString(json['load_source'], 'load_source'),
  );

  final String role;
  final int repMin;
  final int repMax;
  final double? loadKg;

  /// Who decided the load: `analysis`, `last_exposure`, or null for none.
  final String? loadSource;
}
