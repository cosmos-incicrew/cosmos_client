import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// 계단식 픽셀 테두리 박스.
///
/// 모서리를 [pixel] 크기만큼 계단지게 깎아, 레트로 픽셀아트(간판·도트) 느낌을 낸다.
/// START 버튼 같은 톤과 어울린다. 색은 디자인 토큰(AppColors)만 사용한다.
///
/// ```dart
/// PixelBox(
///   borderColor: AppColors.primary,
///   child: Text('세라마이드'),
/// )
/// ```
class PixelBox extends StatelessWidget {
  const PixelBox({
    super.key,
    required this.child,
    this.borderColor = AppColors.textPrimary,
    this.fillColor = AppColors.surface,
    this.shadowColor,
    this.pixel = 6,
    this.borderWidth = 3,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  });

  final Widget child;
  final Color borderColor;
  final Color fillColor;

  /// 아래·오른쪽에 깔리는 픽셀 그림자 색. null이면 그림자 없음.
  final Color? shadowColor;

  /// 계단 한 칸 크기(px). 클수록 각진 픽셀감이 강해진다.
  final double pixel;
  final double borderWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PixelBorderPainter(
        borderColor: borderColor,
        fillColor: fillColor,
        shadowColor: shadowColor,
        pixel: pixel,
        borderWidth: borderWidth,
      ),
      child: Padding(
        // 그림자 자리 + 계단 모서리 여백 확보.
        padding: EdgeInsets.only(
          right: shadowColor != null ? pixel : 0,
          bottom: shadowColor != null ? pixel : 0,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _PixelBorderPainter extends CustomPainter {
  _PixelBorderPainter({
    required this.borderColor,
    required this.fillColor,
    required this.shadowColor,
    required this.pixel,
    required this.borderWidth,
  });

  final Color borderColor;
  final Color fillColor;
  final Color? shadowColor;
  final double pixel;
  final double borderWidth;

  /// 모서리를 pixel 만큼 계단지게 깎은 8각형 경로를 만든다.
  Path _octagon(Rect r, double p) {
    return Path()
      ..moveTo(r.left + p, r.top)
      ..lineTo(r.right - p, r.top)
      ..lineTo(r.right, r.top + p)
      ..lineTo(r.right, r.bottom - p)
      ..lineTo(r.right - p, r.bottom)
      ..lineTo(r.left + p, r.bottom)
      ..lineTo(r.left, r.bottom - p)
      ..lineTo(r.left, r.top + p)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = shadowColor;
    final inset = shadow != null ? pixel : 0.0;
    final rect = Rect.fromLTWH(0, 0, size.width - inset, size.height - inset);

    // 그림자(아래·오른쪽으로 pixel 만큼 오프셋).
    if (shadow != null) {
      final shadowPath = _octagon(rect.translate(inset, inset), pixel);
      canvas.drawPath(shadowPath, Paint()..color = shadow);
    }

    final path = _octagon(rect, pixel);
    // 채움.
    canvas.drawPath(path, Paint()..color = fillColor);
    // 테두리.
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..strokeJoin = StrokeJoin.miter,
    );
  }

  @override
  bool shouldRepaint(_PixelBorderPainter old) =>
      old.borderColor != borderColor ||
      old.fillColor != fillColor ||
      old.shadowColor != shadowColor ||
      old.pixel != pixel ||
      old.borderWidth != borderWidth;
}
