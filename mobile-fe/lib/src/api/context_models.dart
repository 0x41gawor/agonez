import 'json_support.dart';
import 'wire_enums.dart';

class Lease {
  const Lease({
    required this.deviceId,
    required this.epoch,
    required this.isThisDevice,
  });

  factory Lease.fromJson(JsonMap json) => Lease(
    deviceId: asString(requiredJson(json, 'device_id'), 'device_id'),
    epoch: asInt(requiredJson(json, 'epoch'), 'epoch'),
    isThisDevice: asBool(
      requiredJson(json, 'is_this_device'),
      'is_this_device',
    ),
  );

  final String deviceId;
  final int epoch;
  final bool isThisDevice;

  JsonMap toJson() => <String, Object?>{
    'device_id': deviceId,
    'epoch': epoch,
    'is_this_device': isThisDevice,
  };
}

class PositionHint {
  const PositionHint({
    required this.exercisePerformanceId,
    required this.setOrdinal,
    required this.phase,
  });

  factory PositionHint.fromJson(JsonMap json) => PositionHint(
    exercisePerformanceId: asString(
      requiredJson(json, 'exercise_performance_id'),
      'exercise_performance_id',
    ),
    setOrdinal: asInt(requiredJson(json, 'set_ordinal'), 'set_ordinal'),
    phase: decodePositionPhase(requiredJson(json, 'phase')),
  );

  final String exercisePerformanceId;
  final int setOrdinal;
  final PositionPhase phase;

  JsonMap toJson() => <String, Object?>{
    'exercise_performance_id': exercisePerformanceId,
    'set_ordinal': setOrdinal,
    'phase': phase.wireName,
  };
}

class WorkoutCounts {
  const WorkoutCounts({
    required this.prescribedSets,
    required this.performedSets,
    required this.skippedSets,
  });

  factory WorkoutCounts.fromJson(JsonMap json) => WorkoutCounts(
    prescribedSets: asInt(
      requiredJson(json, 'prescribed_sets'),
      'prescribed_sets',
    ),
    performedSets: asInt(
      requiredJson(json, 'performed_sets'),
      'performed_sets',
    ),
    skippedSets: asInt(requiredJson(json, 'skipped_sets'), 'skipped_sets'),
  );

  final int prescribedSets;
  final int performedSets;
  final int skippedSets;

  JsonMap toJson() => <String, Object?>{
    'prescribed_sets': prescribedSets,
    'performed_sets': performedSets,
    'skipped_sets': skippedSets,
  };
}

class ActiveWorkoutSummary {
  const ActiveWorkoutSummary({
    required this.workoutId,
    required this.sessionId,
    required this.workoutUnitName,
    required this.startedAt,
    required this.lease,
    required this.appliedSeq,
    required this.revision,
    required this.positionHint,
    required this.counts,
  });

  factory ActiveWorkoutSummary.fromJson(JsonMap json) => ActiveWorkoutSummary(
    workoutId: asString(requiredJson(json, 'workout_id'), 'workout_id'),
    sessionId: asInt(requiredJson(json, 'session_id'), 'session_id'),
    workoutUnitName: asString(
      requiredJson(json, 'workout_unit_name'),
      'workout_unit_name',
    ),
    startedAt: asDateTime(requiredJson(json, 'started_at'), 'started_at'),
    lease: Lease.fromJson(asJsonMap(requiredJson(json, 'lease'), 'lease')),
    appliedSeq: asInt(requiredJson(json, 'applied_seq'), 'applied_seq'),
    revision: asInt(requiredJson(json, 'revision'), 'revision'),
    positionHint: requiredJson(json, 'position_hint') == null
        ? null
        : PositionHint.fromJson(
            asJsonMap(json['position_hint'], 'position_hint'),
          ),
    counts: WorkoutCounts.fromJson(
      asJsonMap(requiredJson(json, 'counts'), 'counts'),
    ),
  );

  final String workoutId;
  final int sessionId;
  final String workoutUnitName;
  final DateTime startedAt;
  final Lease lease;
  final int appliedSeq;
  final int revision;
  final PositionHint? positionHint;
  final WorkoutCounts counts;

  JsonMap toJson() => <String, Object?>{
    'workout_id': workoutId,
    'session_id': sessionId,
    'workout_unit_name': workoutUnitName,
    'started_at': encodeDateTime(startedAt),
    'lease': lease.toJson(),
    'applied_seq': appliedSeq,
    'revision': revision,
    'position_hint': positionHint?.toJson(),
    'counts': counts.toJson(),
  };
}

