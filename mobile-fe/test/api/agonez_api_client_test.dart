import 'dart:convert';
import 'dart:typed_data';

import 'package:agonez/src/api/api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const deviceId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

  test('central interceptor attaches identity, client, and locale', () async {
    final adapter = _RecordingAdapter(<_StubResponse>[
      const _StubResponse(body: <Object?>[]),
    ]);
    final dio = Dio()..httpClientAdapter = adapter;
    final client = AgonezApiClient(
      dio: dio,
      baseUrl: Uri.parse('http://api.test:33287'),
      deviceId: () => deviceId,
      clientInfo: () => 'agonez-mobile/1.0.0 (android)',
      locale: () => 'pl',
    );

    await client.listPlanRuns(date: '2026-10-10');

    final request = adapter.requests.single;
    expect(request.headers['X-Agonez-Device-Id'], deviceId);
    expect(request.headers['X-Agonez-Client'], 'agonez-mobile/1.0.0 (android)');
    expect(request.headers['Accept-Language'], 'pl');
    expect(request.queryParameters['date'], '2026-10-10');
  });

  test(
    'conditional reads return typed modified and bodyless 304 results',
    () async {
      final adapter = _RecordingAdapter(<_StubResponse>[
        const _StubResponse(
          body: <String, Object?>{
            'generated_at': '2026-10-10T15:00:00Z',
            'context_version': 'ctx-1',
            'plan_run': null,
            'selection_required': false,
            'today': null,
            'microcycle_days': <Object?>[],
            'expected_session': null,
            'alternatives': <Object?>[],
            'fallbacks': <Object?>[],
            'active_workout': null,
            'recent': <Object?>[],
          },
          headers: <String, List<String>>{
            'etag': <String>['"new-etag"'],
          },
        ),
        const _StubResponse(
          statusCode: 304,
          body: null,
          headers: <String, List<String>>{
            'etag': <String>['"new-etag"'],
          },
        ),
      ]);
      final dio = Dio()..httpClientAdapter = adapter;
      final client = AgonezApiClient(
        dio: dio,
        baseUrl: Uri.parse('http://api.test:33287/'),
        deviceId: () => deviceId,
        clientInfo: () => 'agonez-mobile/test (android)',
        locale: () => 'en',
      );

      final modified = await client.getContext(etag: '"old-etag"');
      final unchanged = await client.getContext(etag: '"new-etag"');

      expect(modified, isA<ModifiedResponse<MobileContext>>());
      expect(modified.etag, '"new-etag"');
      expect(
        (modified as ModifiedResponse<MobileContext>).value.contextVersion,
        'ctx-1',
      );
      expect(unchanged, isA<NotModifiedResponse<MobileContext>>());
      expect(unchanged.etag, '"new-etag"');
      expect(adapter.requests[0].headers['If-None-Match'], '"old-etag"');
      expect(adapter.requests[1].headers['If-None-Match'], '"new-etag"');
    },
  );

  test('error envelope becomes a typed API exception', () async {
    final adapter = _RecordingAdapter(<_StubResponse>[
      const _StubResponse(
        statusCode: 409,
        body: <String, Object?>{
          'error': <String, Object?>{
            'code': 'active_workout_exists',
            'message': 'A workout is already active',
            'details': <String, Object?>{
              'workout_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
            },
          },
        },
      ),
    ]);
    final dio = Dio()..httpClientAdapter = adapter;
    final client = AgonezApiClient(
      dio: dio,
      baseUrl: Uri.parse('http://api.test:33287'),
      deviceId: () => deviceId,
      clientInfo: () => 'agonez-mobile/test (android)',
      locale: () => 'en',
    );

    await expectLater(
      client.getActiveWorkout(3),
      throwsA(
        isA<AgonezApiException>()
            .having((error) => error.statusCode, 'status', 409)
            .having(
              (error) => error.error?.code,
              'code',
              'active_workout_exists',
            ),
      ),
    );
  });
}

class _StubResponse {
  const _StubResponse({
    this.statusCode = 200,
    required this.body,
    this.headers = const <String, List<String>>{},
  });

  final int statusCode;
  final Object? body;
  final Map<String, List<String>> headers;
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.responses);

  final List<_StubResponse> responses;
  final List<RequestOptions> requests = <RequestOptions>[];
  var _index = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = responses[_index++];
    final headers = <String, List<String>>{
      'content-type': <String>['application/json'],
      ...response.headers,
    };
    return ResponseBody.fromString(
      response.body == null ? '' : jsonEncode(response.body),
      response.statusCode,
      headers: headers,
    );
  }

  @override
  void close({bool force = false}) {}
}
