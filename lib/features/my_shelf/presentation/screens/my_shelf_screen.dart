import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/screen_title.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/pixel_box.dart';
import '../../data/shelf_preference.dart';

/// 나의 화장대 — 담은 제품·성분을 선호/기피로 나눠 보여준다.
///
/// 구성: 검색창(누르면 담기 모드 검색으로) → 내 화장품 → 내 성분.
/// 각 목록은 선호/기피 뱃지로 구분된다.
class MyShelfScreen extends ConsumerWidget {
  const MyShelfScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(shelfPreferenceProvider);
    final products = entries.where((e) => e.isProduct).toList();
    final ingredients = entries.where((e) => !e.isProduct).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenTitle(title: '나의 화장대'),
              const SizedBox(height: 12),
              _addButton(context),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _section('내 화장품', products, '아직 화장대가 비어있습니다'),
                    const SizedBox(height: 24),
                    _section('내 성분', ingredients, '아직 화장대가 비어있습니다'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 화장품 추가하기 — 누르면 제품·성분 검색 화면으로.
  Widget _addButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/shelf/add'),
      behavior: HitTestBehavior.opaque,
      child: PixelBox(
        borderColor: AppColors.primary,
        fillColor: AppColors.primaryLight,
        pixel: 6,
        borderWidth: 2.5,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: AppColors.primaryDark, size: 22),
            const SizedBox(width: 8),
            Text('화장품 추가하기',
                style: AppTextStyles.title
                    .copyWith(color: AppColors.primaryDark)),
          ],
        ),
      ),
    );
  }

  /// 한 섹션 (내 화장품 / 내 성분).
  /// 선호를 위, 기피를 아래로 모아 보여준다.
  Widget _section(String title, List<ShelfEntry> items, String emptyText) {
    final likes = items.where((e) => e.kind == PreferenceKind.like).toList();
    final dislikes =
        items.where((e) => e.kind == PreferenceKind.dislike).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppTextStyles.pointSm(color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(emptyText,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          )
        else ...[
          for (final e in likes) _entryTile(e),
          for (final e in dislikes) _entryTile(e),
        ],
      ],
    );
  }

  Widget _entryTile(ShelfEntry e) {
    final isLike = e.kind == PreferenceKind.like;
    final color = isLike ? AppColors.safe : AppColors.danger;
    // "선호 제품" / "기피 성분" 처럼 구분해서 보여준다.
    final badge = '${e.kind.label} ${e.isProduct ? '제품' : '성분'}';
    // BSTI 결과의 권장/주의성분에 쓰는 고양이 아이콘을 그대로 쓴다.
    final icon = isLike ? AppAssets.iconRecommend : AppAssets.iconAvoid;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PixelBox(
        borderColor: AppColors.outline,
        pixel: 5,
        borderWidth: 2,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // 선호=권장성분 고양이, 기피=주의성분 고양이.
            Image.asset(
              icon,
              height: 36,
              errorBuilder: (_, __, ___) => const SizedBox(width: 36),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(e.name,
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(badge,
                  style: AppTextStyles.caption.copyWith(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
