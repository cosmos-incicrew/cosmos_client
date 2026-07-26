import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

/// 공용 로딩 표시 — "로딩중." → ".." → "..." 점이 늘어나는 텍스트.
///
/// 파란 원형 스피너 대신 앱 전체가 이걸 쓴다 (보고서의 GIF 로딩만 예외).
/// [caption] 을 주면 아래에 설명이 붙는다. [dense] 는 박스 안 등 좁은 자리용.
class DotsLoading extends StatefulWidget {
  const DotsLoading({super.key, this.caption, this.dense = false});

  final String? caption;
  final bool dense;

  @override
  State<DotsLoading> createState() => _DotsLoadingState();
}

class _DotsLoadingState extends State<DotsLoading> {
  int _dots = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (mounted) setState(() => _dots = _dots % 3 + 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = Text('로딩중${'.' * _dots}',
        style: AppTextStyles.pointSm(color: AppColors.textPrimary)
            .copyWith(fontSize: widget.dense ? 14 : 18));
    if (widget.dense && widget.caption == null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: label));
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          label,
          if (widget.caption != null) ...[
            const SizedBox(height: 8),
            Text(widget.caption!,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}
