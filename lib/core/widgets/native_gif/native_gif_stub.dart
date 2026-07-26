import 'package:flutter/widgets.dart';

/// 비웹 플랫폼용 — 일반 [Image.asset] 으로 그린다 (모바일은 GIF 재생 정상).
/// 웹 구현은 native_gif_web.dart 가 조건부 import 로 대체한다.
class NativeGif extends StatelessWidget {
  const NativeGif({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
  });

  final String assetPath;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}
