import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/policy/display_policy.dart';
import '../../../../core/widgets/dots_loading.dart';
import '../../../../core/widgets/pixel_box.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../bsti/bsti.dart';
import '../../../ingredient/data/models/ingredient.dart';
import '../../../product/data/models/product.dart';
import '../../../ingredient/data/ingredient_providers.dart';
import '../../../ingredient/data/models/ingredient_insight.dart';
import '../../data/ingredient_products_provider.dart';
import '../../../../core/widgets/screen_title.dart';

/// 성분 상세 화면 (검색 결과에서 성분 진입).
///
/// 시안 구성: 검색 성분(칩) → 역할·특징 요약(박스) → 권장 피부타입(코드+페르소나) →
/// 성분 포함 제품. 포함 제품은 저장소에서 역조회한다.
class IngredientDetailScreen extends ConsumerWidget {
  const IngredientDetailScreen({super.key, required this.ingredient});

  final Ingredient ingredient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 이 성분을 포함하는 제품 (이 목록만 비동기 — 나머지는 바로 그린다).
    // 역조회 API 부재 — 추천 풀 + 내 화장대에서 프론트 도출 (기존 API 조합).
    final productsAsync = ref.watch(ingredientProductsProvider(
        (id: ingredient.id, nameKo: ingredient.nameKor)));
    // 이 성분을 권장 성분으로 가진 BSTI 유형을 실제 데이터로 매칭.
    final type = ingredient.bstiIngredientId == null
        ? null
        : BstiEngine.matchTypeByIngredients([ingredient.bstiIngredientId!]);

    return Scaffold(
      backgroundColor: AppColors.background,

      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          ScreenTitle(
            title: '성분 상세',
            onBack: () =>
                context.canPop() ? context.pop() : context.go('/shelf'),
          ),
          const SizedBox(height: 8),
          // 검색 성분 — 박스 없이 큰 글씨로.
          Text('검색 성분',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          // 긴 성분명(영문 병기)이 화면을 넘지 않게 줄바꿈 허용.
          Text(
            ingredient.nameKor != null
                ? (ingredient.nameEng.isEmpty
                    ? ingredient.nameKor!
                    : '${ingredient.nameKor} (${ingredient.nameEng})')
                : ingredient.nameEng,
            style: AppTextStyles.title.copyWith(fontSize: 22, height: 1.3),
          ),
          const SizedBox(height: 16),

          // 역할·특징 요약(박스) — 데이터가 있을 때만.
          // 없으면 "준비 중" 대신 아무것도 안 띄운다: 바로 아래 성분 해설
          // (성분 역할·주의사항)이 실제 성분 정보이기 때문이다.
          if (ingredient.efficacy != null) ...[
            PixelBox(
              borderColor: AppColors.primary,
              fillColor: AppColors.primaryLight.withValues(alpha: 0.35),
              pixel: 6,
              borderWidth: 2.5,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Text(
                ingredient.efficacy!,
                style: AppTextStyles.body.copyWith(height: 1.5),
              ),
            ),
            const SizedBox(height: 28),
          ],

          // 성분 해설 (① GET /ingredients/{id}/detail).
          const SectionLabel('성분 해설'),
          const SizedBox(height: 4),
          _detailSection(ref),
          const SizedBox(height: 28),

          // 권장 피부타입 (코드 + 페르소나).
          const SectionLabel('권장 피부타입'),
          const SizedBox(height: 4),
          if (type != null) ...[
            Text(type.code,
                style: AppTextStyles.pointLg(color: AppColors.primary)),
            const SizedBox(height: 2),
            Text(type.personaName,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ] else
            Text(ingredient.recommendedSkinType ?? '모든 피부',
                style: AppTextStyles.title),
          const SizedBox(height: 28),

          // 성분 포함 제품.
          const SectionLabel('성분 포함 제품'),
          const SizedBox(height: 6),
          // 로딩·실패·없음을 구분해서 보여준다.
          ...productsAsync.when(
            loading: () => [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: DotsLoading(dense: true),
              ),
            ],
            error: (_, __) => [
              Text('제품 정보를 불러오지 못했어요',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
            ],
            data: (products) => products.isEmpty
                ? [
                    Text('이 성분이 든 제품을 아직 찾지 못했어요.',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ]
                : [
                    for (final p in products) _productCard(context, p),
                  ],
          ),
        ],
      ),
    );
  }

  Widget _productCard(BuildContext context, Product p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => context.push('/shelf/product', extra: p),
        behavior: HitTestBehavior.opaque,
        child: PixelBox(
          borderColor: AppColors.outline,
          pixel: 5,
          borderWidth: 2,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // 제품 이미지 (없으면 플레이스홀더).
              Container(
                width: 44,
                height: 44,
                color: AppColors.primaryLight.withValues(alpha: 0.35),
                alignment: Alignment.center,
                clipBehavior: Clip.antiAlias,
                child: p.imageAsset != null
                    ? Image.asset(p.imageAsset!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_outlined,
                            size: 22,
                            color: AppColors.outline))
                    : const Icon(Icons.image_outlined,
                        size: 22, color: AppColors.outline),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${p.brand ?? ''} · ${p.subCategory ?? ''}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  /// ① 해설 — 확인불가/safety 3형태를 명세 규칙대로 그린다.
  Widget _detailSection(WidgetRef ref) {
    final async = ref.watch(ingredientDetailProvider(ingredient.id));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: DotsLoading(dense: true),
      ),
      error: (_, __) => Text('해설을 불러오지 못했어요. 잠시 후 다시 시도해주세요.',
          style:
              AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      data: (detail) {
        if (detail.status == InsightStatus.unavailable) {
          return Text('아직 정보가 없습니다',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary));
        }
        // 본문(출처줄 제거)을 「성분 역할」/「주의사항」 구획으로 나눈다.
        final body = detail.body == null
            ? null
            : InsightSectionPolicy.splitRoleCaution(
                SourceDisplayPolicy.stripSourceLines(detail.body!));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (body != null && body.role.isNotEmpty) ...[
              const SectionLabel('성분 역할', dense: true),
              Text(body.role,
                  style: AppTextStyles.body.copyWith(height: 1.6)),
            ],
            if (body?.caution != null || detail.safety != null) ...[
              const SizedBox(height: 12),
              const SectionLabel('주의사항',
                  color: AppColors.danger, dense: true),
              if (body?.caution != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(body!.caution!,
                      style: AppTextStyles.body.copyWith(height: 1.6)),
                ),
              if (detail.safety != null &&
                  detail.safetyKind == SafetyKind.official)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 16, color: AppColors.danger),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(detail.safety!,
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.danger, height: 1.5)),
                    ),
                  ],
                )
              else if (detail.safety != null &&
                  detail.safetyKind == SafetyKind.general)
                Text(detail.safety!,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textPrimary, height: 1.5)),
            ],
            // 출처 — 표시 정책상 숨김 (source_verified 검증 규칙은 유지).
            if (SourceDisplayPolicy.showSources &&
                detail.sourceVerified &&
                detail.referenceSource != null) ...[
              const SizedBox(height: 8),
              Text('출처: ${detail.referenceSource}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ],
        );
      },
    );
  }
}
