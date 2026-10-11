import 'json_support.dart';

class ExerciseIdentity {
  const ExerciseIdentity({
    required this.id,
    required this.slug,
    required this.name,
    this.fullName,
  });

  factory ExerciseIdentity.fromJson(JsonMap json) => ExerciseIdentity(
    id: asInt(requiredJson(json, 'id'), 'id'),
    slug: asString(requiredJson(json, 'slug'), 'slug'),
    name: asString(requiredJson(json, 'name'), 'name'),
    fullName: asNullableString(json['full_name'], 'full_name'),
  );

  final int id;
  final String slug;
  final String name;
  final String? fullName;

  JsonMap toJson() {
    final json = <String, Object?>{'id': id, 'slug': slug, 'name': name};
    putIfNotNull(json, 'full_name', fullName);
    return json;
  }
}

class TechniqueTldr {
  const TechniqueTldr({this.setup, this.execution, this.focus, this.stopWhen});

  factory TechniqueTldr.fromJson(JsonMap json) => TechniqueTldr(
    setup: asNullableString(json['setup'], 'setup'),
    execution: asNullableString(json['execution'], 'execution'),
    focus: asNullableString(json['focus'], 'focus'),
    stopWhen: asNullableString(json['stop_when'], 'stop_when'),
  );

  final String? setup;
  final String? execution;
  final String? focus;
  final String? stopWhen;

  JsonMap toJson() => <String, Object?>{
    'setup': setup,
    'execution': execution,
    'focus': focus,
    'stop_when': stopWhen,
  };
}

class AtlasMuscle {
  const AtlasMuscle({
    required this.muscleId,
    required this.slug,
    required this.name,
    required this.etuCm2,
    required this.capacityShare,
  });

  factory AtlasMuscle.fromJson(JsonMap json) => AtlasMuscle(
    muscleId: asInt(requiredJson(json, 'muscle_id'), 'muscle_id'),
    slug: asString(requiredJson(json, 'slug'), 'slug'),
    name: asString(requiredJson(json, 'name'), 'name'),
    etuCm2: asDouble(requiredJson(json, 'etu_cm2'), 'etu_cm2'),
    capacityShare: asNullableDouble(
      requiredJson(json, 'capacity_share'),
      'capacity_share',
    ),
  );

  final int muscleId;
  final String slug;
  final String name;
  final double etuCm2;
  final double? capacityShare;

  JsonMap toJson() => <String, Object?>{
    'muscle_id': muscleId,
    'slug': slug,
    'name': name,
    'etu_cm2': etuCm2,
    'capacity_share': capacityShare,
  };
}

class BodyMapRegion {
  BodyMapRegion({required this.regionId, required this.intensity}) {
    if (intensity < 0 || intensity > 1) {
      throw ArgumentError.value(
        intensity,
        'intensity',
        'must be between 0 and 1',
      );
    }
  }

  factory BodyMapRegion.fromJson(JsonMap json) => BodyMapRegion(
    regionId: asString(requiredJson(json, 'region_id'), 'region_id'),
    intensity: asDouble(requiredJson(json, 'intensity'), 'intensity'),
  );

  final String regionId;
  final double intensity;

  JsonMap toJson() => <String, Object?>{
    'region_id': regionId,
    'intensity': intensity,
  };
}

class BodyMap {
  const BodyMap({
    required this.asset,
    required this.assetVersion,
    required this.regions,
  });

  factory BodyMap.fromJson(JsonMap json) => BodyMap(
    asset: asString(requiredJson(json, 'asset'), 'asset'),
    assetVersion: asString(
      requiredJson(json, 'asset_version'),
      'asset_version',
    ),
    regions: decodeList(
      requiredJson(json, 'regions'),
      (value) => BodyMapRegion.fromJson(asJsonMap(value, 'regions[]')),
      'regions',
    ),
  );

  final String asset;
  final String assetVersion;
  final List<BodyMapRegion> regions;

  JsonMap toJson() => <String, Object?>{
    'asset': asset,
    'asset_version': assetVersion,
    'regions': regions.map((item) => item.toJson()).toList(growable: false),
  };
}

class AtlasPeek {
  const AtlasPeek({
    required this.exercise,
    required this.tags,
    required this.techniqueTldr,
    required this.musclesTop,
    required this.bodyMap,
    required this.contentLocale,
    required this.atlasVersion,
  });

