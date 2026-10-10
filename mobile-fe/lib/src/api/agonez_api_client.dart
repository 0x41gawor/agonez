import 'package:dio/dio.dart';

import 'agonez_headers_interceptor.dart';
import 'api_error.dart';
import 'atlas_models.dart';
import 'conditional_response.dart';
import 'context_models.dart';
import 'json_support.dart';
import 'operation_models.dart';
import 'prescription_models.dart';
import 'workout_models.dart';

class AgonezApiClient {
  AgonezApiClient({
    required Dio dio,
    required Uri baseUrl,
    required ApiHeaderValueProvider deviceId,
    required ApiHeaderValueProvider clientInfo,
    required ApiHeaderValueProvider locale,
  }) : _dio = dio {
    if (!baseUrl.hasScheme || baseUrl.host.isEmpty) {
      throw ArgumentError.value(
        baseUrl,
        'baseUrl',
        'must be an absolute HTTP(S) URL',
      );
    }
    _dio.options.baseUrl = baseUrl.toString().replaceFirst(RegExp(r'/+$'), '');
    final previousValidateStatus = _dio.options.validateStatus;
    _dio.options.validateStatus = (status) {
      if (status == 304) {
        return true;
      }
      return previousValidateStatus(status);
    };
    _dio.interceptors.add(
      AgonezHeadersInterceptor(
        deviceId: deviceId,
        clientInfo: clientInfo,
        locale: locale,
      ),
    );
  }

  final Dio _dio;

  Future<ConditionalResponse<MobileContext>> getContext({
    int? planRunId,
    String? date,
    String? etag,
  }) async {
    final query = <String, Object?>{};
    putIfNotNull(query, 'plan_run_id', planRunId);
    putIfNotNull(query, 'date', date);
    final response = await _perform(
      () => _dio.get<Object?>(
        '/api/v1/mobile/context',
        queryParameters: query,
        options: _conditionalOptions(etag),
      ),
    );
    return _conditional(response, (json) => MobileContext.fromJson(json));
  }

  Future<List<PlanRunCompact>> listPlanRuns({String? date}) async {
    final query = <String, Object?>{};
    putIfNotNull(query, 'date', date);
    final response = await _perform(
      () =>
          _dio.get<Object?>('/api/v1/mobile/plan-runs', queryParameters: query),
    );
    return decodeList(
      response.data,
      (value) => PlanRunCompact.fromJson(asJsonMap(value, 'plan-runs[]')),
      'plan-runs',
    );
  }

  Future<WorkoutPrescription> getPrescription(int sessionId) async {
    final response = await _perform(
      () =>
          _dio.get<Object?>('/api/v1/mobile/sessions/$sessionId/prescription'),
    );
    return WorkoutPrescription.fromJson(
      asJsonMap(response.data, 'prescription'),
    );
  }

  Future<WorkoutSnapshot> startWorkout(StartWorkout payload) async {
    final response = await _perform(
      () =>
          _dio.post<Object?>('/api/v1/mobile/workouts', data: payload.toJson()),
    );
    return WorkoutSnapshot.fromJson(asJsonMap(response.data, 'workout'));
  }

  Future<ActiveWorkoutSummary> getActiveWorkout(int planRunId) async {
    final response = await _perform(
      () => _dio.get<Object?>(
        '/api/v1/mobile/workouts/active',
        queryParameters: <String, Object?>{'plan_run_id': planRunId},
      ),
    );
    return ActiveWorkoutSummary.fromJson(
      asJsonMap(response.data, 'active workout'),
    );
  }

  Future<ConditionalResponse<WorkoutSnapshot>> getWorkout(
    String workoutId, {
    String? etag,
  }) async {
    final response = await _perform(
      () => _dio.get<Object?>(
        '/api/v1/mobile/workouts/${Uri.encodeComponent(workoutId)}',
        options: _conditionalOptions(etag),
      ),
    );
    return _conditional(response, (json) => WorkoutSnapshot.fromJson(json));
  }

  Future<WorkoutSnapshot> claimWorkout(
    String workoutId,
    ClaimWorkout payload,
  ) async {
    final response = await _perform(
      () => _dio.post<Object?>(
        '/api/v1/mobile/workouts/${Uri.encodeComponent(workoutId)}/claim',
        data: payload.toJson(),
      ),
    );
    return WorkoutSnapshot.fromJson(asJsonMap(response.data, 'workout'));
  }

  Future<OperationBatchResponse> applyOperations(
    String workoutId,
    OperationBatch payload,
  ) async {
    final response = await _perform(
      () => _dio.post<Object?>(
        '/api/v1/mobile/workouts/${Uri.encodeComponent(workoutId)}/ops',
        data: payload.toJson(),
      ),
    );
    return OperationBatchResponse.fromJson(
      asJsonMap(response.data, 'operation batch response'),
    );
  }

  Future<FinalizeResponse> finalizeWorkout(
    String workoutId,
    FinalizeWorkout payload,
  ) async {
    final response = await _perform(
      () => _dio.post<Object?>(
        '/api/v1/mobile/workouts/${Uri.encodeComponent(workoutId)}/finalize',
        data: payload.toJson(),
      ),
    );
    return FinalizeResponse.fromJson(
      asJsonMap(response.data, 'finalize response'),
    );
  }

  Future<AtlasPeek> getAtlasPeek(int exerciseId) async {
    final response = await _perform(
      () =>
          _dio.get<Object?>('/api/v1/mobile/atlas/exercises/$exerciseId/peek'),
    );
    return AtlasPeek.fromJson(asJsonMap(response.data, 'Atlas peek'));
  }

  Future<AtlasSearchResponse> searchAtlas({
    String? query,
    int limit = 30,
    int? planRunId,
  }) async {
    final parameters = <String, Object?>{'limit': limit};
    putIfNotNull(parameters, 'q', query);
    putIfNotNull(parameters, 'plan_run_id', planRunId);
    final response = await _perform(
      () => _dio.get<Object?>(
        '/api/v1/mobile/atlas/exercises',
        queryParameters: parameters,
      ),
    );
    return AtlasSearchResponse.fromJson(
      asJsonMap(response.data, 'Atlas search'),
    );
  }

  Future<ExerciseDetail> getAtlasExercise(String slug) async {
    final response = await _perform(
      () => _dio.get<Object?>(
        '/api/atlas/exercises/${Uri.encodeComponent(slug)}',
      ),
    );
    return ExerciseDetail.fromJson(asJsonMap(response.data, 'Atlas exercise'));
  }

  Options _conditionalOptions(String? etag) => Options(
    headers: etag == null ? null : <String, Object?>{'If-None-Match': etag},
  );

  ConditionalResponse<T> _conditional<T>(
    Response<Object?> response,
    T Function(JsonMap json) decode,
  ) {
    final responseEtag = response.headers.value('etag');
    if (response.statusCode == 304) {
      return NotModifiedResponse<T>(etag: responseEtag);
    }
    return ModifiedResponse<T>(
      value: decode(asJsonMap(response.data, 'response')),
      etag: responseEtag,
    );
  }

  Future<Response<Object?>> _perform(
    Future<Response<Object?>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw AgonezApiException.fromDio(error);
    }
  }
}
