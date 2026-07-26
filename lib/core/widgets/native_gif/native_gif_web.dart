// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

/// 웹용 — 브라우저 네이티브 `<img>` 로 GIF 를 그린다.
///
/// Flutter 웹 렌더러가 큰 GIF 애니메이션을 첫 프레임에서 멈춰 그리는 문제가
/// 있어, 애니메이션 재생이 보장되는 브라우저 이미지 요소를 직접 얹는다.
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

  static final Set<String> _registered = {};

  @override
  Widget build(BuildContext context) {
    final viewType = 'native-gif-$assetPath';
    if (_registered.add(viewType)) {
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
        final img = html.ImageElement()
          // 웹 빌드에서 에셋은 assets/ 접두사 아래에 배포된다.
          ..src = 'assets/$assetPath'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'contain';
        return img;
      });
    }
    return SizedBox(
      width: width,
      height: height,
      child: HtmlElementView(viewType: viewType),
    );
  }
}
