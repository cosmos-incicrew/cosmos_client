import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/pixel_box.dart';
import '../../../../core/widgets/screen_title.dart';
import '../../data/recommendation.dart';
import '../../data/recommendation_repository.dart';

/// 보고서 2페이지 — ③ 사용법·관리법.
///
/// 맞춤 추천 API 의 `answer.usage_guide` 를 보여준다. 1페이지와 같은
/// [recommendationProvider] 를 watch 하므로 서버 호출은 1회다 (캐시 공유).
class ReportCareScreen extends ConsumerWidget {
  const ReportCareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recoAsync = ref.watch(recommendationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            ScreenTitle(
              title: '사용법·관리법',
              onBack: () =>
                  context.canPop() ? context.pop() : context.go('/report'),
            ),
            const SizedBox(height: 8),
            recoAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => _notice('관리법을 불러오지 못했어요.\n잠시 후 다시 시도해주세요.'),
              data: (reco) => _body(reco),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(RecommendationResult reco) {
    final guide = reco.answer?.usageGuide;
    if (reco.status != RecoStatus.ok || guide == null) {
      // 구버전 서버(서사 없음)·근거 부족·프로필 미입력 — 안내만.
      return _notice(reco.advisory?.message ??
          '맞춤 사용법이 아직 준비되지 않았어요.\n보고서에서 추천 성분을 먼저 확인해보세요.');
    }

    final profile = reco.profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 어떤 프로필 기준 관리법인지.
        if (profile != null)
          Text(
              [
                if (profile.age != null) '${profile.age}세',
                if (profile.gender != null)
                  profile.gender == 'female' ? '여성' : '남성',
                if (profile.bstiType != null) profile.bstiType!,
              ].join(' · '),
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 14),
        PixelBox(
          borderColor: AppColors.primary,
          fillColor: AppColors.primaryLight.withValues(alpha: 0.35),
          pixel: 6,
          borderWidth: 2.5,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(guide, style: AppTextStyles.body.copyWith(height: 1.7)),
        ),
        if (reco.disclaimer != null) ...[
          const SizedBox(height: 16),
          // 전문의 상담 권고 등 고정 고지 — 안전 문구라 눈에 띄게.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(reco.disclaimer!,
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary, height: 1.5)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _notice(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(text,
              textAlign: TextAlign.center,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary, height: 1.6)),
        ),
      );
}