  factory AtlasPeek.fromJson(JsonMap json) => AtlasPeek(
    exercise: ExerciseIdentity.fromJson(
      asJsonMap(requiredJson(json, 'exercise'), 'exercise'),
    ),
    tags: decodeList(
      requiredJson(json, 'tags'),
      (value) => asString(value, 'tags[]'),
      'tags',
    ),
    techniqueTldr: TechniqueTldr.fromJson(
      asJsonMap(requiredJson(json, 'technique_tldr'), 'technique_tldr'),
    ),
    musclesTop: decodeList(
      requiredJson(json, 'muscles_top'),
      (value) => AtlasMuscle.fromJson(asJsonMap(value, 'muscles_top[]')),
      'muscles_top',
    ),
    bodyMap: BodyMap.fromJson(
      asJsonMap(requiredJson(json, 'body_map'), 'body_map'),
    ),
    contentLocale: asString(
      requiredJson(json, 'content_locale'),
      'content_locale',
    ),
    atlasVersion: asString(
      requiredJson(json, 'atlas_version'),
      'atlas_version',
    ),
  );

  final ExerciseIdentity exercise;
  final List<String> tags;
  final TechniqueTldr techniqueTldr;
  final List<AtlasMuscle> musclesTop;
  final BodyMap bodyMap;
  final String contentLocale;
  final String atlasVersion;

  JsonMap toJson() => <String, Object?>{
    'exercise': exercise.toJson(),
    'tags': tags,
    'technique_tldr': techniqueTldr.toJson(),
    'muscles_top': musclesTop
        .map((item) => item.toJson())
        .toList(growable: false),
    'body_map': bodyMap.toJson(),
    'content_locale': contentLocale,
    'atlas_version': atlasVersion,
  };
}

class LastPerformedSet {
  const LastPerformedSet({
    required this.loadKg,
    required this.repetitions,
    required this.rir,
  });

  factory LastPerformedSet.fromJson(JsonMap json) => LastPerformedSet(
    loadKg: asNullableDouble(requiredJson(json, 'load_kg'), 'load_kg'),
    repetitions: asInt(requiredJson(json, 'repetitions'), 'repetitions'),
    rir: asNullableInt(requiredJson(json, 'rir'), 'rir'),
  );

  final double? loadKg;
  final int repetitions;
  final int? rir;

  JsonMap toJson() => <String, Object?>{
    'load_kg': loadKg,
    'repetitions': repetitions,
    'rir': rir,
  };
}

class LastPerformedInRun {
  const LastPerformedInRun({
    required this.microcycleOrdinal,
    required this.sets,
  });

  factory LastPerformedInRun.fromJson(JsonMap json) => LastPerformedInRun(
    microcycleOrdinal: asInt(
      requiredJson(json, 'microcycle_ordinal'),
      'microcycle_ordinal',
    ),
    sets: decodeList(
      requiredJson(json, 'sets'),
      (value) => LastPerformedSet.fromJson(asJsonMap(value, 'sets[]')),
      'sets',
    ),
  );

  final int microcycleOrdinal;
  final List<LastPerformedSet> sets;

  JsonMap toJson() => <String, Object?>{
    'microcycle_ordinal': microcycleOrdinal,
    'sets': sets.map((item) => item.toJson()).toList(growable: false),
  };
}

class AtlasSearchItem {
  const AtlasSearchItem({
    required this.id,
    required this.slug,
    required this.name,
    required this.fullName,
    required this.mechanicsTier,
    required this.targetCategory,
    required this.lastPerformedInRun,
  });

  factory AtlasSearchItem.fromJson(JsonMap json) => AtlasSearchItem(
    id: asInt(requiredJson(json, 'id'), 'id'),
    slug: asString(requiredJson(json, 'slug'), 'slug'),
    name: asString(requiredJson(json, 'name'), 'name'),
    fullName: asString(requiredJson(json, 'full_name'), 'full_name'),
    mechanicsTier: asString(
      requiredJson(json, 'mechanics_tier'),
      'mechanics_tier',
    ),
    targetCategory: asString(
      requiredJson(json, 'target_category'),
      'target_category',
    ),
    lastPerformedInRun: requiredJson(json, 'last_performed_in_run') == null
        ? null
        : LastPerformedInRun.fromJson(
            asJsonMap(json['last_performed_in_run'], 'last_performed_in_run'),
          ),
  );

  final int id;
  final String slug;
  final String name;
  final String fullName;
  final String mechanicsTier;
  final String targetCategory;
  final LastPerformedInRun? lastPerformedInRun;

