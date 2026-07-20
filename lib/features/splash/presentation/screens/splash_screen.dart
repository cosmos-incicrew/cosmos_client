import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/start_button.dart';

/// 앱 시작 시 뜨는 로딩/시작 화면 — 고양이 메인 로고 + START 버튼.
///
/// START를 누르면 온보딩으로 넘어간다.
/// (피그마: 앱 켜면 메인 로고 → START → 온보딩)
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            // 메인 로고 — 움직이는 고양이 GIF (앱 오픈 시 재생).
            // 살짝 오른쪽으로 치우치게 배치.
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Image.asset(
                AppAssets.logoFullAnimated,
                width: w * 0.85,
                fit: BoxFit.contain,
              ),
            ),
            const Spacer(flex: 1),
            // START 버튼(이미지) → 온보딩. 누르면 손가락 커서가 뜬다.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: StartButton(
                onPressed: () => context.go('/onboarding'),
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
