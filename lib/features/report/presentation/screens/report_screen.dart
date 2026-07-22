import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/screen_title.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/pixel_box.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../bsti/bsti.dart';
import '../../../my_shelf/data/shelf_preference.dart';
import '../../../my_shelf/presentation/widgets/ingredient_detail_sheet.dart';
import '../../../onboarding/data/profile_store.dart';
import '../../../onboarding/data/skin_concern.dart';
import '../../../product/data/models/product.dart';
import '../../data/recommendation.dart';
import '../../data/recommendation_repository.dart';
import '../../engine/report_engine.dart';
import '../../data/report_provider.dart';

/// 내 화장대 종합보고서.
///
/// 구성: 내 BSTI 유형(고양이) → 화장대 총점 → 총평
///      → 지금 쓰는 화장품 각각의 매칭 점수.
///
/// 점수는 [ReportEngine]이 실제 BSTI 권장/주의 성분과 대조해 계산한다.
/// 근거가 없으면 점수를 지어내지 않고 "판단 정보 부족"으로 표시한다.
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  /// 로딩 GIF 최소 노출 — 점수 계산·추천 생성 동안의 볼거리 (약 5초).
  bool _minSplashDone = false;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _minSplashDone = true);
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  /// 본문 속 "(근거 1 유사 케이스 1, 2 참고)" 류 인라인 표기는 UI 에서 뗀다 —
  /// 근거는 버튼·시트로 따로 보여주기로 했다. (데이터가 어떻게 와도 적용)
  static String _stripEvidenceRefs(String text) {
    return text
        .replaceAll(RegExp(r'\s*\(근거[^)]*\)'), '')
        .replaceAll(RegExp(r'\s*\(유사\s*케이스[^)]*\)'), '');
  }

  /// 데이터가 하나도 없을 때 — 보고서를 만들 수 없음을 먼저 알린다.
  Widget _insufficientView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        ScreenTitle(
          title: '내 화장대 보고서',
          onBack: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        const SizedBox(height: 40),
        PixelBox(
          borderColor: AppColors.outline,
          pixel: 6,
          borderWidth: 2.5,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('아직 데이터가 충분하지 않아\n보고서를 만들 수 없어요',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w800, height: 1.5)),
              const SizedBox(height: 8),
              Text('BSTI 검사를 하거나 화장대에 제품을 담으면\n맞춤 보고서가 만들어져요',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary, height: 1.5)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.push('/bsti'),
                behavior: HitTestBehavior.opaque,
                child: PixelBox(
                  borderColor: AppColors.primary,
                  fillColor: AppColors.primaryLight,
                  pixel: 5,
                  borderWidth: 2,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text('BSTI 피부타입 검사하러 가기',
                        style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => context.push('/shelf/add'),
                behavior: HitTestBehavior.opaque,
                child: PixelBox(
                  borderColor: AppColors.outline,
                  pixel: 5,
                  borderWidth: 2,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text('화장대에 제품 담으러 가기',
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // 닉네임·나이·피부고민 — 맞춤 추천의 재료.
              GestureDetector(
                onTap: () => context.push('/profile/edit'),
                behavior: HitTestBehavior.opaque,
                child: PixelBox(
                  borderColor: AppColors.outline,
                  pixel: 5,
                  borderWidth: 2,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text('프로필 등록하러 가기',
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 보고서 생성 로딩 — GIF (없으면 스피너로 대체).
  Widget _loadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            AppAssets.reportLoading,
            width: 220,
            height: 220,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const CircularProgressIndicator(),
          ),
          const SizedBox(height: 14),
          Text('내 화장대 보고서를 만들고 있어요…',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 검사도 안 했고 화장대도 비었으면 — 만들 재료가 없다. 로딩을 돌리지
    // 않고 "아직 만들 수 없어요"를 먼저 보여준다 (데이터 유도 CTA 포함).
    final entries = ref.watch(shelfPreferenceProvider);
    final hasBsti = ref.watch(userProfileProvider).bstiType != null;
    if (entries.isEmpty && !hasBsti) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: _insufficientView(context)),
      );
    }

    final reportAsync = ref.watch(shelfReportProvider);
    final recoAsync = ref.watch(recommendationProvider);
    // 점수·추천(원인분석)까지 전부 준비될 때까지 GIF 유지 — 화면이 뜬 뒤에
    // 섹션이 또 로딩 중인 모습을 보여주지 않는다. (추천 실패는 통과시켜
    // 본문에서 "다시 시도"로 처리 — 실패 때문에 GIF 에 갇히면 안 된다)
    final showLoading =
        !_minSplashDone || reportAsync.isLoading || recoAsync.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: showLoading
            ? _loadingView()
            : reportAsync.when(
                loading: _loadingView,
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
    final profile = ref.watch(userProfileProvider);
    // 추천은 보고서보다 늦게 와도 되므로, 없으면 그 구역만 비운다.
    final suggestions =
        ref.watch(shelfSuggestionsProvider).valueOrNull ?? const [];
    // 맞춤 추천 (RAG) — 피부고민 분석 섹션. 실패해도 이 구역만 안내로 대체.
    final recoAsync = ref.watch(recommendationProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        ScreenTitle(
          title: '내 화장대 보고서',
          onBack: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        const SizedBox(height: 8),
        _profileHeader(profile, type),
        // 피부타입은 헤더 오른쪽에 통합 — 검사 전일 때만 유도 카드를 띄운다.
        if (type == null) ...[
          const SizedBox(height: 14),
          _typeCard(context, type),
        ],
        const SizedBox(height: 20),
        _concernSection(
            context, ref, recoAsync, type, profile.concerns.toList()),
        const SizedBox(height: 24),
        _scoreCard(report),
        if (report.conflicts.isNotEmpty) ...[
          const SizedBox(height: 14),
          _conflictSection(context, report),
        ],
        const SizedBox(height: 28),
        Text('지금 쓰는 화장품',
            style: AppTextStyles.pointSm(color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        if (report.isEmpty)
          _emptyBox('화장대에 담은 제품이 없어요', '제품·성분을 검색해 담아보세요',
              onTap: () => context.push('/shelf/add'))
        else
          for (final m in report.matches) _MatchToggle(match: m),
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
            GestureDetector(
              // 성분명을 누르면 논문 근거가 뜬다.
              onTap: s.bstiId == null
                  ? null
                  : () => _showBstiEvidence(context, s.bstiId!),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Flexible(
                    child: Text('${s.ingredientName} 성분이 부족합니다',
                        style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark)),
                  ),
                  if (s.bstiId != null) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.help_outline,
                        size: 15, color: AppColors.textSecondary),
                  ],
                ],
              ),
            ),
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
                  onTap: () => context.push('/shelf/product', extra: p),
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
  /// 검사 전이면: 반영 안 됐음을 알리고 검사 유도 버튼.
  Widget _typeCard(BuildContext context, BstiSkinType? type) {
    if (type == null) {
      return PixelBox(
        borderColor: AppColors.outline,
        pixel: 6,
        borderWidth: 2.5,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('아직 BSTI 결과가 없어 피부타입은 반영되지 않았습니다',
                style: AppTextStyles.body.copyWith(height: 1.5)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.push('/bsti'),
              behavior: HitTestBehavior.opaque,
              child: PixelBox(
                borderColor: AppColors.primary,
                fillColor: AppColors.primaryLight,
                pixel: 5,
                borderWidth: 2,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text('BSTI 검사하고 더 완벽한 보고서 받기',
                      style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark)),
                ),
              ),
            ),
          ],
        ),
      );
    }
    // 유형이 있으면 카드 없음 — 프로필 헤더 오른쪽에 이미 표시된다.
    return const SizedBox.shrink();
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

  /// 보고서 대상 — 고양이 + 닉네임 · 연령 · 피부고민.
  /// 라벨은 갈무리 픽셀체("내 피부타입" 카드와 같은 결), 고민은 픽셀 칩.
  Widget _profileHeader(UserProfile profile, BstiSkinType? type) {
    final name = profile.nickname ?? '사용자';
    final age = profile.age != null ? '${profile.age}세' : '';

    return PixelBox(
      borderColor: AppColors.textPrimary,
      pixel: 6,
      borderWidth: 2.5,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('닉네임',
                    style:
                        AppTextStyles.pointSm(color: AppColors.textSecondary)
                            .copyWith(fontSize: 13)),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(name,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                    ),
                    if (age.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(age,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text('피부고민',
                    style:
                        AppTextStyles.pointSm(color: AppColors.textSecondary)
                            .copyWith(fontSize: 13)),
                const SizedBox(height: 6),
                if (profile.concerns.isEmpty)
                  Text('아직 선택 전이에요',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary))
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final c in profile.concerns)
                        PixelBox(
                          borderColor: AppColors.primary,
                          fillColor: AppColors.primaryLight,
                          pixel: 4,
                          borderWidth: 2,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          child: Text(c.label,
                              style: AppTextStyles.caption.copyWith(
                                  fontSize: 12,
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 내 피부타입 — 프로필 사진 자리. 유형 고양이 + 코드 (검사 전엔 기본).
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('내 피부타입',
                  style: AppTextStyles.pointSm(color: AppColors.textSecondary)
                      .copyWith(fontSize: 11)),
              const SizedBox(height: 4),
              SizedBox(
                width: 64,
                height: 64,
                child: Image.asset(
                  type?.catImageAsset ?? AppAssets.logoFull,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.pets,
                      size: 40, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                type?.code ?? '검사 전',
                style: type == null
                    ? AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary, fontSize: 11)
                    : AppTextStyles.pointBoldEn(
                        size: 15, color: AppColors.primaryDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 피부고민 분석 — 맞춤 추천 API (POST /api/v1/recommendations, RAG).
  /// ① 원인 분석 + ② 추천 성분(근거는 탭해서). ③ 관리법은 /report/care.
  Widget _concernSection(
      BuildContext context,
      WidgetRef ref,
      AsyncValue<RecommendationResult> recoAsync,
      BstiSkinType? type,
      List<SkinConcern> localConcerns) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('피부고민 분석',
            style: AppTextStyles.pointSm(color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        recoAsync.when(
          loading: () => PixelBox(
            borderColor: AppColors.outline,
            pixel: 6,
            borderWidth: 2,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
            child: Column(
              children: [
                const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(height: 12),
                Text('내 프로필로 맞춤 분석을 생성하고 있어요… (최대 1분)',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          error: (_, __) => PixelBox(
            borderColor: AppColors.outline,
            pixel: 6,
            borderWidth: 2,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('분석을 불러오지 못했어요. 잠시 후 다시 시도해주세요.',
                    style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary, height: 1.5)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => ref.invalidate(recommendationProvider),
                  behavior: HitTestBehavior.opaque,
                  child: PixelBox(
                    borderColor: AppColors.primary,
                    fillColor: AppColors.primaryLight,
                    pixel: 5,
                    borderWidth: 2,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text('다시 시도',
                          style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          data: (reco) =>
              _concernBody(context, ref, reco, type, localConcerns),
        ),
      ],
    );
  }

  /// 서버 고민 코드(acne 등) → 한글 라벨. 모르는 코드는 그대로 보여준다.
  static String _concernLabel(String code) {
    for (final c in SkinConcern.values) {
      if (c.name == code) return c.label;
    }
    return code;
  }

  Widget _concernBody(BuildContext context, WidgetRef ref,
      RecommendationResult reco, BstiSkinType? type, List<SkinConcern> localConcerns) {
    // 프로필 미입력(409) — 분석 대신 입력 유도.
    if (reco.status == RecoStatus.profileRequired) {
      return _concernNotice(
        context,
        message: reco.advisory?.message ??
            '추천을 받으려면 먼저 나이와 피부 고민을 입력해 주세요.',
        ctaLabel: '프로필 입력하러 가기',
        onTap: () => context.push('/profile/edit'),
      );
    }

    // 근거 부족 — 에러가 아니라 정형 응답. advisory 의 안내·행동 유도 표시.
    if (reco.status == RecoStatus.insufficientEvidence) {
      return _concernNotice(
        context,
        message: reco.advisory?.message ??
            '아직 추천할 근거가 충분하지 않아요.',
        ctaLabel: _advisoryCtaLabel(reco.advisory?.action),
        onTap: _advisoryCtaAction(context, ref, reco.advisory?.action),
      );
    }

    final profile = reco.profile;
    final profileLine = profile == null
        ? null
        : [
            if (profile.age != null) '${profile.age}세',
            if (profile.gender != null)
              profile.gender == 'female' ? '여성' : '남성',
            if (profile.bstiType != null) profile.bstiType!,
          ].join(' · ');
    final cause = reco.answer?.causeAnalysis;
    final recommendation = reco.answer?.recommendation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 무엇 기준의 분석인지.
        if (profile != null && profile.concerns.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
                profile.concerns.map(_concernLabel).join('·') +
                    (profileLine == null ? '' : ' · $profileLine'),
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ),
        // 근거가 약할 때 배너 (추천은 온 상태).
        if (reco.advisory != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 10),
            child: PixelBox(
              borderColor: AppColors.accent,
              fillColor: AppColors.accent.withValues(alpha: 0.08),
              pixel: 4,
              borderWidth: 2,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(reco.advisory!.message,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary, height: 1.4)),
                  ),
                ],
              ),
            ),
          ),
        // ① 원인 분석 — 서버 서사가 없으면(현 서버) BSTI 기반 피부타입
        // 분석으로 대신한다. 타입과 고민은 다른 축일 수 있으므로(지성인데
        // 여드름 등) "타입 기준"임을 제목에 명시해 분리한다.
        if (cause == null && type != null) ...[
          const SizedBox(height: 8),
          _typeCauseBox(context, type, localConcerns),
        ],
        if (cause != null) ...[
          const SizedBox(height: 8),
          PixelBox(
            borderColor: AppColors.primary,
            fillColor: AppColors.primaryLight.withValues(alpha: 0.35),
            pixel: 6,
            borderWidth: 2.5,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('원인 분석'),
                Text(_stripEvidenceRefs(cause),
                    style: AppTextStyles.body.copyWith(height: 1.6)),
                if (reco.cases.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (i, c) in reco.cases.indexed)
                        GestureDetector(
                          onTap: () => _showSimilarCase(context, i + 1, c),
                          child: PixelBox(
                            borderColor: AppColors.primary,
                            fillColor: AppColors.background,
                            pixel: 4,
                            borderWidth: 2,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: Text('유사 케이스 ${i + 1} 보기',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text('추천 성분 — 피부고민 + 피부타입',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('성분을 누르면 왜 추천되는지 근거를 볼 수 있어요',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        // ② 추천 서사 — 새 명세의 recommendation 섹션.
        if (recommendation != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(_stripEvidenceRefs(recommendation),
                style: AppTextStyles.body.copyWith(height: 1.6)),
          ),
        for (final ing in reco.ingredients)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => _showConcernEvidence(context, ing),
              behavior: HitTestBehavior.opaque,
              child: PixelBox(
                borderColor: AppColors.outline,
                pixel: 5,
                borderWidth: 2,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ing.nameKor,
                              style: AppTextStyles.body
                                  .copyWith(fontWeight: FontWeight.w700)),
                          if (ing.inci != null) ...[
                            const SizedBox(height: 2),
                            Text(ing.inci!,
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11)),
                          ],
                        ],
                      ),
                    ),
                    // 규제 경고가 걸린 성분은 아이콘으로 표시.
                    if (ing.warnings.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.warning_amber_rounded,
                            size: 16, color: AppColors.danger),
                      ),
                    const Icon(Icons.expand_more,
                        size: 20, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => context.push('/report/care'),
          behavior: HitTestBehavior.opaque,
          child: PixelBox(
            borderColor: AppColors.primary,
            fillColor: AppColors.primaryLight,
            pixel: 6,
            borderWidth: 2.5,
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('사용법·관리법 보러가기',
                      style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark)),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward,
                      size: 18, color: AppColors.primaryDark),
                ],
              ),
            ),
          ),
        ),
        // 고정 고지 문구.
        if (reco.disclaimer != null) ...[
          const SizedBox(height: 10),
          Text(reco.disclaimer!,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ],
    );
  }

  /// 분석 대신 띄우는 안내 + (있으면) CTA.
  Widget _concernNotice(BuildContext context,
      {required String message, String? ctaLabel, VoidCallback? onTap}) {
    return PixelBox(
      borderColor: AppColors.outline,
      pixel: 6,
      borderWidth: 2.5,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message, style: AppTextStyles.body.copyWith(height: 1.5)),
          if (ctaLabel != null && onTap != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: PixelBox(
                borderColor: AppColors.primary,
                fillColor: AppColors.primaryLight,
                pixel: 5,
                borderWidth: 2,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(ctaLabel,
                      style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 피부타입 기준 원인 분석 — BSTI 프론트 완결 데이터(논문 근거)로 구성.
  /// 서버 추천 서사(answer.cause_analysis)가 오면 그쪽이 우선한다.
  Widget _typeCauseBox(
      BuildContext context, BstiSkinType type, List<SkinConcern> concerns) {
    return PixelBox(
      borderColor: AppColors.primary,
      fillColor: AppColors.primaryLight.withValues(alpha: 0.35),
      pixel: 6,
      borderWidth: 2.5,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('원인 분석 — 내 피부타입(${type.code}) 기준'),
          // 유형 요약 — BSTI 데이터셋 원문.
          Text(type.summary, style: AppTextStyles.body.copyWith(height: 1.6)),
          // 고민별 연계 — 타입과 고민은 다른 축이라 고민마다 따로 잇는다.
          for (final c in concerns) ...[
            const SizedBox(height: 12),
            Text('「${c.label}」 고민에는',
                style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark)),
            const SizedBox(height: 6),
            if ((kConcernIngredients[c] ?? const []).isNotEmpty)
              _bstiChipRow(context, '도움', AppColors.safe,
                  kConcernIngredients[c]!),
            if ((kConcernAvoidIngredients[c] ?? const []).isNotEmpty)
              _bstiChipRow(context, '주의', AppColors.danger,
                  kConcernAvoidIngredients[c]!),
          ],
          const SizedBox(height: 10),
          Text('성분을 누르면 논문 근거를 볼 수 있어요',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  /// BSTI 사전 성분 칩 줄 — 칩 탭 → 역할 + 논문 근거 시트.
  Widget _bstiChipRow(
      BuildContext context, String label, Color color, List<String> ids) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label,
              style: AppTextStyles.caption.copyWith(
                  fontSize: 11, color: color, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final id in ids)
                if (kBstiIngredients[id] != null)
                  GestureDetector(
                    onTap: () => _showBstiEvidence(context, id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: color, width: 1.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(kBstiIngredients[id]!.nameKo,
                          style: AppTextStyles.caption.copyWith(
                              fontSize: 12, color: AppColors.textPrimary)),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  /// advisory.action → CTA 라벨.
  static String? _advisoryCtaLabel(String? action) => switch (action) {
        'take_bsti' => 'BSTI 검사하러 가기',
        'retry_with_other_concerns' => '피부고민 바꿔보기',
        'retry_later' => '다시 시도',
        _ => null,
      };

  /// advisory.action → CTA 동작.
  VoidCallback? _advisoryCtaAction(
      BuildContext context, WidgetRef ref, String? action) {
    return switch (action) {
      'take_bsti' => () => context.push('/bsti'),
      'retry_with_other_concerns' => () => context.push('/profile/edit'),
      'retry_later' => () => ref.invalidate(recommendationProvider),
      _ => null,
    };
  }

  /// ② 성분 근거 시트 — 효능·권장 농도·주의·규제 경고·근거 문서.
  void _showConcernEvidence(BuildContext context, RecoIngredient ing) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ing.nameKor, style: AppTextStyles.title),
              if (ing.inci != null) ...[
                const SizedBox(height: 2),
                Text(ing.inci!,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
              ],
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 추천 근거 — 새 명세는 efficacy, 구버전은 reason.
                      if (ing.reason != null || ing.efficacy != null) ...[
                        const SectionLabel('추천 근거'),
                        Text(
                            _stripEvidenceRefs(
                                ing.reason ?? ing.efficacy!),
                            style:
                                AppTextStyles.body.copyWith(height: 1.6)),
                        const SizedBox(height: 12),
                      ],
                      if (ing.concentration != null) ...[
                        const SectionLabel('권장 농도'),
                        Text(ing.concentration!,
                            style:
                                AppTextStyles.body.copyWith(height: 1.5)),
                        const SizedBox(height: 12),
                      ],
                      if (ing.safetyNote != null) ...[
                        const SectionLabel('주의사항', color: AppColors.danger),
                        Text(ing.safetyNote!,
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textPrimary, height: 1.5)),
                        const SizedBox(height: 12),
                      ],
                      for (final w in ing.warnings)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  size: 14, color: AppColors.danger),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text('[${w.type}] ${w.text}',
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.danger,
                                        height: 1.4)),
                              ),
                            ],
                          ),
                        ),
                      if (ing.sourceTitles.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        const SectionLabel('근거 문서'),
                        for (final t in ing.sourceTitles.toSet())
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('· $t',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.4)),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// BSTI 성분 근거 시트 — 사전의 역할 + 논문 근거(kBstiReferences).
  void _showBstiEvidence(BuildContext context, String bstiId) {
    final ing = kBstiIngredients[bstiId];
    if (ing == null) return;
    final refs = [
      for (final code in ing.refCodes)
        if (kBstiReferences[code] != null) kBstiReferences[code]!,
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ing.nameKo, style: AppTextStyles.title),
              if (ing.inci != null) ...[
                const SizedBox(height: 2),
                Text(ing.inci!,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
              ],
              if (ing.role != null) ...[
                const SizedBox(height: 12),
                const SectionLabel('성분 역할'),
                Text(ing.role!,
                    style: AppTextStyles.body.copyWith(height: 1.5)),
              ],
              if (refs.isNotEmpty) ...[
                const SizedBox(height: 14),
                const SectionLabel('논문 근거'),
                for (final r in refs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('[${r.code}] ',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700)),
                        Expanded(
                          child: Text(r.title,
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textPrimary, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 유사 케이스 팝업 — 상담 질문·전문가 답변·그때 추천된 성분.
  void _showSimilarCase(BuildContext context, int no, RecoCase c) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('유사 케이스 $no — ${c.targetConcern}',
            style: AppTextStyles.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (c.profileLine.isNotEmpty)
                Text(c.profileLine,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
              if (c.question != null) ...[
                const SizedBox(height: 10),
                const SectionLabel('상담 내용'),
                Text(c.question!,
                    style: AppTextStyles.body.copyWith(height: 1.6)),
              ],
              if (c.answer != null) ...[
                const SizedBox(height: 10),
                const SectionLabel('전문가 답변'),
                Text(c.answer!,
                    style: AppTextStyles.body.copyWith(height: 1.6)),
              ],
              if (c.recommendedIngredients.isNotEmpty) ...[
                const SizedBox(height: 10),
                const SectionLabel('이 케이스의 추천 성분'),
                Text(c.recommendedIngredients.join(', '),
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary, height: 1.5)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }


  /// 제품끼리 겹치는 규제 성분 — 같이 쓰면 과할 수 있는 조합.
  /// 성분을 누르면 해설(①)이 뜬다.
  Widget _conflictSection(BuildContext context, ShelfReport report) {
    return PixelBox(
      borderColor: AppColors.danger,
      fillColor: AppColors.danger.withValues(alpha: 0.06),
      pixel: 5,
      borderWidth: 2,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 18, color: AppColors.danger),
              const SizedBox(width: 6),
              Text('같이 쓰면 과할 수 있어요',
                  style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.danger)),
            ],
          ),
          const SizedBox(height: 4),
          Text('규제(한도) 성분이 여러 제품에 겹칩니다 — 성분을 누르면 해설',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          for (final c in report.conflicts)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () => IngredientDetailSheet.show(
                  context,
                  ingredientId: c.serverIngredientId,
                  fallbackName: c.nameKr,
                ),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('· ',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.danger)),
                    Expanded(
                      child: Text(
                        '${c.nameKr} — ${c.productNames.join(', ')}',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary, height: 1.4),
                      ),
                    ),
                    const Icon(Icons.expand_more,
                        size: 14, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 지금 쓰는 화장품 한 줄 — 펼치면 권장/주의 성분이 나온다.
///
/// 제품명을 누르면 제품 상세로, 성분을 누르면 성분 근거(논문) 시트로.
class _MatchToggle extends StatefulWidget {
  const _MatchToggle({required this.match});

  final ProductMatch match;

  @override
  State<_MatchToggle> createState() => _MatchToggleState();
}

class _MatchToggleState extends State<_MatchToggle> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final score = m.score;
    final color = score == null
        ? AppColors.textSecondary
        : (score >= 80
            ? AppColors.safe
            : score >= 50
                ? AppColors.accent
                : AppColors.danger);
    final hasDetail = m.recommendIds.isNotEmpty || m.avoidIds.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PixelBox(
        borderColor: AppColors.outline,
        pixel: 5,
        borderWidth: 2,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    // 제품명 → 제품 상세.
                    onTap: m.productId == null
                        ? null
                        : () => context.push('/shelf/product',
                            extra: Product(id: m.productId!, name: m.name)),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name,
                            style: AppTextStyles.body
                                .copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(m.verdict,
                            style: AppTextStyles.caption
                                .copyWith(color: color)),
                      ],
                    ),
                  ),
                ),
                Text(score == null ? '–' : '$score',
                    style: AppTextStyles.pointBoldEn(size: 24, color: color)),
                if (hasDetail)
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                          size: 22,
                          color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
            if (_expanded && hasDetail) ...[
              const SizedBox(height: 10),
              if (m.recommendIds.isNotEmpty)
                _chipRow(context, '권장', AppColors.safe, m.recommendIds),
              if (m.avoidIds.isNotEmpty)
                _chipRow(context, '주의', AppColors.danger, m.avoidIds),
            ],
          ],
        ),
      ),
    );
  }

  /// 매칭 성분 칩 줄 — 칩을 누르면 역할+논문 근거 시트.
  Widget _chipRow(
      BuildContext context, String label, Color color, List<String> ids) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(label,
                style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final id in ids)
                  if (kBstiIngredients[id] != null)
                    GestureDetector(
                      onTap: () => _showEvidence(context, id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: color, width: 1.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(kBstiIngredients[id]!.nameKo,
                            style: AppTextStyles.caption.copyWith(
                                fontSize: 12, color: AppColors.textPrimary)),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 왜 권장/주의인지 — 역할 + 논문 근거.
  void _showEvidence(BuildContext context, String bstiId) {
    final ing = kBstiIngredients[bstiId];
    if (ing == null) return;
    final refs = [
      for (final code in ing.refCodes)
        if (kBstiReferences[code] != null) kBstiReferences[code]!,
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ing.nameKo, style: AppTextStyles.title),
              if (ing.role != null) ...[
                const SizedBox(height: 10),
                const SectionLabel('성분 역할'),
                Text(ing.role!,
                    style: AppTextStyles.body.copyWith(height: 1.5)),
              ],
              if (refs.isNotEmpty) ...[
                const SizedBox(height: 12),
                const SectionLabel('논문 근거'),
                for (final r in refs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('[${r.code}] ${r.title}',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary, height: 1.4)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
