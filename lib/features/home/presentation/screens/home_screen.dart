import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../product/data/models/product.dart';
import '../../../product/presentation/widgets/product_card.dart';

/// 홈 화면. 추천 제품 + 성분 검색 진입.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text('cosmos'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => context.push('/search'),
              ),
            ],
          ),
          SliverToBoxAdapter(child: _searchEntry(context)),
          SliverToBoxAdapter(child: _sectionHeader('오늘의 추천')),
          SliverList.builder(
            itemCount: sampleProducts.length,
            itemBuilder: (context, i) {
              final p = sampleProducts[i];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ProductCard(
                  product: p,
                  onTap: () => context.push('/product/${p.id}'),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _searchEntry(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: InkWell(
        onTap: () => context.push('/search'),
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
              Text('제품명 · 성분명으로 검색',
                  style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
    );
  }
}
