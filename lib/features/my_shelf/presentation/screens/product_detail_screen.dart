import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/policy/display_policy.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/pixel_box.dart';
import '../../../../core/widgets/screen_title.dart';
import '../../../bsti/bsti.dart';
import '../../../ingredient/data/ingredient_providers.dart';
import '../../../ingredient/data/models/ingredient_insight.dart';
import '../../../onboarding/data/profile_store.dart';
import '../../../product/data/models/product.dart';
import '../../../product/data/product_providers.dart';

/// 제품 상세 화면.
///
/// 구성: 제품명 → 요약(②, 실패해도 화면은 유지) →
///       권장/기피 피부타입 · 피부고민 (성분 매칭, 프론트 계산) →
///       배합순 TOP 10 성분 토글 (펼치면 ① 효능·특성·주의사항)
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idsAsync = ref.watch(productIngredientIdsProvider(product.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ScreenTitle(
                title: '제품 상세',
                onBack: () =>
                    context.canPop() ? context.pop() : context.go('/shelf'),
              ),
            ),
            Expanded(
              child: idsAsync.when(
                loading: () => const _DotsLoading(),
                error: (_, __) =>
                    _message('제품 정보를 불러오지 못했어요.\n잠시 후 다시 시도해주세요.'),
                data: (ids) => _gate(context, ref, ids),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 이름·요약·TOP10 성분 해설을 **전부 병렬로 미리 당겨오고**, 다 준비된
  /// 뒤에야 본문을 그린다 — 화면이 뜬 뒤 조각조각 로딩되는 모습을 없앤다.
  /// (family 캐시라 같은 제품을 다시 열면 즉시 뜬다. 실패한 조각은 각 섹션
  /// 폴백이 처리하므로 기다림에서 제외한다)
  Widget _gate(BuildContext context, WidgetRef ref, List<int> ids) {
    final top10 = ProductIngredientPolicy.top(ids);
    final loading = <bool>[
      ref.watch(productSummaryProvider(product.id)).isLoading,
      ref.watch(ingredientsByIdsProvider(ingredientIdsKey(top10))).isLoading,
      // ① 해설 프리페치 — 토글을 펼치는 순간 바로 보이게.
      for (final id in top10)
        ref.watch(ingredientDetailProvider(id)).isLoading,
    ];
    if (loading.any((l) => l)) return const _DotsLoading();
    return _body(context, ref, ids);
  }

  Widget _message(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text,
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        ),
      );

  Widget _body(BuildContext context, WidgetRef ref, List<int> ids) {
    final summaryAsync = ref.watch(productSummaryProvider(product.id));
    final bstiIdsAsync = ref.watch(productBstiIdsProvider(product.id));
    // TOP 10 성분 — 표시 정책(정제수 제외)을 거친 배합순 상위 10개.
    // 이름은 일괄 조회(TODO(BE): 엔드포인트 대기)가 비는 동안
    // ② 요약의 대표성분(Top-3) 이름과 ① 펼침 응답이 채운다.
    final top10 = ProductIngredientPolicy.top(ids);
    final names = ref
            .watch(ingredientsByIdsProvider(ingredientIdsKey(top10)))
            .valueOrNull ??
        const [];
    final nameOf = {
      for (final s in summaryAsync.valueOrNull?.topIngredients ?? const [])
        if (s.name != null) s.ingredientId: s.name!,
      for (final ing in names) ing.id: ing.nameKor ?? ing.nameEng,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      children: [
        // 제품명.
        Text('제품명',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(product.name, style: AppTextStyles.title),
        if (product.brand != null) ...[
          const SizedBox(height: 2),
          Text(product.brand!,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
        ],
        const SizedBox(height: 18),

        // 요약 (② — LLM. 실패는 이 칸만).
        summaryAsync.when(
          loading: () => _summaryShell(
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
          ),
          error: (_, __) => _summaryShell(Text(
            '제품 요약이 아직 준비되지 않았어요.',
            style: AppTextStyles.body
                .copyWith(color: AppColors.textSecondary, height: 1.5),
          )),
          data: (summary) => _summaryBox(summary),
        ),
        const SizedBox(height: 20),

        // 권장/기피 — 성분 매칭 (프론트 계산).
        bstiIdsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (bstiIds) => _fitSection(bstiIds),
        ),
        const SizedBox(height: 24),

        // 배합순 TOP 10 성분 — 토글로 ① 해설.
        Text('성분 TOP 10 (배합순)',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('성분을 펼치면 효능·특성과 주의사항을 볼 수 있어요',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        if (ids.isEmpty)
          Text('성분 정보가 아직 없어요',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary))
        else
          for (final (i, id) in top10.indexed)
            _IngredientToggle(
                order: i + 1, ingredientId: id, name: nameOf[id]),
        if (ProductIngredientPolicy.remaining(ids) > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('외 ${ProductIngredientPolicy.remaining(ids)}개 성분',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ),
      ],
    );
  }

  Widget _summaryShell(Widget child) => PixelBox(
        borderColor: AppColors.outline,
        pixel: 6,
        borderWidth: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: SizedBox(width: double.infinity, child: child),
      );

  Widget _summaryBox(ProductSummary summary) {
    if (summary.status == InsightStatus.unavailable ||
        summary.summary == null) {
      return _summaryShell(Text('제품 요약이 아직 준비되지 않았어요.',
          style: AppTextStyles.body
              .copyWith(color: AppColors.textSecondary, height: 1.5)));
    }
    // 출처 줄은 사용자에게 숨긴다 (표시 정책).
    final split =
        splitCaution(SourceDisplayPolicy.stripSourceLines(summary.summary!));
    return PixelBox(
      borderColor: AppColors.primary,
      fillColor: AppColors.primaryLight.withValues(alpha: 0.35),
      pixel: 6,
      borderWidth: 2.5,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('제품 특징'),
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
    );
  }

  /// 권장/기피 피부타입·피부고민 — 이 제품의 성분을 BSTI 사전과 대조해
  /// 프론트에서 계산한다. 근거 없는 항목은 표시하지 않는다.
  Widget _fitSection(List<String> bstiIds) {
    if (bstiIds.isEmpty) return const SizedBox.shrink();
    final idSet = bstiIds.toSet();

    // 권장 피부타입: 권장 성분 교집합이 가장 많은 유형.
    final recommendType = BstiEngine.matchTypeByIngredients(bstiIds);

    // 기피 피부타입: 주의 성분 교집합이 가장 많은 유형 (1개 이상일 때만).
    BstiSkinType? avoidType;
    var maxAvoid = 0;
    for (final t in kBstiSkinTypes.values) {
      final n =
          t.avoid.where((l) => idSet.contains(l.ingredientId)).length;
      if (n > maxAvoid) {
        maxAvoid = n;
        avoidType = t;
      }
    }

    // 권장 피부고민: 고민별 권장 성분과 겹치는 고민.
    final goodConcerns = [
      for (final e in kConcernIngredients.entries)
        if (e.value.any(idSet.contains)) e.key.label,
    ];
    // 기피 피부고민: 고민을 악화시킬 수 있는 성분이 든 경우.
    final badConcerns = [
      for (final e in kConcernAvoidIngredients.entries)
        if (e.value.any(idSet.contains)) e.key.label,
    ];

    if (recommendType == null &&
        avoidType == null &&
        goodConcerns.isEmpty &&
        badConcerns.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('누구에게 맞을까?',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (recommendType != null)
          _fitRow(Icons.thumb_up_alt_outlined, AppColors.safe, '권장 피부타입',
              '${recommendType.code} · ${recommendType.personaName}'),
        if (goodConcerns.isNotEmpty)
          _fitRow(Icons.thumb_up_alt_outlined, AppColors.safe, '권장 피부고민',
              goodConcerns.join(' · ')),
        if (avoidType != null)
          _fitRow(Icons.thumb_down_alt_outlined, AppColors.danger,
              '기피 피부타입', '${avoidType.code} · ${avoidType.personaName}'),
        if (badConcerns.isNotEmpty)
          _fitRow(Icons.thumb_down_alt_outlined, AppColors.danger,
              '기피 피부고민', badConcerns.join(' · ')),
      ],
    );
  }

  Widget _fitRow(IconData icon, Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          SizedBox(
            width: 84,
            child: Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textPrimary, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

/// 성분 하나 — 이름은 즉시 보이고, 펼치면 ① 해설(효능·특성·주의사항)을 가져온다.
///
/// [name] 은 부모가 일괄 조회로 미리 채운다. 펼치기 전에는 ①을 부르지
/// 않는다 (LLM 이라 비용이 있다).
class _IngredientToggle extends ConsumerStatefulWidget {
  const _IngredientToggle({
    required this.order,
    required this.ingredientId,
    this.name,
  });

  final int order;
  final int ingredientId;
  final String? name;

  @override
  ConsumerState<_IngredientToggle> createState() => _IngredientToggleState();
}

class _IngredientToggleState extends ConsumerState<_IngredientToggle> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // ① 해설은 펼친 뒤에만 조회. 이름은 부모의 일괄 조회가 우선이고,
    // (일괄 조회가 실패했을 때) ① 응답의 이름이 대신 채운다.
    final detail = _expanded
        ? ref.watch(ingredientDetailProvider(widget.ingredientId))
        : null;
    final name = widget.name ?? detail?.valueOrNull?.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PixelBox(
        borderColor: AppColors.outline,
        pixel: 5,
        borderWidth: 2,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text('${widget.order}',
                      style:
                          AppTextStyles.pointSm(color: AppColors.primary)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name ?? '성분 ${widget.order} — 펼치면 이름·해설',
                      style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: name == null
                              ? AppColors.textSecondary
                              : AppColors.textPrimary),
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      size: 20, color: AppColors.textSecondary),
                ],
              ),
            ),
            if (_expanded && detail != null) ...[
              const SizedBox(height: 8),
              detail.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))),
                ),
                error: (_, __) => Text('해설을 불러오지 못했어요. 잠시 후 다시 시도해주세요.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
                data: (d) => _detailBody(d),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailBody(IngredientDetail d) {
    if (d.status == InsightStatus.unavailable) {
      return Text('아직 정보가 없습니다',
          style:
              AppTextStyles.caption.copyWith(color: AppColors.textSecondary));
    }
    // 본문(출처줄 제거)을 「성분 역할」/「주의사항」 구획으로 나눠 보여준다.
    final body = d.body == null
        ? null
        : InsightSectionPolicy.splitRoleCaution(
            SourceDisplayPolicy.stripSourceLines(d.body!));
    final cautionText = [
      if (body?.caution != null) body!.caution!,
      if (d.safety != null &&
          (d.safetyKind == SafetyKind.official ||
              d.safetyKind == SafetyKind.general))
        d.safety!,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (body != null && body.role.isNotEmpty) ...[
          const SectionLabel('성분 역할', dense: true),
          Text(body.role,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textPrimary, height: 1.5)),
        ],
        if (cautionText.isNotEmpty) ...[
          const SizedBox(height: 8),
          const SectionLabel('주의사항', color: AppColors.danger, dense: true),
          for (final t in cautionText)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 14, color: AppColors.danger),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(t,
                      style: AppTextStyles.caption.copyWith(
                          color: d.safetyKind == SafetyKind.official
                              ? AppColors.danger
                              : AppColors.textPrimary,
                          height: 1.4)),
                ),
              ],
            ),
        ],
      ],
    );
  }
}

/// "로딩중…" — 점이 하나씩 늘어나는 로딩 표시.
///
/// 제품 상세는 이름·요약·성분 해설까지 병렬로 당겨온 뒤 한 번에 뜨므로,
/// 그동안 사용자에게 진행 중임을 점 애니메이션으로 보여준다.
class _DotsLoading extends StatefulWidget {
  const _DotsLoading();

  @override
  State<_DotsLoading> createState() => _DotsLoadingState();
}

class _DotsLoadingState extends State<_DotsLoading> {
  int _dots = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (mounted) setState(() => _dots = _dots % 3 + 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('로딩중${'.' * _dots}',
              style: AppTextStyles.pointSm(color: AppColors.textPrimary)
                  .copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          Text('성분 이름과 해설까지 준비하고 있어요',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
