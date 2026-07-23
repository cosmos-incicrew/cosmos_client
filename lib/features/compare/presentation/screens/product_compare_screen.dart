import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/policy/display_policy.dart';
import '../../../../core/widgets/pixel_box.dart';
import '../../../../core/widgets/screen_title.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../ingredient/data/ingredient_providers.dart';
import '../../../ingredient/data/models/ingredient_insight.dart';
import '../../../my_shelf/data/shelf_preference.dart';
import '../../../my_shelf/presentation/widgets/ingredient_detail_sheet.dart';
import '../../../product/data/models/product.dart';
import '../../../product/data/models/product_compare.dart';
import '../../../product/data/product_providers.dart';
import '../../engine/compare_match.dart';

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

  /// 대표제품 id — 이 제품 기준으로 상대 비교한다. 기본값 = 처음 담은 제품.
  int? _repId;

  /// 비교 결과. null = 아직 비교 전.
  ProductCompareResult? _result;
  ComparisonSummary? _summary;

  /// 제품 id → BSTI 성분 id (보완성분 판정용, 비교 시점에 조회).
  Map<int, List<String>> _bstiOf = const {};
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
        // 대표를 지웠으면 남은 첫 제품이 대표를 승계.
        if (_repId == p.id) {
          _repId = _selected.isEmpty ? null : _selected.first.id;
        }
      } else if (_selected.length < _maxProducts) {
        _selected.add(p);
        _repId ??= p.id; // 처음 담은 제품이 기본 대표
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
      // 대표제품을 맨 앞에 — 결과 표의 첫 열이 되어 상대 비교 기준이 된다.
      final ordered = [
        ..._selected.where((p) => p.id == _repId),
        ..._selected.where((p) => p.id != _repId),
      ];
      final result = await repo.compare([for (final p in ordered) p.id]);
      // 보완성분 판정용 BSTI 매핑 — 실패해도 비교 자체는 진행한다.
      Map<int, List<String>> bstiOf = const {};
      try {
        bstiOf = await ref
            .read(ingredientRepositoryProvider)
            .bstiIdsByProducts([for (final p in ordered) p.id]);
      } on Object {
        bstiOf = const {};
      }
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
        _bstiOf = bstiOf;
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
            // 비교 완료 후에는 선택·검색 UI 를 걷고 보고서형 결과만 보여준다.
            if (_result == null) ...[
              _selectedRow(),
              const SizedBox(height: 14),
              _shelfPickSection(),
              const SizedBox(height: 14),
              _searchBox(),
              if (_query.isNotEmpty) _searchResults(),
              const SizedBox(height: 16),
              _compareButton(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.danger)),
              ],
            ] else
              ..._reportView(_result!),
          ],
        ),
      ),
    );
  }

  /// 내 화장대에서 가져오기 — 담아둔 제품을 탭 한 번으로 비교 목록에.
  Widget _shelfPickSection() {
    final shelfProducts = [
      for (final e in ref.watch(shelfPreferenceProvider))
        if (e.isProduct) e,
    ];
    if (shelfProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('내 화장대에서 가져오기',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in shelfProducts)
              Builder(builder: (context) {
                final picked = _selected.any((p) => p.id == e.id);
                return GestureDetector(
                  onTap: () => _toggle(Product(id: e.id, name: e.name)),
                  child: PixelBox(
                    borderColor:
                        picked ? AppColors.primary : AppColors.outline,
                    fillColor: picked
                        ? AppColors.primaryLight.withValues(alpha: 0.5)
                        : AppColors.background,
                    pixel: 5,
                    borderWidth: 2,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                            picked
                                ? Icons.check_circle_outline
                                : Icons.add_circle_outline,
                            size: 15,
                            color: picked
                                ? AppColors.primaryDark
                                : AppColors.textSecondary),
                        const SizedBox(width: 5),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 170),
                          child: Text(e.name,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textPrimary)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ],
    );
  }

  /// 비교 결과 — 보고서형. 대표제품 기준 궁합 점수 + 보완/공통/과다 성분.
  List<Widget> _reportView(ProductCompareResult result) {
    final rep = result.products.firstWhere((p) => p.id == _repId,
        orElse: () => result.products.first);
    final matches = CompareMatchEngine.build(result, rep.id, _bstiOf);

    return [
      // 다시 고르기 — 선택 모드로 복귀 (담은 제품은 유지).
      Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: () => setState(() {
            _result = null;
            _summary = null;
          }),
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.refresh,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('다시 고르기',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 6),
      // 대표제품 카드.
      PixelBox(
        borderColor: AppColors.primaryDark,
        fillColor: AppColors.primaryLight.withValues(alpha: 0.45),
        pixel: 6,
        borderWidth: 2.5,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.star, size: 20, color: AppColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('대표제품',
                      style: AppTextStyles.pointSm(
                              color: AppColors.textSecondary)
                          .copyWith(fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(rep.productName,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      for (final m in matches) ...[
        _matchCard(m),
        const SizedBox(height: 14),
      ],
      if (_summary != null) ...[
        const SizedBox(height: 6),
        _summaryBox(_summary!),
      ],
    ];
  }

  /// 상대 제품 하나의 궁합 카드 — 점수 + 보완/공통/과다.
  Widget _matchCard(PairMatch m) {
    final color = m.score >= 80
        ? AppColors.safe
        : m.score >= 50
            ? AppColors.accent
            : AppColors.danger;

    return PixelBox(
      borderColor: AppColors.outline,
      pixel: 6,
      borderWidth: 2.5,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.product.productName,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('대표제품과의 궁합 — ${m.verdict}',
                        style: AppTextStyles.caption.copyWith(color: color)),
                  ],
                ),
              ),
              Text('${m.score}',
                  style: AppTextStyles.pointBoldEn(size: 30, color: color)),
            ],
          ),
          const SizedBox(height: 12),

          // 보완 성분 — 같이 쓰면 좋은 조합.
          const SectionLabel('보완 성분 — 같이 쓰면 좋아요',
              color: AppColors.safe, dense: true),
          if (m.complementary.isEmpty)
            _noneText('보완 성분 조합은 없어요')
          else
            for (final hit in m.complementary)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('· ${hit.pair.reason}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textPrimary, height: 1.5)),
              ),
          const SizedBox(height: 10),

          // 공통 성분.
          const SectionLabel('공통 성분 — 두 제품에 다 들어있어요',
              dense: true),
          if (m.shared.isEmpty)
            _noneText('공통 성분은 없어요')
          else
            Text('두 제품에 공통으로 든 성분이 ${m.shared.length}개 있어요',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textPrimary, height: 1.5)),
          const SizedBox(height: 10),

          // 과다 성분 — 규제 성분이 겹침.
          const SectionLabel('과다 성분 — 겹쳐 쓰면 과할 수 있어요',
              color: AppColors.danger, dense: true),
          if (m.excess.isEmpty)
            _noneText('과다 성분은 없어요 👍')
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final ing in m.excess) _ingChip(ing, AppColors.danger),
              ],
            ),
        ],
      ),
    );
  }

  Widget _noneText(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(text,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
      );

  /// 성분 칩 — 탭하면 ① 성분 해설 시트.
  Widget _ingChip(IngredientPresence ing, Color color) {
    return GestureDetector(
      onTap: () => IngredientDetailSheet.show(
        context,
        ingredientId: ing.ingredientId,
        fallbackName: ing.nameKr,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(ing.nameKr,
            style: AppTextStyles.caption
                .copyWith(fontSize: 12, color: AppColors.textPrimary)),
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
        const SizedBox(height: 2),
        Text('칩을 누르면 ★ 대표제품 지정 — 대표 기준으로 비교됩니다',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary, fontSize: 11)),
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
                GestureDetector(
                  // 칩을 누르면 대표제품으로.
                  onTap: () => setState(() => _repId = p.id),
                  child: PixelBox(
                  borderColor: _repId == p.id
                      ? AppColors.primaryDark
                      : AppColors.primary,
                  fillColor: AppColors.primaryLight,
                  pixel: 5,
                  borderWidth: _repId == p.id ? 2.5 : 2,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_repId == p.id) ...[
                        const Icon(Icons.star,
                            size: 14, color: AppColors.accent),
                        const SizedBox(width: 4),
                      ],
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


  /// 비교하기 — '화장품 추가하기' 버튼과 같은 스타일.
  Widget _compareButton() {
    final enabled = _selected.length >= _minProducts && !_comparing;
    return GestureDetector(
      onTap: enabled ? _compare : null,
      behavior: HitTestBehavior.opaque,
      child: PixelBox(
        borderColor: enabled ? AppColors.primary : AppColors.outline,
        fillColor: enabled
            ? AppColors.primaryLight
            : AppColors.primaryLight.withValues(alpha: 0.35),
        pixel: 6,
        borderWidth: 2.5,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compare_arrows,
                color:
                    enabled ? AppColors.primaryDark : AppColors.textSecondary,
                size: 22),
            const SizedBox(width: 8),
            Text(_comparing ? '비교 중…' : '비교하기',
                style: AppTextStyles.title.copyWith(
                    color: enabled
                        ? AppColors.primaryDark
                        : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  /// ③ 비교 해설 박스. "주의:" 줄은 분리해 강조.
  Widget _summaryBox(ComparisonSummary summary) {
    if (summary.status == InsightStatus.unavailable ||
        summary.summary == null) {
      return Text('비교 해설이 아직 준비되지 않았어요.',
          style:
              AppTextStyles.caption.copyWith(color: AppColors.textSecondary));
    }
    // 출처줄 숨김(표시 정책) 후 「구성 차이」/「주의사항」 소제목으로 구획.
    final split = splitCaution(
        SourceDisplayPolicy.stripSourceLines(summary.summary!));

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
              const SectionLabel('구성 차이'),
              Text(split.body, style: AppTextStyles.body.copyWith(height: 1.6)),
              if (split.caution != null) ...[
                const SizedBox(height: 12),
                const SectionLabel('주의사항', color: AppColors.danger),
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
