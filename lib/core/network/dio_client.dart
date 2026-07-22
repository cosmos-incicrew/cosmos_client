import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import 'supabase_client.dart';

/// cosmos_server(FastAPI) REST 호출용 Dio 인스턴스.
///
/// 백엔드의 모든 `/api/v1/*` 엔드포인트는 Supabase JWT를 요구한다
/// (서버 `app/core/auth.py` — Bearer 토큰의 HS256 서명·audience 검증).
/// 여기서 로그인 세션의 액세스 토큰을 Authorization 헤더에 자동으로 싣는다.
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
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Supabase 미초기화 상태에서 instance 접근은 예외 — 반드시 가드.
        if (Env.hasSupabase) {
          final token = SupabaseService.auth.currentSession?.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (e, handler) {
        // 401 = 토큰 만료/부재. supabase_flutter가 토큰을 자동 갱신하므로
        // 여기서는 그대로 올려보내고, 화면의 에러 뷰(재시도)가 처리한다.
        // TODO: 401 반복 시 로그인 화면으로 보내는 공통 처리
        handler.next(e);
      },
    ),
  );

  return dio;
});
