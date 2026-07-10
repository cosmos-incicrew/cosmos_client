import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// 화장대에 제품·성분 추가 — 검색 자동완성 → 선택 → 추가.
/// (피그마: "여기에 제품·성분명을 입력해주세요", 세라ㅁ→세라마이드 자동완성,
///  아토베리어365 하이드로/크림/캡슐토너 제품 추천, 제품 상세 후 추가하기)
class ShelfAddScreen extends StatelessWidget {
  const ShelfAddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: '제품·성분 검색·추가',
      description: '검색 자동완성(성분/제품) → 선택 → 화장대에 추가',
    );
  }
}
