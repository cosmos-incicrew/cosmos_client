import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_assets.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

/// 좌측 서랍 메뉴 — 홈과 프로필 화면이 함께 쓴다.
///
/// 스타일은 하단바(푸터)와 맞춘다: 배경·연블루 포인트·갈무리 픽셀 폰트.
/// 아이콘은 픽셀 사각 불릿 — 픽셀 이미지 아이콘이 들어오면 교체한다.
///
/// 항목이 모두 온보딩 완료를 요구하는 곳이라, 여는 쪽에서 완료 여부를 보고
/// 햄버거 자체를 감춘다.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Image.asset(
                AppAssets.logoWordmark,
                height: 36,
                alignment: Alignment.centerLeft,
                errorBuilder: (_, __, ___) =>
                    Text('COSMOS', style: AppTextStyles.pointBoldEn(size: 20)),
              ),
            ),
            const Divider(height: 1, color: AppColors.outline),
            const SizedBox(height: 8),
            _item(context, 'BSTI 검사', () => context.push('/bsti')),
            _item(context, '나의 화장대', () => context.go('/shelf')),
            _item(context, '맞춤 제품추천', () => context.push('/recommendation')),
            _item(context, '제품 비교', () => context.push('/compare')),
            _item(context, '마이페이지', () => context.go('/profile')),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, String label, VoidCallback go) {
    return InkWell(
      onTap: () {
        // 열어둔 채 이동하면 다음 화면 위에 남는다.
        Navigator.pop(context);
        go();
      },
      // 호버·탭 시 푸터 인디케이터와 같은 연블루.
      hoverColor: AppColors.primaryLight.withValues(alpha: 0.5),
      splashColor: AppColors.primaryLight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // 픽셀 사각 불릿 (이미지 아이콘 오기 전까지의 픽셀 스타일).
            Container(
              width: 10,
              height: 10,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: 14),
            // 갈무리 픽셀 폰트 — 푸터 라벨과 같은 계열, 잘 보이게 17.
            Text(label,
                style: AppTextStyles.pointSm(color: AppColors.textPrimary)),
            const Spacer(),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
