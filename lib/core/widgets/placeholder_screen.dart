import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// 화면 구조·라우팅 배선 단계용 공통 플레이스홀더.
///
/// 각 화면의 상세 UI는 담당자가 피그마대로 채운다. 지금은 동선(라우팅)이
/// 동작하는지 확인하기 위한 뼈대다. 실제 화면을 구현하면 이 위젯을 교체한다.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    this.description,
    this.actions = const [],
  });

  final String title;
  final String? description;

  /// 다음 화면으로 가는 임시 버튼들: (라벨, onTap).
  final List<({String label, VoidCallback onTap})> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.widgets_outlined,
                  size: 48, color: AppColors.primary.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              if (description != null) ...[
                const SizedBox(height: 8),
                Text(description!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
              const SizedBox(height: 8),
              const Text('(화면 준비 중 — 라우팅 배선 단계)',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 24),
              for (final a in actions) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: a.onTap, child: Text(a.label)),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
