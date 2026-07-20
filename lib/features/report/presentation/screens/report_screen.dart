import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/pixel_box.dart';
import '../../../bsti/bsti.dart';
import '../../../my_shelf/presentation/screens/product_detail_screen.dart';
import '../../data/report_engine.dart';
import '../../data/report_provider.dart';

/// 내 화장대 종합보고서.
///
/// 구성: 내 BSTI 유형(고양이) → 화장대 총점 → 총평
///      → 지금 쓰는 화장품 각각의 매칭 점수.
///
/// 점수는 [ReportEngine]이 실제 BSTI 권장/주의 성분과 대조해 계산한다.
/// 근거가 없으면 점수를 지어내지 않고 "판단 정보 부족"으로 표시한다.
class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(shelfReportProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('내 화장대 보고서', style: AppTextStyles.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: AppColors.textPrimary),
            iconSize: 28,
            onPressed: () => context.go('/home'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: reportAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('보고서를 불러오지 못했어요',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary)),
            ),
          ),
          data: (report) => _body(context, ref, report),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, ShelfReport report) {
    final type =
        report.typeCode == null ? null : kBstiSkinTypes[report.typeCode];
    // 추천은 보고서보다 늦게 와도 되므로, 없으면 그 구역만 비운다.
    final suggestions =
        ref.watch(shelfSuggestionsProvider).valueOrNull ?? const [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        _typeCard(type),
        const SizedBox(height: 20),
        _scoreCard(report),
        const SizedBox(height: 28),
        Text('지금 쓰는 화장품',
            style: AppTextStyles.pointSm(color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        if (report.isEmpty)
          _emptyBox('화장대에 담은 제품이 없어요', '제품·성분을 검색해 담아보세요',
              onTap: () => context.push('/shelf/add'))
        else
          for (final m in report.matches) _matchTile(m),
        // 부족한 성분 → 채워줄 제품 추천.
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 32),
          Text('이런 성분이 부족해요',
              style: AppTextStyles.pointSm(color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          for (final s in suggestions) _suggestionCard(context, s),
        ],
      ],
    );
  }

  /// "OO 성분이 부족합니다 — 이 제품을 추천해요" 카드 하나.
  Widget _suggestionCard(BuildContext context, ShelfSuggestion s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: PixelBox(
        borderColor: AppColors.accent,
        pixel: 5,
        borderWidth: 2,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${s.ingredientName} 성분이 부족합니다',
                style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
            if (s.ingredientRole != null) ...[
              const SizedBox(height: 4),
              Text(s.ingredientRole!,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 12),
            Text('이 제품을 추천해요',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            for (final p in s.products)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: p),
                    ));
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle_outline,
                          size: 16, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('${p.name} (${p.brand ?? ''})',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textPrimary)),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 내 BSTI 유형 — 고양이 + 코드 + 페르소나.
  Widget _typeCard(BstiSkinType? type) {
    if (type == null) {
      return _emptyBox('아직 BSTI 검사 전이에요', '검사하면 제품 적합도를 알려드려요');
    }
    return PixelBox(
      borderColor: AppColors.primary,
      pixel: 6,
      borderWidth: 2.5,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Image.asset(
            type.catImageAsset,
            width: 84,
            height: 84,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox(width: 84, height: 84),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('내 피부타입',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(type.code,
                    style: AppTextStyles.pointBoldEn(
                        size: 28, color: AppColors.primaryDark)),
                const SizedBox(height: 4),
                Text(type.personaName,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 화장대 총점 + 총평.
  Widget _scoreCard(ShelfReport report) {
    final total = report.totalScore;
    final color = total == null
        ? AppColors.textSecondary
        : (total >= 80
            ? AppColors.safe
            : total >= 50
                ? AppColors.accent
                : AppColors.danger);

    return PixelBox(
      borderColor: AppColors.textPrimary,
      pixel: 6,
      borderWidth: 2.5,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          Text('내 화장대 점수',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          // 점수 — 근거가 없으면 숫자를 만들지 않는다.
          Text(
            total == null ? '–' : '$total',
            style: AppTextStyles.pointBoldEn(size: 52, color: color),
          ),
          const SizedBox(height: 8),
          Text(report.summary,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(height: 1.5)),
          // 총평 밑 구체 설명 — "잘 맞아요" 한 줄로 끝내지 않는다.
          if (report.details.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: AppColors.outline, height: 1),
            const SizedBox(height: 14),
            for (final line in report.details)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('· ',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                    Expanded(
                      child: Text(line,
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.textPrimary, height: 1.5)),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// 제품 하나의 매칭 결과.
  Widget _matchTile(ProductMatch m) {
    final score = m.score;
    final color = score == null
        ? AppColors.textSecondary
        : (score >= 80
            ? AppColors.safe
            : score >= 50
                ? AppColors.accent
                : AppColors.danger);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PixelBox(
        borderColor: AppColors.outline,
        pixel: 5,
        borderWidth: 2,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  // 점수 근거 — 왜 이 점수인지 보여준다.
                  Row(
                    children: [
                      _hit(AppAssets.iconRecommend, '권장 ${m.recommendHits}'),
                      const SizedBox(width: 10),
                      _hit(AppAssets.iconAvoid, '주의 ${m.avoidHits}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(score == null ? '–' : '$score',
                    style: AppTextStyles.pointBoldEn(size: 24, color: color)),
                Text(m.verdict,
                    style: AppTextStyles.caption.copyWith(color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _hit(String asset, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(asset,
            height: 20, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _emptyBox(String title, String desc, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: PixelBox(
        borderColor: AppColors.outline,
        pixel: 5,
        borderWidth: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            Text(title,
                style:
                    AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(desc,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
