import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';

/// 홈 화면 — 기능 허브.
/// (피그마 Home: 제품·성분 검색바 + 내 화장대 만들기 + 맞춤 제품추천 + BSTI + My skin i-TEM)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('cosmos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _searchBar(context),
          const SizedBox(height: 20),
          _entryCard(
            context,
            title: 'BSTI 검사',
            subtitle: '16가지 유형 피부타입 검사 · 내 피부와 화장대의 종합분석',
            icon: Icons.psychology_outlined,
            onTap: () => context.push('/bsti'),
          ),
          _entryCard(
            context,
            title: '내 화장대 만들기',
            subtitle: '내 화장대는 몇 점? · 자주 쓰는 제품·성분 등록',
            icon: Icons.shelves,
            onTap: () => context.push('/shelf'),
          ),
          _entryCard(
            context,
            title: '맞춤 제품추천',
            subtitle: 'My skin i-TEM · 나와 꼭 맞는 성분·제품 추천',
            icon: Icons.recommend_outlined,
            onTap: () => context.push('/recommendation'),
          ),
        ],
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/shelf/add'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: AppColors.primary),
            SizedBox(width: 12),
            Text('여기에 제품·성분명을 입력해주세요',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _entryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
