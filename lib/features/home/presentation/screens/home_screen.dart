import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/pixel_box.dart';
import '../../../../core/widgets/pixel_button.dart';

/// 홈 화면 — 기능 허브. (피그마 가안 레이아웃)
///
/// 상단바: 햄버거(좌) · COSMOS 로고(중앙) · 마이페이지(우)
/// 검색바: "제품·성분" 라벨 + 알약형 입력창
/// 섹션: ① 내 화장대 점수 배너(이미지 전체가 버튼 → BSTI)
///        ② 2×2 메뉴 (피부타입 검사·맞춤 제품추천 / 내 화장대·베스트 궁합추천)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 헤더(로고)·서랍·푸터는 쉘(AppShell)이 고정으로 가진다.
    return Scaffold(
      // 한 화면에 들어오게 배치하되, 작은 화면에선 안전하게 스크롤.
      // IntrinsicHeight — 스크롤 안에서도 Spacer가 동작하도록 높이를 확정한다.
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  child: Column(
                    children: [
                      _searchBar(context),
                      // 검색창 바로 아래로 배너를 붙인다.
                      const SizedBox(height: 16),
                      _shelfScoreSection(context),
                      // 배너와 메뉴 사이는 붙이고, 남는 공간은 아래로 몬다.
                      const SizedBox(height: 16),
                      _menuGrid(context),
                      const SizedBox(height: 14),
                      // 다중 제품 비교 — 성분 구성 차이 + 해설.
                      PixelButton(
                        label: '제품 비교하기',
                        icon: Icons.compare_arrows,
                        onPressed: () => context.push('/compare'),
                      ),
                      const Spacer(flex: 3),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 검색바: 🔍 제품·성분 + 알약형 입력창 ──
  Widget _searchBar(BuildContext context) {
    return Row(
      children: [
        Image.asset(AppAssets.iconSearch,
            width: 34,
            height: 34,
            errorBuilder: (_, __, ___) => const Icon(Icons.search,
                color: AppColors.textPrimary, size: 32)),
        const SizedBox(width: 8),
        Text('제품·성분',
            style: AppTextStyles.title.copyWith(color: AppColors.textPrimary)),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/shelf/add'),
            behavior: HitTestBehavior.opaque,
            child: PixelBox(
              borderColor: AppColors.textPrimary,
              // 그림자 없이 테두리만.
              pixel: 6,
              borderWidth: 2.5,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text('여기에 제품·성분명을 입력해주세요',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
            ),
          ),
        ),
      ],
    );
  }

  // ── ① 내 화장대는 몇 점? — 배너 이미지 한 장 전체가 버튼 ──
  //
  // 타이틀·설명·START·고양이가 이미지 안에 모두 그려져 있어서
  // 따로 텍스트나 버튼 위젯을 얹지 않는다. 이미지 전체를 탭하면 BSTI로.
  Widget _shelfScoreSection(BuildContext context) {
    // 배너 문구가 "종합분석 보고서 보러가기" → 보고서로.
    // (BSTI 검사 전이면 보고서가 "검사 먼저" 안내를 띄운다)
    return _ImageButton(
      asset: AppAssets.homeShelfScoreBanner,
      // START 버튼만 커진 버전 — 이미지가 들어오면 자동으로 교체된다.
      hoverAsset: AppAssets.homeShelfScoreBannerHover,
      label: '내 화장대 점수는??',
      onTap: () => context.push('/report'),
    );
  }

  // ── ② 메뉴 — [BSTI | 내 화장대] 2단, 그 아래 My-Skin ITEM 가로 전체 ──
  //
  // 이미지 안에 캡션·타이틀·버튼이 모두 그려져 있어 텍스트를 얹지 않는다.
  Widget _menuGrid(BuildContext context) {
    return Column(
      children: [
        // 1행: BSTI | 내 화장대 (정사각 이미지 2장 → 좌우 균등)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ImageButton(
                asset: AppAssets.homeBsti,
                label: 'BSTI 피부타입 검사',
                // BSTI PNG 는 내부 여백이 많아 같은 폭에서 작아 보인다 —
                // 살짝 키워 화장대(0.92)와 크기를 맞춘다. (1.04 는 12px 간격
                // 안에서 흡수되는 수준이라 옆 버튼을 침범하지 않는다)
                widthFactor: 1.04,
                onTap: () => context.push('/bsti'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ImageButton(
                asset: AppAssets.homeShelf,
                label: '내 화장대 만들기',
                // 원본 PNG 여백이 BSTI 쪽보다 적어 더 크게 보인다 — 살짝 줄여 맞춤.
                widthFactor: 0.92,
                // 화장대(담은 리스트)로. 담기는 거기 검색창에서 한다.
                onTap: () => context.go('/shelf'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 2행: My-Skin ITEM — 가로로 긴 이미지. 폭을 살짝만 좁힌다.
        FractionallySizedBox(
          widthFactor: 0.88,
          child: _ImageButton(
            asset: AppAssets.homeMyItem,
            label: '나와 베스트 궁합 제품추천',
            onTap: () => context.push('/recommendation'),
          ),
        ),
      ],
    );
  }
}

/// 이미지 한 장이 통째로 버튼인 홈 메뉴.
///
/// 캡션·타이틀·화살표가 이미지 안에 그려져 있으므로 위에 아무것도 얹지 않는다.
/// 이미지가 없을 때만 [label] 텍스트 플레이스홀더로 대체한다.
class _ImageButton extends StatefulWidget {
  const _ImageButton({
    required this.asset,
    required this.label,
    required this.onTap,
    this.widthFactor = 1.0,
    this.hoverAsset,
  });

  final String asset;

  /// 이미지 로드 실패 시 보여줄 대체 문구 (스크린리더 라벨 겸용).
  final String label;
  final VoidCallback onTap;

  /// 1.0 미만이면 그만큼 줄여 그린다 — 원본 PNG 여백이 제각각이라
  /// 버튼끼리 크기를 맞출 때 쓴다.
  final double widthFactor;

  /// 호버 시 교체할 이미지 (예: START 버튼만 커진 버전).
  /// 주어지면 스케일 효과 대신 **이미지 두 장 교체**로 반응한다.
  /// 파일이 아직 없으면 기본 이미지가 유지된다.
  final String? hoverAsset;

  @override
  State<_ImageButton> createState() => _ImageButtonState();
}

class _ImageButtonState extends State<_ImageButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    // 호버 반응: 호버 이미지가 있으면 두 장 교체, 없으면 스케일.
    // 프레스(누름)는 공통으로 살짝 눌린다.
    final hasHoverImage = widget.hoverAsset != null;
    final scale =
        _pressed ? 0.96 : (_hovered && !hasHoverImage ? 1.04 : 1.0);

    return Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: FractionallySizedBox(
              widthFactor: widget.widthFactor,
              // 두 장을 겹쳐두고 투명도만 바꾼다 — 첫 호버에 로딩 깜빡임이 없다.
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: hasHoverImage && _hovered ? 0.0 : 1.0,
                    child: Image.asset(
                      widget.asset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryLight.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(widget.label,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textPrimary)),
                      ),
                    ),
                  ),
                  if (hasHoverImage)
                    Positioned.fill(
                      child: Opacity(
                        opacity: _hovered ? 1.0 : 0.0,
                        child: Image.asset(
                          widget.hoverAsset!,
                          fit: BoxFit.contain,
                          // 호버 이미지가 아직 없으면 조용히 기본 유지.
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 햄버거 메뉴 드로어 (임시 — 실제 메뉴 항목은 피그마 확정 후 채움).
