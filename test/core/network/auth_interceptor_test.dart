// 401 회복 인터셉터 검증.
//
// 어긋나면 앱을 켤 때마다 로그인이 풀리고, 온보딩을 마친 사용자가 프로필 등록
// 화면으로 되돌아간다 — 실제로 그렇게 샜던 자리다.
// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'dart:typed_data';

import 'package:cosmos_app/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// 요청마다 정해진 상태코드를 돌려주는 대역. 보낸 토큰을 기록한다.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.statuses);

  /// 순서대로 소비된다. 다 쓰면 마지막 값을 계속 쓴다.
  final List<int> statuses;
  final List<String?> sentTokens = [];
  int _call = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    sentTokens.add(options.headers['Authorization'] as String?);
    final status = statuses[_call.clamp(0, statuses.length - 1)];
    _call++;
    return ResponseBody.fromString(
      jsonEncode({'ok': true}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// 인터셉터를 붙인 Dio 와 호출 기록을 함께 만든다.
({Dio dio, _StubAdapter adapter, List<String> calls}) _make({
  required List<int> statuses,
  required bool refreshSucceeds,
  String? token = 'old-token',
}) {
  final adapter = _StubAdapter(statuses);
  final calls = <String>[];
  var current = token;
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
    ..httpClientAdapter = adapter;
  dio.interceptors.add(buildAuthInterceptor(
    dio: dio,
    readToken: () => current,
    refreshSession: () async {
      calls.add('refresh');
      // 실제 갱신은 네트워크 왕복이다. 즉시 완료하면 동시 요청이 겹치는 구간이
      // 생기지 않아 중복 갱신 검증이 무의미해진다.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      if (refreshSucceeds) current = 'new-token';
      return refreshSucceeds;
    },
    signOut: () async => calls.add('signOut'),
  ));
  return (dio: dio, adapter: adapter, calls: calls);
}

void main() {
  test('401 을 받아도 갱신에 성공하면 로그아웃하지 않고 다시 보낸다', () async {
    // 앱 재시작 직후: 저장된 토큰이 만료됐지만 갱신하면 살아나는 상태.
    final h = _make(statuses: [401, 200], refreshSucceeds: true);

    final response = await h.dio.get<dynamic>('/api/v1/users/me/profile');

    expect(response.statusCode, 200);
    expect(h.calls, ['refresh']); // signOut 이 있으면 안 된다
    expect(h.adapter.sentTokens, ['Bearer old-token', 'Bearer new-token']);
  });

  test('갱신까지 실패하면 로그아웃한다', () async {
    final h = _make(statuses: [401], refreshSucceeds: false);

    await expectLater(
      h.dio.get<dynamic>('/api/v1/users/me/profile'),
      throwsA(isA<DioException>()),
    );
    expect(h.calls, ['refresh', 'signOut']);
  });

  test('갱신 후에도 401 이면 한 번만 재시도하고 멈춘다', () async {
    // 무한 루프 방지. 없으면 갱신→401→갱신… 으로 계속 돈다.
    final h = _make(statuses: [401, 401], refreshSucceeds: true);

    await expectLater(
      h.dio.get<dynamic>('/api/v1/users/me/profile'),
      throwsA(isA<DioException>()),
    );
    expect(h.calls, ['refresh']);
    expect(h.adapter.sentTokens, hasLength(2));
  });

  test('게스트(토큰 없음)의 401 은 건드리지 않는다', () async {
    // 게스트는 토큰이 없어 401 이 정상 경로다. 여기서 로그아웃시키면
    // 게스트 상태가 지워져 쓰던 화면에서 튕긴다.
    final h = _make(statuses: [401], refreshSucceeds: true, token: null);

    await expectLater(
      h.dio.get<dynamic>('/api/v1/users/me/profile'),
      throwsA(isA<DioException>()),
    );
    expect(h.calls, isEmpty);
  });

  test('401 이 아닌 실패는 세션을 건드리지 않는다', () async {
    final h = _make(statuses: [500], refreshSucceeds: true);

    await expectLater(
      h.dio.get<dynamic>('/api/v1/users/me/profile'),
      throwsA(isA<DioException>()),
    );
    expect(h.calls, isEmpty);
  });

  test('동시에 401 을 받아도 갱신은 한 번만 돈다', () async {
    // 각자 갱신하면 리프레시 토큰이 회전하면서 뒤늦은 쪽이 실패하고,
    // 방금 살아난 세션이 로그아웃된다.
    final h = _make(statuses: [401, 401, 401, 200, 200, 200],
        refreshSucceeds: true);

    await Future.wait([
      h.dio.get<dynamic>('/a'),
      h.dio.get<dynamic>('/b'),
      h.dio.get<dynamic>('/c'),
    ]);

    expect(h.calls, ['refresh']);
  });
}
