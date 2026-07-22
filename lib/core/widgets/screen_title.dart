import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

/// 화면 상단 타이틀 줄.
///
/// 헤더(로고)와 푸터(탭)는 쉘이 고정으로 갖고 있으므로, 화면들은 AppBar 대신
/// body 맨 위에 이걸 놓는다. [onBack] 을 주면 뒤로가기 화살표가 붙는다.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  size: 18, color: AppColors.textPrimary),
              onPressed: onBack,
            )
          else
            const SizedBox(width: 16),
          Expanded(
            child: Text(title,
                textAlign: onBack == null ? TextAlign.left : TextAlign.center,
                style: AppTextStyles.title),
          ),
          trailing ?? SizedBox(width: onBack != null ? 48 : 16),
        ],
      ),
    );
  }
}
