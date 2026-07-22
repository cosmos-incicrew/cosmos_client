import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_assets.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/widgets/start_button.dart';
import '../../core/widgets/screen_title.dart';

/// BSTI 소개 콘텐츠 (재사용 위젯).
///
/// "내 피부타입 / 검사하고" → 큰 타이틀 BSTI → 설명 → 하단 표현.
/// - 온보딩 첫 슬라이드([showCats]=false): 8개 축 글자(O·S·P·W / D·R·N·T)
/// - BSTI 검사 시작 화면([showCats]=true): 16개 유형 고양이 모음 이미지
/// 폰트는 앱 컨셉 그대로: 큰 글씨=갈무리, 작은 글씨=Pretendard.
class BstiIntroContent extends StatelessWidget {
  const BstiIntroContent({super.key, this.showCats = false});

  /// 하단에 고양이 모음 이미지를 보일지 여부. false면 축 글자를 보인다.
  final bool showCats;

  static const _axesTop = [
    ('O', '지성'),
    ('S', '민감'),
    ('P', '색소'),
    ('W', '주름'),
  ];
  static const _axesBottom = [
    ('D', '건성'),
    ('R', '저항'),
    ('N', '비색소'),
    ('T', '탱탱'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 1),
          Text('내 피부타입', style: AppTextStyles.body.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          Text('검사하고', style: AppTextStyles.body.copyWith(fontSize: 18)),
          const SizedBox(height: 20),
          // 영문은 굵은 갈무리(Galmuri11 Bold).
          Text('BSTI', style: AppTextStyles.pointBoldEn(size: 44)),
          // BSTI 글씨 바로 밑에 16개 유형 고양이 모음 — 크게.
          if (showCats) ...[
            const SizedBox(height: 12),
            Flexible(
              flex: 5,
              child: Image.asset(
                AppAssets.bstiAllTypes,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text('25가지 문항으로 알아보는',
              style: AppTextStyles.body.copyWith(fontSize: 18)),
          const SizedBox(height: 10),
          Text('16개 유형의 피부 MBTI',
              style: AppTextStyles.body.copyWith(fontSize: 18)),
          const SizedBox(height: 24),
          // 축 글자 (지성/민감/색소/주름 …) — 항상 표시.
          _axisRow(_axesTop),
          const SizedBox(height: 20),
          _axisRow(_axesBottom),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _axisRow(List<(String, String)> axes) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final (code, label) in axes)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 축 알파벳도 영문 → 굵은 갈무리.
              Text(code, style: AppTextStyles.pointBoldEn(size: 30)),
              const SizedBox(height: 6),
              Text(label,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textPrimary)),
            ],
          ),
      ],
    );
  }
}

/// BSTI 검사 시작 화면 (홈에서 BSTI 진입).
///
/// 구성: 설명 문구 → BSTI 타이틀 → START 버튼 → 16개 유형 고양이 모음.
class BstiIntroScreen extends StatelessWidget {
  const BstiIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              ScreenTitle(
                title: 'BSTI 검사',
                onBack: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
              ),
              const Spacer(flex: 2),
              // 설명 문구 → BSTI 위로. (키움)
              Text('25가지 문항으로 알아보는',
                  style: AppTextStyles.title.copyWith(fontSize: 20)),
              const SizedBox(height: 12),
              Text('16개 유형의 피부 MBTI',
                  style: AppTextStyles.title.copyWith(fontSize: 20)),
              const SizedBox(height: 28),
              // 타이틀 — 더 크게. 영문이라 굵은 갈무리.
              Text('BSTI', style: AppTextStyles.pointBoldEn(size: 60)),
              const SizedBox(height: 28),
              // BSTI 아래 START 버튼(이미지).
              SizedBox(
                width: 170,
                child: StartButton(onPressed: () => context.push('/bsti/test')),
              ),
              const Spacer(flex: 1),
              // 16개 유형 고양이 모음.
              Image.asset(
                AppAssets.bstiAllTypes,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
