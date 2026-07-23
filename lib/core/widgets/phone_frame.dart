import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 데스크톱/웹에서 앱을 "폰 화면 비율"로 보이게 감싸는 개발용 프레임.
///
/// 넓은 화면(웹/데스크톱)에서는 앱을 [frameSize] 크기(기본 iPhone 14 = 390×844)의
/// 캔버스 안에만 렌더하고 바깥은 여백으로 처리한다. 실제 모바일(작은 화면)에서는
/// 프레임 없이 그대로 전체 화면을 쓴다.
///
/// [MaterialApp.builder]에 끼워 모든 화면에 일괄 적용한다.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({
    super.key,
    required this.child,
    this.frameSize = const Size(390, 844),
  });

  final Widget child;

  /// 폰 캔버스 크기 (논리 픽셀). 기본값 = iPhone 14 (390×844).
  final Size frameSize;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);

    // 이미 폰만 한 화면이면(세로로 길고 프레임보다 크지 않음) 프레임을 씌우지 않는다.
    final isNarrow = screen.width <= frameSize.width + 1;
    if (isNarrow) return child;

    // 프레임을 씌우는 건 데스크톱/웹 미리보기 용도. 실제 모바일 릴리스에서는
    // 원본 그대로 두되, 웹 배포(릴리스지만 폰이 아님)에서는 프레임을 유지해야
    // 데스크톱 가로폭에 늘어나 잘리지 않는다. (실제 폰은 위 isNarrow 로 이미 제외됨)
    if (kReleaseMode && !kIsWeb) return child;

    // 세로 여백이 부족하면 비율 유지하며 축소.
    final maxH = screen.height - 32;
    final scale =
        maxH < frameSize.height ? (maxH / frameSize.height).clamp(0.1, 1.0) : 1.0;

    return ColoredBox(
      color: const Color(0xFF2B2B2B), // 프레임 바깥 배경 (여백)
      child: Center(
        child: SizedBox(
          width: frameSize.width * scale,
          height: frameSize.height * scale,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24 * scale),
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: frameSize.width,
                height: frameSize.height,
                // 프레임 내부는 폰 크기의 MediaQuery로 재정의 →
                // 화면들이 자신을 "폰 폭"으로 인식해 레이아웃한다.
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(size: frameSize),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
