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
      title: 'cosmos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      // 데스크톱/웹에서 폰 화면 비율로 보이게 감싼다. (실제 모바일에선 그대로)
      builder: (context, child) =>
          PhoneFrame(child: child ?? const SizedBox.shrink()),
    );
  }
}
