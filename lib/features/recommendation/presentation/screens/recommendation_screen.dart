import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/screen_title.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/pixel_box.dart';
import '../../../product/data/models/product.dart';
import '../../data/recommendation_provider.dart';

/// 맞춤 제품 추천 — 카테고리(토너·크림·선크림…)별로 나눠 보여준다.
///
/// 계산은 [recommendationProvider] 가 한다 (내 피부유형·피부고민·기피성분 반영).
/// 이 화면은 그 결과를 그리기만 한다.
/// 서버 규칙상 근거가 부족하면 "확인 불가"를 내야 하므로,
/// 문구도 단정 대신 "추천" 수준으로 둔다.
class RecommendationScreen extends ConsumerWidget {
  const RecommendationScreen({super.key});

  /// 화면에 보일 카테고리 순서 (스킨케어 사용 순서대로).
  static const _categoryOrder = <String>[
    '토너',
    '세럼/앰플',
    '에센스',
    '로션',
    '크림',
    '선크림',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1단계(제품 풀)만 기다려 화면을 먼저 띄운다 (1~2초).
    // 2단계(매칭 정렬)는 뒤에서 오면 정렬만 갱신 — 시연 때 로딩에 안 갇힌다.
    final poolAsync = ref.watch(recommendationPoolProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: poolAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _message('추천을 불러오지 못했어요'),
          data: (pool) => _body(context, ref, pool),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, RecommendationResult pool) {
    // 매칭 hit 이 도착했으면 정렬 적용, 아직이면 씨앗 순서 그대로.
    final hitsAsync = ref.watch(recommendationHitsProvider);
    final hits = hitsAsync.valueOrNull;
    final result =
        hits == null ? pool : sortRecommendationByHits(pool, hits);
    final sorting = hitsAsync.isLoading;
    final grouped = result.byCategory;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        ScreenTitle(
          title: '맞춤 추천',
          onBack: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        const SizedBox(height: 8),
        _header(result.basis),
        if (sorting) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 8),
              Text('내 피부에 맞춰 정렬하는 중…',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
        const SizedBox(height: 20),
        if (grouped.isEmpty)
          _message('추천할 제품을 찾지 못했어요')
        else ...[
          // 정해둔 순서 먼저, 나머지 카테고리는 그 뒤에.
          for (final category in [
            ..._categoryOrder.where((c) =>
                grouped[c] != null && grouped[c]!.isNotEmpty),
            ...grouped.keys.where((c) => !_categoryOrder.contains(c)),
          ])
            _CategoryToggle(
              category: category,
              items: grouped[category]!,
              hits: hits ?? const {},
            ),
        ],
      ],
    );
  }

  Widget _message(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(text,
              textAlign: TextAlign.center,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary)),
        ),
      );

  /// 상단 안내 — 무엇을 반영해 추천했는지 근거를 밝힌다.
  ///
  /// 반영한 것만 적는다. BSTI를 안 했으면 "BSTI 반영"이라고 쓰지 않는다.
  Widget _header(RecommendationBasis basisData) {
    final basis = <String>[
      if (basisData.typeCode != null) '내 피부유형(${basisData.typeCode})',
      if (basisData.concernLabels.isNotEmpty)
        '피부고민(${basisData.concernLabels.join('·')})',
      if (basisData.avoidCount > 0) '기피성분 ${basisData.avoidCount}개',
    ];

    final text = basis.isEmpty
        ? 'BSTI 검사와 프로필을 입력하면 나에게 맞는 추천을 받을 수 있어요'
        : '${basis.join(', ')}을(를) 반영해 추천했어요';

    return PixelBox(
      borderColor: AppColors.primary,
      fillColor: AppColors.primaryLight,
      pixel: 6,
      borderWidth: 2.5,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome,
              color: AppColors.primaryDark, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.primaryDark, height: 1.5)),
          ),
        ],
      ),
    );
  }


}

/// 카테고리 토글 — 기본 접힘. 펼치면 그 카테고리의 추천 제품이 나온다.
class _CategoryToggle extends StatefulWidget {
  const _CategoryToggle({
    required this.category,
    required this.items,
    required this.hits,
  });

  final String category;
  final List<Product> items;

  /// 제품 id → 내 성분과 겹치는 수 (배지 표시용, 비어있으면 미표시).
  final Map<int, int> hits;

  @override
  State<_CategoryToggle> createState() => _CategoryToggleState();
}

class _CategoryToggleState extends State<_CategoryToggle> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PixelBox(
        borderColor: AppColors.outline,
        pixel: 5,
        borderWidth: 2,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(widget.category,
                      style: AppTextStyles.pointSm(
                          color: AppColors.textPrimary)),
                  const SizedBox(width: 8),
                  Text('${widget.items.length}개',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                  const Spacer(),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      size: 22, color: AppColors.textSecondary),
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              for (final p in widget.items) _card(context, p),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, Product p) {
    final hit = widget.hits[p.id] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => context.push('/shelf/product', extra: p),
        behavior: HitTestBehavior.opaque,
        child: PixelBox(
          borderColor: AppColors.outline,
          pixel: 4,
          borderWidth: 2,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(p.brand ?? '',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                    if (hit > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('맞춤 성분 $hit개',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.primaryDark,
                                fontSize: 11)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
