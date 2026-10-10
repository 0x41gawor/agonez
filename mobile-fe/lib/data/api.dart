import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/config.dart';
import '../domain/models.dart';

class MobileApi {
  MobileApi(
    AppConfig config, {
    required String deviceId,
    required String Function() locale,
    Dio? dio,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: config.apiBaseUrl,
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 15),
               sendTimeout: const Duration(seconds: 15),
             ),
           ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers.addAll({
            'X-Agonez-Device-Id': deviceId,
            'X-Agonez-Client': 'agonez-mobile/1.0.0 (android)',
            'Accept-Language': locale(),
          });
          handler.next(options);
        },
        onError: (error, handler) {
          debugPrint(
            '[api] ${error.requestOptions.method} ${error.requestOptions.uri} '
            '${error.response?.statusCode ?? error.type}: ${error.message}',
          );
          final body = error.response?.data;
          if (body is Map && body['error'] is Map) {
            final value = Map<String, dynamic>.from(body['error'] as Map);
            handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                error: ApiFailure(
                  value['code'] as String? ?? 'unknown',
                  details: Map<String, dynamic>.from(
                    value['details'] as Map? ?? const {},
                  ),
                ),
              ),
            );
          } else {
            handler.next(error);
          }
        },
      ),
    );
  }
  final Dio _dio;

  Future<MobileContext> context({int? planRunId}) async =>
      MobileContext.fromJson(
        Map<String, dynamic>.from(
          (await _dio.get(
                '/api/v1/mobile/context',
                queryParameters: {
                  'plan_run_id': ?planRunId,
                  'date': DateTime.now().toIso8601String().substring(0, 10),
                },
              )).data
              as Map,
        ),
      );
  Future<Prescription> prescription(int sessionId) async => Prescription(
    Map<String, dynamic>.from(
      (await _dio.get('/api/v1/mobile/sessions/$sessionId/prescription')).data
          as Map,
    ),
  );
  Future<Json> start(Json body) async => Map<String, dynamic>.from(
    (await _dio.post('/api/v1/mobile/workouts', data: body)).data as Map,
  );
  Future<Json> snapshot(String id) async => Map<String, dynamic>.from(
    (await _dio.get('/api/v1/mobile/workouts/$id')).data as Map,
  );
  Future<Json> claim(String id, Json body) async => Map<String, dynamic>.from(
    (await _dio.post('/api/v1/mobile/workouts/$id/claim', data: body)).data
        as Map,
  );
  Future<Json> ops(String id, Json body) async => Map<String, dynamic>.from(
    (await _dio.post('/api/v1/mobile/workouts/$id/ops', data: body)).data
        as Map,
  );
  Future<Json> finalize(String id, Json body) async =>
      Map<String, dynamic>.from(
        (await _dio.post(
              '/api/v1/mobile/workouts/$id/finalize',
              data: body,
            )).data
            as Map,
      );
  Future<List<Json>> searchAtlas(String q, {int? planRunId}) async =>
      ((await _dio.get(
                '/api/v1/mobile/atlas/exercises',
                queryParameters: {
                  if (q.isNotEmpty) 'q': q,
                  'plan_run_id': ?planRunId,
                },
              )).data
              as Map)['items']
          .cast<Map<String, dynamic>>();
  Future<Json> atlasPeek(int id) async => Map<String, dynamic>.from(
    (await _dio.get('/api/v1/mobile/atlas/exercises/$id/peek')).data as Map,
  );
  Future<Json> atlasArticle(String slug) async => Map<String, dynamic>.from(
    (await _dio.get('/api/atlas/exercises/$slug')).data as Map,
  );
}
