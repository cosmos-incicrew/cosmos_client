import 'package:flutter/material.dart';

import '../../app/theme/app_assets.dart';
import '../../app/theme/app_text_styles.dart';

/// 픽셀 START 버튼.
///
/// START 이미지를 버튼으로 쓰고, 누르는 동안 손가락 커서 이미지가 겹쳐 뜬다.
/// (이미지가 없으면 텍스트 버튼으로 폴백)
class StartButton extends StatefulWidget {
  const StartButton({super.key, required this.onPressed, this.label = 'START'});

  final VoidCallback onPressed;
  final String label;

  @override
  State<StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<StartButton> {
  bool _pressed = false;

  void _set(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onPressed,
      // 누르면 살짝 작아지는 느낌만.
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Image.asset(
          AppAssets.startButton,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            height: 56,
            alignment: Alignment.center,
            color: Colors.black87,
            child: Text(widget.label,
                style: AppTextStyles.pointSm(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