class PlanRunCompact {
  const PlanRunCompact({
    required this.id,
    required this.name,
    required this.status,
    required this.startsOn,
    required this.endsOn,
    required this.microcycleCount,
    required this.currentMicrocycleOrdinal,
  });

  factory PlanRunCompact.fromJson(JsonMap json) => PlanRunCompact(
    id: asInt(requiredJson(json, 'id'), 'id'),
    name: asString(requiredJson(json, 'name'), 'name'),
    status: asString(requiredJson(json, 'status'), 'status'),
    startsOn: asString(requiredJson(json, 'starts_on'), 'starts_on'),
    endsOn: asString(requiredJson(json, 'ends_on'), 'ends_on'),
    microcycleCount: asInt(
      requiredJson(json, 'microcycle_count'),
      'microcycle_count',
    ),
    currentMicrocycleOrdinal: asNullableInt(
      requiredJson(json, 'current_microcycle_ordinal'),
      'current_microcycle_ordinal',
    ),
  );

  final int id;
  final String name;
  final String status;
  final String startsOn;
  final String endsOn;
  final int microcycleCount;
  final int? currentMicrocycleOrdinal;

  JsonMap toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'status': status,
    'starts_on': startsOn,
    'ends_on': endsOn,
    'microcycle_count': microcycleCount,
    'current_microcycle_ordinal': currentMicrocycleOrdinal,
  };
}

class ContextPlanRun {
  const ContextPlanRun({
    required this.id,
    required this.name,
    required this.status,
    required this.startsOn,
    required this.endsOn,
    required this.microcycleCount,
    required this.currentMicrocycleOrdinal,
    required this.planName,
    required this.microcycleDurationDays,
  });

  factory ContextPlanRun.fromJson(JsonMap json) => ContextPlanRun(
    id: asInt(requiredJson(json, 'id'), 'id'),
    name: asString(requiredJson(json, 'name'), 'name'),
    status: asString(requiredJson(json, 'status'), 'status'),
    startsOn: asString(requiredJson(json, 'starts_on'), 'starts_on'),
    endsOn: asString(requiredJson(json, 'ends_on'), 'ends_on'),
    microcycleCount: asInt(
      requiredJson(json, 'microcycle_count'),
      'microcycle_count',
    ),
    currentMicrocycleOrdinal: asNullableInt(
      requiredJson(json, 'current_microcycle_ordinal'),
      'current_microcycle_ordinal',
    ),
    planName: asString(requiredJson(json, 'plan_name'), 'plan_name'),
    microcycleDurationDays: asInt(
      requiredJson(json, 'microcycle_duration_days'),
      'microcycle_duration_days',
    ),
  );

  final int id;
  final String name;
  final String status;
  final String startsOn;
  final String endsOn;
  final int microcycleCount;
  final int? currentMicrocycleOrdinal;
  final String planName;
  final int microcycleDurationDays;

  JsonMap toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'status': status,
    'starts_on': startsOn,
    'ends_on': endsOn,
    'microcycle_count': microcycleCount,
    'current_microcycle_ordinal': currentMicrocycleOrdinal,
    'plan_name': planName,
    'microcycle_duration_days': microcycleDurationDays,
  };
}

class TodayMicrocycle {
  const TodayMicrocycle({
    required this.id,
    required this.ordinal,
    required this.dayOrdinal,
    required this.classification,
  });

  factory TodayMicrocycle.fromJson(JsonMap json) => TodayMicrocycle(
    id: asInt(requiredJson(json, 'id'), 'id'),
    ordinal: asInt(requiredJson(json, 'ordinal'), 'ordinal'),
    dayOrdinal: asInt(requiredJson(json, 'day_ordinal'), 'day_ordinal'),
    classification: asString(
      requiredJson(json, 'classification'),
      'classification',
    ),
  );

  final int id;
  final int ordinal;
  final int dayOrdinal;
  final String classification;

  JsonMap toJson() => <String, Object?>{
    'id': id,
    'ordinal': ordinal,
    'day_ordinal': dayOrdinal,
    'classification': classification,
  };
}

class TodayPosition {
  const TodayPosition({required this.date, required this.microcycle});

  factory TodayPosition.fromJson(JsonMap json) => TodayPosition(
    date: asString(requiredJson(json, 'date'), 'date'),
    microcycle: requiredJson(json, 'microcycle') == null
        ? null
        : TodayMicrocycle.fromJson(asJsonMap(json['microcycle'], 'microcycle')),
  );

