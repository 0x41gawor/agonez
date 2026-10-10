import 'dart:async';

import 'package:dio/dio.dart';

typedef ApiHeaderValueProvider = FutureOr<String> Function();

class AgonezHeadersInterceptor extends Interceptor {
  AgonezHeadersInterceptor({
    required this.deviceId,
    required this.clientInfo,
    required this.locale,
  });

  final ApiHeaderValueProvider deviceId;
  final ApiHeaderValueProvider clientInfo;
  final ApiHeaderValueProvider locale;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final resolvedDeviceId = (await deviceId()).trim();
      final resolvedClient = (await clientInfo()).trim();
      final resolvedLocale = (await locale()).trim();
      if (resolvedDeviceId.isEmpty) {
        throw StateError('X-Agonez-Device-Id cannot be empty');
      }
      if (resolvedClient.isEmpty) {
        throw StateError('X-Agonez-Client cannot be empty');
      }
      if (resolvedLocale.isEmpty) {
        throw StateError('Accept-Language cannot be empty');
      }
      options.headers['X-Agonez-Device-Id'] = resolvedDeviceId;
      options.headers['X-Agonez-Client'] = resolvedClient;
      options.headers['Accept-Language'] = resolvedLocale;
      handler.next(options);
    } on Object catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
          type: DioExceptionType.unknown,
          message: 'Could not resolve Agonez request headers',
        ),
      );
    }
  }
}
