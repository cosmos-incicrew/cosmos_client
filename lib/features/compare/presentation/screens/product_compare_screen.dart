import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/pixel_box.dart';
import '../../../../core/widgets/pixel_button.dart';
import '../../../../core/widgets/screen_title.dart';
import '../../../ingredient/data/ingredient_providers.dart';
import '../../../ingredient/data/models/ingredient_insight.dart';
import '../../../my_shelf/presentation/widgets/ingredient_detail_sheet.dart';
import '../../../product/data/models/product.dart';
import '../../../product/data/models/product_compare.dart';
import '../../../product/data/product_providers.dart';

/// 다중 제품 비교 화면 (명세 "화면 매핑" 기준).
///
///  제품 선택 (검색으로 2~4개 담기)
///   → 비교 표          ← POST /products/compare (성분 × 제품 포함 여부)
///   → 비교 해설         ← ③ POST /ingredients/comparison-summary
///       └ "주의: ..." 줄 강조
///
/// ⚠️ 해설은 성분 **구성의 차이**만 말한다 — 제품 간 우열·추천은 하지 않는다
/// (배합 비율이 비공개라 판단 근거가 없음).
class ProductCompareScreen extends ConsumerStatefulWidget {
  const ProductCompareScreen({super.key});

  @override
  ConsumerState<ProductCompareScreen> createState() =>
      _ProductCompareScreenState();
}

class _ProductCompareScreenState extends ConsumerState<ProductCompareScreen> {
  static const _minProducts = 2;
  static const _maxProducts = 4; // MVP 초기값 — 서버와 함께 바뀔 수 있다

  final _searchController = TextEditingController();
  String _query = '';
  Timer? _debounce;

  /// 비교할 제품 (2~4개).
  final List<Product> _selected = [];

