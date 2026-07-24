import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/phone_frame.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// 앱 루트 위젯.
class CosmosApp extends ConsumerWidget {
  const CosmosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'COSMOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // 앱 디자인이 밝은 픽셀 테마 기준이라, 시스템(OS) 다크모드를 따라가면
      // 배경이 어둡게 떠서 깨진다. 시스템 무관하게 항상 라이트로 고정한다.
      themeMode: ThemeMode.light,
      routerConfig: router,
      // 데스크톱/웹에서 폰 화면 비율로 보이게 감싼다. (실제 모바일에선 그대로)
      builder: (context, child) =>
          PhoneFrame(child: child ?? const SizedBox.shrink()),
    );
  }
}
