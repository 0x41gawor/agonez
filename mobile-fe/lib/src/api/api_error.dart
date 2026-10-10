import 'package:dio/dio.dart';

import 'json_support.dart';

class ApiErrorBody {
  const ApiErrorBody({
    required this.code,
    required this.message,
    required this.details,
  });

  factory ApiErrorBody.fromJson(JsonMap json) => ApiErrorBody(
    code: asString(requiredJson(json, 'code'), 'code'),
    message: asString(requiredJson(json, 'message'), 'message'),
    details: asJsonMap(requiredJson(json, 'details'), 'details'),
  );

  final String code;
  final String message;
  final JsonMap details;

  JsonMap toJson() => <String, Object?>{
    'code': code,
    'message': message,
    'details': details,
  };
}

class ApiErrorEnvelope {
  const ApiErrorEnvelope({required this.error});

  factory ApiErrorEnvelope.fromJson(JsonMap json) => ApiErrorEnvelope(
    error: ApiErrorBody.fromJson(
      asJsonMap(requiredJson(json, 'error'), 'error'),
    ),
  );

  final ApiErrorBody error;

  JsonMap toJson() => <String, Object?>{'error': error.toJson()};
}

class AgonezApiException implements Exception {
  const AgonezApiException({
    required this.statusCode,
    required this.error,
    required this.responseData,
    required this.cause,
  });

  factory AgonezApiException.fromDio(DioException exception) {
    final data = exception.response?.data;
    ApiErrorBody? body;
    try {
      if (data is Map) {
        body = ApiErrorEnvelope.fromJson(asJsonMap(data, 'response')).error;
      }
    } on FormatException {
      body = null;
    }
    return AgonezApiException(
      statusCode: exception.response?.statusCode,
      error: body,
      responseData: data,
      cause: exception,
    );
  }

  final int? statusCode;
  final ApiErrorBody? error;
  final Object? responseData;
  final DioException cause;

  bool get isTransportFailure => statusCode == null;

  @override
  String toString() {
    final code = error?.code;
    if (code != null) {
      return 'Agonez API error $statusCode ($code): ${error!.message}';
    }
    return 'Agonez API request failed${statusCode == null ? '' : ' ($statusCode)'}: '
        '${cause.message ?? cause.type.name}';
  }
}