  JsonMap toJson() => <String, Object?>{
    'id': id,
    'slug': slug,
    'name': name,
    'full_name': fullName,
    'mechanics_tier': mechanicsTier,
    'target_category': targetCategory,
    'last_performed_in_run': lastPerformedInRun?.toJson(),
  };
}

class AtlasSearchResponse {
  const AtlasSearchResponse({required this.items});

  factory AtlasSearchResponse.fromJson(JsonMap json) => AtlasSearchResponse(
    items: decodeList(
      requiredJson(json, 'items'),
      (value) => AtlasSearchItem.fromJson(asJsonMap(value, 'items[]')),
      'items',
    ),
  );

  final List<AtlasSearchItem> items;

  JsonMap toJson() => <String, Object?>{
    'items': items.map((item) => item.toJson()).toList(growable: false),
  };
}

class RecommendedRepRange {
  RecommendedRepRange({required this.min, required this.max}) {
    if (min < 1 || max < 1 || min > 32767 || max > 32767) {
      throw ArgumentError('Recommended rep range must be inside 1..32767');
    }
  }

  factory RecommendedRepRange.fromJson(JsonMap json) => RecommendedRepRange(
    min: asInt(requiredJson(json, 'min'), 'min'),
    max: asInt(requiredJson(json, 'max'), 'max'),
  );

  final int min;
  final int max;

  JsonMap toJson() => <String, Object?>{'min': min, 'max': max};
}

class RecommendedRepProfile {
  const RecommendedRepProfile({
    required this.highLoad,
    required this.moderateLoad,
    required this.lowLoad,
  });

  factory RecommendedRepProfile.fromJson(JsonMap json) => RecommendedRepProfile(
    highLoad: _decodeRepRange(requiredJson(json, 'high_load'), 'high_load'),
    moderateLoad: _decodeRepRange(
      requiredJson(json, 'moderate_load'),
      'moderate_load',
    ),
    lowLoad: _decodeRepRange(requiredJson(json, 'low_load'), 'low_load'),
  );

  final RecommendedRepRange? highLoad;
  final RecommendedRepRange? moderateLoad;
  final RecommendedRepRange? lowLoad;

  JsonMap toJson() => <String, Object?>{
    'high_load': highLoad?.toJson(),
    'moderate_load': moderateLoad?.toJson(),
    'low_load': lowLoad?.toJson(),
  };
}

RecommendedRepRange? _decodeRepRange(Object? value, String name) =>
    value == null ? null : RecommendedRepRange.fromJson(asJsonMap(value, name));

class ExerciseEngine {
  const ExerciseEngine({
    required this.propulsiveFcsaContributionVector,
    required this.activeTensionExposureVector,
    required this.etuVector,
    required this.muscleRecoveryCostModifierVector,
    required this.jointLoadExposureVector,
  });

  factory ExerciseEngine.fromJson(JsonMap json) => ExerciseEngine(
    propulsiveFcsaContributionVector: _decodeNumberMap(
      requiredJson(json, 'propulsive_fcsa_contribution_vector'),
      'propulsive_fcsa_contribution_vector',
    ),
    activeTensionExposureVector: _decodeNumberMap(
      requiredJson(json, 'active_tension_exposure_vector'),
      'active_tension_exposure_vector',
    ),
    etuVector: _decodeNumberMap(requiredJson(json, 'etu_vector'), 'etu_vector'),
    muscleRecoveryCostModifierVector: _decodeNumberMap(
      requiredJson(json, 'muscle_recovery_cost_modifier_vector'),
      'muscle_recovery_cost_modifier_vector',
    ),
    jointLoadExposureVector: _decodeNumberMap(
      requiredJson(json, 'joint_load_exposure_vector'),
      'joint_load_exposure_vector',
    ),
  );

  final Map<String, double>? propulsiveFcsaContributionVector;
  final Map<String, double>? activeTensionExposureVector;
  final Map<String, double>? etuVector;
  final Map<String, double>? muscleRecoveryCostModifierVector;
  final Map<String, double>? jointLoadExposureVector;

  JsonMap toJson() => <String, Object?>{
    'propulsive_fcsa_contribution_vector': propulsiveFcsaContributionVector,
    'active_tension_exposure_vector': activeTensionExposureVector,
    'etu_vector': etuVector,
    'muscle_recovery_cost_modifier_vector': muscleRecoveryCostModifierVector,
    'joint_load_exposure_vector': jointLoadExposureVector,
  };
}