  final String date;
  final TodayMicrocycle? microcycle;

  JsonMap toJson() => <String, Object?>{
    'date': date,
    'microcycle': microcycle?.toJson(),
  };
}

class MicrocycleDay {
  const MicrocycleDay({
    required this.date,
    required this.dayOrdinal,
    required this.sessionId,
    required this.workoutUnitName,
    required this.status,
  });

  factory MicrocycleDay.fromJson(JsonMap json) => MicrocycleDay(
    date: asString(requiredJson(json, 'date'), 'date'),
    dayOrdinal: asInt(requiredJson(json, 'day_ordinal'), 'day_ordinal'),
    sessionId: asNullableInt(requiredJson(json, 'session_id'), 'session_id'),
    workoutUnitName: asNullableString(
      requiredJson(json, 'workout_unit_name'),
      'workout_unit_name',
    ),
    status: asString(requiredJson(json, 'status'), 'status'),
  );

  final String date;
  final int dayOrdinal;
  final int? sessionId;
  final String? workoutUnitName;
  final String status;

  JsonMap toJson() => <String, Object?>{
    'date': date,
    'day_ordinal': dayOrdinal,
    'session_id': sessionId,
    'workout_unit_name': workoutUnitName,
    'status': status,
  };
}

class PrescriptionReadiness {
  const PrescriptionReadiness({
    required this.readiness,
    this.prescriptionVersion,
    this.updatedAt,
    this.exerciseCount,
    this.setCount,
    this.estimatedDurationMin,
  });

  factory PrescriptionReadiness.fromJson(JsonMap json) => PrescriptionReadiness(
    readiness: decodePrescriptionReadiness(requiredJson(json, 'readiness')),
    prescriptionVersion: asNullableString(
      json['prescription_version'],
      'prescription_version',
    ),
    updatedAt: asNullableDateTime(json['updated_at'], 'updated_at'),
    exerciseCount: asNullableInt(json['exercise_count'], 'exercise_count'),
    setCount: asNullableInt(json['set_count'], 'set_count'),
    estimatedDurationMin: asNullableInt(
      json['estimated_duration_min'],
      'estimated_duration_min',
    ),
  );

  final PrescriptionReadinessStatus readiness;
  final String? prescriptionVersion;
  final DateTime? updatedAt;
  final int? exerciseCount;
  final int? setCount;
  final int? estimatedDurationMin;

  JsonMap toJson() => <String, Object?>{
    'readiness': readiness.wireName,
    'prescription_version': prescriptionVersion,
    'updated_at': updatedAt == null ? null : encodeDateTime(updatedAt!),
    'exercise_count': exerciseCount,
    'set_count': setCount,
    'estimated_duration_min': estimatedDurationMin,
  };
}

class SessionSummary {
  const SessionSummary({
    required this.sessionId,
    required this.workoutUnitName,
    required this.workoutTrackId,
    required this.scheduledOn,
    required this.status,
    required this.prescription,
    this.relation,
  });

  factory SessionSummary.fromJson(JsonMap json) => SessionSummary(
    sessionId: asInt(requiredJson(json, 'session_id'), 'session_id'),
    workoutUnitName: asString(
      requiredJson(json, 'workout_unit_name'),
      'workout_unit_name',
    ),
    workoutTrackId: asInt(
      requiredJson(json, 'workout_track_id'),
      'workout_track_id',
    ),
    scheduledOn: asString(requiredJson(json, 'scheduled_on'), 'scheduled_on'),
    status: asString(requiredJson(json, 'status'), 'status'),
    prescription: PrescriptionReadiness.fromJson(
      asJsonMap(requiredJson(json, 'prescription'), 'prescription'),
    ),
    relation: json['relation'] == null
        ? null
        : decodeSessionRelation(json['relation']),
  );

  final int sessionId;
  final String workoutUnitName;
  final int workoutTrackId;
  final String scheduledOn;
  final String status;
  final PrescriptionReadiness prescription;
  final SessionRelation? relation;

  JsonMap toJson() => <String, Object?>{
    'session_id': sessionId,
    'workout_unit_name': workoutUnitName,
    'workout_track_id': workoutTrackId,
    'scheduled_on': scheduledOn,
    'status': status,
    'prescription': prescription.toJson(),
    'relation': relation?.wireName,
  };
}

class RecentWorkout {
  const RecentWorkout({
    required this.sessionId,
    required this.workoutUnitName,
    required this.completedAt,
    required this.performedSets,
    required this.prescribedSets,
    required this.skippedSets,
  });

