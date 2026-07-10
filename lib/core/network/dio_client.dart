import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';

/// BE 팀이 담당하는 검색 API 등 커스텀 REST 호출용 Dio 인스턴스.
///
/// Supabase 세션 토큰을 자동으로 Authorization 헤더에 실어 보냅니다.
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
        // TODO: Supabase 세션 토큰 주입
        // final token = SupabaseService.auth.currentSession?.accessToken;
        // if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (e, handler) {
        // TODO: 공통 에러 처리 (401 → 로그인, 재시도 등)
        handler.next(e);
      },
    ),
  );

  return dio;
});
