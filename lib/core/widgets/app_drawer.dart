import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_assets.dart';

/// 좌측 서랍 메뉴 — 홈과 프로필 화면이 함께 쓴다.
///
/// 항목이 모두 온보딩 완료를 요구하는 곳이라, 여는 쪽에서 완료 여부를 보고
/// 햄버거 자체를 감춘다.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Image.asset(AppAssets.logoWordmark, height: 32),
            ),
            const Divider(height: 1),
            _item(context, Icons.psychology_outlined, 'BSTI 검사',
                () => context.push('/bsti')),
            _item(context, Icons.shelves, '나의 화장대',
                () => context.go('/shelf')),
            _item(context, Icons.recommend_outlined, '맞춤 제품추천',
                () => context.push('/recommendation')),
            _item(context, Icons.person_outline, '마이페이지',
                () => context.go('/profile')),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback go,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        // 열어둔 채 이동하면 다음 화면 위에 남는다.
        Navigator.pop(context);
        go();
      },
    );
  }
}
