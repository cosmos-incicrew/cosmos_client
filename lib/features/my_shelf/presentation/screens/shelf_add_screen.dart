import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/widgets/pixel_box.dart';
import '../../../ingredient/data/models/ingredient.dart';
import '../../../product/data/models/product.dart';
import '../../data/shelf_preference.dart';
import '../widgets/preference_dialog.dart';
import 'ingredient_detail_screen.dart';
import 'product_detail_screen.dart';

/// 제품·성분 검색 화면.
///
/// 입력하면 목데이터(mockProducts / mockIngredients)에서 실시간 필터.
/// 결과를 누르면 선호/기피 선택 팝업이 뜨고, 고르면 내 화장대에 담긴다.
/// (백엔드 없이 프론트 목데이터로 동작)
class ShelfAddScreen extends ConsumerStatefulWidget {
  const ShelfAddScreen({super.key});

  @override
  ConsumerState<ShelfAddScreen> createState() => _ShelfAddScreenState();
}

class _ShelfAddScreenState extends ConsumerState<ShelfAddScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Product> get _matchedProducts {
    if (_query.isEmpty) return const [];
    final q = _query.toLowerCase();
    return mockProducts
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            (p.brand ?? '').toLowerCase().contains(q))
        .toList();
  }

  List<Ingredient> get _matchedIngredients {
    if (_query.isEmpty) return const [];
    final q = _query.toLowerCase();
    return mockIngredients
        .where((i) =>
            (i.nameKor ?? '').toLowerCase().contains(q) ||
            i.nameEng.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final products = _matchedProducts;
    final ingredients = _matchedIngredients;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        // 긴 한글 제목은 Pretendard로 (갈무리 픽셀 폰트는 깨져 보임).
        title: const Text('제품·성분 검색', style: AppTextStyles.title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 기능 페이지 상단 여백.
              const SizedBox(height: 60),
              // 검색 입력창 (비트맵 픽셀 박스).
              PixelBox(
                borderColor: AppColors.textPrimary,
                pixel: 6,
                borderWidth: 2.5,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    // 돋보기 이미지 아이콘.
                    Image.asset(AppAssets.iconSearch,
                        width: 26,
                        height: 26,
                        errorBuilder: (_, __, ___) => const Icon(Icons.search,
                            color: AppColors.textPrimary, size: 24)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        onChanged: (v) => setState(() => _query = v.trim()),
                        decoration: const InputDecoration(
                          hintText: '제품·성분명을 입력해주세요',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: AppTextStyles.body,
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                        child: const Icon(Icons.close,
                            size: 20, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _query.isEmpty
                    ? _emptyHint()
                    : (products.isEmpty && ingredients.isEmpty)
                        ? _noResult()
                        : ListView(
                            children: [
                              if (products.isNotEmpty) ...[
                                _sectionLabel('제품'),
                                for (final p in products) _productTile(p),
                                const SizedBox(height: 16),
                              ],
                              if (ingredients.isNotEmpty) ...[
                                _sectionLabel('성분'),
                                for (final i in ingredients) _ingredientTile(i),
                              ],
                            ],
                          ),
              ),
              // 완료 — 누르면 내 화장대로 돌아간다.
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: GestureDetector(
                  onTap: () => context.pop(),
                  behavior: HitTestBehavior.opaque,
                  child: PixelBox(
                    borderColor: AppColors.primary,
                    fillColor: AppColors.primaryLight,
                    pixel: 6,
                    borderWidth: 2.5,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text('완료',
                          style: AppTextStyles.title
                              .copyWith(color: AppColors.primaryDark)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(text,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
      );

  Widget _productTile(Product p) {
    final kind = ref
        .read(shelfPreferenceProvider.notifier)
        .kindOf(id: p.id, isProduct: true);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        // 타일 본체 → 제품 상세 (권장 피부타입 등).
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: p),
          ));
        },
        behavior: HitTestBehavior.opaque,
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
              // 우측 + 버튼 → 선호/기피 팝업.
              _addButton(
                kind: kind,
                onTap: () => _pick(id: p.id, name: p.name, isProduct: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 우측 담기 버튼.
  ///
  /// 아직 안 담았으면 + 아이콘, 담았으면 선호/기피 뱃지.
  /// 뱃지를 다시 누르면 팝업이 떠서 바꾸거나 취소할 수 있다.
  Widget _addButton({
    required PreferenceKind? kind,
    required VoidCallback onTap,
  }) {
    final color = kind == null
        ? AppColors.primary
        : (kind == PreferenceKind.like ? AppColors.safe : AppColors.danger);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: kind == null ? Colors.transparent : color,
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: kind == null
            ? Icon(Icons.add, size: 20, color: color)
            : Text(kind.label,
                style: AppTextStyles.caption.copyWith(color: Colors.white)),
      ),
    );
  }

  /// 선호/기피 팝업을 띄우고, 고른 대로 화장대에 담는다.
  Future<void> _pick({
    required int id,
    required String name,
    required bool isProduct,
  }) async {
    final kind = await showPreferenceDialog(
      context,
      name: name,
      isProduct: isProduct,
    );
    // 취소면 아무것도 하지 않는다.
    if (kind == null || !mounted) return;

    ref.read(shelfPreferenceProvider.notifier).add(
          ShelfEntry(id: id, name: name, isProduct: isProduct, kind: kind),
        );
    setState(() {}); // 뱃지 갱신

    if (!mounted) return;
    final what = isProduct ? '제품' : '성분';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('$name — ${kind.label} $what으로 담았어요'),
        duration: const Duration(seconds: 2),
      ));
  }

  Widget _ingredientTile(Ingredient i) {
    final kind = ref
        .read(shelfPreferenceProvider.notifier)
        .kindOf(id: i.id, isProduct: false);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        // 타일 본체 → 성분 상세.
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => IngredientDetailScreen(ingredient: i),
          ));
        },
        behavior: HitTestBehavior.opaque,
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
                    Text(i.displayName,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w700)),
                    if (i.efficacy != null) ...[
                      const SizedBox(height: 2),
                      Text(i.efficacy!,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
              // 우측 + 버튼 → 선호/기피 팝업.
              _addButton(
                kind: kind,
                onTap: () =>
                    _pick(id: i.id, name: i.displayName, isProduct: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyHint() => Center(
        child: Text('제품명이나 성분명을 검색해보세요',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
      );

  Widget _noResult() => Center(
        child: Text('"$_query" 검색 결과가 없어요',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
      );
}
