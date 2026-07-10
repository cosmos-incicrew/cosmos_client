import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// 나의 화장대 — 등록한 제품·성분 LIST + 화장대 점수.
/// (피그마: "나의 화장대", 제품/성분 검색 등록, 나의 화장대 LIST)
class MyShelfScreen extends StatelessWidget {
  const MyShelfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: '나의 화장대',
      description: '등록한 제품·성분 목록 + 화장대 점수. "내 화장대는 몇 점?"',
      actions: [
        (label: '제품·성분 추가', onTap: () => context.push('/shelf/add')),
      ],
    );
  }
}
