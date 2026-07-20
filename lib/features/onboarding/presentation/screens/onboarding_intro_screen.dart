import 'package:flutter/material.dart';

import '../../../../app/theme/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../bsti/bsti_intro_screen.dart';

/// 온보딩 인트로 — 서비스 소개 슬라이드 (가로 스와이프).
///
/// 피그마 온보딩 여러 장을 PageView로 구성한다. 마지막 장에서 "시작하기"를 누르면
/// 로그인 시트(/login)로 이어진다. 각 슬라이드의 이미지·문구는 피그마 확정본으로 교체.
class OnboardingIntroScreen extends StatefulWidget {
  const OnboardingIntroScreen({super.key});

  @override
  State<OnboardingIntroScreen> createState() => _OnboardingIntroScreenState();
}

class _OnboardingIntroScreenState extends State<OnboardingIntroScreen> {
  final _controller = PageController();
  int _page = 0;

  // 피그마 온보딩 슬라이드 (문구 기준 — 이미지는 추후 교체).
  static const _slides = <_Slide>[
    _Slide(
      badge: 'BSTI',
      title: '내 피부타입 검사하고',
      body: '25가지 문항으로 알아보는\n16개 유형의 피부 MBTI',
      asset: AppAssets.bstiAllTypes,
    ),
    _Slide(
      badge: 'MY SHELF',
      title: '내 피부고민과\n화장품 등록하면',
      body: '검색 기반의 빠르고 쉬운\n제품·성분 등록',
      asset: AppAssets.onboardingShelf,
    ),
    _Slide(
      badge: 'REPORT',
      title: '내 화장대\n종합보고서까지',
      body: '나와 꼭 맞는\n제품추천',
      asset: AppAssets.onboardingReport,
    ),
  ];

  bool get _isLast => _page == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      LoginSheet.show(context); // 온보딩 끝 → 로그인 시트(모달, 뒤 화면 유지)
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 건너뛰기 — 글자 없이 큰 화살표만으로 '나가기' 표시.
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => LoginSheet.show(context),
                  icon: const Icon(Icons.arrow_forward,
                      size: 30, color: AppColors.textSecondary),
                  tooltip: '건너뛰기',
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                // 첫 장은 BSTI 소개 디자인(고양이 모음 + 축 글자), 나머지는 기본 슬라이드.
                itemBuilder: (_, i) => i == 0
                    ? const BstiIntroContent(showCats: true)
                    : _SlideView(slide: _slides[i]),
              ),
            ),
            // 인디케이터 (점)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.outline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_isLast ? '시작하기' : '다음'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.badge,
    required this.title,
    required this.body,
    this.asset,
  });
  final String badge;
  final String title;
  final String body;

  /// 슬라이드 일러스트 경로. null이면 badge 텍스트 박스로 대체.
  final String? asset;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 순서: 제목 → 일러스트 → 본문
          Text(slide.title,
              textAlign: TextAlign.center, style: AppTextStyles.pointMd()),
          const SizedBox(height: 24),
          // 일러스트 — 이미지가 있으면 표시, 없으면 badge 텍스트 박스.
          if (slide.asset != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                slide.asset!,
                width: 240,
                height: 240,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _badgeBox(),
              ),
            )
          else
            _badgeBox(),
          const SizedBox(height: 24),
          Text(slide.body,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                  fontSize: 18, color: AppColors.textSecondary, height: 1.6)),
        ],
      ),
    );
  }

  /// 일러스트가 없는 슬라이드용 대체 박스 (badge 텍스트).
  Widget _badgeBox() => Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: Text(slide.badge,
            style: AppTextStyles.pointBoldEn(
                size: 30, color: AppColors.primary)),
      );
}
