import 'package:dio/dio.dart';
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

/// 서버 REST 호출용 Dio. Supabase 세션 토큰을 자동으로 실어 보낸다.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    buildAuthInterceptor(
      dio: dio,
      readToken: () => SupabaseService.currentAccessToken,
      refreshSession: SupabaseService.tryRefreshSession,
      signOut: SupabaseService.signOutIfSignedIn,
    ),
  );

  return dio;
});
