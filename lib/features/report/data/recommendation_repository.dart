import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/network/dio_client.dart';
import '../demo/demo_recommendation.dart';
import 'recommendation.dart';

/// 맞춤 추천 (RAG) — cosmos_server `/api/v1/recommendations` 연동.
class RecommendationRepository {
  RecommendationRepository(this._dio);

  final Dio _dio;

  /// POST /api/v1/recommendations — **요청 바디 없음** (서버가 JWT 로 프로필 조회).
  ///
  /// - 200 + status ok / insufficient_evidence → 정형 응답 (에러 아님)
  /// - 409 PROFILE_ONBOARDING_REQUIRED → [RecoStatus.profileRequired] 로 변환
  ///   (화면이 프로필 입력 CTA 를 띄운다 — 예외로 흘리지 않는다)
  /// - 502/503 등은 예외로 흘려 화면이 "다시 시도"를 띄운다.
  Future<RecommendationResult> fetch() async {
    if (!Env.hasApi) {
      throw StateError('API_BASE_URL 미설정 — 맞춤 추천은 서버가 필요합니다');
    }
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/v1/recommendations',
        // RAG 검색 + LLM 서사 3섹션 생성 — 가장 무거운 엔드포인트다.
        options: Options(receiveTimeout: const Duration(seconds: 90)),
      );
      final result = RecommendationResult.fromJson(res.data ?? const {});

      // 확장 응답(answer·cases)이 서버에 아직 없다 — 그 두 조각만 데모로
      // 채운다 (성분 추천·프로필·경고는 실제 응답 그대로). 서버가 answer 를
      // 내려주기 시작하면 이 분기는 자동으로 타지 않는다 → demo/ 폴더 삭제.
      if (result.status == RecoStatus.ok && result.answer == null) {
        return RecommendationResult(
          status: result.status,
          answer: kDemoRecoAnswer,
          cases: result.cases.isEmpty ? kDemoRecoCases : result.cases,
          ingredients: result.ingredients,
          advisory: result.advisory,
          profile: result.profile,
          disclaimer: result.disclaimer,
        );
      }
      return result;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final message =
            ((e.response?.data as Map<String, dynamic>?)?['error']
                    as Map<String, dynamic>?)?['message'] as String? ??
                '추천을 받으려면 먼저 나이와 피부 고민을 입력해 주세요.';
        return RecommendationResult.profileRequired(message);
      }
      rethrow;
    }
  }
}

/// 추천 저장소. 테스트에서는 이 프로바이더를 override 한다.
final recommendationRepositoryProvider =
    Provider<RecommendationRepository>((ref) {
  return RecommendationRepository(ref.watch(dioProvider));
});

/// 맞춤 추천 결과 — 보고서(피부고민 분석)와 관리법 페이지가 공유한다.
/// 캐시되므로 두 화면이 각각 watch 해도 호출은 1회다.
final recommendationProvider =
    FutureProvider<RecommendationResult>((ref) async {
  return ref.watch(recommendationRepositoryProvider).fetch();
});
