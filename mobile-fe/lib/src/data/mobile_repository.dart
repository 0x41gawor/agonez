import 'dart:convert';

import '../api/agonez_api_client.dart';
import '../api/api_error.dart';
import '../api/atlas_models.dart';
import '../api/conditional_response.dart';
import '../api/context_models.dart';
import '../api/json_support.dart';
import '../api/prescription_models.dart';
import '../storage/app_database.dart';

class LoadedValue<T> {
  const LoadedValue({
    required this.value,
    required this.fromCache,
    this.offline = false,
    this.etag,
  });

  final T value;
  final bool fromCache;
  final bool offline;
  final String? etag;
}

class MobileRepository {
  MobileRepository({
    required AppDatabase database,
    required AgonezApiClient api,
  }) : _database = database,
       _api = api;

  final AppDatabase _database;
  final AgonezApiClient _api;

  Future<int?> selectedPlanRunId() async {
    final value = await _database.readSetting('selected_plan_run_id');
    return value == null ? null : int.tryParse(value);
  }

  Future<void> selectPlanRun(int? id) async {
    if (await _database.activeWorkout() != null) {
      throw StateError('Plan run selection is locked during a workout');
    }
    await _database.writeSetting('selected_plan_run_id', id?.toString() ?? '');
  }

  Future<LoadedValue<MobileContext>> loadContext({
    int? planRunId,
    required String locale,
    DateTime? date,
  }) async {
    final dateKey = date == null
        ? 'today'
        : '${date.year.toString().padLeft(4, '0')}-'
              '${date.month.toString().padLeft(2, '0')}-'
              '${date.day.toString().padLeft(2, '0')}';
    final key = 'context:${planRunId ?? 'auto'}:$dateKey:$locale';
    final cached = await _database.cachedDocument(key);
    MobileContext? cachedValue;
    if (cached != null) {
      try {
        cachedValue = MobileContext.fromJson(
          asJsonMap(jsonDecode(cached.json), 'cached context'),
        );
      } on FormatException {
        cachedValue = null;
      }
    }
    try {
      final response = await _api.getContext(
        planRunId: planRunId,
        date: date == null ? null : dateKey,
        etag: cached?.etag,
      );
      if (response is ModifiedResponse<MobileContext>) {
        await _database.putCachedDocument(
          key: key,
          json: jsonEncode(response.value.toJson()),
          etag: response.etag,
        );
        return LoadedValue(
          value: response.value,
          fromCache: false,
          etag: response.etag,
        );
      }
      if (cachedValue != null) {
        return LoadedValue(
          value: cachedValue,
          fromCache: true,
          etag: response.etag ?? cached?.etag,
        );
      }
      throw const FormatException('Server returned 304 without cached context');
    } on AgonezApiException {
      if (cachedValue != null) {
        return LoadedValue(
          value: cachedValue,
          fromCache: true,
          offline: true,
          etag: cached?.etag,
        );
      }
      rethrow;
    }
  }

  Future<List<PlanRunCompact>> listPlanRuns() => _api.listPlanRuns();

  Future<LoadedValue<WorkoutPrescription>> loadPrescription(
    int sessionId, {
    bool preferCache = false,
  }) async {
    final key = 'prescription:$sessionId';
    final cached = await _database.cachedDocument(key);
    WorkoutPrescription? cachedValue;
    if (cached != null) {
      try {
        cachedValue = WorkoutPrescription.fromJson(
          asJsonMap(jsonDecode(cached.json), 'cached prescription'),
        );
      } on FormatException {
        cachedValue = null;
      }
    }
    if (preferCache && cachedValue != null) {
      return LoadedValue(value: cachedValue, fromCache: true);
    }
    try {
      final value = await _api.getPrescription(sessionId);
      await _database.putCachedDocument(
        key: key,
        json: jsonEncode(value.toJson()),
      );
      return LoadedValue(value: value, fromCache: false);
    } on AgonezApiException {
      if (cachedValue != null) {
        return LoadedValue(value: cachedValue, fromCache: true, offline: true);
      }
      rethrow;
    }
  }

  Future<LoadedValue<AtlasPeek>> loadAtlasPeek(
    int exerciseId, {
    AtlasPeek? embedded,
  }) async {
    final key = 'atlas-peek:$exerciseId';
    if (embedded != null) {
      await _database.putCachedDocument(
        key: key,
        json: jsonEncode(embedded.toJson()),
      );
    }
    try {
      final value = await _api.getAtlasPeek(exerciseId);
      await _database.putCachedDocument(
        key: key,
        json: jsonEncode(value.toJson()),
      );
      return LoadedValue(value: value, fromCache: false);
    } on AgonezApiException {
      if (embedded != null) {
        return LoadedValue(value: embedded, fromCache: true, offline: true);
      }
      final cached = await _database.cachedDocument(key);
      if (cached != null) {
        return LoadedValue(
          value: AtlasPeek.fromJson(
            asJsonMap(jsonDecode(cached.json), 'cached Atlas peek'),
          ),
          fromCache: true,
          offline: true,
        );
      }
      rethrow;
    }
  }

  Future<AtlasSearchResponse> searchAtlas({String? query, int? planRunId}) =>
      _api.searchAtlas(query: query, planRunId: planRunId);

  Future<LoadedValue<ExerciseDetail>> loadAtlasArticle(
    String slug, {
    bool preferCache = false,
  }) async {
    final key = 'atlas-article:$slug';
    final cached = await _database.cachedDocument(key);
    ExerciseDetail? cachedValue;
    if (cached != null) {
      try {
        cachedValue = ExerciseDetail.fromJson(
          asJsonMap(jsonDecode(cached.json), 'cached Atlas article'),
        );
      } on FormatException {
        cachedValue = null;
      }
    }
    if (preferCache && cachedValue != null) {
      return LoadedValue(value: cachedValue, fromCache: true);
    }
    try {
      final value = await _api.getAtlasExercise(slug);
      await _database.putCachedDocument(
        key: key,
        json: jsonEncode(value.toJson()),
      );
      return LoadedValue(value: value, fromCache: false);
    } on AgonezApiException {
      if (cachedValue != null) {
        return LoadedValue(value: cachedValue, fromCache: true, offline: true);
      }
      rethrow;
    }
  }
}
