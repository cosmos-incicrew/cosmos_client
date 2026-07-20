import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

/// 픽셀(비트맵) 스타일 버튼.
///
/// 로고·갈무리 폰트의 레트로 픽셀 톤에 맞춘 버튼이다.
/// - 각진 사각형(라운드 0) + 두꺼운 테두리
/// - 아래·오른쪽으로 오프셋 그림자 → 눌리면 그림자가 사라지며 내려앉는 느낌
/// - 색: 기본 primary(#7490D2) / 누름 primaryLight(#C0D7F8) (docs/design-system.md)
class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// true면 가로로 꽉 채움(기본), false면 내용 크기.
  final bool expand;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _pressed = false;

  static const _borderColor = AppColors.textPrimary; // 차콜 테두리(픽셀 라인)
  static const _shadowColor = AppColors.textPrimary;
  static const _shadowOffset = 4.0;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final bg = !_enabled
        ? AppColors.outline
        : _pressed
            ? AppColors.primaryLight // 누름
            : AppColors.primary; // 기본

    final fg = _pressed ? AppColors.textPrimary : Colors.white;

    // 누르면 버튼이 그림자 자리로 내려앉는다(offset 만큼 이동 + 그림자 제거).
    final dy = _pressed ? _shadowOffset : 0.0;

    return GestureDetector(
      onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.onPressed,
      child: Padding(
        // 그림자가 들어갈 자리를 아래·오른쪽에 확보
        padding: const EdgeInsets.only(right: _shadowOffset, bottom: _shadowOffset),
        child: Transform.translate(
          offset: Offset(dy, dy),
          child: Container(
            width: widget.expand ? double.infinity : null,
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: _borderColor, width: 2.5),
              // 라운드 없음 = 각진 픽셀 형태
              borderRadius: BorderRadius.zero,
              boxShadow: _pressed
                  ? null
                  : const [
                      BoxShadow(
                        color: _shadowColor,
                        offset: Offset(_shadowOffset, _shadowOffset),
                        blurRadius: 0, // blur 0 = 픽셀처럼 딱 떨어지는 그림자
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: fg, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: AppTextStyles.pointSm(color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