class ExerciseDetail {
  const ExerciseDetail({
    required this.slug,
    required this.name,
    required this.nameFull,
    required this.bodyPart,
    required this.targetCategory,
    required this.mechanicsTier,
    required this.resistanceSource,
    required this.executionPattern,
    required this.loadCapacity,
    required this.systemicPropulsiveFcsaDemand,
    required this.recommendedRepProfile,
    required this.propulsiveFcsaContributionVector,
    required this.createdAt,
    required this.updatedAt,
    required this.technique,
    required this.comments,
    required this.videoLinks,
    required this.imageUrl,
    required this.engine,
  });

  factory ExerciseDetail.fromJson(JsonMap json) => ExerciseDetail(
    slug: asString(requiredJson(json, 'slug'), 'slug'),
    name: asString(requiredJson(json, 'name'), 'name'),
    nameFull: asString(requiredJson(json, 'name_full'), 'name_full'),
    bodyPart: asString(requiredJson(json, 'body_part'), 'body_part'),
    targetCategory: asString(
      requiredJson(json, 'target_category'),
      'target_category',
    ),
    mechanicsTier: asString(
      requiredJson(json, 'mechanics_tier'),
      'mechanics_tier',
    ),
    resistanceSource: asString(
      requiredJson(json, 'resistance_source'),
      'resistance_source',
    ),
    executionPattern: asString(
      requiredJson(json, 'execution_pattern'),
      'execution_pattern',
    ),
    loadCapacity: asNullableDouble(
      requiredJson(json, 'load_capacity'),
      'load_capacity',
    ),
    systemicPropulsiveFcsaDemand: asNullableDouble(
      requiredJson(json, 'systemic_propulsive_fcsa_demand'),
      'systemic_propulsive_fcsa_demand',
    ),
    recommendedRepProfile: RecommendedRepProfile.fromJson(
      asJsonMap(
        requiredJson(json, 'recommended_rep_profile'),
        'recommended_rep_profile',
      ),
    ),
    propulsiveFcsaContributionVector: _decodeNumberMap(
      requiredJson(json, 'propulsive_fcsa_contribution_vector'),
      'propulsive_fcsa_contribution_vector',
    ),
    createdAt: asDateTime(requiredJson(json, 'created_at'), 'created_at'),
    updatedAt: asDateTime(requiredJson(json, 'updated_at'), 'updated_at'),
    technique: asJsonMap(requiredJson(json, 'technique'), 'technique'),
    comments: asJsonMap(requiredJson(json, 'comments'), 'comments'),
    videoLinks: decodeList(
      requiredJson(json, 'video_links'),
      (value) => asString(value, 'video_links[]'),
      'video_links',
    ),
    imageUrl: asNullableString(requiredJson(json, 'image_url'), 'image_url'),
    engine: requiredJson(json, 'engine') == null
        ? null
        : ExerciseEngine.fromJson(asJsonMap(json['engine'], 'engine')),
  );

  final String slug;
  final String name;
  final String nameFull;
  final String bodyPart;
  final String targetCategory;
  final String mechanicsTier;
  final String resistanceSource;
  final String executionPattern;
  final double? loadCapacity;
  final double? systemicPropulsiveFcsaDemand;
  final RecommendedRepProfile recommendedRepProfile;
  final Map<String, double>? propulsiveFcsaContributionVector;
  final DateTime createdAt;
  final DateTime updatedAt;
  final JsonMap technique;
  final JsonMap comments;
  final List<String> videoLinks;
  final String? imageUrl;
  final ExerciseEngine? engine;

  JsonMap toJson() => <String, Object?>{
    'slug': slug,
    'name': name,
    'name_full': nameFull,
    'body_part': bodyPart,
    'target_category': targetCategory,
    'mechanics_tier': mechanicsTier,
    'resistance_source': resistanceSource,
    'execution_pattern': executionPattern,
    'load_capacity': loadCapacity,
    'systemic_propulsive_fcsa_demand': systemicPropulsiveFcsaDemand,
    'recommended_rep_profile': recommendedRepProfile.toJson(),
    'propulsive_fcsa_contribution_vector': propulsiveFcsaContributionVector,
    'created_at': encodeDateTime(createdAt),
    'updated_at': encodeDateTime(updatedAt),
    'technique': technique,
    'comments': comments,
    'video_links': videoLinks,
    'image_url': imageUrl,
    'engine': engine?.toJson(),
  };
}

Map<String, double>? _decodeNumberMap(Object? value, String name) {
  if (value == null) {
    return null;
  }
  final json = asJsonMap(value, name);
  return json.map((key, child) => MapEntry(key, asDouble(child, '$name.$key')));
}