  factory RecentWorkout.fromJson(JsonMap json) => RecentWorkout(
    sessionId: asInt(requiredJson(json, 'session_id'), 'session_id'),
    workoutUnitName: asString(
      requiredJson(json, 'workout_unit_name'),
      'workout_unit_name',
    ),
    completedAt: asDateTime(requiredJson(json, 'completed_at'), 'completed_at'),
    performedSets: asInt(
      requiredJson(json, 'performed_sets'),
      'performed_sets',
    ),
    prescribedSets: asInt(
      requiredJson(json, 'prescribed_sets'),
      'prescribed_sets',
    ),
    skippedSets: asInt(requiredJson(json, 'skipped_sets'), 'skipped_sets'),
  );

  final int sessionId;
  final String workoutUnitName;
  final DateTime completedAt;
  final int performedSets;
  final int prescribedSets;
  final int skippedSets;

  JsonMap toJson() => <String, Object?>{
    'session_id': sessionId,
    'workout_unit_name': workoutUnitName,
    'completed_at': encodeDateTime(completedAt),
    'performed_sets': performedSets,
    'prescribed_sets': prescribedSets,
    'skipped_sets': skippedSets,
  };
}

class MobileContext {
  const MobileContext({
    required this.generatedAt,
    required this.contextVersion,
    required this.planRun,
    required this.selectionRequired,
    required this.today,
    required this.microcycleDays,
    required this.expectedSession,
    required this.alternatives,
    required this.fallbacks,
    required this.activeWorkout,
    required this.recent,
  });

  factory MobileContext.fromJson(JsonMap json) => MobileContext(
    generatedAt: asDateTime(requiredJson(json, 'generated_at'), 'generated_at'),
    contextVersion: asString(
      requiredJson(json, 'context_version'),
      'context_version',
    ),
    planRun: requiredJson(json, 'plan_run') == null
        ? null
        : ContextPlanRun.fromJson(asJsonMap(json['plan_run'], 'plan_run')),
    selectionRequired: asBool(
      requiredJson(json, 'selection_required'),
      'selection_required',
    ),
    today: requiredJson(json, 'today') == null
        ? null
        : TodayPosition.fromJson(asJsonMap(json['today'], 'today')),
    microcycleDays: decodeList(
      requiredJson(json, 'microcycle_days'),
      (value) => MicrocycleDay.fromJson(asJsonMap(value, 'microcycle_days[]')),
      'microcycle_days',
    ),
    expectedSession: requiredJson(json, 'expected_session') == null
        ? null
        : SessionSummary.fromJson(
            asJsonMap(json['expected_session'], 'expected_session'),
          ),
    alternatives: decodeList(
      requiredJson(json, 'alternatives'),
      (value) => SessionSummary.fromJson(asJsonMap(value, 'alternatives[]')),
      'alternatives',
    ),
    fallbacks: decodeList(
      requiredJson(json, 'fallbacks'),
      (value) => asJsonMap(value, 'fallbacks[]'),
      'fallbacks',
    ),
    activeWorkout: requiredJson(json, 'active_workout') == null
        ? null
        : ActiveWorkoutSummary.fromJson(
            asJsonMap(json['active_workout'], 'active_workout'),
          ),
    recent: decodeList(
      requiredJson(json, 'recent'),
      (value) => RecentWorkout.fromJson(asJsonMap(value, 'recent[]')),
      'recent',
    ),
  );

  final DateTime generatedAt;
  final String contextVersion;
  final ContextPlanRun? planRun;
  final bool selectionRequired;
  final TodayPosition? today;
  final List<MicrocycleDay> microcycleDays;
  final SessionSummary? expectedSession;
  final List<SessionSummary> alternatives;
  final List<JsonMap> fallbacks;
  final ActiveWorkoutSummary? activeWorkout;
  final List<RecentWorkout> recent;

  JsonMap toJson() => <String, Object?>{
    'generated_at': encodeDateTime(generatedAt),
    'context_version': contextVersion,
    'plan_run': planRun?.toJson(),
    'selection_required': selectionRequired,
    'today': today?.toJson(),
    'microcycle_days': microcycleDays
        .map((item) => item.toJson())
        .toList(growable: false),
    'expected_session': expectedSession?.toJson(),
    'alternatives': alternatives
        .map((item) => item.toJson())
        .toList(growable: false),
    'fallbacks': fallbacks,
    'active_workout': activeWorkout?.toJson(),
    'recent': recent.map((item) => item.toJson()).toList(growable: false),
  };
}