  /// 비교 결과. null = 아직 비교 전.
  ProductCompareResult? _result;
  ComparisonSummary? _summary;
  bool _comparing = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final next = value.trim();
    if (next.isEmpty) {
      setState(() => _query = '');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = next);
    });
  }

  void _toggle(Product p) {
    setState(() {
      final i = _selected.indexWhere((e) => e.id == p.id);
      if (i >= 0) {
        _selected.removeAt(i);
      } else if (_selected.length < _maxProducts) {
        _selected.add(p);
      }
      // 선택이 바뀌면 이전 비교 결과는 무효.
      _result = null;
      _summary = null;
      _error = null;
    });
  }

  Future<void> _compare() async {
    setState(() {
      _comparing = true;
      _error = null;
    });
    try {
      final repo = ref.read(productRepositoryProvider);
      final result = await repo.compare([for (final p in _selected) p.id]);
      // ③ 해설 — 비교 결과를 그대로 넘긴다. 해설 실패는 표만 보여준다
      // (표는 검색엔진, 해설은 LLM — 한쪽 실패가 다른 쪽을 막지 않게).
      ComparisonSummary? summary;
      try {
        summary = await ref
            .read(ingredientRepositoryProvider)
            .getComparisonSummary(result);
      } on Object {
        summary = null;
      }
      if (!mounted) return;
      setState(() {
        _result = result;
        _summary = summary;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _error = '비교에 실패했어요. 잠시 후 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _comparing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            ScreenTitle(
              title: '제품 비교',
              onBack: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
            ),
            const SizedBox(height: 8),
            _selectedRow(),
            const SizedBox(height: 12),
            _searchBox(),
            if (_query.isNotEmpty) _searchResults(),
            const SizedBox(height: 16),
            PixelButton(
              label: _comparing ? '비교 중…' : '비교하기',
              onPressed:
                  _selected.length >= _minProducts && !_comparing
                      ? _compare
                      : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.danger)),
            ],
            if (_result != null) ...[
              const SizedBox(height: 24),
              _resultTable(_result!),
              const SizedBox(height: 20),
              if (_summary != null) _summaryBox(_summary!),
            ],
          ],
        ),
      ),
    );
  }

  /// 선택된 제품 칩 줄 (2~4개).
  Widget _selectedRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('비교할 제품 (${_selected.length}/$_maxProducts) — 2개 이상 골라주세요',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        if (_selected.isEmpty)
          Text('아래 검색으로 제품을 담아보세요',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in _selected)
                PixelBox(
                  borderColor: AppColors.primary,
                  fillColor: AppColors.primaryLight,
                  pixel: 5,
                  borderWidth: 2,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(p.name,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.primaryDark)),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _toggle(p),
                        child: const Icon(Icons.close,
                            size: 16, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _searchBox() {
    return PixelBox(
      borderColor: AppColors.textPrimary,
      pixel: 6,
      borderWidth: 2.5,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textPrimary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onQueryChanged,
              decoration: const InputDecoration(
                hintText: '비교할 제품명을 검색해주세요',
                border: InputBorder.none,
                isDense: true,
              ),
              style: AppTextStyles.body,
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _query = '');
              },
              child: const Icon(Icons.close,
                  size: 20, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _searchResults() {
    final async = ref.watch(productSearchProvider(_query));
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => Text('검색에 실패했어요',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        data: (products) => products.isEmpty
            ? Text('"$_query" 검색 결과가 없어요',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary))
            : Column(
                children: [
                  for (final p in products.take(6)) _resultTile(p),
                ],
              ),
      ),
    );
  }

  Widget _resultTile(Product p) {
    final picked = _selected.any((e) => e.id == p.id);
    final full = !picked && _selected.length >= _maxProducts;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: full ? null : () => _toggle(p),
        behavior: HitTestBehavior.opaque,
        child: PixelBox(
          borderColor: picked ? AppColors.primary : AppColors.outline,
          pixel: 5,
          borderWidth: 2,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(
                picked ? Icons.check_box : Icons.check_box_outline_blank,
                size: 20,
                color: full
                    ? AppColors.outline
                    : (picked ? AppColors.primary : AppColors.textSecondary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${p.name}${p.brand != null ? ' · ${p.brand}' : ''}',
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                      color: full
                          ? AppColors.textSecondary
                          : AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 비교 표 — 성분 × 제품 포함 여부.
  ///
  /// 공통(all) → 일부(partial) → 개별(single) 순으로 묶고,
  /// 규제 있는 성분엔 경고 아이콘. 행을 누르면 ① 성분 해설.
  Widget _resultTable(ProductCompareResult result) {
    final rows = [...result.ingredientPresence]..sort(
        (a, b) => a.presenceType.index.compareTo(b.presenceType.index));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('성분 비교',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('행을 누르면 성분 해설을 볼 수 있어요',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        PixelBox(
          borderColor: AppColors.outline,
          pixel: 5,
          borderWidth: 2,
          padding: const EdgeInsets.all(10),
          // 제품이 많으면 표가 옆으로 넘친다 — 표 안에서만 가로 스크롤.
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 18,
              horizontalMargin: 4,
              headingRowHeight: 40,
              dataRowMinHeight: 36,
              dataRowMaxHeight: 44,
              columns: [
                const DataColumn(label: Text('성분')),
                for (final p in result.products)
                  DataColumn(
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 88),
                      child: Text(p.productName,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption
                              .copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
              rows: [
                for (final row in rows)
                  DataRow(
                    onSelectChanged: (_) => IngredientDetailSheet.show(
                      context,
                      ingredientId: row.ingredientId,
                      fallbackName: row.nameKr,
                    ),
                    cells: [
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 110),
                            child: Text(row.nameKr,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption),
                          ),
                          if (row.restrictions.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.warning_amber_rounded,
                                size: 14, color: AppColors.danger),
                          ],
                        ],
                      )),
                      for (final p in result.products)
                        DataCell(Center(
                          child: row.productIds.contains(p.id)
                              ? Icon(Icons.check,
                                  size: 18, color: _presenceColor(row))
                              : const SizedBox.shrink(),
                        )),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 범례.
        Wrap(
          spacing: 14,
          children: [
            _legend(AppColors.safe, '모든 제품 공통'),
            _legend(AppColors.accent, '일부 제품'),
            _legend(AppColors.textSecondary, '한 제품만'),
          ],
        ),
      ],
    );
  }

  Color _presenceColor(IngredientPresence row) => switch (row.presenceType) {
        PresenceType.all => AppColors.safe,
        PresenceType.partial => AppColors.accent,
        PresenceType.single => AppColors.textSecondary,
      };

  Widget _legend(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary, fontSize: 11)),
        ],
      );

  /// ③ 비교 해설 박스. "주의:" 줄은 분리해 강조.
  Widget _summaryBox(ComparisonSummary summary) {
    if (summary.status == InsightStatus.unavailable ||
        summary.summary == null) {
      return Text('비교 해설이 아직 준비되지 않았어요.',
          style:
              AppTextStyles.caption.copyWith(color: AppColors.textSecondary));
    }
    final split = splitCaution(summary.summary!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('비교 해설',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        PixelBox(
          borderColor: AppColors.primary,
          fillColor: AppColors.primaryLight.withValues(alpha: 0.35),
          pixel: 6,
          borderWidth: 2.5,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(split.body, style: AppTextStyles.body.copyWith(height: 1.6)),
              if (split.caution != null) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 18, color: AppColors.danger),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(split.caution!,
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700,
                              height: 1.5)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
