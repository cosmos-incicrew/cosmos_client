import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import 'supabase_client.dart';

/// 재시도 1회 제한 표식. 없으면 갱신→401→갱신… 으로 무한히 돈다.
const _retriedKey = 'auth_retried';

/// 토큰 부착 + 401 회복 인터셉터.
///
/// 세션 조작을 인자로 받는 이유는 [SupabaseService] 가 정적 멤버라 테스트에서
/// 갈아끼울 수 없어서다.
InterceptorsWrapper buildAuthInterceptor({
  required Dio dio,
  required String? Function() readToken,
  required Future<bool> Function() refreshSession,
  required Future<void> Function() signOut,
}) {
  // 진행 중인 갱신. 동시에 401 을 받은 요청들이 각자 갱신하면 리프레시 토큰이
  // 회전하면서 뒤늦은 쪽이 실패하고, 방금 살아난 세션이 로그아웃된다.
  // (지금은 gotrue 가 같은 토큰의 갱신을 중복 제거해 주지만, 그건 SDK 내부 구현이다)
  Future<bool>? refreshing;

  return InterceptorsWrapper(
    onRequest: (options, handler) {
      // 게스트는 세션이 없다 — 그대로 보내고 401 을 받게 둔다.
      final token = readToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (e, handler) async {
      // 게스트의 401 은 정상 경로다. 여기서 로그아웃시키면 쓰던 화면에서 튕긴다.
      final sentToken = e.requestOptions.headers.containsKey('Authorization');
      final alreadyRetried = e.requestOptions.extra[_retriedKey] == true;
      if (e.response?.statusCode != 401 || !sentToken || alreadyRetried) {
        return handler.next(e);
      }

      // 앱을 다시 켠 직후에는 저장된 토큰이 만료됐고 갱신은 아직 안 끝났다.
      // 그 사이 나간 요청의 401 을 세션 만료로 단정하면 재시작마다 로그인이 풀린다.
      final result =
          refreshing ??= refreshSession().whenComplete(() => refreshing = null);
      if (!await result) {
        await signOut();
        return handler.next(e);
      }

      // 실패한 채로 두면 앱을 켤 때마다 첫 프로필 조회가 깨져
      // 이미 온보딩을 마친 사용자가 프로필 등록 화면으로 되돌아간다.
      // (Authorization 은 재전송 때 onRequest 가 새 토큰으로 다시 채운다)
      final retry = e.requestOptions..extra[_retriedKey] = true;
      try {
        handler.resolve(await dio.fetch<dynamic>(retry));
      } on DioException catch (retryError) {
        handler.next(retryError);
      }
    },
  );
}

/// 일시적 오류 재시도 횟수 표식.
const _retryCountKey = 'transient_retry_count';

/// 일시적 오류(콜드스타트·순간 장애) 자동 재시도 인터셉터.
///
/// 배포 백엔드가 GCE 라 오래 쉬면 첫 요청에서 인스턴스가 깨어나며
/// 타임아웃·5xx 가 날 수 있다. 그때 바로 에러 화면을 띄우는 대신 짧게
/// backoff 하며 최대 [maxRetries] 회 다시 시도한다 — 사용자는 "살짝 느리게
/// 뜸"으로 느낀다. (401 은 [buildAuthInterceptor] 담당이라 여기선 제외)
InterceptorsWrapper buildRetryInterceptor({
  required Dio dio,
  int maxRetries = 2,
}) {
  bool isTransient(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        final code = e.response?.statusCode ?? 0;
        return code >= 500 && code < 600; // 502·503·504 (콜드스타트 등)
    }
  }

  return InterceptorsWrapper(
    onError: (e, handler) async {
      final count = (e.requestOptions.extra[_retryCountKey] as int?) ?? 0;
      if (!isTransient(e) || count >= maxRetries) {
        return handler.next(e);
      }
      // 0.5s → 1.0s backoff 후 재시도.
      await Future<void>.delayed(Duration(milliseconds: 500 * (count + 1)));
      final options = e.requestOptions..extra[_retryCountKey] = count + 1;
      try {
        handler.resolve(await dio.fetch<dynamic>(options));
      } on DioException catch (retryError) {
        handler.next(retryError);
      }
    },
  );
}

/// 서버 REST 호출용 Dio. Supabase 세션 토큰을 자동으로 실어 보낸다.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      // 성분요약·비교해설·성분해설은 Gemini(Vertex) 호출이라 20~30초까지 걸린다.
      // 15초로 끊으면 제품 상세의 ② 요약이 타임아웃나 정보가 안 뜬다.
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    buildAuthInterceptor(
      dio: dio,
      // 실제 로그인 세션이 우선. 없으면 개발용 토큰(DEV_JWT) —
      // OAuth 설정 없이 API 를 테스트하는 경로로, 릴리즈 빌드에선 무시된다.
      readToken: () =>
          SupabaseService.currentAccessToken ??
          (!kReleaseMode && Env.devJwt.isNotEmpty ? Env.devJwt : null),
      refreshSession: SupabaseService.tryRefreshSession,
      signOut: SupabaseService.signOutIfSignedIn,
    ),
  );

  // 401 회복(위) 다음에 일시적 오류 재시도를 건다 — 둘은 서로 다른 오류를
  // 다뤄 겹치지 않는다(401 vs 타임아웃·5xx).
  dio.interceptors.add(buildRetryInterceptor(dio: dio));

  return dio;
});
