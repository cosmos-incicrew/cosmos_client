import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/pixel_box.dart';
import '../../../../core/widgets/screen_title.dart';
import '../../../ingredient/data/ingredient_providers.dart';
import '../../../ingredient/data/models/ingredient.dart';
import '../../../product/data/models/product.dart';
import '../../../product/data/product_providers.dart';
import '../../data/shelf_preference.dart';
import '../widgets/preference_dialog.dart';

/// 제품·성분 검색 화면.
///
/// 입력하면 저장소에서 검색한다(제품·성분 각각).
/// 결과를 누르면 선호/기피 선택 팝업이 뜨고, 고르면 내 화장대에 담긴다.
class ShelfAddScreen extends ConsumerStatefulWidget {
  const ShelfAddScreen({super.key});

  @override
  ConsumerState<ShelfAddScreen> createState() => _ShelfAddScreenState();
}

class _ShelfAddScreenState extends ConsumerState<ShelfAddScreen> {
  final _controller = TextEditingController();

  /// 실제로 검색에 쓰이는 값 (디바운스를 거친 뒤 갱신된다).
  String _query = '';
  Timer? _debounce;

  /// 한글 IME는 자모마다 onChanged 를 쏜다 — '아토베리어' 한 단어에 10회 이상.
  /// 그대로 두면 타이핑 중 요청이 그만큼 나가므로 입력이 멎은 뒤에만 검색한다.
  static const _debounceDelay = Duration(milliseconds: 300);

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final next = value.trim();
    // 지우기는 즉시 반영 (빈 화면으로 바로 돌아가야 자연스럽다).
    if (next.isEmpty) {
      setState(() => _query = '');
      return;
    }
    _debounce = Timer(_debounceDelay, () {
      if (mounted) setState(() => _query = next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productSearchProvider(_query));
    final ingredientsAsync = ref.watch(ingredientSearchProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenTitle(
                title: '제품·성분 검색',
                onBack: () =>
                    context.canPop() ? context.pop() : context.go('/shelf'),
              ),
              const SizedBox(height: 16),
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
                        onChanged: _onChanged,
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
                    : _results(productsAsync, ingredientsAsync),
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

  /// 검색 결과 영역.
  ///
  /// 로딩 / 실패 / 결과없음을 **구분해서** 보여준다.
  /// 특히 실패와 결과없음이 같아 보이면, 백엔드 연동이 안 된 건지
  /// 정말 결과가 없는 건지 알 수 없다.
  Widget _results(
    AsyncValue<List<Product>> productsAsync,
    AsyncValue<List<Ingredient>> ingredientsAsync,
  ) {
    // 둘 중 하나라도 실패하면 실패로 본다 (부분 결과는 오해를 부른다).
    if (productsAsync.hasError || ingredientsAsync.hasError) {
      return _errorView();
    }
    // 둘 다 와야 결과를 그린다 — 섹션이 따로 깜빡이지 않게.
    if (productsAsync.isLoading || ingredientsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final products = productsAsync.value ?? const <Product>[];
    final ingredients = ingredientsAsync.value ?? const <Ingredient>[];
    if (products.isEmpty && ingredients.isEmpty) return _noResult();

    return ListView(
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
    );
  }

  /// 검색 실패 — 다시 시도할 수 있게 한다.
  Widget _errorView() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('검색에 실패했어요',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                ref.invalidate(productSearchProvider(_query));
                ref.invalidate(ingredientSearchProvider(_query));
              },
              behavior: HitTestBehavior.opaque,
              child: PixelBox(
                borderColor: AppColors.primary,
                pixel: 5,
                borderWidth: 2,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text('다시 시도',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.primaryDark)),
              ),
            ),
          ],
        ),
      );

  /// 화장대 목록에서 이 항목의 선호/기피를 찾는다. 안 담았으면 null.
  static PreferenceKind? _kindOf(
    List<ShelfEntry> entries, {
    required int id,
    required bool isProduct,
  }) {
    for (final e in entries) {
      if (e.id == id && e.isProduct == isProduct) return e.kind;
    }
    return null;
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(text,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
      );

  Widget _productTile(Product p) {
    // watch — 담기면 뱃지가 알아서 갱신된다 (수동 setState 불필요).
    final kind = ref.watch(shelfPreferenceProvider
        .select((s) => _kindOf(s, id: p.id, isProduct: true)));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        // 타일 본체 → 제품 상세 (권장 피부타입 등).
        onTap: () => context.push('/shelf/product', extra: p),
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
    final kind = ref.watch(shelfPreferenceProvider
        .select((s) => _kindOf(s, id: i.id, isProduct: false)));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        // 타일 본체 → 성분 상세.
        onTap: () => context.push('/shelf/ingredient', extra: i),
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
